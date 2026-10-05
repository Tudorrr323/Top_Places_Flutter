import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:top_places/app.dart';
import 'package:top_places/models/place.dart';
import 'package:top_places/screens/explore_screen.dart';
import 'package:top_places/services/gemini_service.dart';
import 'package:top_places/services/places_repository.dart';
import 'package:top_places/view_models/language_settings.dart';

import '../fake_gemini.dart';

void main() {
  final repository = PlacesRepository.fromJsonStrings(
    placesJson: File('assets/data/locations.json').readAsStringSync(),
    citiesJson: File('assets/data/romanian_cities.json').readAsStringSync(),
  );

  /// Starts the app and goes straight to [location], like a link on the web.
  Future<void> openLink(
    WidgetTester tester,
    String location, {
    GeminiService? gemini,
    PlacesRepository? places,
    LanguageSettings? language,
  }) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      TopPlacesApp(
        repository: places ?? repository,
        gemini: gemini,
        language: language,
      ),
    );
    await tester.pumpAndSettle();
    GoRouter.of(tester.element(find.byType(ExploreScreen))).go(location);
    await tester.pumpAndSettle();
  }

  const english =
      'Modern design, perfect for a relaxed brunch. They have the best cakes.';
  const romanian =
      'Design modern, perfect pentru un brunch relaxat. Au cele mai bune prăjituri.';

  testWidgets('the description follows the language of the app', (
    tester,
  ) async {
    final language = LanguageSettings();
    await openLink(tester, '/locations/cafe-new-world', language: language);
    expect(find.text(romanian), findsOneWidget);
    expect(find.text(english), findsNothing);
    expect(find.text('EN'), findsNothing, reason: 'no switch on the page');

    language.choose(LanguageSettings.english);
    await tester.pumpAndSettle();

    expect(find.text(english), findsOneWidget);
    expect(find.text('About the place'), findsOneWidget);
  });

  testWidgets('the vibe button shows an example, labelled as one', (
    tester,
  ) async {
    await openLink(tester, '/locations/cafe-new-world');

    await tester.tap(find.text('Arată un exemplu de vibe'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Atmosfera este electrică'), findsOneWidget);
    expect(
      find.text('Exemplu scris dinainte, nu generat de AI.'),
      findsOneWidget,
    );
  });

  testWidgets('the back button of a page opened from a link leads to Explore', (
    tester,
  ) async {
    await openLink(tester, '/locations/cafe-new-world');

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.byType(ExploreScreen), findsOneWidget);
  });

  testWidgets('an unknown place shows the not-found page', (tester) async {
    await openLink(tester, '/locations/does-not-exist');

    expect(find.text('Nu am găsit pagina căutată.'), findsOneWidget);
  });

  testWidgets('with a key, the vibe comes from Gemini, labelled as such', (
    tester,
  ) async {
    const vibe = 'Brunch lejer și prăjituri bune, într-un decor modern. 🍰';
    await openLink(
      tester,
      '/locations/cafe-new-world',
      gemini: fakeGemini(vibe),
    );

    await tester.tap(find.text('Generează un vibe cu AI'));
    await tester.pumpAndSettle();

    expect(find.text(vibe), findsOneWidget);
    expect(
      find.text('Generat cu Gemini. Poate conține greșeli.'),
      findsOneWidget,
    );
  });

  testWidgets('in English, the vibe examples are in English too', (
    tester,
  ) async {
    await openLink(
      tester,
      '/locations/cafe-new-world',
      language: LanguageSettings(locale: LanguageSettings.english),
    );

    await tester.tap(find.text('Show an example vibe'));
    await tester.pumpAndSettle();

    expect(find.textContaining('The atmosphere is electric'), findsOneWidget);
  });

  testWidgets('with a key, the vibe is asked for in the chosen language', (
    tester,
  ) async {
    final asked = <String>[];
    await openLink(
      tester,
      '/locations/cafe-new-world',
      gemini: fakeGemini(
        'A relaxed brunch spot with great cakes. 🍰',
        onRequest: (request) => asked.add(request.body),
      ),
      language: LanguageSettings(locale: LanguageSettings.english),
    );

    await tester.tap(find.text('Generate a vibe with AI'));
    await tester.pumpAndSettle();

    expect(asked.single, contains('Write only in English'));
    expect(find.text('A relaxed brunch spot with great cakes. 🍰'), findsOne);
  });

  testWidgets('an example stays on screen and changes language', (
    tester,
  ) async {
    final language = LanguageSettings();
    await openLink(tester, '/locations/cafe-new-world', language: language);
    await tester.tap(find.text('Arată un exemplu de vibe'));
    await tester.pumpAndSettle();

    language.choose(LanguageSettings.english);
    await tester.pumpAndSettle();

    expect(find.textContaining('The atmosphere is electric'), findsOneWidget);
  });

  testWidgets('an AI vibe stays on screen and is translated', (tester) async {
    final asked = <String>[];
    final language = LanguageSettings();
    await openLink(
      tester,
      '/locations/cafe-new-world',
      gemini: fakeGeminiAnswers([
        'Brunch lejer și prăjituri bune. 🍰',
        'A relaxed brunch and great cakes. 🍰',
      ], onRequest: (request) => asked.add(request.body)),
      language: language,
    );
    await tester.tap(find.text('Generează un vibe cu AI'));
    await tester.pumpAndSettle();

    language.choose(LanguageSettings.english);
    await tester.pumpAndSettle();

    expect(find.text('A relaxed brunch and great cakes. 🍰'), findsOneWidget);
    expect(asked.last, contains('Translate the text below into English'));

    // Back to Romanian: the first text again, without a new request.
    language.choose(LanguageSettings.romanian);
    await tester.pumpAndSettle();

    expect(find.text('Brunch lejer și prăjituri bune. 🍰'), findsOneWidget);
    expect(asked, hasLength(2));
  });

  testWidgets('without a Romanian description, the English one shows', (
    tester,
  ) async {
    final oneLanguage = PlacesRepository(
      initialPlaces: [
        const Place(
          id: 'ceainaria-ana',
          name: 'Ceainăria Ana',
          address: 'Str. Lăpușneanu, Nr. 3, Iași',
          city: 'Iași',
          lat: 47.16,
          lng: 27.58,
          imageUrl: '',
          description: 'Ceai bun și liniște, aproape de centru.',
          rating: 4.5,
          ownerId: 'dan',
        ),
      ],
      cities: const [],
    );
    await openLink(tester, '/locations/ceainaria-ana', places: oneLanguage);

    expect(find.text('Ceai bun și liniște, aproape de centru.'), findsOne);
  });

  testWidgets('without Supabase the reviews tab says why it is empty', (
    tester,
  ) async {
    await openLink(tester, '/locations/cafe-new-world');

    await tester.tap(find.text('Recenzii'));
    await tester.pumpAndSettle();

    expect(find.textContaining('conectată la Supabase'), findsOneWidget);
    expect(find.text('Recenzia ta'), findsNothing);
  });
}
