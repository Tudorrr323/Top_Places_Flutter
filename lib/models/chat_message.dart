import 'package:top_places/models/place.dart';

/// What the "Arată pe hartă" button under an answer shows. The class is
/// sealed: the compiler knows every kind of action, so a switch over one
/// must handle them all.
sealed class ChatAction {
  const ChatAction();
}

/// One place the assistant found.
class ShowPlace extends ChatAction {
  const ShowPlace(this.place);

  final Place place;
}

/// Every place in a city.
class ShowCity extends ChatAction {
  const ShowCity(this.city);

  /// The name as written in romanian_cities.json, e.g. "Cluj-Napoca".
  final String city;
}

/// The longest message the history keeps.
const maxMessageLength = 4000;

/// One message in the chat: from the user, from the assistant's rules, or
/// written by Gemini.
class ChatMessage {
  const ChatMessage.user(this.text)
    : fromUser = true,
      fromAi = false,
      action = null;

  const ChatMessage.bot(this.text, {this.action})
    : fromUser = false,
      fromAi = false;

  const ChatMessage.ai(this.text, {this.action})
    : fromUser = false,
      fromAi = true;

  /// A message from the history. [placeById] finds the place of its
  /// button; a place no longer in the app leaves the answer without one.
  factory ChatMessage.fromRow(
    Map<String, dynamic> row, {
    required Place? Function(String id) placeById,
  }) {
    final text = row['body'] as String;
    final placeId = row['place_id'] as String?;
    final place = placeId == null ? null : placeById(placeId);
    final city = row['city'] as String?;
    final action = place != null
        ? ShowPlace(place)
        : city != null
        ? ShowCity(city)
        : null;
    return switch (row['author']) {
      'user' => ChatMessage.user(text),
      'ai' => ChatMessage.ai(text, action: action),
      _ => ChatMessage.bot(text, action: action),
    };
  }

  final String text;
  final bool fromUser;

  /// True when Gemini wrote it, so the chat can label it.
  final bool fromAi;

  /// Only answers from the assistant can have one.
  final ChatAction? action;

  /// The row of chat_messages, without its conversation. A very long
  /// message is cut to what the database takes.
  Map<String, Object?> toRow() => {
    'author': fromUser
        ? 'user'
        : fromAi
        ? 'ai'
        : 'bot',
    'body': text.length > maxMessageLength
        ? text.substring(0, maxMessageLength)
        : text,
    'place_id': switch (action) {
      ShowPlace(:final place) => place.id,
      _ => null,
    },
    'city': switch (action) {
      ShowCity(:final city) => city,
      _ => null,
    },
  };
}
