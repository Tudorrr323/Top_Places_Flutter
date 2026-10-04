import 'package:flutter/foundation.dart';
import 'package:top_places/models/profile.dart';
import 'package:top_places/services/account_service.dart';

/// The account shown on the Profile tab: who is signed in, the actions they
/// can take, and the error of the last action.
class AccountViewModel extends ChangeNotifier {
  AccountViewModel(this._service) {
    // A session saved on the device is already open when the app starts.
    if (_service != null) refresh();
  }

  /// Null when the app runs without Supabase: there are no accounts then.
  final AccountService? _service;

  Profile? _profile;
  bool _busy = false;
  String? _error;

  bool get isAvailable => _service != null;

  /// The signed-in user's profile, or null.
  Profile? get profile => _profile;

  /// True while an action talks to the server; the buttons wait meanwhile.
  bool get isBusy => _busy;

  /// What went wrong in the last action, or null.
  String? get error => _error;

  /// Loads the profile again, e.g. after an admin changed it.
  Future<bool> refresh() => _run(() async {
    _profile = await _service!.loadProfile();
  });

  Future<bool> signIn(String email, String password) => _run(() async {
    await _service!.signIn(email: email.trim(), password: password);
    _profile = await _service.loadProfile();
  });

  /// True when the account was created; the user then confirms the email
  /// and signs in.
  Future<bool> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) => _run(
    () => _service!.signUp(
      email: email.trim(),
      password: password,
      firstName: firstName.trim(),
      lastName: lastName.trim(),
    ),
  );

  Future<bool> signOut() => _run(() async {
    await _service!.signOut();
    _profile = null;
  });

  Future<bool> updateName(String firstName, String lastName) => _run(() async {
    _profile = await _service!.updateName(
      firstName: firstName.trim(),
      lastName: lastName.trim(),
    );
  });

  Future<bool> requestOperatorRole() => _run(() async {
    _profile = await _service!.requestOperatorRole();
  });

  /// Runs [action] and keeps [isBusy] and [error] up to date. Returns true
  /// when it worked.
  Future<bool> _run(Future<void> Function() action) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await action();
      return true;
    } on AccountException catch (error) {
      _error = error.message;
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}
