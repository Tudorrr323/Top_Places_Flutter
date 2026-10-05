import 'package:flutter/material.dart';
import 'package:top_places/models/place.dart';
import 'package:top_places/utils/plural.dart';

/// A place on the map: a circle with its rating, filled red when selected.
class PlaceMarker extends StatelessWidget {
  const PlaceMarker({
    super.key,
    required this.place,
    required this.selected,
    required this.onTap,
  });

  final Place place;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final rating = place.ratingText;

    return Tooltip(
      message: place.name,
      // What a screen reader says, instead of only "4.7".
      child: Semantics(
        label: '${place.name}, ${place.ratingLabel}',
        button: true,
        selected: selected,
        onTap: onTap,
        excludeSemantics: true,
        child: Material(
          color: selected ? colors.error : colors.surface,
          shape: CircleBorder(side: BorderSide(color: colors.error, width: 3)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Center(
              child: selected
                  ? Icon(Icons.restaurant, size: 22, color: colors.onError)
                  : Text(
                      rating,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Several places too close to tell apart at this zoom: a bigger circle with
/// how many they are. Tapping it zooms in until they separate.
class ClusterMarker extends StatelessWidget {
  const ClusterMarker({super.key, required this.places, required this.onTap});

  final List<Place> places;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final label = countLabel(places.length, 'local', 'localuri');

    return Tooltip(
      message: label,
      child: Semantics(
        label: '$label aici. Apasă ca să apropii harta.',
        button: true,
        onTap: onTap,
        excludeSemantics: true,
        child: Material(
          color: colors.primary,
          shape: CircleBorder(
            side: BorderSide(color: colors.onPrimary, width: 3),
          ),
          elevation: 3,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Center(
              child: Text(
                '${places.length}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors.onPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
