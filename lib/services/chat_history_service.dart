import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:top_places/models/chat_message.dart';
import 'package:top_places/models/conversation.dart';
import 'package:top_places/models/place.dart';

/// A call to the history that failed: no internet, or a refusal of the
/// database. [detail] is for the logs; the chat says what happened in its
/// own words.
class ChatHistoryException implements Exception {
  const ChatHistoryException([this.detail]);

  final String? detail;

  @override
  String toString() => 'ChatHistoryException($detail)';
}

/// The signed-in account's conversations with the assistant. An interface,
/// so that the tests can use a fake.
abstract class ChatHistoryService {
  /// Every conversation, newest first.
  Future<List<Conversation>> conversations();

  /// Starts a conversation, without messages yet.
  Future<Conversation> start(String title);

  /// Adds [messages] at the end of a conversation.
  Future<void> addMessages(String conversationId, List<ChatMessage> messages);

  /// The messages of a conversation, in order.
  Future<List<ChatMessage>> messages(
    String conversationId, {
    required Place? Function(String id) placeById,
  });

  Future<Conversation> rename(String conversationId, String title);

  /// Deletes a conversation with its messages.
  Future<void> delete(String conversationId);
}

class SupabaseChatHistoryService implements ChatHistoryService {
  SupabaseChatHistoryService(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Conversation>> conversations() async {
    final rows = await _guard(
      () => _client
          .from('conversations')
          .select()
          // order() sorts in descending order unless told otherwise.
          .order('updated_at'),
    );
    return [for (final row in rows) Conversation.fromRow(row)];
  }

  @override
  Future<Conversation> start(String title) async {
    final row = await _guard(
      () => _client
          .from('conversations')
          .insert({'title': title})
          .select()
          .single(),
    );
    return Conversation.fromRow(row);
  }

  @override
  Future<void> addMessages(
    String conversationId,
    List<ChatMessage> messages,
  ) async {
    await _guard(
      () => _client.from('chat_messages').insert([
        for (final message in messages)
          {...message.toRow(), 'conversation_id': conversationId},
      ]),
    );
  }

  @override
  Future<List<ChatMessage>> messages(
    String conversationId, {
    required Place? Function(String id) placeById,
  }) async {
    final rows = await _guard(
      () => _client
          .from('chat_messages')
          .select()
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true)
          .order('id', ascending: true),
    );
    return [
      for (final row in rows) ChatMessage.fromRow(row, placeById: placeById),
    ];
  }

  @override
  Future<Conversation> rename(String conversationId, String title) async {
    final row = await _guard(
      () => _client
          .from('conversations')
          .update({'title': title.trim()})
          .eq('id', conversationId)
          .select()
          .single(),
    );
    return Conversation.fromRow(row);
  }

  @override
  Future<void> delete(String conversationId) async {
    await _guard(
      () => _client.from('conversations').delete().eq('id', conversationId),
    );
  }

  /// Turns the errors of Supabase and of the network into
  /// ChatHistoryException.
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on PostgrestException catch (error) {
      throw ChatHistoryException(error.message);
    } on Exception catch (error) {
      throw ChatHistoryException('$error');
    }
  }
}
