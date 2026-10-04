import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:top_places/app.dart';
import 'package:top_places/screens/place_details_screen.dart';
import 'package:top_places/services/places_repository.dart';
import 'package:top_places/widgets/place_card.dart';

void main() {
  final repository = PlacesRepository.fromJsonStrings(
    placesJson: File('assets/data/locations.json').readAsStringSync(),
    citiesJson: File('assets/data/romanian_cities.json').readAsStringSync(),
  );

  Future<void> startApp(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(TopPlacesApp(repository: repository));
    await tester.pumpAndSettle();
  }

  testWidgets('the map button swaps the list for the map', (tester) async {
    await startApp(tester, const Size(400, 900));

    await tester.tap(find.byTooltip('Arată harta'));
    await tester.pumpAndSettle();

    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.byType(PlaceCard), findsNothing);
  });

  testWidgets('a wide window shows the list and the map together', (
    tester,
  ) async {
    await startApp(tester, const Size(1400, 900));

    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.byType(PlaceCard), findsWidgets);
    expect(find.byTooltip('Arată harta'), findsNothing);
  });

  testWidgets('a marker opens a card that leads to the details', (
    tester,
  ) async {
    await startApp(tester, const Size(400, 900));
    await tester.tap(find.byTooltip('Arată harta'));
    await tester.pumpAndSettle();

    // A marker with no neighbours: zoomed out, nearby markers overlap.
    await tester.tap(find.byTooltip("Gaming Coffee Shop 'Restart'"));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Detalii'));
    await tester.pumpAndSettle();

    expect(find.byType(PlaceDetailsScreen), findsOneWidget);
  });
}
