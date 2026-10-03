import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:top_places/services/places_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final repository = PlacesRepository.fromJsonStrings(
    placesJson: File('assets/data/locations.json').readAsStringSync(),
    citiesJson: File('assets/data/romanian_cities.json').readAsStringSync(),
  );

  test('reads all places and cities', () {
    expect(repository.places, hasLength(20));
    expect(repository.cities, hasLength(42));
  });

  test('every place has a unique id', () {
    final ids = repository.places.map((place) => place.id).toSet();
    expect(ids, hasLength(repository.places.length));
  });

  test("every place's city is in the city list", () {
    for (final place in repository.places) {
      expect(repository.cityByName(place.city), isNotNull, reason: place.name);
    }
  });

  test('finds a place by id', () {
    expect(repository.placeById('cafe-new-world')?.city, 'Iași');
    expect(repository.placeById('does-not-exist'), isNull);
  });

  test('load() reads the files bundled with the app', () async {
    final bundled = await PlacesRepository.load();
    expect(bundled.places, hasLength(20));
  });
}