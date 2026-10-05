import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:top_places/app.dart';
import 'package:top_places/models/profile.dart';
import 'package:top_places/services/account_service.dart';
import 'package:top_places/services/places_repository.dart';

import '../fake_account_service.dart';

void main() {
  final repository = PlacesRepository.fromJsonStrings(
    placesJson: File('assets/data/locations.json').readAsStringSync(),
    citiesJson: File('assets/data/romanian_cities.json').readAsStringSync(),
  );

  const ana = Profile(
    id: '1',
    email: 'ana@test.ro',
    firstName: 'Ana',
    lastName: 'Pop',
    role: Role.user,
  );

  /// Starts the app on a phone-sized screen and opens the Profil tab.
  Future<void> openProfile(
    WidgetTester tester, {
    AccountService? accounts,
  }) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      TopPlacesApp(repository: repository, accounts: accounts),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
  }

  Future<void> type(WidgetTester tester, String label, String text) =>
      tester.enterText(find.widgetWithText(TextFormField, label), text);

  testWidgets('without Supabase, the tab says there are no accounts', (
    tester,
  ) async {
    await openProfile(tester);
    expect(find.textContaining('Conturile nu sunt disponibile'), findsOne);
  });

  testWidgets('the form checks the fields before sending them', (tester) async {
    await openProfile(tester, accounts: FakeAccountService());
    await tester.tap(find.text('Cont nou'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Creează contul'));
    await tester.pumpAndSettle();

    expect(find.text('Câmp obligatoriu.'), findsNWidgets(2));
    expect(find.text('Scrie o adresă de email validă.'), findsOne);
  });

  testWidgets('a new account is asked to confirm the email', (tester) async {
    await openProfile(tester, accounts: FakeAccountService());
    await tester.tap(find.text('Cont nou'));
    await tester.pumpAndSettle();

    await type(tester, 'Prenume', 'Ion');
    await type(tester, 'Nume', 'Ionescu');
    await type(tester, 'Email', 'ion@test.ro');
    await type(tester, 'Parolă', 'parola123');
    await type(tester, 'Repetă parola', 'parola123');
    await tester.tap(find.text('Creează contul'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Ți-am trimis un email la ion@test.ro'),
      findsOne,
    );
  });

  testWidgets('a user can ask to become an operator', (tester) async {
    await openProfile(tester, accounts: FakeAccountService(signedIn: ana));
    expect(find.text('Ana Pop'), findsOne);

    await tester.tap(find.text('Vreau să adaug localuri'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Ai cerut să devii operator'), findsOne);
  });

  testWidgets('a suspended account sees the reason and cannot ask', (
    tester,
  ) async {
    const suspended = Profile(
      id: '1',
      email: 'ana@test.ro',
      firstName: 'Ana',
      lastName: 'Pop',
      role: Role.user,
      suspendedReason: 'Date false',
    );
    await openProfile(
      tester,
      accounts: FakeAccountService(signedIn: suspended),
    );

    expect(find.textContaining('Motiv: Date false'), findsOne);
    expect(find.text('Vreau să adaug localuri'), findsNothing);
  });

  testWidgets('signing out shows the sign-in form again', (tester) async {
    await openProfile(tester, accounts: FakeAccountService(signedIn: ana));

    await tester.tap(find.text('Ieși din cont'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilledButton, 'Intră în cont'), findsOne);
  });

  testWidgets('the eye button shows and hides the password', (tester) async {
    await openProfile(tester, accounts: FakeAccountService());
    await type(tester, 'Parolă', 'parola123');

    bool hidden() => tester
        .widget<EditableText>(
          find.descendant(
            of: find.widgetWithText(TextFormField, 'Parolă'),
            matching: find.byType(EditableText),
          ),
        )
        .obscureText;

    expect(hidden(), isTrue);
    await tester.tap(find.byTooltip('Arată parola'));
    await tester.pump();
    expect(hidden(), isFalse);
    await tester.tap(find.byTooltip('Ascunde parola'));
    await tester.pump();
    expect(hidden(), isTrue);
  });

  testWidgets('opening the Profil tab loads the account again', (tester) async {
    final accounts = FakeAccountService(signedIn: ana);
    await openProfile(tester, accounts: accounts);
    expect(find.text('Vreau să adaug localuri'), findsOne);

    // Meanwhile an admin turns the request into the operator role.
    accounts.replaceProfile(
      const Profile(
        id: '1',
        email: 'ana@test.ro',
        firstName: 'Ana',
        lastName: 'Pop',
        role: Role.operator,
      ),
    );
    await tester.tap(find.text('Explorează'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();

    expect(find.text('Localurile mele'), findsOne);
  });

  testWidgets('a rejected request shows the reason', (tester) async {
    const rejected = Profile(
      id: '1',
      email: 'ana@test.ro',
      firstName: 'Ana',
      lastName: 'Pop',
      role: Role.user,
      operatorRequest: OperatorRequest.rejected,
      operatorRequestReason: 'Nu ai un local',
    );
    await openProfile(tester, accounts: FakeAccountService(signedIn: rejected));

    expect(find.textContaining('Motiv: Nu ai un local'), findsOne);
    expect(find.text('Trimite din nou cererea'), findsOne);
  });
}
