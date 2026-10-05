import 'package:top_places/models/place.dart';
import 'package:top_places/models/rating.dart';
import 'package:top_places/services/place_service.dart';

/// Places kept in memory, instead of Supabase. [offline] makes every call
/// fail the way a missing connection does.
class FakePlaceService implements PlaceService {
  FakePlaceService({
    List<Place> public = const [],
    this.offline = false,
    this.me,
    this.meIsAdmin = false,
  }) : _public = List.of(public),
       _startingRatings = {for (final place in public) place.id: place.rating};

  final List<Place> _public;
  final mine = <Place>[];

  /// What an admin sees: every place, in every status.
  final all = <Place>[];

  /// Every review, like the ratings table.
  final ratings = <Rating>[];

  /// The id of the account the calls are made as, like the session in
  /// Supabase; null when nobody is signed in.
  final String? me;

  /// True when [me] is an admin.
  final bool meIsAdmin;

  /// The rating each public place had before its reviews.
  final Map<String, double> _startingRatings;
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
      ratingCount: old.ratingCount,
      status: status == null ? old.status : PlaceStatus.values.byName(status),
      statusReason: status == null
          ? old.statusReason
          : row['status_reason'] as String?,
      ownerId: old.ownerId,
    );
    all[index] = place;
    return place;
  }

  @override
  Future<Rating?> myRating(String placeId) async {
    _checkOnline();
    return ratings
        .where((rating) => rating.placeId == placeId && rating.userId == me)
        .firstOrNull;
  }

  /// Like the database: a new or changed review waits for the operator,
  /// except an admin's, which is public at once.
  @override
  Future<Rating> saveRating(
    String placeId, {
    required int stars,
    String comment = '',
  }) async {
    _checkOnline();
    final message = comment.trim();
    final rating = Rating(
      stars: stars,
      comment: message.isEmpty ? null : message,
      status: meIsAdmin ? RatingStatus.approved : RatingStatus.pending,
      author: 'Eu',
      placeId: placeId,
      userId: me!,
    );
    ratings
      ..removeWhere((old) => old.placeId == placeId && old.userId == me)
      ..add(rating);
    _refreshAverage(placeId);
    return rating;
  }

  @override
  Future<void> deleteRating(Rating rating) async {
    _checkOnline();
    ratings.removeWhere(
      (old) => old.placeId == rating.placeId && old.userId == rating.userId,
    );
    _refreshAverage(rating.placeId);
  }

  @override
  Future<List<Rating>> placeRatings(String placeId) async {
    _checkOnline();
    return [
      for (final rating in ratings)
        if (rating.placeId == placeId && rating.status == RatingStatus.approved)
          _changed(rating, mine: rating.userId == me),
    ];
  }

  /// Every review except the reader's own; the fake does not check roles.
  @override
  Future<List<Rating>> ratingsToModerate() async {
    _checkOnline();
    return [
      for (final rating in ratings)
        if (rating.userId != me) rating,
    ];
  }

  @override
  Future<void> decideRating(Rating rating, RatingDecision decision) async {
    _checkOnline();
    final index = ratings.indexWhere(
      (old) => old.placeId == rating.placeId && old.userId == rating.userId,
    );
    final status = RatingStatus.values.byName(
      decision.row['status']! as String,
    );
    ratings[index] = _changed(
      ratings[index],
      status: status,
      statusReason: decision.row['status_reason'] as String?,
    );
    _refreshAverage(rating.placeId);
  }

  /// Like the database: the public place's rating is the average of the
  /// accepted reviews, or the rating it started with when there are none.
  void _refreshAverage(String placeId) {
    final index = _public.indexWhere((place) => place.id == placeId);
    if (index < 0) return;
    final accepted = [
      for (final rating in ratings)
        if (rating.placeId == placeId && rating.status == RatingStatus.approved)
          rating.stars,
    ];
    final old = _public[index];
    _public[index] = Place(
      id: old.id,
      name: old.name,
      address: old.address,
      city: old.city,
      lat: old.lat,
      lng: old.lng,
      imageUrl: old.imageUrl,
      description: old.description,
      descriptionRo: old.descriptionRo,
      rating: accepted.isEmpty
          ? _startingRatings[placeId] ?? 0
          : (accepted.reduce((a, b) => a + b) / accepted.length * 10)
                    .roundToDouble() /
                10,
      ratingCount: accepted.length,
      ownerId: old.ownerId,
    );
  }

  /// [rating] with a new status, or marked as the reader's own.
  static Rating _changed(
    Rating rating, {
    RatingStatus? status,
    String? statusReason,
    bool? mine,
  }) => Rating(
    stars: rating.stars,
    comment: rating.comment,
    status: status ?? rating.status,
    statusReason: status == null ? rating.statusReason : statusReason,
    author: rating.author,
    placeId: rating.placeId,
    placeName: rating.placeName,
    userId: rating.userId,
    updatedAt: rating.updatedAt,
    mine: mine ?? rating.mine,
  );

  void _checkOnline() {
    if (offline) {
      throw const PlaceException(PlaceProblem.offline);
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
    descriptionRo: draft.descriptionRo,
    rating: 0,
    status: PlaceStatus.pending,
  );
}
