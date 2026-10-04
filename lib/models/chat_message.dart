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

/// One message in the chat, written by the user or by the assistant.
class ChatMessage {
  const ChatMessage.user(this.text) : fromUser = true, action = null;

  const ChatMessage.bot(this.text, {this.action}) : fromUser = false;

  final String text;
  final bool fromUser;

  /// Only answers from the assistant can have one.
  final ChatAction? action;
}
