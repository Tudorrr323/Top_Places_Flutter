import 'package:top_places/models/profile.dart';
import 'package:top_places/services/account_service.dart';

/// Accounts kept in memory, with Supabase's main rule: a new account can
/// sign in only after its email is confirmed.
class FakeAccountService implements AccountService {
  FakeAccountService({Profile? signedIn}) : _profile = signedIn;

  Profile? _profile;

  /// Accounts that can sign in: the email, with its password and profile.
  final accounts = <String, (String, Profile)>{};

  /// Addresses that signed up but have not opened the email yet.
  final unconfirmed = <String>{};

  @override
  Future<Profile?> loadProfile() async => _profile;

  @override
  Future<void> signIn({required String email, required String password}) async {
    if (unconfirmed.contains(email)) {
      throw const AccountException('Încă nu ți-ai confirmat emailul.');
    }
    final account = accounts[email];
    if (account == null || account.$1 != password) {
      throw const AccountException('Email sau parolă greșite.');
    }
    _profile = account.$2;
  }

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    unconfirmed.add(email);
  }

  @override
  Future<void> signOut() async => _profile = null;

  @override
  Future<Profile> updateName({
    required String firstName,
    required String lastName,
  }) async {
    return _profile = _changed(firstName: firstName, lastName: lastName);
  }

  @override
  Future<Profile> requestOperatorRole() async {
    return _profile = _changed(request: OperatorRequest.pending);
  }

  Profile _changed({
    String? firstName,
    String? lastName,
    OperatorRequest? request,
  }) {
    final profile = _profile!;
    return Profile(
      id: profile.id,
      email: profile.email,
      firstName: firstName ?? profile.firstName,
      lastName: lastName ?? profile.lastName,
      role: profile.role,
      operatorRequest: request ?? profile.operatorRequest,
      suspendedReason: profile.suspendedReason,
    );
  }
}
