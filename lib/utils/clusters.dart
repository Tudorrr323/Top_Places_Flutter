import 'dart:ui' show Offset;

/// Groups the [items] that are closer than [distance] to each other, by the
/// positions [positionOf] gives them (in pixels, on the screen). Each group
/// starts at the first item left over and takes every other item left
/// within [distance] of it. The result does not depend on chance, and every
/// item is in exactly one group, in the order of [items].
List<List<T>> groupNearby<T>(
  List<T> items,
  Offset Function(T item) positionOf, {
  required double distance,
}) {
  final positions = [for (final item in items) positionOf(item)];
  final grouped = List.filled(items.length, false);
  final groups = <List<T>>[];
  for (var first = 0; first < items.length; first++) {
    if (grouped[first]) continue;
    final group = [items[first]];
    for (var other = first + 1; other < items.length; other++) {
      if (!grouped[other] &&
          (positions[other] - positions[first]).distance < distance) {
        group.add(items[other]);
        grouped[other] = true;
      }
    }
    groups.add(group);
  }
  return groups;
}
