import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:top_places/app.dart';
import 'package:top_places/models/place.dart';
import 'package:top_places/models/profile.dart';
import 'package:top_places/services/places_repository.dart';

import '../fake_account_service.dart';
import '../fake_place_service.dart';

void main() {
  const admin = Profile(
    id: 'admin',
    email: 'maria@test.ro',
    firstName: 'Maria',
    lastName: 'Admin',
    role: Role.admin,
  );
  const dan = Profile(
    id: 'dan',
    email: 'dan@test.ro',
    firstName: 'Dan',
    lastName: 'Pop',
    role: Role.user,
    operatorRequest: OperatorRequest.pending,
  );
  const ion = Profile(
    id: 'ion',
    email: 'ion@test.ro',
    firstName: 'Ion',
    lastName: 'Ionescu',
    role: Role.user,
  );
  const pending = Place(
    id: 'p1',
    name: 'Ceainăria Ana',
    address: 'Str. Lăpușneanu, Nr. 3, Iași',
    city: 'Iași',
    lat: 47.16,
    lng: 27.58,
    imageUrl: '',
    description: 'Ceai bun și liniște, aproape de centru.',
    rating: 0,
    status: PlaceStatus.pending,
    ownerId: 'dan',
  );

  late FakePlaceService places;
  late FakeAccountService accounts;

  /// Starts the app as the admin, then opens the admin screen behind
  /// [button] on the Profil tab.
  Future<void> openAdmin(WidgetTester tester, String button) async {
    places = FakePlaceService()..all.add(pending);
    accounts = FakeAccountService(signedIn: admin)
      ..profiles.addAll([admin, dan, ion]);
    final repository = PlacesRepository.fromJsonStrings(
      placesJson: File('assets/data/locations.json').readAsStringSync(),
      citiesJson: File('assets/data/romanian_cities.json').readAsStringSync(),
      remote: places,
    );
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      TopPlacesApp(repository: repository, accounts: accounts),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(button));
    await tester.pumpAndSettle();
  }

  group('places', () {
    testWidgets('an admin approves a place with a rating', (tester) async {
      await openAdmin(tester, 'Localuri: aprobări și suspendări');
      expect(find.text('Ceainăria Ana'), findsOne);

      await tester.tap(find.widgetWithText(FilledButton, 'Aprobă'));
      await tester.pumpAndSettle();
      // The dialog's button, over the one on the card.
      await tester.tap(find.widgetWithText(FilledButton, 'Aprobă').last);
      await tester.pumpAndSettle();

      expect(places.all.single.status, PlaceStatus.approved);
      expect(places.all.single.rating, 4.0);
      expect(find.text('Ceainăria Ana'), findsNothing, reason: 'not waiting');
    });

    testWidgets('rejecting a place asks for the reason', (tester) async {
      await openAdmin(tester, 'Localuri: aprobări și suspendări');
      await tester.tap(find.text('Respinge'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Respinge'));
      await tester.pumpAndSettle();
      expect(find.text('Scrie motivul.'), findsOne);

      await tester.enterText(find.byType(TextFormField), 'Adresa e incompletă');
      await tester.tap(find.widgetWithText(FilledButton, 'Respinge'));
      await tester.pumpAndSettle();

      expect(places.all.single.status, PlaceStatus.rejected);
      expect(places.all.single.statusReason, 'Adresa e incompletă');
    });
  });

  group('accounts', () {
    testWidgets('approving a request gives the operator role', (tester) async {
      await openAdmin(tester, 'Utilizatori și operatori');
      expect(find.text('Dan Pop'), findsOne);

      await tester.tap(find.byTooltip('Acțiuni pentru Dan Pop'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Aprobă ca operator'));
      await tester.pumpAndSettle();

      expect(accounts.profiles[1].role, Role.operator);
      expect(find.text('Dan Pop'), findsNothing, reason: 'no request left');
    });

    testWidgets('suspending asks for a reason, never on her own account', (
      tester,
    ) async {
      await openAdmin(tester, 'Utilizatori și operatori');
      await tester.tap(find.text('Toți'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Acțiuni pentru Maria Admin'));
      await tester.pumpAndSettle();
      expect(find.text('Schimbă numele'), findsOne);
      expect(find.text('Suspendă contul'), findsNothing);
      // Closes the menu.
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Acțiuni pentru Ion Ionescu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Suspendă contul'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'Recenzii false');
      await tester.tap(find.widgetWithText(FilledButton, 'Suspendă'));
      await tester.pumpAndSettle();

      expect(accounts.profiles[2].suspendedReason, 'Recenzii false');
      expect(find.textContaining('Suspendat: Recenzii false'), findsOne);
    });
  });
}
