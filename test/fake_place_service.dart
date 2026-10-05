import 'package:top_places/models/place.dart';
import 'package:top_places/services/place_service.dart';

/// Places kept in memory, instead of Supabase. [offline] makes every call
/// fail the way a missing connection does.
class FakePlaceService implements PlaceService {
  FakePlaceService({List<Place> public = const [], this.offline = false})
    : _public = List.of(public);

  final List<Place> _public;
  final mine = <Place>[];

  /// What an admin sees: every place, in every status.
  final all = <Place>[];
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

  @override
  Future<List<Place>> allPlaces() async {
    _checkOnline();
    return List.of(all);
  }

  /// Applies the review like the database does: approving clears the
  /// reason, and a review without a rating keeps the old one.
  @override
  Future<Place> review(String id, PlaceReview review) async {
    _checkOnline();
    final index = all.indexWhere((place) => place.id == id);
    final old = all[index];
    final row = review.row;
    final status = row['status'] as String?;
    final place = Place(
      id: old.id,
      name: old.name,
      address: old.address,
      city: old.city,
      lat: old.lat,
      lng: old.lng,
      imageUrl: old.imageUrl,
      description: old.description,
      descriptionRo: old.descriptionRo,
      rating: row['rating'] as double? ?? old.rating,
      status: status == null ? old.status : PlaceStatus.values.byName(status),
      statusReason: status == null
          ? old.statusReason
          : row['status_reason'] as String?,
      ownerId: old.ownerId,
    );
    all[index] = place;
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
