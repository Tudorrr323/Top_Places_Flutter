import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:top_places/app.dart';
import 'package:top_places/services/location_service.dart';
import 'package:top_places/services/places_repository.dart';
import 'package:top_places/widgets/place_marker.dart';

import '../fake_location_service.dart';

import 'package:top_places/widgets/place_card.dart';

void main() {
  final repository = PlacesRepository.fromJsonStrings(
    placesJson: File('assets/data/locations.json').readAsStringSync(),
    citiesJson: File('assets/data/romanian_cities.json').readAsStringSync(),
  );

  Future<void> startApp(
    WidgetTester tester,
    Size size, {
    LocationService? location,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      TopPlacesApp(
        repository: repository,
        location: location ?? FakeLocationService(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the map button swaps the list for the map', (tester) async {
    await startApp(tester, const Size(400, 900));

    await tester.tap(find.byTooltip('Arată harta'));
    await tester.pumpAndSettle();

    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.byType(PlaceCard), findsNothing);
  });

  testWidgets('a wide window shows the list and the map together', (
    tester,
  ) async {
    await startApp(tester, const Size(1400, 900));

    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.byType(PlaceCard), findsWidgets);
    expect(find.byTooltip('Arată harta'), findsNothing);
  });

  group('a marker opens a sheet', () {
    const name = "Gaming Coffee Shop 'Restart'";

    /// Opens the map and taps the marker of [name], which has no
    /// neighbours: zoomed out, nearby markers overlap.
    Future<void> openSheet(WidgetTester tester) async {
      await startApp(tester, const Size(400, 900));
      await tester.tap(find.byTooltip('Arată harta'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(name));
      await tester.pumpAndSettle();
    }

    /// How tall the sheet is now.
    double sheetHeight(WidgetTester tester) => tester
        .getSize(
          find
              .descendant(
                of: find.byType(DraggableScrollableSheet),
                matching: find.byType(Material),
              )
              .first,
        )
        .height;

    testWidgets('small at first, with what matters most', (tester) async {
      await openSheet(tester);

      expect(find.text(name), findsOneWidget);
      expect(find.text('Strada Vasile Alecsandri, Nr. 5, Galați'), findsOne);
      expect(find.textContaining('Jocuri de societate'), findsOne);
      expect(find.text('★ 4.1'), findsOne);
      expect(sheetHeight(tester), lessThan(300));
    });

    testWidgets('dragged up, it covers the screen, tabs included', (
      tester,
    ) async {
      await openSheet(tester);

      await tester.drag(find.text(name), const Offset(0, -700));
      await tester.pumpAndSettle();

      expect(sheetHeight(tester), 900);
      expect(find.byTooltip('Micșorează'), findsOne);
      await tester.tap(find.text('Recenzii'));
      await tester.pumpAndSettle();
      expect(find.textContaining('conectată la Supabase'), findsOne);
    });

    testWidgets('its button resizes it', (tester) async {
      await openSheet(tester);

      await tester.tap(find.byTooltip('Toate detaliile'));
      await tester.pumpAndSettle();
      expect(sheetHeight(tester), 900);

      await tester.tap(find.byTooltip('Micșorează'));
      await tester.pumpAndSettle();
      expect(sheetHeight(tester), lessThan(300));
    });

    testWidgets('full, it shrinks when dragged down, then closes', (
      tester,
    ) async {
      await openSheet(tester);
      await tester.tap(find.byTooltip('Toate detaliile'));
      await tester.pumpAndSettle();

      await tester.timedDrag(
        find.text(name),
        const Offset(0, 500),
        const Duration(milliseconds: 300),
      );
      await tester.pumpAndSettle();
      expect(sheetHeight(tester), lessThan(300));

      await tester.timedDrag(
        find.text(name),
        const Offset(0, 200),
        const Duration(milliseconds: 300),
      );
      await tester.pumpAndSettle();
      expect(find.byType(DraggableScrollableSheet), findsNothing);
    });

    testWidgets('a tap on the map closes it', (tester) async {
      await openSheet(tester);

      await tester.tapAt(const Offset(200, 200));
      await tester.pumpAndSettle();

      expect(find.byType(DraggableScrollableSheet), findsNothing);
    });

    testWidgets('dragged down, it closes', (tester) async {
      await openSheet(tester);

      await tester.drag(find.text(name), const Offset(0, 300));
      await tester.pumpAndSettle();

      expect(find.byType(DraggableScrollableSheet), findsNothing);
    });
  });

  testWidgets('nearby places share a bubble that splits when tapped', (
    tester,
  ) async {
    await startApp(tester, const Size(400, 900));
    await tester.tap(find.byTooltip('Arată harta'));
    await tester.pumpAndSettle();

    final clusters = tester.widgetList<ClusterMarker>(
      find.byType(ClusterMarker),
    );
    expect(clusters, isNotEmpty);
    final inClusters = clusters.fold(0, (sum, c) => sum + c.places.length);
    expect(
      inClusters + find.byType(PlaceMarker).evaluate().length,
      20,
      reason: 'every place shows once',
    );

    // Tapping a bubble zooms in on its places: each then has its own
    // marker, or is in a smaller bubble.
    var group = clusters.first.places;
    await tester.tap(find.byType(ClusterMarker).first);
    await tester.pumpAndSettle();
    for (final place in group) {
      final alone = find.byTooltip(place.name).evaluate().isNotEmpty;
      final inSmaller = tester
          .widgetList<ClusterMarker>(find.byType(ClusterMarker))
          .any(
            (bubble) =>
                bubble.places.length < group.length &&
                bubble.places.contains(place),
          );
      expect(alone || inSmaller, isTrue, reason: place.name);
    }

    // Tapping the smaller bubbles ends with a marker for each place.
    for (var tap = 0; tap < 5; tap++) {
      final smaller = find.byWidgetPredicate(
        (widget) =>
            widget is ClusterMarker && widget.places.any(group.contains),
      );
      if (smaller.evaluate().isEmpty) break;
      group = tester.widget<ClusterMarker>(smaller.first).places;
      await tester.tap(smaller.first);
      await tester.pumpAndSettle();
    }
    for (final place in group) {
      expect(find.byTooltip(place.name), findsOne, reason: place.name);
    }
  });

  group('the GPS button', () {
    testWidgets('moves the map to where the device is', (tester) async {
      const bucharest = LatLng(44.4268, 26.1025);
      await startApp(
        tester,
        const Size(400, 900),
        location: FakeLocationService(location: bucharest),
      );
      await tester.tap(find.byTooltip('Arată harta'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Arată-mi locația'));
      await tester.pumpAndSettle();

      final camera = tester
          .widget<FlutterMap>(find.byType(FlutterMap))
          .mapController!
          .camera;
      expect(camera.center.latitude, closeTo(bucharest.latitude, 0.001));
      expect(camera.center.longitude, closeTo(bucharest.longitude, 0.001));
      expect(camera.zoom, greaterThanOrEqualTo(15));
      expect(find.bySemanticsLabel('Locația ta'), findsOne);
    });

    testWidgets('says why when the location is refused', (tester) async {
      var opened = false;
      await startApp(
        tester,
        const Size(400, 900),
        location: FakeLocationService(
          error: LocationException(
            'Ai refuzat localizarea pentru Top Places.',
            openSettings: () async => opened = true,
          ),
        ),
      );
      await tester.tap(find.byTooltip('Arată harta'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Arată-mi locația'));
      await tester.pumpAndSettle();
      expect(find.text('Ai refuzat localizarea pentru Top Places.'), findsOne);

      await tester.tap(find.text('Setări'));
      await tester.pumpAndSettle();
      expect(opened, isTrue);
      expect(find.bySemanticsLabel('Locația ta'), findsNothing);
    });
  });
}
