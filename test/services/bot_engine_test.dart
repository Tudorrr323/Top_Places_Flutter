import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:top_places/l10n/app_localizations.dart';
import 'package:top_places/models/chat_message.dart';
import 'package:top_places/services/bot_engine.dart';
import 'package:top_places/services/places_repository.dart';

void main() {
  final repository = PlacesRepository.fromJsonStrings(
    placesJson: File('assets/data/locations.json').readAsStringSync(),
    citiesJson: File('assets/data/romanian_cities.json').readAsStringSync(),
  );

  /// A new assistant for every test, so no test sees another's conversation.
  BotEngine newBot([String language = 'ro']) => BotEngine(
    places: repository.places,
    cities: repository.cities,
    l10n: lookupAppLocalizations(Locale(language)),
  );

  /// The place an answer shows on the map, or null.
  String? placeIn(ChatMessage answer) => switch (answer.action) {
    ShowPlace(:final place) => place.name,
    _ => null,
  };

  /// The city an answer shows on the map, or null.
  String? cityIn(ChatMessage answer) => switch (answer.action) {
    ShowCity(:final city) => city,
    _ => null,
  };

  group('questions about the app', () {
    test('a greeting', () {
      expect(newBot().reply('Bună ziua!').text, startsWith('Salut!'));
    });

    test('how to book', () {
      expect(newBot().reply('Cum fac o rezervare?').text, contains('WhatsApp'));
    });

    test('the map and the list', () {
      expect(newBot().reply('Unde e harta?').text, contains('listă și hartă'));
    });

    test('anything else gets the fallback, with no button', () {
      final answer = newBot().reply('Care e capitala Franței?');
      expect(answer.text, startsWith('Nu am înțeles'));
      expect(answer.action, isNull);
    });
  });

  group('going out', () {
    test('a drink in Cluj-Napoca lists the cafés, not the restaurant', () {
      final answer = newBot().reply('Vreau să beau ceva în Cluj-Napoca');
      expect(cityIn(answer), 'Cluj-Napoca');
      expect(answer.text, contains("Coffee Shop 'Zen'"));
      expect(answer.text, isNot(contains('The Old Inn')));
    });

    test('a meal in Târgu Mureș, typed without diacritics', () {
      final answer = newBot().reply('unde pot manca in targu mures?');
      expect(cityIn(answer), 'Târgu Mureș');
      expect(answer.text, contains("Restaurant 'The Citadel'"));
    });

    test('asks for the city, then remembers what it was for', () {
      final bot = newBot();
      expect(bot.reply('Aș vrea să beau ceva').text, contains('În ce oraș'));

      final answer = bot.reply('Iași');
      expect(cityIn(answer), 'Iași');
      expect(answer.text, contains('poți bea ceva'));
    });

    test('a city alone shows its places', () {
      expect(cityIn(newBot().reply('Brașov')), 'Brașov');
    });
  });

  group('searching', () {
    test('the best coffee is the first of the two rated 4.8', () {
      final answer = newBot().reply('Unde găsesc cea mai bună cafea?');
      expect(placeIn(answer), "The Literary Coffee House 'Citadel'");
    });

    test('the best coffee in Cluj', () {
      final answer = newBot().reply('cea mai buna cafea din Cluj');
      expect(placeIn(answer), "Coffee Shop 'Zen'");
    });

    test('"vin" means wine, not the end of "servings"', () {
      final answer = newBot().reply('Unde găsesc un vin bun?');
      expect(placeIn(answer), "Trattoria 'Bella Vita'");
    });

    test('a bar in Alba Iulia', () {
      final answer = newBot().reply('un bar în Alba Iulia');
      expect(placeIn(answer), "Smoothie Bar 'Energy'");
    });

    test('a place by its name', () {
      expect(placeIn(newBot().reply('Caută New World')), "Café 'New World'");
      expect(
        placeIn(newBot().reply('Arată-mi restaurantul The Citadel')),
        "Restaurant 'The Citadel'",
      );
    });

    test('says so when nothing matches', () {
      final answer = newBot().reply('Vreau sushi');
      expect(answer.text, startsWith('Din păcate'));
      expect(answer.action, isNull);
    });
  });

  group('in English', () {
    test('it answers in English', () {
      expect(newBot('en').reply('Hello!').text, startsWith('Hi!'));
      expect(newBot('en').reply('How do I book?').text, contains('WhatsApp'));
    });

    test('it understands what someone wants, and where', () {
      final answer = newBot('en').reply('I want a drink in Cluj-Napoca');
      expect(answer.text, startsWith('In Cluj-Napoca you can have a drink at'));
      expect(cityIn(answer), 'Cluj-Napoca');
    });

    test('it asks for the city, and remembers the question', () {
      final bot = newBot('en');
      expect(bot.reply('Where can I eat?').text, contains('In which city'));
      expect(cityIn(bot.reply('Iasi')), 'Iași');
    });

    test('it finds a place by its name', () {
      expect(placeIn(newBot('en').reply('Find Burger Shack')), 'Burger Shack');
    });

    test('the best coffee', () {
      final answer = newBot('en').reply('The best coffee');
      expect(answer.text, contains('with the best rating'));
      expect(placeIn(answer), isNotNull);
    });
  });

  group('the language of a message', () {
    test('Romanian and English are understood', () {
      for (final message in [
        'Vreau să beau ceva în Cluj-Napoca',
        'Cea mai bună cafea din Iași',
        'I want a drink in Cluj-Napoca',
        'Where can I eat?',
        // Diacritics of other languages, in the names of places.
        'Caută Café New World',
        'Fast-Food Döner King',
        'Iasi',
      ]) {
        expect(BotEngine.speaksLanguageOf(message), isTrue, reason: message);
      }
    });

    test('other languages are recognised', () {
      for (final message in [
        'Ich möchte in Cluj etwas trinken',
        'Wo kann ich in Iași gut essen?',
        'Je voudrais manger à Brașov',
        '¿Dónde puedo comer en Sibiu?',
        'Vorrei mangiare qualcosa a Timișoara',
        'Dove si mangia bene a Sibiu?',
        'Hol tudok enni Kolozsváron? Szeretnék egy jó éttermet',
        'Где поесть в Клуже?',
        '札幌でおすすめのカフェは?',
      ]) {
        expect(BotEngine.speaksLanguageOf(message), isFalse, reason: message);
      }
    });
  });
}
