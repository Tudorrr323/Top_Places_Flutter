import 'package:flutter/material.dart';
import 'package:top_places/l10n/l10n.dart';
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

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = context.l10n;
    final ratingChoices = [
      (0.0, l10n.filtersAnyRating),
      (4.0, '4.0+'),
      (4.5, '4.5+'),
      (4.8, '4.8+'),
    ];
    final sortChoices = [
      (SortBy.recommended, l10n.sortRecommended),
      (SortBy.ratingDescending, l10n.sortRatingDown),
      (SortBy.ratingAscending, l10n.sortRatingUp),
      (SortBy.nameAscending, l10n.sortName),
    ];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.filtersTitle, style: textTheme.titleLarge),
            const SizedBox(height: 16),
            Text(l10n.filtersCity, style: textTheme.titleMedium),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: Text(l10n.filtersAllCities),
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
            Text(l10n.filtersMinRating, style: textTheme.titleMedium),
            Wrap(
              spacing: 8,
              children: [
                for (final (rating, label) in ratingChoices)
                  ChoiceChip(
                    label: Text(label),
                    selected: _minRating == rating,
                    onSelected: (_) => setState(() => _minRating = rating),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(l10n.filtersSort, style: textTheme.titleMedium),
            Wrap(
              spacing: 8,
              children: [
                for (final (sortBy, label) in sortChoices)
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
                  child: Text(l10n.filtersReset),
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
                  child: Text(l10n.filtersApply),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
