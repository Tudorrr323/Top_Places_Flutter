import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:top_places/models/city.dart';
import 'package:top_places/models/place.dart';

/// The places and cities that ship with the app as JSON assets.
class PlacesRepository {
  const PlacesRepository({required this.places, required this.cities});

  /// Parses the contents of the two JSON files. Tests call this directly,
  /// with the files read from disk.
  factory PlacesRepository.fromJsonStrings({
    required String placesJson,
    required String citiesJson,
  }) {
    final placeList = jsonDecode(placesJson) as List<dynamic>;
    final cityList = jsonDecode(citiesJson) as List<dynamic>;
    return PlacesRepository(
      places: [
        for (final item in placeList)
          Place.fromJson(item as Map<String, dynamic>),
      ],
      cities: [
        for (final item in cityList)
          City.fromJson(item as Map<String, dynamic>),
      ],
    );
  }

  /// Reads both files from the app bundle (assets/data/ in pubspec.yaml).
  static Future<PlacesRepository> load() async {
    final placesJson = await rootBundle.loadString(
      'assets/data/locations.json',
    );
    final citiesJson = await rootBundle.loadString(
      'assets/data/romanian_cities.json',
    );
    return PlacesRepository.fromJsonStrings(
      placesJson: placesJson,
      citiesJson: citiesJson,
    );
  }

  final List<Place> places;
  final List<City> cities;

  /// The place with this id, or null if there is none.
  Place? placeById(String id) {
    return places.where((place) => place.id == id).firstOrNull;
  }

  /// The city with this exact name, or null if there is none.
  City? cityByName(String name) {
    return cities.where((city) => city.name == name).firstOrNull;
  }
}