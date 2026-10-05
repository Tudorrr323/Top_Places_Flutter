import 'package:flutter_test/flutter_test.dart';
import 'package:top_places/models/place.dart';
import 'package:top_places/widgets/place_photo.dart';

void main() {
  Place withPhoto(String url) => Place(
    id: 'x',
    name: 'X',
    address: 'Str. A, Nr. 1, Iași',
    city: 'Iași',
    lat: 47.16,
    lng: 27.58,
    imageUrl: url,
    description: 'O descriere a locului.',
    rating: 4,
  );

  test('Unsplash makes the photo as wide as asked', () {
    expect(
      photoUrl(withPhoto('https://images.unsplash.com/photo-1'), 800),
      'https://images.unsplash.com/photo-1?w=800&q=80',
    );
  });

  test("an operator's link stays as it is", () {
    expect(
      photoUrl(withPhoto('https://example.ro/poza.jpg?v=2'), 800),
      'https://example.ro/poza.jpg?v=2',
    );
  });

  test('no link, no download', () {
    expect(photoUrl(withPhoto('  '), 800), isNull);
  });
}
