import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:top_places/models/place.dart';
import 'package:top_places/utils/links.dart';
import 'package:top_places/widgets/mini_place_card.dart';
import 'package:top_places/widgets/place_marker.dart';

/// OpenStreetMap with a marker for every place. Tapping a marker shows a
/// small card; tapping the map hides it.
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

  @override
  Widget build(BuildContext context) {
    // Hide the card when its place has been filtered out.
    final selected = widget.places.contains(_selected) ? _selected : null;

    return Stack(
      children: [
        FlutterMap(
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
            onTap: (tapPosition, point) => setState(() => _selected = null),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              // The OpenStreetMap tile policy asks apps to identify themselves.
              userAgentPackageName: 'com.tudorrrr.top_places',
            ),
            MarkerLayer(
              markers: [
                for (final place in widget.places)
                  Marker(
                    point: LatLng(place.lat, place.lng),
                    width: 48,
                    height: 48,
                    child: PlaceMarker(
                      place: place,
                      selected: place == selected,
                      onTap: () => setState(() => _selected = place),
                    ),
                  ),
              ],
            ),
            // The policy also asks for this credit, always visible on the map.
            const _OsmCredit(),
          ],
        ),
        if (selected != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 40,
            child: MiniPlaceCard(place: selected),
          ),
      ],
    );
  }
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
