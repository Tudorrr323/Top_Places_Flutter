import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:top_places/app.dart';
import 'package:top_places/models/place.dart';
import 'package:top_places/models/profile.dart';
import 'package:top_places/models/rating.dart';
import 'package:top_places/screens/explore_screen.dart';
import 'package:top_places/services/places_repository.dart';
import 'package:top_places/widgets/review_tile.dart';

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

  /// Opens the "Recenzii" tab of [place], with [me] signed in (or nobody)
  /// and the reviews in [ratings].
  Future<void> openReviews(
    WidgetTester tester, {
    Place place = newPlace,
    Profile? me,
    List<Rating> ratings = const [],
  }) async {
    places = FakePlaceService(
      public: [place],
      me: me?.id,
      meIsAdmin: me?.role == Role.admin,
    )..ratings.addAll(ratings);
    final repository = PlacesRepository(
      initialPlaces: [place],
      cities: const [],
      remote: places,
    );
    // Tall enough for the whole tab, without scrolling.
    tester.view.physicalSize = const Size(400, 1600);
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
    await tester.tap(find.text('Recenzii'));
    await tester.pumpAndSettle();
  }

  Rating review(
    String userId,
    String author, {
    int stars = 5,
    String? comment,
    RatingStatus status = RatingStatus.approved,
    String? statusReason,
  }) => Rating(
    stars: stars,
    comment: comment,
    status: status,
    statusReason: statusReason,
    author: author,
    placeId: newPlace.id,
    userId: userId,
  );

  testWidgets('anyone reads the accepted reviews, signed in or not', (
    tester,
  ) async {
    await openReviews(
      tester,
      ratings: [
        review('ion', 'Ion I.', comment: 'Ceai excelent, liniște.'),
        review(
          'dan2',
          'Dan D.',
          comment: 'Încă nu e acceptată.',
          status: RatingStatus.pending,
        ),
      ],
    );

    expect(find.text('Ion I.'), findsOne);
    expect(find.text('Ceai excelent, liniște.'), findsOne);
    expect(find.text('Încă nu e acceptată.'), findsNothing);
    expect(find.textContaining('Intră în cont'), findsOne);
    expect(find.byTooltip('1 stea'), findsNothing);
  });

  testWidgets('a sent review waits, and the form is gone', (tester) async {
    await openReviews(tester, me: ana);
    expect(find.text('Nicio recenzie publicată încă.'), findsOne);

    await tester.tap(find.byTooltip('4 stele'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '  Liniște și ceai bun.  ');
    await tester.tap(find.text('Trimite recenzia'));
    await tester.pumpAndSettle();

    final saved = places.ratings.single;
    expect(saved.stars, 4);
    expect(saved.comment, 'Liniște și ceai bun.');
    expect(saved.status, RatingStatus.pending);
    expect(
      find.text('Recenzia ta a fost trimisă și e în așteptare.'),
      findsOne,
    );
    // The review, with where it is, instead of the form.
    expect(find.text('În așteptare'), findsOne);
    expect(find.text('Liniște și ceai bun.'), findsOne);
    expect(
      find.text(
        'Apare după ce o acceptă operatorul localului. Până atunci o vezi '
        'doar tu.',
      ),
      findsOne,
    );
    expect(find.byType(TextField), findsNothing);
    expect(find.byTooltip('1 stea'), findsNothing);
    // Not counted yet: the place is still new.
    expect(find.text('Nicio recenzie încă.'), findsOne);
  });

  testWidgets("an admin's review is public at once", (tester) async {
    const admin = Profile(
      id: 'maria',
      email: 'maria@test.ro',
      firstName: 'Maria',
      lastName: 'Admin',
      role: Role.admin,
    );
    // Even on an operator's place: admins wait for nobody.
    await openReviews(tester, me: admin);
    expect(
      find.textContaining('Ca administrator, recenzia ta apare imediat.'),
      findsOne,
    );

    await tester.tap(find.byTooltip('5 stele'));
    await tester.pump();
    await tester.tap(find.text('Trimite recenzia'));
    await tester.pumpAndSettle();

    expect(find.text('Recenzia ta a fost publicată.'), findsOne);
    expect(find.text('Publicată'), findsOne);
    expect(find.text('Ratingul vine dintr-o singură recenzie.'), findsOne);
  });

  testWidgets('a rejected review says why, and can be sent again', (
    tester,
  ) async {
    await openReviews(
      tester,
      me: ana,
      ratings: [
        review(
          'ana',
          'Ana P.',
          stars: 2,
          comment: 'Prost.',
          status: RatingStatus.rejected,
          statusReason: 'Prea scurtă',
        ),
      ],
    );
    expect(find.text('Respinsă'), findsOne);
    expect(find.textContaining('Motiv: Prea scurtă'), findsOne);

    await tester.tap(find.text('Modifică'));
    await tester.pumpAndSettle();
    final send = find.widgetWithText(FilledButton, 'Trimite din nou');
    expect(
      tester.widget<FilledButton>(send).onPressed,
      isNull,
      reason: 'nothing changed yet',
    );
    await tester.enterText(
      find.byType(TextField),
      'Ceaiul a venit rece, dar personalul a fost amabil.',
    );
    await tester.pump();
    await tester.tap(send);
    await tester.pumpAndSettle();

    expect(places.ratings.single.status, RatingStatus.pending);
    expect(find.text('În așteptare'), findsOne);
  });

  testWidgets('the author deletes their review after confirming', (
    tester,
  ) async {
    await openReviews(tester, me: ana, ratings: [review('ana', 'Ana P.')]);
    expect(find.textContaining('Publicată'), findsOne);

    await tester.tap(find.text('Șterge recenzia'));
    await tester.pumpAndSettle();
    expect(find.text('Ștergi recenzia?'), findsOne);
    await tester.tap(find.widgetWithText(FilledButton, 'Șterge'));
    await tester.pumpAndSettle();

    expect(places.ratings, isEmpty);
    expect(find.text('Trimite recenzia'), findsOne);
  });

  testWidgets('an operator cannot review their own place', (tester) async {
    const dan = Profile(
      id: 'dan',
      email: 'dan@test.ro',
      firstName: 'Dan',
      lastName: 'Pop',
      role: Role.operator,
    );
    await openReviews(tester, me: dan);

    expect(find.text('Nu poți scrie recenzii la propriul local.'), findsOne);
    expect(find.byTooltip('1 stea'), findsNothing);
  });

  testWidgets('a suspended account cannot review', (tester) async {
    const suspended = Profile(
      id: 'ana',
      email: 'ana@test.ro',
      firstName: 'Ana',
      lastName: 'Pop',
      role: Role.user,
      suspendedReason: 'Recenzii false',
    );
    await openReviews(tester, me: suspended);

    expect(
      find.text('Contul tău e suspendat: nu poți scrie recenzii.'),
      findsOne,
    );
    expect(find.byTooltip('1 stea'), findsNothing);
  });

  testWidgets('when sending fails, the user is told', (tester) async {
    await openReviews(tester, me: ana);
    places.offline = true;

    await tester.tap(find.byTooltip('5 stele'));
    await tester.pump();
    await tester.tap(find.text('Trimite recenzia'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Nu mă pot conecta.'), findsOne);
    expect(places.ratings, isEmpty);
  });

  testWidgets('the tab says what the rating is made of', (tester) async {
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
    await openReviews(tester, place: rated);
    expect(find.text('Ratingul e media celor 20 de recenzii.'), findsOne);
  });

  testWidgets("an original place keeps the old app's rating until reviewed", (
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
    await openReviews(tester, place: original, me: ana);

    expect(
      find.text(
        'Ratingul vine din aplicația originală, până la primele recenzii.',
      ),
      findsOne,
    );
    // A place without an operator: the admins accept its reviews.
    expect(find.textContaining('o acceptă un administrator'), findsOne);
  });

  testWidgets('the tabs show the description or the reviews', (tester) async {
    await openReviews(tester);
    expect(find.text('Despre locație'), findsNothing);
    expect(find.text('Ce spun ceilalți'), findsOne);

    await tester.tap(find.text('Descriere'));
    await tester.pumpAndSettle();

    expect(find.text('Despre locație'), findsOne);
    expect(find.text('Ce spun ceilalți'), findsNothing);
  });

  testWidgets('a few reviews show; all of them, by stars, one tap away', (
    tester,
  ) async {
    await openReviews(
      tester,
      ratings: [
        for (var stars = 1; stars <= 5; stars++)
          review(
            'u$stars',
            'Autor $stars',
            stars: stars,
            comment: 'Părerea $stars.',
          ),
      ],
    );
    expect(find.byType(ReviewTile), findsNWidgets(3));

    await tester.ensureVisible(find.text('Vezi mai multe (5)'));
    await tester.tap(find.text('Vezi mai multe (5)'));
    await tester.pumpAndSettle();
    expect(find.text('Recenzii: Ceainăria Dan'), findsOne);
    expect(find.byType(ReviewTile), findsNWidgets(5));

    await tester.tap(find.text('1 ★ (1)'));
    await tester.pumpAndSettle();
    expect(find.byType(ReviewTile), findsOne);
    expect(find.text('Părerea 1.'), findsOne);

    await tester.tap(find.text('Toate (5)'));
    await tester.pumpAndSettle();
    expect(find.byType(ReviewTile), findsNWidgets(5));
  });

  testWidgets('with three reviews or fewer there is nothing more to show', (
    tester,
  ) async {
    await openReviews(
      tester,
      ratings: [review('u1', 'Autor 1'), review('u2', 'Autor 2')],
    );

    expect(find.byType(ReviewTile), findsNWidgets(2));
    expect(find.textContaining('Vezi mai multe'), findsNothing);
  });
}
