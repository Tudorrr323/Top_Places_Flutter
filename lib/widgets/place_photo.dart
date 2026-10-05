import 'package:flutter/material.dart';
import 'package:top_places/models/place.dart';

/// The address to download [place]'s photo from, or null without a photo.
/// Unsplash resizes on its side, so only the pixels needed are downloaded;
/// the links that operators give are used as they are.
String? photoUrl(Place place, int width) {
  final url = place.imageUrl.trim();
  if (url.isEmpty) return null;
  return url.startsWith('https://images.unsplash.com/')
      ? '$url?w=$width&q=80'
      : url;
}

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
    final url = photoUrl(place, width);
    if (url == null) {
      return ColoredBox(
        color: placeholderColor,
        child: const Icon(Icons.storefront_outlined),
      );
    }

    return Image.network(
      url,
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
