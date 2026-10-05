import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:top_places/models/place.dart';
import 'package:top_places/utils/clusters.dart';
import 'package:top_places/utils/links.dart';
import 'package:top_places/widgets/place_marker.dart';
import 'package:top_places/widgets/place_sheet.dart';

/// How wide a marker is.
const _markerSize = 48.0;

/// How wide a bubble of several places is. Markers closer than that share
/// one, so that no two touch.
const _bubbleSize = 56.0;

/// From this zoom on, every place has its own marker, even when close.
const _separateZoom = 17.0;

/// OpenStreetMap with a marker for every place. Places too close to tell
/// apart share one bubble, which splits when the map zooms in. Tapping a
/// marker opens the place in a sheet: small at first, the whole page when
/// dragged up.
class PlacesMap extends StatefulWidget {
  const PlacesMap({super.key, required this.places});

  final List<Place> places;

  @override
  State<PlacesMap> createState() => _PlacesMapState();
}

class _PlacesMapState extends State<PlacesMap> {
  final _mapController = MapController();
  Place? _selected;

  /// Moves and zooms the map so that every place in the list is visible.
  CameraFit get _fitAllPlaces => CameraFit.coordinates(
    coordinates: [
      for (final place in widget.places) LatLng(place.lat, place.lng),
    ],
    padding: const EdgeInsets.all(64),
    maxZoom: 14,
  );

  @override
  void didUpdateWidget(PlacesMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    // After a search or a filter, show the places that are left.
    final placesChanged = !listEquals(oldWidget.places, widget.places);
    if (placesChanged && widget.places.isNotEmpty) {
      // Wait until this frame is drawn; the map can't move in the middle of it.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _mapController.fitCamera(_fitAllPlaces);
      });
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  /// Zooms in on [places], until their markers separate.
  void _zoomTo(List<Place> places) {
    _mapController.fitCamera(
      CameraFit.coordinates(
        coordinates: [for (final place in places) LatLng(place.lat, place.lng)],
        padding: const EdgeInsets.all(80),
        maxZoom: _separateZoom,
      ),
    );
  }

  /// Opens the sheet of [place]; its marker stays marked until it closes.
  Future<void> _open(Place place) async {
    setState(() => _selected = place);
    await showPlaceSheet(context, place);
    if (mounted) setState(() => _selected = null);
  }

  @override
  Widget build(BuildContext context) {
    // No marked marker when its place has been filtered out.
    final selected = widget.places.contains(_selected) ? _selected : null;

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: const LatLng(45.9, 24.9), // the middle of Romania
        initialZoom: 6,
        initialCameraFit: widget.places.isEmpty ? null : _fitAllPlaces,
        minZoom: 4,
        maxZoom: 19,
        interactionOptions: InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
          // Without this, Ctrl + drag still rotates the map on desktop.
          cursorKeyboardRotationOptions:
              CursorKeyboardRotationOptions.disabled(),
          // Keep the keyboard focus on the search bar when the map opens.
          keyboardOptions: const KeyboardOptions(autofocus: false),
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          // The OpenStreetMap tile policy asks apps to identify themselves.
          userAgentPackageName: 'com.tudorrrr.top_places',
        ),
        _Markers(
          places: widget.places,
          selected: selected,
          onOpen: _open,
          onZoomTo: _zoomTo,
        ),
        // The policy also asks for this credit, always visible on the map.
        const _OsmCredit(),
      ],
    );
  }
}

/// The markers, with the places too close to tell apart at this zoom in one
/// bubble. Built again whenever the map moves.
class _Markers extends StatelessWidget {
  const _Markers({
    required this.places,
    required this.selected,
    required this.onOpen,
    required this.onZoomTo,
  });

  final List<Place> places;
  final Place? selected;
  final ValueChanged<Place> onOpen;
  final ValueChanged<List<Place>> onZoomTo;

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);
    final groups = camera.zoom >= _separateZoom
        ? [
            for (final place in places) [place],
          ]
        : groupNearby(
            places,
            (place) => camera.projectAtZoom(LatLng(place.lat, place.lng)),
            distance: _bubbleSize,
          );

    return MarkerLayer(
      markers: [
        for (final group in groups)
          if (group case [final place])
            Marker(
              point: LatLng(place.lat, place.lng),
              width: _markerSize,
              height: _markerSize,
              child: PlaceMarker(
                place: place,
                selected: place == selected,
                onTap: () => onOpen(place),
              ),
            )
          else
            Marker(
              point: _middle(group),
              width: _bubbleSize,
              height: _bubbleSize,
              child: ClusterMarker(places: group, onTap: () => onZoomTo(group)),
            ),
      ],
    );
  }

  /// The point in the middle of [places].
  static LatLng _middle(List<Place> places) => LatLng(
    places.fold(0.0, (sum, place) => sum + place.lat) / places.length,
    places.fold(0.0, (sum, place) => sum + place.lng) / places.length,
  );
}

/// "© OpenStreetMap contributors" in the bottom right corner, linking to the
/// OpenStreetMap copyright page. On a narrow screen the text wraps instead of
/// overflowing.
class _OsmCredit extends StatelessWidget {
  const _OsmCredit();

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;

    return Align(
      alignment: Alignment.bottomRight,
      child: Semantics(
        link: true,
        child: Material(
          color: surface.withValues(alpha: 0.85),
          child: InkWell(
            onTap: () => openLink(
              context,
              Uri.parse('https://www.openstreetmap.org/copyright'),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Text(
                '© OpenStreetMap contributors',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
