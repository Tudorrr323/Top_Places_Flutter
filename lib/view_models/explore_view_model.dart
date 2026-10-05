import 'package:flutter/foundation.dart';
import 'package:top_places/models/chat_message.dart';
import 'package:top_places/models/filters.dart';
import 'package:top_places/models/place.dart';
import 'package:top_places/utils/place_search.dart';
import 'package:top_places/utils/text_normalize.dart';

/// Something to show on the map, asked for from elsewhere: [place] to move
/// to and open or, when null, every place left after new filters. [number]
/// grows with each request, so that the map answers each one once.
typedef MapRequest = ({int number, Place? place});

/// The state of the Explore tab: the search text and the filters.
/// Widgets that watch it rebuild every time it calls notifyListeners().
class ExploreViewModel extends ChangeNotifier {
  ExploreViewModel(this._allPlaces);

  List<Place> _allPlaces;
  String _query = '';
  Filters _filters = const Filters();
  bool _showMap = false;
  MapRequest? _mapRequest;
  int _requests = 0;

  String get query => _query;
  Filters get filters => _filters;

  /// On narrow screens: true shows the map, false the list.
  bool get showMap => _showMap;

  /// What the map should show next, or null once it has shown it. Typing in
  /// the search bar asks for nothing: the map stays where it is.
  MapRequest? get mapRequest => _mapRequest;

  /// Called by the map once it has shown [mapRequest].
  void mapRequestShown() => _mapRequest = null;

  void _requestMap([Place? place]) {
    _mapRequest = (number: ++_requests, place: place);
  }

  /// The places to show, after the search text, the filters and the sorting.
  List<Place> get visiblePlaces =>
      searchPlaces(_allPlaces, query: _query, filters: _filters);

  /// The cities that have at least one place, in alphabetical order.
  List<String> get cities {
    final names = {for (final place in _allPlaces) place.city}.toList();
    names.sort((a, b) => normalize(a).compareTo(normalize(b)));
    return names;
  }

  /// New places, e.g. the live list from Supabase. The search and the
  /// filters stay.
  void setPlaces(List<Place> places) {
    if (identical(places, _allPlaces)) return;
    _allPlaces = places;
    notifyListeners();
  }

  void setQuery(String value) {
    if (value == _query) return;
    _query = value;
    notifyListeners();
  }

  void applyFilters(Filters value) {
    _filters = value;
    // The map shows the places that are left.
    _requestMap();
    notifyListeners();
  }

  void resetFilters() => applyFilters(const Filters());

  void toggleMap() {
    _showMap = !_showMap;
    notifyListeners();
  }

  /// The places whose name, address or city match [text], for the
  /// suggestions under the search bar. The filters do not hide any:
  /// choosing one shows it anyway.
  List<Place> suggestionsFor(String text) => text.trim().isEmpty
      ? const []
      : searchPlaces(_allPlaces, query: text).take(6).toList();

  /// Shows [place] on the map, which moves to it from where it is and opens
  /// it. A search or filters that would hide the place go.
  void focusPlace(Place place) {
    if (!visiblePlaces.contains(place)) {
      _query = '';
      if (!searchPlaces(_allPlaces, filters: _filters).contains(place)) {
        _filters = const Filters();
      }
    }
    _showMap = true;
    _requestMap(place);
    notifyListeners();
  }

  /// Shows on the map what the assistant found: one place, or every place
  /// in a city. Nothing from before can hide the result (in the old app the
  /// button then did nothing).
  void showOnMap(ChatAction action) {
    switch (action) {
      case ShowPlace(:final place):
        focusPlace(place);
      case ShowCity(:final city):
        _query = '';
        _filters = Filters(city: city);
        _showMap = true;
        _requestMap();
        notifyListeners();
    }
  }
}
