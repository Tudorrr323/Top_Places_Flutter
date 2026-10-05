import 'package:top_places/models/chat_message.dart';
import 'package:top_places/models/conversation.dart';
import 'package:top_places/models/place.dart';
import 'package:top_places/services/chat_history_service.dart';

/// Conversations kept in memory, instead of Supabase. [offline] makes every
/// call fail the way a missing connection does.
class FakeChatHistoryService implements ChatHistoryService {
  /// Every conversation, in the order they were started.
  final saved = <Conversation>[];

  /// The rows of chat_messages, for each conversation.
  final rows = <String, List<Map<String, Object?>>>{};

  bool offline = false;
  int _nextId = 1;

  /// A clock that moves a minute at every change, like the times the
  /// database gives.
  DateTime _now = DateTime(2026, 10, 1, 12);

  DateTime _tick() => _now = _now.add(const Duration(minutes: 1));

  /// A conversation saved before the test.
  Conversation savedBefore(String title, List<ChatMessage> messages) {
    final conversation = Conversation(
      id: 'c${_nextId++}',
      title: title,
      updatedAt: _tick(),
    );
    saved.add(conversation);
    rows[conversation.id] = [for (final message in messages) message.toRow()];
    return conversation;
  }

  /// The titles, newest first, as the app lists them.
  List<String> get titles => [
    for (final conversation in _newestFirst()) conversation.title,
  ];

  @override
  Future<List<Conversation>> conversations() async {
    _checkOnline();
    return _newestFirst();
  }

  @override
  Future<Conversation> start(String title) async {
    _checkOnline();
    final conversation = Conversation(
      id: 'c${_nextId++}',
      title: title,
      updatedAt: _tick(),
    );
    saved.add(conversation);
    rows[conversation.id] = [];
    return conversation;
  }

  @override
  Future<void> addMessages(
    String conversationId,
    List<ChatMessage> messages,
  ) async {
    _checkOnline();
    rows[conversationId]!.addAll(messages.map((message) => message.toRow()));
    _replace(conversationId, (old) => old.copyWith(updatedAt: _tick()));
  }

  @override
  Future<List<ChatMessage>> messages(
    String conversationId, {
    required Place? Function(String id) placeById,
  }) async {
    _checkOnline();
    return [
      for (final row in rows[conversationId]!)
        ChatMessage.fromRow(row, placeById: placeById),
    ];
  }

  @override
  Future<Conversation> rename(String conversationId, String title) async {
    _checkOnline();
    return _replace(conversationId, (old) => old.copyWith(title: title.trim()));
  }

  @override
  Future<void> delete(String conversationId) async {
    _checkOnline();
    saved.removeWhere((conversation) => conversation.id == conversationId);
    rows.remove(conversationId);
  }

  List<Conversation> _newestFirst() =>
      [...saved]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  Conversation _replace(
    String conversationId,
    Conversation Function(Conversation old) change,
  ) {
    final index = saved.indexWhere(
      (conversation) => conversation.id == conversationId,
    );
    return saved[index] = change(saved[index]);
  }

  void _checkOnline() {
    if (offline) throw const ChatHistoryException('offline');
  }
}
