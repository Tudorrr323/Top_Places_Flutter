import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:top_places/models/profile.dart';
import 'package:top_places/services/account_service.dart';
import 'package:top_places/view_models/account_view_model.dart';

import '../fake_account_service.dart';

void main() {
  const ana = Profile(
    id: '1',
    email: 'ana@test.ro',
    firstName: 'Ana',
    lastName: 'Pop',
    role: Role.user,
  );

  test('without Supabase there are no accounts', () {
    expect(AccountViewModel(null).isAvailable, isFalse);
  });

  test('signs in and loads the profile', () async {
    final service = FakeAccountService()
      ..accounts['ana@test.ro'] = ('parola123', ana);
    final account = AccountViewModel(service);

    expect(await account.signIn(' ana@test.ro ', 'parola123'), isTrue);
    expect(account.profile?.firstName, 'Ana');
    expect(account.error, isNull);
  });

  test('a wrong password leaves an error and nobody signed in', () async {
    final service = FakeAccountService()
      ..accounts['ana@test.ro'] = ('parola123', ana);
    final account = AccountViewModel(service);

    expect(await account.signIn('ana@test.ro', 'greșită'), isFalse);
    expect(account.profile, isNull);
    expect(account.error, 'Email sau parolă greșite.');
  });

  test('a new account signs in only after the email is confirmed', () async {
    final account = AccountViewModel(FakeAccountService());

    expect(
      await account.signUp(
        email: 'ion@test.ro',
        password: 'parola123',
        firstName: 'Ion',
        lastName: 'Ionescu',
      ),
      isTrue,
    );
    expect(await account.signIn('ion@test.ro', 'parola123'), isFalse);
    expect(account.error, contains('confirmat'));
  });

  test('Profile.fromJson reads the role, the request and the suspension', () {
    final profile = Profile.fromJson({
      'id': '2',
      'email': 'op@test.ro',
      'first_name': 'Dan',
      'last_name': 'Op',
      'role': 'operator',
      'operator_request': null,
      'suspended_reason': 'Date false',
    });

    expect(profile.role, Role.operator);
    expect(profile.operatorRequest, isNull);
    expect(profile.isSuspended, isTrue);
  });

  test('Supabase errors become messages in Romanian', () {
    expect(
      authErrorMessage(
        const AuthApiException(
          'Email not confirmed',
          statusCode: '400',
          code: 'email_not_confirmed',
        ),
      ),
      contains('confirmat'),
    );
    expect(
      authErrorMessage(
        const AuthApiException(
          'Invalid login credentials',
          statusCode: '400',
          code: 'invalid_credentials',
        ),
      ),
      'Email sau parolă greșite.',
    );
  });
}
