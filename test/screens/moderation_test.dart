import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:top_places/app.dart';
import 'package:top_places/models/place.dart';
import 'package:top_places/models/profile.dart';
import 'package:top_places/models/rating.dart';
import 'package:top_places/services/places_repository.dart';

import '../fake_account_service.dart';
import '../fake_place_service.dart';

void main() {
  const dan = Profile(
    id: 'dan',
    email: 'dan@test.ro',
    firstName: 'Dan',
    lastName: 'Pop',
    role: Role.operator,
  );
  const admin = Profile(
    id: 'admin',
    email: 'maria@test.ro',
    firstName: 'Maria',
    lastName: 'Admin',
    role: Role.admin,
  );
  const place = Place(
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

  Rating waiting(String userId, String author, int stars, String comment) =>
      Rating(
        stars: stars,
        comment: comment,
        status: RatingStatus.pending,
        author: author,
        placeId: place.id,
        placeName: place.name,
        userId: userId,
      );

  late FakePlaceService places;
  late PlacesRepository repository;

  /// Signs in as [me] and opens the reviews from the Profil tab, with the
  /// button labelled [button].
  Future<void> openModeration(
    WidgetTester tester,
    Profile me,
    String button,
  ) async {
    places = FakePlaceService(public: [place], me: me.id)
      ..mine.add(place)
      ..ratings.addAll([
        waiting('ana', 'Ana P.', 4, 'Ceai bun.'),
        waiting('ion', 'Ion I.', 2, 'Prea scump.'),
      ]);
    repository = PlacesRepository(
      initialPlaces: [place],
      cities: const [],
      remote: places,
    );
    tester.view.physicalSize = const Size(400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      TopPlacesApp(
        repository: repository,
        accounts: FakeAccountService(signedIn: me),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(button));
    await tester.tap(find.text(button));
    await tester.pumpAndSettle();
  }

  testWidgets('the operator accepts a review, which then counts', (
    tester,
  ) async {
    await openModeration(tester, dan, 'Recenziile localurilor mele');
    expect(find.text('„Ceai bun.”'), findsOne);
    expect(find.text('Ana P. · 4 stele'), findsOne);
    expect(find.text('Șterge'), findsNothing, reason: 'only admins delete');

    await tester.tap(find.widgetWithText(FilledButton, 'Acceptă').first);
    await tester.pumpAndSettle();
    expect(find.text('Accepți recenzia lui Ana P.?'), findsOne);
    // The dialog's button, over the ones on the cards.
    await tester.tap(find.widgetWithText(FilledButton, 'Acceptă').last);
    await tester.pumpAndSettle();

    expect(places.ratings.first.status, RatingStatus.approved);
    expect(find.text('„Ceai bun.”'), findsNothing, reason: 'not waiting');
    // Explore shows the new average.
    expect(repository.placeById(place.id)!.rating, 4);
    expect(repository.placeById(place.id)!.ratingCount, 1);
  });

  testWidgets('rejecting a review asks for the reason', (tester) async {
    await openModeration(tester, dan, 'Recenziile localurilor mele');

    await tester.tap(find.widgetWithText(TextButton, 'Respinge').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Respinge'));
    await tester.pumpAndSettle();
    expect(find.text('Scrie motivul.'), findsOne);

    await tester.enterText(
      find.byType(TextFormField),
      'Fără legătură cu localul',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Respinge'));
    await tester.pumpAndSettle();

    expect(places.ratings.last.status, RatingStatus.rejected);
    expect(places.ratings.last.statusReason, 'Fără legătură cu localul');

    await tester.tap(find.text('Respinse'));
    await tester.pumpAndSettle();
    expect(find.text('Motiv: Fără legătură cu localul'), findsOne);
  });

  testWidgets('an admin can also delete a review', (tester) async {
    await openModeration(tester, admin, 'Recenzii: acceptări și ștergeri');

    await tester.tap(find.widgetWithText(TextButton, 'Șterge').first);
    await tester.pumpAndSettle();
    expect(find.text('Ștergi recenzia lui Ana P.?'), findsOne);
    await tester.tap(find.widgetWithText(FilledButton, 'Șterge'));
    await tester.pumpAndSettle();

    expect(places.ratings.map((rating) => rating.author), ['Ion I.']);
    expect(find.text('„Ceai bun.”'), findsNothing);
  });

  testWidgets('the search bar filters the reviews', (tester) async {
    await openModeration(tester, dan, 'Recenziile localurilor mele');

    await tester.enterText(find.byType(TextField), 'scump');
    await tester.pumpAndSettle();

    expect(find.text('„Prea scump.”'), findsOne);
    expect(find.text('„Ceai bun.”'), findsNothing);
  });
}
