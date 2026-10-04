import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:top_places/app.dart';
import 'package:top_places/services/places_repository.dart';

void main() {
  final repository = PlacesRepository.fromJsonStrings(
    placesJson: File('assets/data/locations.json').readAsStringSync(),
    citiesJson: File('assets/data/romanian_cities.json').readAsStringSync(),
  );

  /// Starts the app on a phone-sized screen and opens the Asistent tab.
  Future<void> openChat(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(TopPlacesApp(repository: repository));
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
    expect(find.text('3 rezultate'), findsOneWidget);
  });

  testWidgets('a place found by the assistant goes into the search bar', (
    tester,
  ) async {
    await openChat(tester);
    await tester.tap(find.text('Caută Burger Shack'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Arată pe hartă'));
    await tester.pumpAndSettle();

    expect(find.text('Burger Shack'), findsOneWidget);
    expect(find.text('1 rezultat'), findsOneWidget);
  });
}
