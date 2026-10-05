import 'package:top_places/utils/text_normalize.dart';

/// Where a place is in the review. Only approved places are public.
enum PlaceStatus { pending, approved, rejected, suspended }

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
    this.descriptionRo,
    required this.rating,
    this.ratingCount = 0,
    this.status = PlaceStatus.approved,
    this.statusReason,
    this.ownerId,
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
      descriptionRo: json['short_description_ro'] as String?,
      rating: (json['rating'] as num).toDouble(),
    );
  }

  /// Builds a place from a row of the places table or the public_places
  /// view in Supabase.
  factory Place.fromRow(Map<String, dynamic> row) {
    final status = row['status'] as String?;
    return Place(
      id: row['id'] as String,
      name: row['name'] as String,
      address: row['address'] as String,
      city: row['city'] as String,
      lat: (row['lat'] as num).toDouble(),
      lng: (row['lng'] as num).toDouble(),
      imageUrl: row['image_url'] as String,
      description: row['description'] as String,
      descriptionRo: row['description_ro'] as String?,
      // A new place has no rating until people rate it.
      rating: (row['rating'] as num?)?.toDouble() ?? 0,
      ratingCount: (row['rating_count'] as num?)?.toInt() ?? 0,
      // The public view has no status: everything in it is approved.
      status: status == null
          ? PlaceStatus.approved
          : PlaceStatus.values.byName(status),
      statusReason: row['status_reason'] as String?,
      ownerId: row['owner_id'] as String?,
    );
  }

  final String id;
  final String name;
  final String address;
  final String city;
  final double lat;
  final double lng;
  final String imageUrl;

  /// The original description, in English.
  final String description;

  /// The Romanian translation of [description], or null if there is none.
  final String? descriptionRo;

  /// From 1 to 5; 0 for a new place that nobody has rated yet.
  final double rating;

  /// How many ratings [rating] is the average of. 0 for a place nobody has
  /// rated in the app yet: the original 20 then show the old app's rating.
  final int ratingCount;

  final PlaceStatus status;

  /// Why an admin rejected or suspended the place.
  final String? statusReason;

  /// The operator who added the place; null for the original 20.
  final String? ownerId;

  /// False for a new place, until people rate it.
  bool get isRated => rating > 0;

  /// "4.7", or "Nou" for a place without a rating yet.
  String get ratingText => isRated ? rating.toStringAsFixed(1) : 'Nou';

  /// What a screen reader says instead of [ratingText].
  String get ratingLabel => isRated ? '$ratingText stele' : 'local nou';

  /// The city is the last part of the address ("Str. X, Nr. 1, Iași" -> "Iași").
  /// The data writes Bucharest in English, so it is mapped to the Romanian
  /// name used in romanian_cities.json.
  static String cityFromAddress(String address) {
    final city = address.split(',').last.trim();
    return city == 'Bucharest' ? 'București' : city;
  }
}
