import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:top_places/models/place.dart';
import 'package:top_places/widgets/place_photo.dart';

/// One place in the Explore list: photo, name, city and rating.
class PlaceCard extends StatelessWidget {
  const PlaceCard({super.key, required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/locations/${place.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 180, child: PlacePhoto(place: place, width: 800)),
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
                    place.isRated ? '★ ${place.ratingText}' : 'Nou',
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
