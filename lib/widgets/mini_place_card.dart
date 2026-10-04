import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:top_places/models/place.dart';
import 'package:top_places/utils/links.dart';

/// The card shown over the map when a marker is tapped.
class MiniPlaceCard extends StatelessWidget {
  const MiniPlaceCard({super.key, required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(place.name, style: textTheme.titleMedium),
            Text(place.address),
            Text('★ ${place.rating.toStringAsFixed(1)}'),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: OverflowBar(
                spacing: 8,
                children: [
                  TextButton.icon(
                    onPressed: () => openLink(context, directionsUri(place)),
                    icon: const Icon(Icons.directions),
                    label: const Text('Indicații'),
                  ),
                  FilledButton(
                    onPressed: () => context.push('/locations/${place.id}'),
                    child: const Text('Detalii'),
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
