import 'package:flutter/material.dart';
import 'package:top_places/models/place.dart';

/// The photo of a place, filling the space it gets. A plain background shows
/// while it loads, and an icon when it can't be loaded (e.g. offline).
class PlacePhoto extends StatelessWidget {
  const PlacePhoto({super.key, required this.place, required this.width});

  final Place place;

  /// How wide Unsplash should send the photo, in pixels.
  final int width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final placeholderColor = theme.colorScheme.surfaceContainerHighest;

    return Image.network(
      // Unsplash resizes on its side, so only the pixels needed are downloaded.
      '${place.imageUrl}?w=$width&q=80',
      fit: BoxFit.cover,
      // A stock photo, not information: screen readers skip it.
      excludeFromSemantics: true,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : ColoredBox(color: placeholderColor),
      errorBuilder: (context, error, stackTrace) => ColoredBox(
        color: placeholderColor,
        child: const Icon(Icons.image_not_supported_outlined),
      ),
    );
  }
}
