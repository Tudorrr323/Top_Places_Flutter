import 'package:top_places/models/place.dart';
import 'package:top_places/services/place_service.dart';

/// Places kept in memory, instead of Supabase. [offline] makes every call
/// fail the way a missing connection does.
class FakePlaceService implements PlaceService {
  FakePlaceService({List<Place> public = const [], this.offline = false})
    : _public = List.of(public);

  final List<Place> _public;
  final mine = <Place>[];
  bool offline;
  int _nextId = 1;

  @override
  Future<List<Place>> publicPlaces() async {
    _checkOnline();
    return List.of(_public);
  }

  @override
  Future<List<Place>> myPlaces() async {
    _checkOnline();
    return List.of(mine);
  }

  @override
  Future<Place> addPlace(PlaceDraft draft) async {
    _checkOnline();
    final place = _fromDraft('new-${_nextId++}', draft);
    mine.add(place);
    return place;
  }

  @override
  Future<Place> updatePlace(String id, PlaceDraft draft) async {
    _checkOnline();
    final place = _fromDraft(id, draft);
    mine[mine.indexWhere((old) => old.id == id)] = place;
    return place;
  }

  void _checkOnline() {
    if (offline) {
      throw const PlaceException('Nu mă pot conecta.');
    }
  }

  /// Like the database: an operator's place waits for review, unrated.
  static Place _fromDraft(String id, PlaceDraft draft) => Place(
    id: id,
    name: draft.name,
    address: draft.address,
    city: draft.city,
    lat: draft.lat,
    lng: draft.lng,
    imageUrl: draft.imageUrl,
    description: draft.description,
    rating: 0,
    status: PlaceStatus.pending,
  );
}
