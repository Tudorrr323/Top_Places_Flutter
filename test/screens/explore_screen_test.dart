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

  Future<void> startApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(TopPlacesApp(repository: repository));
    await tester.pumpAndSettle();
  }

  testWidgets('shows how many places there are', (tester) async {
    await startApp(tester);
    expect(find.text('20 de rezultate'), findsOneWidget);
  });

  testWidgets('typing in the search bar filters the list', (tester) async {
    await startApp(tester);
    await tester.enterText(find.byType(TextField), 'cluj');
    await tester.pumpAndSettle();
    expect(find.text('3 rezultate'), findsOneWidget);
  });

  testWidgets('the clear button empties the search', (tester) async {
    await startApp(tester);
    await tester.enterText(find.byType(TextField), 'cluj');
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Șterge căutarea'));
    await tester.pumpAndSettle();

    expect(find.text('20 de rezultate'), findsOneWidget);
  });

  testWidgets('an unknown name shows the empty state', (tester) async {
    await startApp(tester);
    await tester.enterText(find.byType(TextField), 'xyz');
    await tester.pumpAndSettle();
    expect(find.text('Nu am găsit locații.'), findsOneWidget);
  });
}