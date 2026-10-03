import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:top_places/app.dart';
import 'package:top_places/services/places_repository.dart';

void main() {
  final repository = PlacesRepository.fromJsonStrings(
    placesJson: File('assets/data/locations.json').readAsStringSync(),
    citiesJson: File('assets/data/romanian_cities.json').readAsStringSync(),
  );

  testWidgets('shows the places and opens one', (tester) async {
    await tester.pumpWidget(TopPlacesApp(repository: repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text("Café 'New World'"));
    await tester.pumpAndSettle();

    expect(find.text('Str. Lăpușneanu, Nr. 12, Iași'), findsOneWidget);
  });
}
