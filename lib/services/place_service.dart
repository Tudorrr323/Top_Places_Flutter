import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:top_places/models/place.dart';
import 'package:top_places/models/rating.dart';

/// A failed action on places, with a message the user can act on.
class PlaceException implements Exception {
  const PlaceException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// What an operator fills in for a place. The rest (owner, status) is
/// decided by the database and by the admins, and the rating by the users.
class PlaceDraft {
  const PlaceDraft({
    required this.name,
    required this.address,
    required this.city,
    required this.lat,
    required this.lng,
    required this.imageUrl,
    required this.description,
  });

  final String name;
  final String address;
  final String city;
  final double lat;
  final double lng;
  final String imageUrl;
  final String description;

  Map<String, Object> toRow() => {
    'name': name.trim(),
    'address': address.trim(),
    'city': city,
    'lat': lat,
    'lng': lng,
    'image_url': imageUrl.trim(),
    'description': description.trim(),
  };
}

/// What an admin decides about a place. The database checks the rest: a
/// reason is required to reject or suspend. Ratings are not the admin's:
/// they come from the people who rate the place.
class PlaceReview {
  /// Approves the place, or reactivates a suspended one.
  PlaceReview.approve() : row = {'status': 'approved'};

  PlaceReview.reject(String reason)
    : row = {'status': 'rejected', 'status_reason': reason.trim()};

  PlaceReview.suspend(String reason)
    : row = {'status': 'suspended', 'status_reason': reason.trim()};

  /// The columns to change.
  final Map<String, Object> row;
}

/// What a place's operator (or an admin) decides about a review. The
/// database asks for a reason to reject one.
class RatingDecision {
  RatingDecision.approve() : row = {'status': 'approved'};

  RatingDecision.reject(String reason)
    : row = {'status': 'rejected', 'status_reason': reason.trim()};

  /// The columns to change.
  final Map<String, Object> row;
}

/// Places stored in Supabase. An interface, so that the tests can use a fake.
abstract class PlaceService {
  /// What everyone sees: approved places whose owner is not suspended.
  Future<List<Place>> publicPlaces();

  /// The signed-in operator's own places, in every status.
  Future<List<Place>> myPlaces();

  /// Adds a place, which then waits for an admin's approval.
  Future<Place> addPlace(PlaceDraft draft);

  /// Changes a place; the owner's changes go back to review.
  Future<Place> updatePlace(String id, PlaceDraft draft);

  /// Every place, in every status. Only an admin gets them all.
  Future<List<Place>> allPlaces();

  /// An admin's decision about a place.
  Future<Place> review(String id, PlaceReview review);

  /// The signed-in account's review of the place, in any status, or null.
  Future<Rating?> myRating(String placeId);

  /// Saves the signed-in account's review of the place, new or changed.
  /// Either way it waits for the place's operator, and counts once accepted.
  Future<Rating> saveRating(
    String placeId, {
    required int stars,
    String comment = '',
  });

  /// Deletes a review: the author's own, or any of them for an admin.
  Future<void> deleteRating(Rating rating);

  /// The accepted reviews of a public place, newest first. Everyone sees
  /// them, signed in or not.
  Future<List<Rating>> placeRatings(String placeId);

  /// The reviews the signed-in account decides about: those of an
  /// operator's places, or of every place for an admin.
  Future<List<Rating>> ratingsToModerate();

