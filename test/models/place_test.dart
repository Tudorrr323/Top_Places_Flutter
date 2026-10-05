import 'package:flutter_test/flutter_test.dart';
import 'package:top_places/models/city.dart';
import 'package:top_places/models/place.dart';
import 'package:top_places/utils/text_normalize.dart';

void main() {
  group('normalize', () {
    test('removes diacritics and upper case', () {
      expect(normalize('București'), 'bucuresti');
      expect(normalize('TÂRGU MUREȘ'), 'targu mures');
    });
  });

  group('slugify', () {
    test('turns a name into an ASCII id', () {
      expect(slugify("Café 'New World'"), 'cafe-new-world');
      expect(slugify("Fast-Food 'Döner King'"), 'fast-food-doner-king');
    });
  });

  group('Place.fromJson', () {
    final place = Place.fromJson({
      'name': "Café 'New World'",
      'address': 'Str. Academiei, Nr. 15, Bucharest',
      'coordinates': {'lat': 44.43, 'long': 26.1},
      'image_url': 'https://images.unsplash.com/photo-123',
      'short_description': 'A quiet café.',
      'rating': 4,
    });

    test('reads the fields', () {
      expect(place.id, 'cafe-new-world');
      expect(place.lng, 26.1);
    });

    test('maps Bucharest to București', () {
      expect(place.city, 'București');
    });

    test('reads an integer rating as a double', () {
      expect(place.rating, 4.0);
    });
  });

  test('Place.fromRow reads a row from Supabase', () {
    final place = Place.fromRow({
      'id': 'ceainaria-ana',
      'name': 'Ceainăria Ana',
      'address': 'Str. Lăpușneanu, Nr. 3, Iași',
      'city': 'Iași',
      'lat': 47.16,
      'lng': 27,
      'image_url': '',
      'description': 'Ceai bun și liniște, aproape de centru.',
      'description_ro': null,
      'rating': null,
      'status': 'pending',
      'status_reason': null,
      'owner_id': 'a1b2',
    });

    expect(place.lng, 27.0);
    expect(place.rating, 0, reason: 'not rated yet');
    expect(place.status, PlaceStatus.pending);
    expect(place.ownerId, 'a1b2');
  });

  test('City.fromJson reads lat and lng', () {
    final city = City.fromJson({'name': 'Galați', 'lat': 45.43, 'lng': 28.05});
    expect(city.name, 'Galați');
    expect(city.lng, 28.05);
  });
}
