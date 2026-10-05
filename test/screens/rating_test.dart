import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:top_places/app.dart';
import 'package:top_places/models/place.dart';
import 'package:top_places/models/profile.dart';
import 'package:top_places/screens/explore_screen.dart';
import 'package:top_places/services/places_repository.dart';

import '../fake_account_service.dart';
import '../fake_place_service.dart';

void main() {
  const ana = Profile(
    id: 'ana',
    email: 'ana@test.ro',
    firstName: 'Ana',
    lastName: 'Pop',
    role: Role.user,
  );
  const newPlace = Place(
    id: 'ceainaria-dan',
    name: 'Ceainăria Dan',
    address: 'Str. Lăpușneanu, Nr. 3, Iași',
    city: 'Iași',
    lat: 47.16,
    lng: 27.58,
    imageUrl: '',
    description: 'Ceai bun și liniște, aproape de centru.',
    rating: 0,
    ownerId: 'dan',
  );

  late FakePlaceService places;

  /// Opens the page of [place], with [me] signed in (or nobody) and the
  /// stars they gave before in [rated].
  Future<void> openPlace(
    WidgetTester tester, {
    Place place = newPlace,
    Profile? me,
    Map<String, int> rated = const {},
  }) async {
    places = FakePlaceService(public: [place])..myRatings.addAll(rated);
    final repository = PlacesRepository(
      initialPlaces: [place],
      cities: const [],
      remote: places,
    );
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      TopPlacesApp(
        repository: repository,
        accounts: FakeAccountService(signedIn: me),
      ),
    );
    await tester.pumpAndSettle();
    GoRouter.of(tester.element(find.byType(ExploreScreen)))
        .go('/locations/${place.id}');
    await tester.pumpAndSettle();
  }

  Future<void> tapStar(WidgetTester tester, String tooltip) async {
    await tester.ensureVisible(find.byTooltip(tooltip));
    await tester.tap(find.byTooltip(tooltip));
    await tester.pumpAndSettle();
  }

  testWidgets('without an account, the page says how to rate', (tester) async {
    await openPlace(tester);

    expect(find.text('Nicio notă încă.'), findsOne);
    expect(find.textContaining('Intră în cont'), findsOne);
    expect(find.byTooltip('1 stea'), findsNothing);
  });

  testWidgets('a user rates a place and sees the new rating', (tester) async {
    await openPlace(tester, me: ana);
    expect(find.text('Atinge o stea ca să dai o notă.'), findsOne);

    await tapStar(tester, '4 stele');

    expect(places.myRatings['ceainaria-dan'], 4);
    expect(find.text('Ai dat 4 stele. Poți schimba nota oricând.'), findsOne);
    // The page shows the new average from the server.
    expect(find.text('4.0'), findsOne);
    expect(find.text('Ratingul vine dintr-o singură notă.'), findsOne);
  });

  testWidgets('the stars given before show, and can change', (tester) async {
    await openPlace(tester, me: ana, rated: {'ceainaria-dan': 3});
    expect(find.text('Ai dat 3 stele. Poți schimba nota oricând.'), findsOne);

    await tapStar(tester, '1 stea');

    expect(places.myRatings['ceainaria-dan'], 1);
    expect(find.text('Ai dat 1 stea. Poți schimba nota oricând.'), findsOne);
  });

  testWidgets('an operator cannot rate their own place', (tester) async {
    const dan = Profile(
      id: 'dan',
      email: 'dan@test.ro',
      firstName: 'Dan',
      lastName: 'Pop',
      role: Role.operator,
    );
    await openPlace(tester, me: dan);

    expect(find.text('Nu îți poți nota propriul local.'), findsOne);
    expect(find.byTooltip('1 stea'), findsNothing);
  });

  testWidgets('a suspended account cannot rate', (tester) async {
    const suspended = Profile(
      id: 'ana',
      email: 'ana@test.ro',
      firstName: 'Ana',
      lastName: 'Pop',
      role: Role.user,
      suspendedReason: 'Note false',
    );
    await openPlace(tester, me: suspended);

    expect(find.text('Contul tău e suspendat: nu poți da note.'), findsOne);
    expect(find.byTooltip('1 stea'), findsNothing);
  });

  testWidgets('when saving fails, the user is told', (tester) async {
    await openPlace(tester, me: ana);
    places.offline = true;

    await tapStar(tester, '5 stele');

    expect(find.text('Nu mă pot conecta.'), findsOne);
    expect(find.text('Atinge o stea ca să dai o notă.'), findsOne);
  });

  testWidgets('the page says what the rating is made of', (tester) async {
    const rated = Place(
      id: 'cafe-new-world',
      name: 'Café New World',
      address: 'Str. Lăpușneanu, Nr. 12, Iași',
      city: 'Iași',
      lat: 47.16,
      lng: 27.58,
      imageUrl: '',
      description: 'Design modern, perfect pentru un brunch relaxat.',
      rating: 4.6,
      ratingCount: 20,
    );
    await openPlace(tester, place: rated);
    expect(find.text('Ratingul e media celor 20 de note.'), findsOne);
  });

  testWidgets("an original place keeps the old app's rating until rated", (
    tester,
  ) async {
    const original = Place(
      id: 'cafe-new-world',
      name: 'Café New World',
      address: 'Str. Lăpușneanu, Nr. 12, Iași',
      city: 'Iași',
      lat: 47.16,
      lng: 27.58,
      imageUrl: '',
      description: 'Design modern, perfect pentru un brunch relaxat.',
      rating: 4.7,
    );
    await openPlace(tester, place: original);
    expect(
      find.text('Ratingul vine din aplicația originală, până la primele note.'),
      findsOne,
    );
  });
}
