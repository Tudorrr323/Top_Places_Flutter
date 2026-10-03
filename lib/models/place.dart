import 'package:top_places/utils/text_normalize.dart';

class Place {
  const Place({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.lat,
    required this.lng,
    required this.imageUrl,
    required this.description,
    required this.rating,
  });

  /// Builds a place from one object of assets/data/locations.json.
  factory Place.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String;
    final address = json['address'] as String;
    final coordinates = json['coordinates'] as Map<String, dynamic>;
    return Place(
      id: slugify(name),
      name: name,
      address: address,
      city: cityFromAddress(address),
      lat: (coordinates['lat'] as num).toDouble(),
      lng: (coordinates['long'] as num).toDouble(),
      imageUrl: json['image_url'] as String,
      description: json['short_description'] as String,
      rating: (json['rating'] as num).toDouble(),
    );
  }

  final String id;
  final String name;
  final String address;
  final String city;
  final double lat;
  final double lng;
  final String imageUrl;
  final String description;
  final double rating;

  /// The city is the last part of the address ("Str. X, Nr. 1, Iași" -> "Iași").
  /// The data writes Bucharest in English, so it is mapped to the Romanian
  /// name used in romanian_cities.json.
  static String cityFromAddress(String address) {
    final city = address.split(',').last.trim();
    return city == 'Bucharest' ? 'București' : city;
  }
}