import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:top_places/models/chat_message.dart';
import 'package:top_places/models/conversation.dart';
import 'package:top_places/models/place.dart';
import 'package:top_places/services/chat_history_service.dart';
import 'package:top_places/view_models/account_view_model.dart';

/// The history of the chat: the signed-in account's conversations, newest
/// first. It follows the account: another account gets its own, and
/// signing out forgets them.
class ConversationsViewModel extends ChangeNotifier {
  ConversationsViewModel(this._service, this._account) {
    _account.addListener(_followAccount);
    _followAccount();
  }

  /// Null when the app runs without Supabase: there is no history then.
  final ChatHistoryService? _service;
  final AccountViewModel _account;

  String? _accountId;
  List<Conversation> _conversations = const [];
  bool _loading = false;
  bool _failed = false;

  /// False for visitors who are not signed in, and without Supabase.
  bool get isAvailable => _service != null && _accountId != null;

  /// The account whose conversations these are, or null.
  String? get accountId => _accountId;

  List<Conversation> get conversations => _conversations;
  bool get isLoading => _loading;

  /// True when the list could not be loaded.
  bool get hasFailed => _failed;

  void _followAccount() {
    final id = _account.profile?.id;
    if (id == _accountId) return;
    _accountId = id;
    _conversations = const [];
    _loading = false;
    _failed = false;
    notifyListeners();
    if (isAvailable) unawaited(load());
  }

  /// Loads the list again, e.g. after it failed.
  Future<void> load() async {
    final account = _accountId;
    _loading = true;
    _failed = false;
    notifyListeners();
    try {
      final loaded = await _service!.conversations();
      // Another account signed in meanwhile: these are not its own.
      if (account != _accountId) return;
      _conversations = loaded;
    } on ChatHistoryException {
      if (account != _accountId) return;
      _failed = true;
    }
    _loading = false;
    notifyListeners();
  }

  /// Starts a conversation, titled by its first message, at the top of the
  /// list.
  Future<Conversation> start(String firstMessage) async {
    final conversation = await _service!.start(titleFrom(firstMessage));
    _conversations = [conversation, ..._conversations];
    notifyListeners();
    return conversation;
  }

  /// Saves [messages] at the end of [conversation], which moves to the top.
  Future<void> add(
    Conversation conversation,
    List<ChatMessage> messages,
  ) async {
    await _service!.addMessages(conversation.id, messages);
    final index = _conversations.indexWhere(
      (saved) => saved.id == conversation.id,
    );
    // Gone meanwhile: deleted, or another account signed in.
    if (index < 0) return;
    _conversations = [
      _conversations[index].copyWith(updatedAt: DateTime.now()),
      ..._conversations.where((saved) => saved.id != conversation.id),
    ];
    notifyListeners();
  }

  /// The messages of [conversation], in order.
  Future<List<ChatMessage>> messagesOf(
    Conversation conversation, {
    required Place? Function(String id) placeById,
  }) => _service!.messages(conversation.id, placeById: placeById);

  /// True when the new title was saved.
  Future<bool> rename(Conversation conversation, String title) async {
    try {
      final renamed = await _service!.rename(conversation.id, title);
      _conversations = [
        for (final saved in _conversations)
          saved.id == renamed.id ? renamed : saved,
      ];
      notifyListeners();
      return true;
    } on ChatHistoryException {
      return false;
    }
  }

  /// True when the conversation was deleted.
  Future<bool> delete(Conversation conversation) async {
    try {
      await _service!.delete(conversation.id);
      _conversations = [
        for (final saved in _conversations)
          if (saved.id != conversation.id) saved,
      ];
      notifyListeners();
      return true;
    } on ChatHistoryException {
      return false;
    }
  }

  @override
  void dispose() {
    _account.removeListener(_followAccount);
    super.dispose();
  }
}
