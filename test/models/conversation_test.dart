import 'package:flutter_test/flutter_test.dart';
import 'package:top_places/models/chat_message.dart';
import 'package:top_places/models/conversation.dart';
import 'package:top_places/models/place.dart';

void main() {
  group('the title of a new conversation', () {
    test('is the first message, on one line', () {
      expect(titleFrom('  Vreau o cafea\n în Cluj  '), 'Vreau o cafea în Cluj');
    });

    test('a long message is cut at a word, near 60 characters', () {
      final title = titleFrom(
        'Merg în weekend la Sibiu cu prietenii și vrem să mâncăm bine, '
        'ce ne recomanzi?',
      );
      expect(title, 'Merg în weekend la Sibiu cu prietenii și vrem să mâncăm…');
      expect(title.length, lessThanOrEqualTo(maxTitleLength));
    });

    test('a long word is cut anyway, never inside an emoji', () {
      expect(titleFrom('a' * 100), '${'a' * 60}…');
      final title = titleFrom('${'b' * 59}😀${'c' * 40}');
      expect(title, '${'b' * 59}…');
    });
  });

  group('a message in the history', () {
    const place = Place(
      id: 'coffee-shop-zen',
      name: "Coffee Shop 'Zen'",
      address: 'Strada Dorobanților, Nr. 80, Cluj-Napoca',
      city: 'Cluj-Napoca',
      lat: 46.777,
      lng: 23.6067,
      imageUrl: '',
      description: 'Specialty coffee.',
      rating: 4.7,
    );
    Place? placeById(String id) => id == place.id ? place : null;
    ChatMessage again(ChatMessage message) =>
        ChatMessage.fromRow(message.toRow(), placeById: placeById);

    test('keeps who wrote it and what it shows on the map', () {
      final user = again(const ChatMessage.user('Cafea în Cluj'));
      expect(
        (user.text, user.fromUser, user.action),
        ('Cafea în Cluj', true, null),
      );

      final bot = again(
        const ChatMessage.bot(
          'În Cluj-Napoca...',
          action: ShowCity('Cluj-Napoca'),
        ),
      );
      expect(bot.fromUser || bot.fromAi, isFalse);
      expect((bot.action! as ShowCity).city, 'Cluj-Napoca');

      final ai = again(
        const ChatMessage.ai('Încearcă Zen.', action: ShowPlace(place)),
      );
      expect(ai.fromAi, isTrue);
      expect((ai.action! as ShowPlace).place, same(place));
    });

    test('a place no longer in the app leaves the answer without a button', () {
      final row = const ChatMessage.ai(
        'Încearcă Zen.',
        action: ShowPlace(place),
      ).toRow();
      final message = ChatMessage.fromRow(row, placeById: (id) => null);
      expect(message.action, isNull);
      expect(message.text, 'Încearcă Zen.');
    });

    test('a very long message is cut to what the database takes', () {
      final row = ChatMessage.user('x' * 5000).toRow();
      expect((row['body']! as String).length, maxMessageLength);
    });
  });
}
