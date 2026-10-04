import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:top_places/models/profile.dart';

/// The Supabase project, from config/dev.json (--dart-define-from-file).
/// Empty when the app runs without it; there are no accounts then.
const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabasePublishableKey = String.fromEnvironment(
  'SUPABASE_PUBLISHABLE_KEY',
);

/// A failed account action, with a message the user can act on.
class AccountException implements Exception {
  const AccountException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Accounts: signing up and in, and the signed-in user's own profile. An
/// interface, so that the tests can use a fake instead of Supabase.
abstract class AccountService {
  /// The signed-in user's profile, or null when nobody is signed in.
  Future<Profile?> loadProfile();

  Future<void> signIn({required String email, required String password});

  /// Creates the account. With "Confirm email" on in Supabase, the user can
  /// sign in only after opening the link in the email they receive.
  Future<void> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  });

  Future<void> signOut();

  Future<Profile> updateName({
    required String firstName,
    required String lastName,
  });

  /// Asks an admin for the operator role.
  Future<Profile> requestOperatorRole();
}

class SupabaseAccountService implements AccountService {
  SupabaseAccountService(this._client);

  final SupabaseClient _client;

  @override
  Future<Profile?> loadProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    final row = await _guard(
      () => _client.from('profiles').select().eq('id', user.id).single(),
    );
    return Profile.fromJson(row);
  }

  @override
  Future<void> signIn({required String email, required String password}) {
    return _guard(
      () => _client.auth.signInWithPassword(email: email, password: password),
    );
  }

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) {
    return _guard(
      () => _client.auth.signUp(
        email: email,
        password: password,
        // Read by the database trigger that creates the profile.
        data: {'first_name': firstName, 'last_name': lastName},
      ),
    );
  }

  @override
  Future<void> signOut() => _guard(() => _client.auth.signOut());

  @override
  Future<Profile> updateName({
    required String firstName,
    required String lastName,
  }) {
    return _updateOwnProfile({'first_name': firstName, 'last_name': lastName});
  }

  @override
  Future<Profile> requestOperatorRole() {
    return _updateOwnProfile({'operator_request': 'pending'});
  }

  Future<Profile> _updateOwnProfile(Map<String, Object> values) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AccountException('Intră din nou în cont.');
    }
    final row = await _guard(
      () => _client
          .from('profiles')
          .update(values)
          .eq('id', user.id)
          .select()
          .single(),
    );
    return Profile.fromJson(row);
  }

  /// Turns the errors of Supabase and of the network into AccountException.
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AuthException catch (error) {
      throw AccountException(authErrorMessage(error));
    } on PostgrestException catch (error) {
      throw AccountException('Nu am putut salva: ${error.message}');
    } on Exception {
      throw const AccountException(_offline);
    }
  }
}

const _offline = 'Nu mă pot conecta. Verifică internetul și încearcă din nou.';

/// Romanian messages for the errors that people can cause themselves.
String authErrorMessage(AuthException error) {
  if (error is AuthRetryableFetchException) return _offline;
  return switch (error.code) {
    'invalid_credentials' => 'Email sau parolă greșite.',
    'email_not_confirmed' =>
      'Încă nu ți-ai confirmat emailul. Deschide linkul din emailul '
          'primit, apoi încearcă din nou.',
    'over_email_send_rate_limit' =>
      'S-au trimis prea multe emailuri. Încearcă din nou peste o oră.',
    'weak_password' => 'Parola e prea slabă. Alege una mai lungă.',
    'email_address_invalid' => 'Adresa de email nu e acceptată.',
    'user_already_exists' ||
    'email_exists' => 'Există deja un cont cu acest email.',
    _ => 'Nu a mers: ${error.message}',
  };
}
