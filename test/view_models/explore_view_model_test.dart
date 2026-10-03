import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:top_places/models/filters.dart';
import 'package:top_places/services/places_repository.dart';
import 'package:top_places/view_models/explore_view_model.dart';

void main() {
  final places = PlacesRepository.fromJsonStrings(
    placesJson: File('assets/data/locations.json').readAsStringSync(),
    citiesJson: File('assets/data/romanian_cities.json').readAsStringSync(),
  ).places;

  test('starts with every place', () {
    expect(ExploreViewModel(places).visiblePlaces, hasLength(20));
  });

  test('setQuery filters the places and notifies the listeners', () {
    final viewModel = ExploreViewModel(places);
    var notifications = 0;
    viewModel.addListener(() => notifications++);

    viewModel.setQuery('bucuresti');

    expect(viewModel.visiblePlaces, hasLength(3));
    expect(notifications, 1);
  });

  test('the same text again does not notify', () {
    final viewModel = ExploreViewModel(places)..setQuery('cluj');
    var notifications = 0;
    viewModel.addListener(() => notifications++);

    viewModel.setQuery('cluj');

    expect(notifications, 0);
  });

  test('applyFilters and resetFilters', () {
    final viewModel = ExploreViewModel(places)
      ..applyFilters(const Filters(city: 'Iași'));
    expect(viewModel.visiblePlaces, hasLength(2));
    expect(viewModel.filters.isActive, isTrue);

    viewModel.resetFilters();
    expect(viewModel.visiblePlaces, hasLength(20));
    expect(viewModel.filters.isActive, isFalse);
  });

  test('cities lists only the 13 cities with places, A to Z', () {
    final cities = ExploreViewModel(places).cities;
    expect(cities, hasLength(13));
    expect(cities.first, 'Alba Iulia');
    expect(cities.last, 'Timișoara');
  });
}