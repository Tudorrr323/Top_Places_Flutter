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

  /// Opens the filter sheet, picks [city] and taps "Aplică filtre".
  Future<void> filterByCity(WidgetTester tester, String city) async {
    await tester.tap(find.byTooltip('Filtrează și sortează'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, city));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Aplică filtre'));
    await tester.tap(find.text('Aplică filtre'));
    await tester.pumpAndSettle();
  }

  testWidgets('choosing a city filters the list', (tester) async {
    await startApp(tester);
    await filterByCity(tester, 'Brașov');

    expect(find.text('2 rezultate'), findsOneWidget);
    expect(find.text('Filtre active'), findsOneWidget);
  });

  testWidgets('Resetează shows every place again', (tester) async {
    await startApp(tester);
    await filterByCity(tester, 'Brașov');

    await tester.tap(find.text('Resetează'));
    await tester.pumpAndSettle();

    expect(find.text('20 de rezultate'), findsOneWidget);
    expect(find.text('Filtre active'), findsNothing);
  });
}