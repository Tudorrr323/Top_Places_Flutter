import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:top_places/models/filters.dart';
import 'package:top_places/models/place.dart';
import 'package:top_places/services/places_repository.dart';
import 'package:top_places/utils/place_search.dart';

void main() {
  final places = PlacesRepository.fromJsonStrings(
    placesJson: File('assets/data/locations.json').readAsStringSync(),
    citiesJson: File('assets/data/romanian_cities.json').readAsStringSync(),
  ).places;

  group('search text', () {
    test('empty text returns everything, in the original order', () {
      expect(searchPlaces(places), places);
    });

    test('București finds the 3 places written as Bucharest', () {
      expect(searchPlaces(places, query: 'bucuresti'), hasLength(3));
      expect(searchPlaces(places, query: 'București'), hasLength(3));
      expect(searchPlaces(places, query: 'BUCHAREST'), hasLength(3));
    });

    test('ignores case and diacritics', () {
      final result = searchPlaces(places, query: 'CAFE');
      expect(result.single.name, "Café 'New World'");
    });
  });

  group('filters', () {
    test('city', () {
      final result = searchPlaces(
        places,
        filters: const Filters(city: 'Cluj-Napoca'),
      );
      expect(result, hasLength(3));
      expect(result.every((place) => place.city == 'Cluj-Napoca'), isTrue);
    });

    test('minimum rating', () {
      final result = searchPlaces(
        places,
        filters: const Filters(minRating: 4.7),
      );
      expect(result, hasLength(7));
    });

    test('city and minimum rating together', () {
      final result = searchPlaces(
        places,
        filters: const Filters(city: 'Brașov', minRating: 4.5),
      );
      expect(result.single.name, "Pizzeria 'Il Drago'");
    });

    test('isActive is false only for the defaults', () {
      expect(const Filters().isActive, isFalse);
      expect(const Filters(minRating: 3).isActive, isTrue);
    });
  });

  group('sorting', () {
    test('rating, highest first', () {
      final result = searchPlaces(
        places,
        filters: const Filters(sortBy: SortBy.ratingDescending),
      );
      for (var i = 1; i < result.length; i++) {
        expect(result[i - 1].rating, greaterThanOrEqualTo(result[i].rating));
      }
    });

    test('name, A to Z', () {
      final result = searchPlaces(
        places,
        filters: const Filters(sortBy: SortBy.nameAscending),
      );
      expect(result.first.name, "Bistro 'At The Forest'");
      expect(result.last.name, "Vegan Restaurant 'The Green Garden'");
    });
  });

  test('places without a rating come last, whichever way it sorts', () {
    const rated = Place(
      id: 'a',
      name: 'A',
      address: 'Str. A, Nr. 1, Iași',
      city: 'Iași',
      lat: 47.1,
      lng: 27.5,
      imageUrl: '',
      description: 'Un loc cu rating.',
      rating: 3,
    );
    const unrated = Place(
      id: 'b',
      name: 'B',
      address: 'Str. B, Nr. 2, Iași',
      city: 'Iași',
      lat: 47.1,
      lng: 27.5,
      imageUrl: '',
      description: 'Un loc nou, fără rating.',
      rating: 0,
    );
    for (final sortBy in [SortBy.ratingAscending, SortBy.ratingDescending]) {
      final result = searchPlaces(const [
        unrated,
        rated,
      ], filters: Filters(sortBy: sortBy));
      expect(result.last.name, 'B', reason: sortBy.name);
    }
    expect(unrated.isRated, isFalse);
  });
}
