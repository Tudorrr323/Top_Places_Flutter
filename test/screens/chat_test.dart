import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:top_places/app.dart';
import 'package:top_places/services/gemini_service.dart';
import 'package:top_places/services/places_repository.dart';
import 'package:top_places/widgets/place_marker.dart';

import '../fake_gemini.dart';

void main() {
  final repository = PlacesRepository.fromJsonStrings(
    placesJson: File('assets/data/locations.json').readAsStringSync(),
    citiesJson: File('assets/data/romanian_cities.json').readAsStringSync(),
  );

  /// Starts the app on a phone-sized screen and opens the Asistent tab.
  Future<void> openChat(WidgetTester tester, {GeminiService? gemini}) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      TopPlacesApp(repository: repository, gemini: gemini),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Asistent'));
    await tester.pumpAndSettle();
  }

  /// Types [message] and presses Enter.
  Future<void> send(WidgetTester tester, String message) async {
    await tester.enterText(find.byType(TextField), message);
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pumpAndSettle();
  }

  testWidgets('Enter sends the message and the assistant answers', (
    tester,
  ) async {
    await openChat(tester);
    await send(tester, 'Cum fac o rezervare?');

    expect(find.text('Cum fac o rezervare?'), findsOneWidget);
    expect(find.textContaining('WhatsApp'), findsOneWidget);
  });

  testWidgets('Arată pe hartă opens Explore on the map, with the city', (
    tester,
  ) async {
    await openChat(tester);
    await send(tester, 'Vreau să beau ceva în Cluj-Napoca');

    await tester.tap(find.text('Arată pe hartă'));
    await tester.pumpAndSettle();

    expect(find.byType(FlutterMap), findsOneWidget);
    // The city is a filter, said in words over the map.
    expect(find.text('Filtre active'), findsOneWidget);
    // Its 3 places, with a marker each or in a bubble.
    final alone = find.byType(PlaceMarker).evaluate().length;
    final grouped = tester
        .widgetList<ClusterMarker>(find.byType(ClusterMarker))
        .fold(0, (sum, bubble) => sum + bubble.places.length);
    expect(alone + grouped, 3);
  });

  testWidgets('a place found by the assistant opens on the map', (
    tester,
  ) async {
    await openChat(tester);
    await tester.tap(find.text('Caută Burger Shack'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Arată pe hartă'));
    await tester.pumpAndSettle();

    expect(find.byType(FlutterMap), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(DraggableScrollableSheet),
        matching: find.text('Burger Shack'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('with a key, Gemini answers what the rules do not understand', (
    tester,
  ) async {
    const answer =
        "Pentru ceva dulce, încearcă prăjiturile de la Café 'New World', "
        'din Iași.';
    final asked = <String>[];
    await openChat(
      tester,
      gemini: fakeGemini(
        answer,
        onRequest: (request) => asked.add(request.body),
      ),
    );
    await send(tester, 'Am chef de ceva dulce, ce-mi recomanzi?');

    // Romanian, in the language of the app.
    expect(asked.single, contains('Limba răspunsului'));
    expect(find.text(answer), findsOneWidget);
    expect(
      find.text('Generat cu Gemini. Poate conține greșeli.'),
      findsOneWidget,
    );
    // The answer names one place, so it can be shown on the map.
    expect(find.text('Arată pe hartă'), findsOneWidget);
  });

  testWidgets(
    'with a key, another language goes to Gemini, which answers in it',
    (tester) async {
      const answer = 'In Cluj-Napoca empfehle ich das Restaurant The Old Inn.';
      final asked = <String>[];
      await openChat(
        tester,
        gemini: fakeGemini(
          answer,
          onRequest: (request) => asked.add(request.body),
        ),
      );

      // The rules would answer this one, by the city, in Romanian.
      await send(tester, 'Ich möchte in Cluj etwas essen');

      // In English, even though the app is in Romanian: from Romanian
      // instructions, Gemini answers some languages in Romanian.
      expect(asked.single, contains('Language of the answer'));
      expect(asked.single, isNot(contains('Localurile:')));
      expect(find.text(answer), findsOneWidget);
      expect(find.text('Arată pe hartă'), findsOneWidget);
    },
  );

  testWidgets('Romanian still gets the rules, without Gemini', (tester) async {
    final asked = <String>[];
    await openChat(
      tester,
      gemini: fakeGemini('-', onRequest: (request) => asked.add(request.body)),
    );

    await send(tester, 'Vreau să beau ceva în Cluj-Napoca');

    expect(asked, isEmpty);
    expect(find.textContaining('În Cluj-Napoca poți bea ceva la'), findsOne);
  });
}
