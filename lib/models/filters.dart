/// How the list of places is ordered.
enum SortBy { recommended, ratingAscending, ratingDescending, nameAscending }

/// The choices made in the "Filtrează & Sortează" sheet.
class Filters {
  const Filters({
    this.city,
    this.minRating = 0,
    this.sortBy = SortBy.recommended,
  });

  /// Only places in this city; null means every city.
  final String? city;

  /// Only places rated at least this much; 0 means no limit.
  final double minRating;

  final SortBy sortBy;

  /// True when something differs from the defaults. The filter button
  /// uses it to show that filters are on.
  bool get isActive =>
      city != null || minRating > 0 || sortBy != SortBy.recommended;
}