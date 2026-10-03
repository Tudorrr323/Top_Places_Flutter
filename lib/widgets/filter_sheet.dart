import 'package:flutter/material.dart';
import 'package:top_places/models/filters.dart';

/// The "Filtrează & Sortează" sheet. It returns the chosen [Filters] when the
/// user taps "Aplică filtre" or "Resetează", and null when it is closed
/// another way.
class FilterSheet extends StatefulWidget {
  const FilterSheet({super.key, required this.initial, required this.cities});

  final Filters initial;

  /// Only cities that have places, so no choice ends in an empty list.
  final List<String> cities;

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  // A draft: the screen only changes when the user taps "Aplică filtre".
  late String? _city = widget.initial.city;
  late double _minRating = widget.initial.minRating;
  late SortBy _sortBy = widget.initial.sortBy;

  static const _ratingChoices = [
    (0.0, 'Oricare'),
    (4.0, '4.0+'),
    (4.5, '4.5+'),
    (4.8, '4.8+'),
  ];

  static const _sortChoices = [
    (SortBy.recommended, 'Recomandat'),
    (SortBy.ratingDescending, 'Rating ↓'),
    (SortBy.ratingAscending, 'Rating ↑'),
    (SortBy.nameAscending, 'Nume (A-Z)'),
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filtrează & Sortează', style: textTheme.titleLarge),
            const SizedBox(height: 16),
            Text('Oraș', style: textTheme.titleMedium),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Toate'),
                  selected: _city == null,
                  onSelected: (_) => setState(() => _city = null),
                ),
                for (final city in widget.cities)
                  ChoiceChip(
                    label: Text(city),
                    selected: _city == city,
                    onSelected: (_) => setState(() => _city = city),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Rating minim', style: textTheme.titleMedium),
            Wrap(
              spacing: 8,
              children: [
                for (final (rating, label) in _ratingChoices)
                  ChoiceChip(
                    label: Text(label),
                    selected: _minRating == rating,
                    onSelected: (_) => setState(() => _minRating = rating),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Sortare', style: textTheme.titleMedium),
            Wrap(
              spacing: 8,
              children: [
                for (final (sortBy, label) in _sortChoices)
                  ChoiceChip(
                    label: Text(label),
                    selected: _sortBy == sortBy,
                    onSelected: (_) => setState(() => _sortBy = sortBy),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            // Side by side when they fit, one under the other when they don't
            // (small phones, large text).
            OverflowBar(
              alignment: MainAxisAlignment.spaceBetween,
              overflowSpacing: 8,
              overflowAlignment: OverflowBarAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context, const Filters()),
                  child: const Text('Resetează'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(
                    context,
                    Filters(
                      city: _city,
                      minRating: _minRating,
                      sortBy: _sortBy,
                    ),
                  ),
                  child: const Text('Aplică filtre'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}