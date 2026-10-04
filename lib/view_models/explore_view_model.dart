import 'package:flutter/foundation.dart';
import 'package:top_places/models/chat_message.dart';
import 'package:top_places/models/filters.dart';
import 'package:top_places/models/place.dart';
import 'package:top_places/utils/place_search.dart';
import 'package:top_places/utils/text_normalize.dart';

/// The state of the Explore tab: the search text and the filters.
/// Widgets that watch it rebuild every time it calls notifyListeners().
class ExploreViewModel extends ChangeNotifier {
  ExploreViewModel(this._allPlaces);

  final List<Place> _allPlaces;
  String _query = '';
  Filters _filters = const Filters();
  bool _showMap = false;

  String get query => _query;
  Filters get filters => _filters;

  /// On narrow screens: true shows the map, false the list.
  bool get showMap => _showMap;

  /// The places to show, after the search text, the filters and the sorting.
  List<Place> get visiblePlaces =>
      searchPlaces(_allPlaces, query: _query, filters: _filters);

  /// The cities that have at least one place, in alphabetical order.
  List<String> get cities {
    final names = {for (final place in _allPlaces) place.city}.toList();
    names.sort((a, b) => normalize(a).compareTo(normalize(b)));
    return names;
  }

  void setQuery(String value) {
    if (value == _query) return;
    _query = value;
    notifyListeners();
  }

  void applyFilters(Filters value) {
    _filters = value;
    notifyListeners();
  }

  void resetFilters() => applyFilters(const Filters());

  void toggleMap() {
    _showMap = !_showMap;
    notifyListeners();
  }

  /// Shows on the map what the assistant found: one place, searched by its
  /// name, or every place in a city. The old search and filters go, so they
  /// can't hide the result (in the old app the button then did nothing).
  void showOnMap(ChatAction action) {
    switch (action) {
      case ShowPlace(:final place):
        _query = place.name;
        _filters = const Filters();
      case ShowCity(:final city):
        _query = '';
        _filters = Filters(city: city);
    }
    _showMap = true;
    notifyListeners();
  }
}
