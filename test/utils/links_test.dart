import 'package:flutter_test/flutter_test.dart';
import 'package:top_places/models/place.dart';
import 'package:top_places/utils/links.dart';

void main() {
  const place = Place(
    id: 'test',
    name: 'Test',
    address: 'Str. Test, Nr. 1, Galați',
    city: 'Galați',
    lat: 45.43,
    lng: 28.05,
    imageUrl: 'https://images.unsplash.com/photo-1',
    description: 'A test place.',
    rating: 4.5,
  );

  test('directionsUri points Google Maps at the place', () {
    final uri = directionsUri(place);

    expect(uri.host, 'www.google.com');
    expect(uri.path, '/maps/dir/');
    expect(uri.queryParameters, {'api': '1', 'destination': '45.43,28.05'});
  });

  test('whatsAppUri puts the booking message in the link', () {
    final uri = whatsAppUri(place);

    expect(uri.toString(), 'https://wa.me/?text=Rezervare%20la%20Test');
  });
}
