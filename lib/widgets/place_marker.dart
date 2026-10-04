import 'package:flutter/material.dart';
import 'package:top_places/models/place.dart';

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
    final rating = place.rating.toStringAsFixed(1);

    return Tooltip(
      message: place.name,
      // What a screen reader says, instead of only "4.7".
      child: Semantics(
        label: '${place.name}, $rating stele',
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
