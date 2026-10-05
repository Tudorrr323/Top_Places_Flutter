import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:top_places/models/place.dart';
import 'package:top_places/services/places_repository.dart';

import '../fake_place_service.dart';

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

  test('every place has a Romanian description', () {
    for (final place in repository.places) {
      expect(place.descriptionRo, isNotNull, reason: place.name);
    }
  });

  test('finds a place by id', () {
    expect(repository.placeById('cafe-new-world')?.city, 'Iași');
    expect(repository.placeById('does-not-exist'), isNull);
  });

  group('refresh', () {
    const liveOne = Place(
      id: 'new-place',
      name: 'Local nou',
      address: 'Str. Nouă, Nr. 1, Iași',
      city: 'Iași',
      lat: 47.16,
      lng: 27.58,
      imageUrl: '',
      description: 'Un loc nou, aprobat de un administrator.',
      rating: 4.2,
    );

    PlacesRepository withRemote(FakePlaceService remote) =>
        PlacesRepository.fromJsonStrings(
          placesJson: File('assets/data/locations.json').readAsStringSync(),
          citiesJson: File('assets/data/romanian_cities.json')
              .readAsStringSync(),
          remote: remote,
        );

    test('replaces the bundled places with the live ones', () async {
      final repository = withRemote(FakePlaceService(public: [liveOne]));
      var notified = false;
      repository.addListener(() => notified = true);

      expect(await repository.refresh(), isTrue);
      expect(repository.places.single.name, 'Local nou');
      expect(notified, isTrue);
    });

    test('keeps the bundled places when offline', () async {
      final offline = withRemote(FakePlaceService(offline: true));

      expect(await offline.refresh(), isFalse);
      expect(offline.places, hasLength(20));
    });
  });

  test('load() reads the files bundled with the app', () async {
    final bundled = await PlacesRepository.load();
    expect(bundled.places, hasLength(20));
  });
}
