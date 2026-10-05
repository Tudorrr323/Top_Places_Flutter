import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:top_places/l10n/l10n.dart';
import 'package:top_places/models/place.dart';
import 'package:top_places/services/location_service.dart';
import 'package:top_places/utils/clusters.dart';
import 'package:top_places/utils/links.dart';
import 'package:top_places/widgets/place_marker.dart';
import 'package:top_places/view_models/explore_view_model.dart';
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
/// dragged up. The GPS button shows where the device is. The map moves only
/// when asked to: by a [request], a marker or the GPS button.
class PlacesMap extends StatefulWidget {
  const PlacesMap({
    super.key,
    required this.places,
    this.request,
    this.onRequestShown,
  });

  final List<Place> places;

  /// Something to show, asked for from elsewhere.
  final MapRequest? request;

  /// Called once [request] is shown.
  final VoidCallback? onRequestShown;

  @override
  State<PlacesMap> createState() => _PlacesMapState();
}

class _PlacesMapState extends State<PlacesMap>
    with SingleTickerProviderStateMixin {
  final _mapController = MapController();
  Place? _selected;

  /// The flight of the map to a place.
  late final _flight = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  /// What moves the map during the current flight.
  VoidCallback? _flightStep;

  /// The number of the last request shown.
  int? _shownRequest;

  /// Where the device is, once the GPS button found it.
  LatLng? _myLocation;

  /// True while the GPS button looks for the device.
  bool _locating = false;

  /// Moves and zooms the map so that every place in the list is visible.
  CameraFit get _fitAllPlaces => CameraFit.coordinates(
    coordinates: [
      for (final place in widget.places) LatLng(place.lat, place.lng),
    ],
    padding: const EdgeInsets.all(64),
    maxZoom: 14,
  );

  @override
  void initState() {
    super.initState();
    _showLater(widget.request);
  }

  @override
  void didUpdateWidget(PlacesMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    _showLater(widget.request);
  }

  @override
  void dispose() {
    _flight.dispose();
    _mapController.dispose();
    super.dispose();
  }

  /// Shows [request] once this frame is drawn: the map can't move in the
  /// middle of it.
  void _showLater(MapRequest? request) {
    if (request == null || request.number == _shownRequest) return;
    _shownRequest = request.number;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onRequestShown?.call();
      switch (request.place) {
        case final place?:
          _flyTo(place);
        case null when widget.places.isNotEmpty:
          _mapController.fitCamera(_fitAllPlaces);
        case null:
          break;
      }
    });
  }

  /// Moves the map smoothly from where it is to [place], close enough for
  /// the place to have its own marker, then opens it.
  Future<void> _flyTo(Place place) async {
    final camera = _mapController.camera;
    final zoom = math.max(camera.zoom, _separateZoom);
    // The place ends above the middle, clear of the sheet that opens over
    // the bottom of the map.
    final shift = Offset(0, math.min(120, camera.size.height / 4));
    final target = camera.unprojectAtZoom(
      camera.projectAtZoom(LatLng(place.lat, place.lng), zoom) + shift,
      zoom,
    );
    if (await _fly(target, zoom) && mounted) await _open(place);
  }

  /// Moves the map smoothly from where it is to [target] at [zoom]. False
  /// when another flight took over, or the map closed, before the end.
  Future<bool> _fly(LatLng target, double zoom) async {
    final camera = _mapController.camera;
    final from = camera.center;
    final fromZoom = camera.zoom;

    _stopFlight();
    void step() {
      final t = Curves.easeInOutCubic.transform(_flight.value);
      _mapController.move(
        LatLng(
          lerpDouble(from.latitude, target.latitude, t)!,
          lerpDouble(from.longitude, target.longitude, t)!,
        ),
        lerpDouble(fromZoom, zoom, t)!,
      );
    }

    _flightStep = step;
    _flight.addListener(step);
    // No motion when the system settings ask for less of it.
    if (MediaQuery.disableAnimationsOf(context)) {
      _flight.value = 1;
    } else {
      try {
        await _flight.forward(from: 0).orCancel;
      } on TickerCanceled {
        return false;
      }
    }
    _stopFlight();
    return true;
  }

  void _stopFlight() {
    _flight.stop();
    if (_flightStep case final step?) _flight.removeListener(step);
    _flightStep = null;
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

  /// The GPS button: asks for the permission the first time, then flies
  /// the map to where the device is.
  Future<void> _goToMyLocation() async {
    final location = context.read<LocationService>();
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    setState(() => _locating = true);
    try {
      final here = await location.currentLocation();
      if (!mounted) return;
      setState(() => _myLocation = here);
      // Close enough to see the streets, without zooming out.
      await _fly(here, math.max(_mapController.camera.zoom, 15));
    } on LocationException catch (error) {
      final openSettings = error.openSettings;
      messenger.showSnackBar(
        SnackBar(
          content: Text(switch (error.problem) {
            LocationProblem.serviceOff => l10n.locationServiceOff,
            LocationProblem.denied => l10n.locationDenied,
            LocationProblem.deniedForever => l10n.locationDeniedForever,
            LocationProblem.blockedByBrowser => l10n.locationBlockedByBrowser,
            LocationProblem.accuracyOff => l10n.locationAccuracyOff,
            LocationProblem.notFound => l10n.locationNotFound,
          }),
          action: openSettings == null
              ? null
              : SnackBarAction(label: l10n.settings, onPressed: openSettings),
        ),
      );
    } finally {
      if (mounted) setState(() => _locating = false);
    }
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

    final myLocation = _myLocation;

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
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              // The OpenStreetMap tile policy asks apps to identify themselves.
              userAgentPackageName: 'com.tudorrrr.top_places',
            ),
            // Under the places, so that they stay easy to tap.
            if (myLocation != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: myLocation,
                    width: 24,
                    height: 24,
                    child: const _MyLocationDot(),
                  ),
                ],
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
        ),
        // Bottom left, away from the credit on the right.
        Positioned(
          left: 16,
          bottom: 16,
          child: FloatingActionButton.small(
            // Not shared with another screen.
            heroTag: null,
            tooltip: context.l10n.myLocationTooltip,
            onPressed: _locating ? null : _goToMyLocation,
            child: _locating
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location),
          ),
        ),
      ],
    );
  }
}

/// The device's location: a blue dot with a white ring.
class _MyLocationDot extends StatelessWidget {
  const _MyLocationDot();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.l10n.myLocationLabel,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)],
        ),
      ),
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
