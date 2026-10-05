import 'package:flutter/material.dart';
import 'package:top_places/l10n/l10n.dart';
import 'package:top_places/models/rating.dart';

/// One accepted review: who wrote it and when, the stars and the message.
class ReviewTile extends StatelessWidget {
  const ReviewTile({super.key, required this.rating});

  final Rating rating;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  rating.mine
                      ? l10n.reviewAuthorYou(rating.author)
                      : rating.author,
                  style: theme.textTheme.titleSmall,
                ),
              ),
              Text(
                l10n.date(rating.updatedAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          StarRow(stars: rating.stars),
          if (rating.comment case final comment?) ...[
            const SizedBox(height: 4),
            Text(comment),
          ],
        ],
      ),
    );
  }
}

/// Five stars, [stars] of them filled. Read as "4 stele" instead of five
/// icons.
class StarRow extends StatelessWidget {
  const StarRow({super.key, required this.stars});

  final int stars;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.l10n.stars(stars),
      excludeSemantics: true,
      child: Row(
        children: [
          for (var star = 1; star <= 5; star++)
            Icon(
              star <= stars ? Icons.star : Icons.star_border,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
        ],
      ),
    );
  }
}
