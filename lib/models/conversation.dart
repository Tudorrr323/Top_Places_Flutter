/// A conversation with the assistant, kept for a signed-in account.
class Conversation {
  const Conversation({
    required this.id,
    required this.title,
    required this.updatedAt,
  });

  factory Conversation.fromRow(Map<String, dynamic> row) => Conversation(
    id: row['id'] as String,
    title: row['title'] as String,
    updatedAt: DateTime.parse(row['updated_at'] as String).toLocal(),
  );

  final String id;
  final String title;

  /// When its last message was written: the newest come first.
  final DateTime updatedAt;

  Conversation copyWith({String? title, DateTime? updatedAt}) => Conversation(
    id: id,
    title: title ?? this.title,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

/// The longest title the database takes.
const maxTitleLength = 80;

/// The title of a new conversation: its first message, cut at a word near
/// 60 characters. supabase/tools/generate_seed_conversations.js does the
/// same.
String titleFrom(String message) {
  final text = message.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (text.length <= 60) return text;
  final space = text.lastIndexOf(' ', 60);
  var end = space > 30 ? space : 60;
  // Never half of an emoji, which the database would refuse.
  if (_isHighSurrogate(text.codeUnitAt(end - 1))) end--;
  return '${text.substring(0, end).trimRight()}…';
}

bool _isHighSurrogate(int codeUnit) => codeUnit >= 0xD800 && codeUnit <= 0xDBFF;