  /// Accepts a review, or rejects it with a reason.
  Future<void> decideRating(Rating rating, RatingDecision decision);
}

class SupabasePlaceService implements PlaceService {
  SupabasePlaceService(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Place>> publicPlaces() async {
    final rows = await _guard(
      () => _client
          .from('public_places')
          .select()
          // order() sorts in descending order unless told otherwise.
          .order('created_at', ascending: true)
          .order('name', ascending: true),
    );
    return [for (final row in rows) Place.fromRow(row)];
  }

  @override
  Future<List<Place>> myPlaces() async {
    final user = _client.auth.currentUser;
    if (user == null) return const [];
    final rows = await _guard(
      () => _client
          .from('places')
          .select()
          .eq('owner_id', user.id)
          .order('created_at', ascending: true),
    );
    return [for (final row in rows) Place.fromRow(row)];
  }

  @override
  Future<Place> addPlace(PlaceDraft draft) async {
    final row = await _guard(
      () => _client.from('places').insert(draft.toRow()).select().single(),
    );
    return Place.fromRow(row);
  }

  @override
  Future<Place> updatePlace(String id, PlaceDraft draft) =>
      _update(id, draft.toRow());

  @override
  Future<List<Place>> allPlaces() async {
    final rows = await _guard(
      () => _client
          .from('places')
          .select()
          .order('created_at', ascending: true)
          .order('name', ascending: true),
    );
    return [for (final row in rows) Place.fromRow(row)];
  }

  @override
  Future<Place> review(String id, PlaceReview review) =>
      _update(id, review.row);

  @override
  Future<Rating?> myRating(String placeId) async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    final row = await _guard(
      () => _client
          .from('ratings')
          .select()
          .eq('place_id', placeId)
          .eq('user_id', user.id)
          .maybeSingle(),
    );
    return row == null ? null : Rating.fromRow(row);
  }

  @override
  Future<Rating> saveRating(
    String placeId, {
    required int stars,
    String comment = '',
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const PlaceException('Intră în cont ca să scrii o recenzie.');
    }
    final message = comment.trim();
    // One row per account and place: writing again changes it.
    final row = await _guard(
      () => _client
          .from('ratings')
          .upsert({
            'place_id': placeId,
            'user_id': user.id,
            'stars': stars,
            'comment': message.isEmpty ? null : message,
          }, onConflict: 'place_id,user_id')
          .select()
          .single(),
    );
    return Rating.fromRow(row);
  }

  @override
  Future<void> deleteRating(Rating rating) async {
    final rows = await _guard(
      () => _client
          .from('ratings')
          .delete()
          .eq('place_id', rating.placeId)
          .eq('user_id', rating.userId)
          .select(),
    );
    // Nothing deleted: the rules do not allow it.
    if (rows.isEmpty) {
      throw const PlaceException('Nu ai voie să ștergi această recenzie.');
    }
  }

  @override
  Future<List<Rating>> placeRatings(String placeId) =>
      _ratingsFrom('place_ratings', {'place': placeId});

  @override
  Future<List<Rating>> ratingsToModerate() =>
      _ratingsFrom('ratings_to_moderate', const {});

  @override
  Future<void> decideRating(Rating rating, RatingDecision decision) async {
    await _guard(
      () => _client
          .from('ratings')
          .update(decision.row)
          .eq('place_id', rating.placeId)
          .eq('user_id', rating.userId)
          .select()
          .single(),
    );
  }

  /// Calls one of the review functions in the database. They return only
  /// the author's name, never the email.
  Future<List<Rating>> _ratingsFrom(
    String function,
    Map<String, Object> params,
  ) async {
    final rows = await _guard(
      () => _client.rpc<List<dynamic>>(function, params: params),
    );
    return [
      for (final row in rows) Rating.fromRow(row as Map<String, dynamic>),
    ];
  }

  Future<Place> _update(String id, Map<String, Object> values) async {
    final row = await _guard(
      () =>
          _client.from('places').update(values).eq('id', id).select().single(),
    );
    return Place.fromRow(row);
  }

  /// Turns the errors of Supabase and of the network into PlaceException.
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on PostgrestException catch (error) {
      throw PlaceException(switch (error.code) {
        // A check in the table refused a value.
        '23514' =>
          'Unele câmpuri nu sunt valide. Verifică-le și încearcă din '
              'nou.',
        // No row matched: the rules do not allow it (e.g. a suspension).
        'PGRST116' || '42501' => 'Nu ai voie să faci această modificare.',
        _ => 'Nu am putut salva: ${error.message}',
      });
    } on Exception {
      throw const PlaceException(
        'Nu mă pot conecta. Verifică internetul și încearcă din nou.',
      );
    }
  }
}
