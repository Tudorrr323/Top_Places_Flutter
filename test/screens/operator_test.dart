import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:top_places/app.dart';
import 'package:top_places/models/place.dart';
import 'package:top_places/models/profile.dart';
import 'package:top_places/services/gemini_service.dart';
import 'package:top_places/services/places_repository.dart';
import 'package:top_places/widgets/my_places.dart';

import '../fake_account_service.dart';
import '../fake_gemini.dart';
import '../fake_place_service.dart';

void main() {
  const operator = Profile(
    id: 'op',
    email: 'dan@test.ro',
    firstName: 'Dan',
    lastName: 'Pop',
    role: Role.operator,
  );

  const rejected = Place(
    id: 'p1',
    name: 'Ceainăria Ana',
    address: 'Str. Lăpușneanu, Nr. 3, Iași',
    city: 'Iași',
    lat: 47.16,
    lng: 27.58,
    imageUrl: '',
    description: 'Ceai bun și liniște, aproape de centru.',
    rating: 0,
    status: PlaceStatus.rejected,
    statusReason: 'Adresa nu e completă',
  );

  /// Starts the app signed in as [profile], whose own places are [mine],
  /// and opens the Profil tab. Returns the fake, to check what was saved.
  Future<FakePlaceService> openProfile(
    WidgetTester tester, {
    Profile profile = operator,
    List<Place> mine = const [],
    GeminiService? gemini,
  }) async {
    final service = FakePlaceService()..mine.addAll(mine);
    final repository = PlacesRepository.fromJsonStrings(
      placesJson: File('assets/data/locations.json').readAsStringSync(),
      citiesJson: File('assets/data/romanian_cities.json').readAsStringSync(),
      remote: service,
    );
    tester.view.physicalSize = const Size(400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      TopPlacesApp(
        repository: repository,
        accounts: FakeAccountService(signedIn: profile),
        gemini: gemini,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    return service;
  }

  Future<void> openForm(WidgetTester tester) async {
    await tester.tap(find.text('Adaugă un local'));
    await tester.pumpAndSettle();
  }

  Future<void> send(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Trimite spre aprobare'));
    await tester.tap(find.text('Trimite spre aprobare'));
    await tester.pumpAndSettle();
  }

  testWidgets('an operator sees their places and why one was rejected', (
    tester,
  ) async {
    await openProfile(tester, mine: [rejected]);

    expect(find.text('Localurile mele'), findsOne);
    expect(find.text('Ceainăria Ana'), findsOne);
    expect(find.textContaining('Respins: Adresa nu e completă'), findsOne);
  });

  testWidgets('the form shows what is missing, the position too', (
    tester,
  ) async {
    await openProfile(tester);
    await openForm(tester);

    await send(tester);

    // The name, the address and the description in both languages.
    expect(find.text('Câmp obligatoriu.'), findsNWidgets(4));
    expect(find.text('Alege orașul.'), findsOne);
    expect(find.text('Atinge harta ca să alegi locul.'), findsOne);
  });

  testWidgets('a new place is sent for approval and shows in the list', (
    tester,
  ) async {
    final service = await openProfile(tester);
    await openForm(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nume'),
      'Ceainăria Ana',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Adresă'),
      'Str. Lăpușneanu, Nr. 3',
    );
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Iași').last);
    await tester.pumpAndSettle();
    // The map now shows Iași; a tap in its middle sets the position.
    await tester.tap(find.byType(FlutterMap));
    // flutter_map waits a moment to tell a tap from a double tap.
    await tester.pump(const Duration(milliseconds: 500));
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Descriere în română'),
      'Ceai bun și liniște, aproape de centru.',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Descriere în engleză'),
      'Good tea and quiet, near the centre.',
    );
    await send(tester);

    final saved = service.mine.single;
    expect(saved.descriptionRo, 'Ceai bun și liniște, aproape de centru.');
    expect(saved.description, 'Good tea and quiet, near the centre.');
    expect(saved.city, 'Iași');
    expect(saved.lat, closeTo(47.16, 0.05));
    expect(find.text('Localurile mele'), findsOne);
    expect(find.textContaining('În așteptarea aprobării'), findsOne);
  });

  testWidgets('a suspended operator can no longer add or edit places', (
    tester,
  ) async {
    const suspended = Profile(
      id: 'op',
      email: 'dan@test.ro',
      firstName: 'Dan',
      lastName: 'Pop',
      role: Role.operator,
      suspendedReason: 'Date false',
    );
    await openProfile(tester, profile: suspended, mine: [rejected]);

    expect(find.text('Ceainăria Ana'), findsOne);
    expect(find.text('Adaugă un local'), findsNothing);
    expect(find.byTooltip('Editează Ceainăria Ana'), findsNothing);
  });

  group('the translate button', () {
    Finder field(String label) => find.widgetWithText(TextFormField, label);

    String textOf(WidgetTester tester, String label) =>
        tester.widget<TextFormField>(field(label)).controller!.text;

    testWidgets('writes the other language from the one written', (
      tester,
    ) async {
      final asked = <String>[];
      await openProfile(
        tester,
        gemini: fakeGeminiAnswers([
          'Good tea and quiet, near the centre.',
          'Ceai bun, liniște și prăjituri, aproape de centru.',
        ], onRequest: (request) => asked.add(request.body)),
      );
      await openForm(tester);
      expect(find.textContaining('butonul o traduce'), findsOne);

      await tester.enterText(
        field('Descriere în română'),
        'Ceai bun și liniște, aproape de centru.',
      );
      await tester.pump();
      await tester.ensureVisible(find.text('Tradu în engleză'));
      await tester.tap(find.text('Tradu în engleză'));
      await tester.pumpAndSettle();

      expect(asked.single, contains('Translate into English'));
      expect(
        textOf(tester, 'Descriere în engleză'),
        'Good tea and quiet, near the centre.',
      );

      // Changed last, the English one is now translated into Romanian.
      await tester.enterText(
        field('Descriere în engleză'),
        'Good tea, quiet and cakes, near the centre.',
      );
      await tester.pump();
      await tester.tap(find.text('Tradu în română'));
      await tester.pumpAndSettle();

      expect(asked.last, contains('Tradu în română'));
      expect(
        textOf(tester, 'Descriere în română'),
        'Ceai bun, liniște și prăjituri, aproape de centru.',
      );
    });

    testWidgets('without a Gemini key, says what it needs', (tester) async {
      await openProfile(tester);
      await openForm(tester);

      expect(
        find.text('Traducerea automată are nevoie de cheia Gemini.'),
        findsOne,
      );
      expect(find.text('Tradu în engleză'), findsNothing);
    });
  });

  testWidgets('with many places, a few show; all, with filters, one tap away', (
    tester,
  ) async {
    final many = [
      for (var number = 1; number <= 6; number++)
        Place(
          id: 'p$number',
          name: 'Local $number',
          address: 'Str. A, Nr. $number',
          city: number.isEven ? 'Iași' : 'Cluj-Napoca',
          lat: 47.1,
          lng: 27.5,
          imageUrl: '',
          description: 'Un local de test, numărul $number.',
          rating: 0,
          status: switch (number) {
            1 => PlaceStatus.rejected,
            2 => PlaceStatus.pending,
            _ => PlaceStatus.approved,
          },
          statusReason: number == 1 ? 'Lipsește poza' : null,
        ),
    ];
    await openProfile(tester, mine: many);

    // The three added last, the newest first.
    expect(find.byType(MyPlaceCard), findsNWidgets(3));
    expect(find.text('Local 6'), findsOne);
    expect(find.text('Local 1'), findsNothing);

    await tester.ensureVisible(find.text('Vezi toate (6)'));
    await tester.tap(find.text('Vezi toate (6)'));
    await tester.pumpAndSettle();
    expect(find.byType(MyPlaceCard), findsNWidgets(6));
    expect(find.text('Suspendate (0)'), findsNothing, reason: 'no such place');

    await tester.tap(find.text('Respinse (1)'));
    await tester.pumpAndSettle();
    expect(find.byType(MyPlaceCard), findsOne);
    expect(find.textContaining('Lipsește poza'), findsOne);

    await tester.tap(find.text('Toate (6)'));
    await tester.tap(find.text('Iași'));
    await tester.pumpAndSettle();
    expect(find.byType(MyPlaceCard), findsNWidgets(3));

    await tester.enterText(find.byType(TextField), 'local 4');
    await tester.pumpAndSettle();
    expect(find.byType(MyPlaceCard), findsOne);
    expect(find.text('Local 4'), findsOne);
  });
}
