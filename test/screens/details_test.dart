import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:top_places/app.dart';
import 'package:top_places/screens/explore_screen.dart';
import 'package:top_places/services/gemini_service.dart';
import 'package:top_places/services/places_repository.dart';

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
  }) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      TopPlacesApp(repository: repository, gemini: gemini),
    );
    await tester.pumpAndSettle();
    GoRouter.of(tester.element(find.byType(ExploreScreen))).go(location);
    await tester.pumpAndSettle();
  }

  const english =
      'Modern design, perfect for a relaxed brunch. They have the best cakes.';
  const romanian =
      'Design modern, perfect pentru un brunch relaxat. Au cele mai bune prăjituri.';

  testWidgets(
    'the description is in Romanian, with the original one tap away',
    (tester) async {
      await openLink(tester, '/locations/cafe-new-world');
      expect(find.text(romanian), findsOneWidget);
      expect(find.text(english), findsNothing);

      await tester.tap(find.text('EN'));
      await tester.pumpAndSettle();

      expect(find.text(english), findsOneWidget);
      expect(find.text('Textul original, în engleză.'), findsOneWidget);
    },
  );

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
}
