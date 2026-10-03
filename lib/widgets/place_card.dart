import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:top_places/models/place.dart';

/// One place in the Explore list: photo, name, city and rating.
class PlaceCard extends StatelessWidget {
  const PlaceCard({super.key, required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final placeholderColor = theme.colorScheme.surfaceContainerHighest;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/locations/${place.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 180,
              child: Image.network(
                // Unsplash resizes on its side; 800 px wide is enough here.
                '${place.imageUrl}?w=800&q=80',
                fit: BoxFit.cover,
                // A stock photo, not information: screen readers skip it.
                excludeFromSemantics: true,
                loadingBuilder: (context, child, progress) => progress == null
                    ? child
                    : ColoredBox(color: placeholderColor),
                errorBuilder: (context, error, stackTrace) => ColoredBox(
                  color: placeholderColor,
                  child: const Icon(Icons.image_not_supported_outlined),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(place.name, style: theme.textTheme.titleMedium),
                        Text(place.city),
                      ],
                    ),
                  ),
                  Text(
                    '★ ${place.rating.toStringAsFixed(1)}',
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}