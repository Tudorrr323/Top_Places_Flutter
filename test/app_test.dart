import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:top_places/app.dart';
import 'package:top_places/services/places_repository.dart';

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

  testWidgets('tapping a place opens its details', (tester) async {
    await startApp(tester, const Size(400, 800));
    await tester.tap(find.text("Café 'New World'"));
    await tester.pumpAndSettle();
    expect(find.text('Str. Lăpușneanu, Nr. 12, Iași'), findsOneWidget);
  });

  testWidgets('the Profil tab opens the profile screen', (tester) async {
    await startApp(tester, const Size(400, 800));
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    expect(find.text('Contul vine într-o etapă următoare.'), findsOneWidget);
  });
}