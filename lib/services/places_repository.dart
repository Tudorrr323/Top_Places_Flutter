import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:top_places/models/city.dart';
import 'package:top_places/models/place.dart';
import 'package:top_places/services/place_service.dart';

/// The places and the cities. The places start as the JSON bundled with the
/// app; with Supabase, [refresh] replaces them with the live list, and the
/// widgets that watch the repository rebuild.
class PlacesRepository extends ChangeNotifier {
  PlacesRepository({
    required List<Place> initialPlaces,
    required this.cities,
    this.remote,
  }) : _places = initialPlaces;

  /// Parses the contents of the two JSON files. Tests call this directly,
  /// with the files read from disk.
  factory PlacesRepository.fromJsonStrings({
    required String placesJson,
    required String citiesJson,
    PlaceService? remote,
  }) {
    final placeList = jsonDecode(placesJson) as List<dynamic>;
    final cityList = jsonDecode(citiesJson) as List<dynamic>;
    return PlacesRepository(
      initialPlaces: [
        for (final item in placeList)
          Place.fromJson(item as Map<String, dynamic>),
      ],
      cities: [
        for (final item in cityList)
          City.fromJson(item as Map<String, dynamic>),
      ],
      remote: remote,
    );
  }

  /// Reads both files from the app bundle (assets/data/ in pubspec.yaml).
  static Future<PlacesRepository> load({PlaceService? remote}) async {
    final placesJson = await rootBundle.loadString(
      'assets/data/locations.json',
    );
    final citiesJson = await rootBundle.loadString(
      'assets/data/romanian_cities.json',
    );
    return PlacesRepository.fromJsonStrings(
      placesJson: placesJson,
      citiesJson: citiesJson,
      remote: remote,
    );
  }

  /// Null when the app runs without Supabase.
  final PlaceService? remote;

  List<Place> _places;
  final List<City> cities;

  List<Place> get places => _places;

  /// Replaces the places with the live list from Supabase. Returns false
  /// when there is none (no Supabase, or offline); the current places stay.
  Future<bool> refresh() async {
    final remote = this.remote;
    if (remote == null) return false;
    try {
      _places = await remote.publicPlaces();
    } on PlaceException {
      return false;
    }
    notifyListeners();
    return true;
  }

  /// The place with this id, or null if there is none.
  Place? placeById(String id) {
    return places.where((place) => place.id == id).firstOrNull;
  }

  /// The city with this exact name, or null if there is none.
  City? cityByName(String name) {
    return cities.where((city) => city.name == name).firstOrNull;
  }
}
