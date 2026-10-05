import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:top_places/l10n/l10n.dart';
import 'package:top_places/models/place.dart';
import 'package:top_places/models/rating.dart';
import 'package:top_places/services/place_service.dart';
import 'package:top_places/widgets/review_tile.dart';

/// Every accepted review of a place, newest first, with a filter by stars.
class AllReviewsScreen extends StatefulWidget {
  const AllReviewsScreen({super.key, required this.place});

  final Place place;

  @override
  State<AllReviewsScreen> createState() => _AllReviewsScreenState();
}

class _AllReviewsScreenState extends State<AllReviewsScreen> {
  late final Future<List<Rating>> _ratings;

  /// The stars shown, or null for all of them.
  int? _stars;

  @override
  void initState() {
    super.initState();
    _ratings = context.read<PlaceService?>()!.placeRatings(widget.place.id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.allReviewsTitle(widget.place.name))),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: FutureBuilder(
            future: _ratings,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.error case final error?) {
                return Center(child: Text(l10n.error(error)));
              }
              final all = snapshot.data!;
              int count(int stars) =>
                  all.where((rating) => rating.stars == stars).length;
              final shown = [
                for (final rating in all)
                  if (_stars == null || rating.stars == _stars) rating,
              ];

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      Icon(Icons.star, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        l10n.placeRating(widget.place),
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(l10n.reviewCount(all.length))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: Text(l10n.filterAllStars(all.length)),
                        selected: _stars == null,
                        onSelected: (_) => setState(() => _stars = null),
                      ),
                      for (var stars = 5; stars >= 1; stars--)
                        ChoiceChip(
                          label: Text(l10n.filterStars(stars, count(stars))),
                          selected: _stars == stars,
                          onSelected: (_) => setState(() => _stars = stars),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (shown.isEmpty)
                    Text(
                      l10n.noReviewsWithStars(_stars ?? 0),
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    )
                  else
                    for (final rating in shown) ReviewTile(rating: rating),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
