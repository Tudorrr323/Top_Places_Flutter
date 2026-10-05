import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:top_places/l10n/l10n.dart';
import 'package:top_places/models/place.dart';

void main() {
  final ro = lookupAppLocalizations(const Locale('ro'));
  final en = lookupAppLocalizations(const Locale('en'));

  test('Romanian counts add "de" from 20 on, but not after 101-119', () {
    expect(ro.results(0), '0 rezultate');
    expect(ro.results(1), '1 rezultat');
    expect(ro.results(3), '3 rezultate');
    expect(ro.results(19), '19 rezultate');
    expect(ro.results(20), '20 de rezultate');
    expect(ro.results(101), '101 rezultate');
    expect(ro.reviewCount(100), '100 de recenzii');
    expect(ro.ratingAverage(3), 'Ratingul e media celor 3 recenzii.');
    expect(ro.ratingAverage(20), 'Ratingul e media celor 20 de recenzii.');
  });

  test('English counts', () {
    expect(en.results(1), '1 result');
    expect(en.results(20), '20 results');
    expect(en.stars(1), '1 star');
    expect(en.stars(4), '4 stars');
  });

  test('the rating of a place, rated or new', () {
    const rated = Place(
      id: 'a',
      name: 'A',
      address: 'Str. A, Nr. 1, Iași',
      city: 'Iași',
      lat: 47.1,
      lng: 27.5,
      imageUrl: '',
      description: 'A quiet place.',
      descriptionRo: 'Un loc liniștit.',
      rating: 4.7,
    );
    const unrated = Place(
      id: 'b',
      name: 'B',
      address: 'Str. B, Nr. 2, Iași',
      city: 'Iași',
      lat: 47.1,
      lng: 27.5,
      imageUrl: '',
      description: 'A new place.',
      rating: 0,
    );
    expect(ro.placeRating(rated), '4.7');
    expect(ro.placeRatingLabel(rated), '4.7 stele');
    expect(ro.placeRating(unrated), 'Nou');
    expect(en.placeRating(unrated), 'New');
    expect(ro.description(rated), 'Un loc liniștit.');
    expect(en.description(rated), 'A quiet place.');
    expect(ro.description(unrated), 'A new place.', reason: 'no translation');
  });
}
