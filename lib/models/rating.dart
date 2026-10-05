/// Where a review is: waiting for the place's operator (or an admin),
/// accepted and public, or rejected with a reason.
enum RatingStatus { pending, approved, rejected }

/// A review: the stars an account gave a place, with a message if the
/// author wrote one. The same class holds the reader's own review, a public
/// one and one to decide about; each comes with the fields it needs.
class Rating {
  const Rating({
    required this.stars,
    this.comment,
    this.status = RatingStatus.approved,
    this.statusReason,
    this.author = '',
    this.placeId = '',
    this.placeName = '',
    this.userId = '',
    this.updatedAt,
    this.mine = false,
  });

  /// Builds a review from a row of the ratings table, or of the
  /// place_ratings and ratings_to_moderate functions in Supabase.
  factory Rating.fromRow(Map<String, dynamic> row) {
    final status = row['status'] as String?;
    final updatedAt = row['updated_at'] as String?;
    return Rating(
      stars: (row['stars'] as num).toInt(),
      comment: row['comment'] as String?,
      // place_ratings returns only accepted reviews, without a status.
      status: status == null
          ? RatingStatus.approved
          : RatingStatus.values.byName(status),
      statusReason: row['status_reason'] as String?,
      author: row['author'] as String? ?? '',
      placeId: row['place_id'] as String? ?? '',
      placeName: row['place_name'] as String? ?? '',
      userId: row['user_id'] as String? ?? '',
      updatedAt: updatedAt == null ? null : DateTime.parse(updatedAt).toLocal(),
      mine: row['mine'] as bool? ?? false,
    );
  }

  /// From 1 to 5.
  final int stars;

  /// The message, or null when the author wrote none.
  final String? comment;

  final RatingStatus status;

  /// Why the review was rejected.
  final String? statusReason;

  /// How the author is shown: "Ana P.", never the email.
  final String author;

  final String placeId;
  final String placeName;
  final String userId;

  /// When the author last wrote it.
  final DateTime? updatedAt;

  /// True for the reader's own review.
  final bool mine;
}
