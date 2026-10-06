import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

/// The OpenStreetMap tiles under every map of the app.
class MapTiles extends StatelessWidget {
  const MapTiles({super.key});

  @override
  Widget build(BuildContext context) {
    return TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      // The OpenStreetMap tile policy asks apps to identify themselves.
      userAgentPackageName: 'com.tudorrrr.top_places',
      tileProvider: NetworkTileProvider(
        // Tiles the map no longer needs, as it flies or zooms, stop
        // downloading. Except in a debug build on the web: there the
        // browser reports each stopped download as an uncaught error, and
        // the debugger stops on it, although the map handles it.
        abortObsoleteRequests: !(kIsWeb && kDebugMode),
      ),
      // Darker in the dark theme, so that it does not glare.
      tileBuilder: Theme.of(context).brightness == Brightness.dark
          ? darkModeTileBuilder
          : null,
    );
  }
}
