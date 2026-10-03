import 'package:top_places/models/filters.dart';
import 'package:top_places/models/place.dart';
import 'package:top_places/utils/text_normalize.dart';
import 'package:top_places/models/filters.dart';
import 'package:top_places/models/place.dart';
import 'package:top_places/utils/text_normalize.dart';

/// The places that match the search text and the filters, ordered as
/// [Filters.sortBy] says. The list passed in is not changed.
List<Place> searchPlaces(
  List<Place> places, {
  String query = '',
  Filters filters = const Filters(),
}) {
  final text = normalize(query.trim());

  final result = places.where((place) {
    final matchesText =
        text.isEmpty ||
        normalize(place.name).contains(text) ||
        normalize(place.address).contains(text) ||
        normalize(place.city).contains(text);
    final matchesCity = filters.city == null || place.city == filters.city;
    final matchesRating = place.rating >= filters.minRating;
    return matchesText && matchesCity && matchesRating;
  }).toList();

  switch (filters.sortBy) {
    case SortBy.recommended:
      break;
    case SortBy.ratingAscending:
      result.sort((a, b) => a.rating.compareTo(b.rating));
    case SortBy.ratingDescending:
      result.sort((a, b) => b.rating.compareTo(a.rating));
    case SortBy.nameAscending:
      result.sort((a, b) => normalize(a.name).compareTo(normalize(b.name)));
  }
  return result;
}