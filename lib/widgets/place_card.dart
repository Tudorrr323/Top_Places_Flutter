import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:top_places/l10n/l10n.dart';
import 'package:top_places/models/place.dart';
import 'package:top_places/view_models/explore_view_model.dart';
import 'package:top_places/widgets/place_photo.dart';

/// One place in the Explore list: photo, name, city and rating. Tapping it
/// shows the place on the map, with everything about it in a sheet.
class PlaceCard extends StatelessWidget {
  const PlaceCard({super.key, required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.read<ExploreViewModel>().focusPlace(place),
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
                    place.isRated
                        ? '★ ${context.l10n.placeRating(place)}'
                        : context.l10n.ratingNew,
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
