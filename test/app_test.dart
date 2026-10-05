import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:top_places/app.dart';
import 'package:top_places/services/places_repository.dart';
import 'package:top_places/view_models/language_settings.dart';

void main() {
  final repository = PlacesRepository.fromJsonStrings(
    placesJson: File('assets/data/locations.json').readAsStringSync(),
    citiesJson: File('assets/data/romanian_cities.json').readAsStringSync(),
  );

  /// Starts the app in a window of the given size (in logical pixels).
  Future<void> startApp(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(TopPlacesApp(repository: repository));
    await tester.pumpAndSettle();
  }

  testWidgets('a narrow window gets a bottom navigation bar', (tester) async {
    await startApp(tester, const Size(400, 800));
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
  });

  testWidgets('a wide window gets a navigation rail', (tester) async {
    await startApp(tester, const Size(1200, 800));
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('tapping a place in the list opens it on the map', (
    tester,
  ) async {
    await startApp(tester, const Size(400, 800));
    // The cards are tall, so search first to bring the place to the top.
    await tester.enterText(find.byType(TextField), 'new world');
    await tester.pumpAndSettle();
    await tester.tap(find.text("Café 'New World'"));
    await tester.pumpAndSettle();

    expect(find.byType(DraggableScrollableSheet), findsOneWidget);
    expect(find.text('Str. Lăpușneanu, Nr. 12, Iași'), findsOneWidget);
  });

  testWidgets('the Profil tab opens the profile screen', (tester) async {
    await startApp(tester, const Size(400, 800));
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Profil'), findsOneWidget);
  });

  testWidgets('English, chosen on the Profil tab, changes every text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final language = LanguageSettings();
    await tester.pumpWidget(
      TopPlacesApp(repository: repository, language: language),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('English'));
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(language.locale, LanguageSettings.english);
    expect(find.text('Explore'), findsOneWidget);
    expect(find.text('Assistant'), findsOneWidget);
    expect(find.widgetWithText(AppBar, 'Profile'), findsOneWidget);
    expect(find.text('Language of the app'), findsOneWidget);

    await tester.tap(find.text('Explore'));
    await tester.pumpAndSettle();
    expect(find.text('Search places or cities...'), findsOneWidget);
    expect(find.text('20 results'), findsOneWidget);
  });
}
