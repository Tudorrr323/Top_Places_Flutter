import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:top_places/models/place.dart';

/// A failed action on places, with a message the user can act on.
class PlaceException implements Exception {
  const PlaceException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// What an operator fills in for a place. The rest (owner, status, rating)
/// is decided by the database and by the admins.
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
/// they will come from the people who visit the place.
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
