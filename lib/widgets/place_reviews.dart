import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:top_places/l10n/l10n.dart';
import 'package:top_places/models/place.dart';
import 'package:top_places/models/profile.dart';
import 'package:top_places/models/rating.dart';
import 'package:top_places/screens/all_reviews_screen.dart';
import 'package:top_places/services/place_service.dart';
import 'package:top_places/services/places_repository.dart';
import 'package:top_places/view_models/account_view_model.dart';
import 'package:top_places/widgets/dialogs.dart';
import 'package:top_places/widgets/review_tile.dart';

/// The "Recenzii" tab: what the rating is made of, the signed-in account's
/// own review, and the accepted reviews of everyone else. The database
/// checks the same rules as the screen.
class PlaceReviews extends StatelessWidget {
  const PlaceReviews({super.key, required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final account = context.watch<AccountViewModel>();
    // Reviews need the accounts and the places in Supabase.
    final available =
        account.isAvailable && context.watch<PlaceService?>() != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              place.isRated ? Icons.star : Icons.fiber_new_outlined,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(l10n.placeRating(place), style: theme.textTheme.headlineSmall),
            const SizedBox(width: 12),
            Expanded(child: Text(_ratingSource(l10n, place))),
          ],
        ),
        const SizedBox(height: 16),
        if (!available)
          Text(
            l10n.reviewsNeedSupabase,
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          )
        else ...[
          // A new state for each account, so the review shown is always the
          // one of whoever is signed in.
          _MyReview(
            key: ValueKey(account.profile?.id),
            place: place,
            me: account.profile,
          ),
          const Divider(height: 32),
          _PublicReviews(place: place),
        ],
      ],
    );
  }

  /// What the rating is made of.
  static String _ratingSource(AppLocalizations l10n, Place place) =>
      switch (place.ratingCount) {
        0 when place.isRated => l10n.ratingFromOldApp,
        0 => l10n.noReviewsYet,
        1 => l10n.ratingFromOneReview,
        final count => l10n.ratingAverage(count),
      };
}

/// "Recenzia ta". Without a review, a form to write one. Once sent, the
/// review itself, with where it is: waiting, public or rejected. It can be
/// deleted, and a rejected one changed and sent again; there is one review
/// per account and place.
class _MyReview extends StatefulWidget {
  const _MyReview({super.key, required this.place, required this.me});

  final Place place;

  /// The signed-in account, or null.
  final Profile? me;

  @override
  State<_MyReview> createState() => _MyReviewState();
}

class _MyReviewState extends State<_MyReview> {
  /// The review as saved, or null when there is none.
  Rating? _saved;

  /// True while a rejected review is being changed, in the form.
  bool _editing = false;

  /// The stars chosen in the form.
  int? _stars;

  final _comment = TextEditingController();

  /// True until the saved review arrives.
  bool _loading = false;

  /// True while the review saves or is deleted; the buttons wait meanwhile.
  bool _busy = false;

  /// Why this account cannot write a review here, or null when it can.
  String? _cannotWrite(AppLocalizations l10n) {
    final me = widget.me;
    if (me == null) return l10n.reviewSignInFirst;
    if (me.isSuspended) return l10n.reviewSuspended;
    if (widget.place.ownerId == me.id) return l10n.reviewOwnPlace;
    return null;
  }

  /// True when this account can write a review here.
  bool get _canWrite {
    final me = widget.me;
    return me != null && !me.isSuspended && widget.place.ownerId != me.id;
  }

  /// When a waiting review becomes public: once the place's operator
  /// accepts it, or an admin for a place without one.
  String get _whenAccepted => widget.place.ownerId == null
      ? context.l10n.reviewAcceptedByAdmin
      : context.l10n.reviewAcceptedByOperator;

  /// When a review sent from this form becomes public. The database decides
  /// the same way: an admin's review is public at once.
  String get _whenPublic => widget.me?.role == Role.admin
      ? context.l10n.reviewAdminAtOnce
      : _whenAccepted;

  /// True when the form differs from the saved review: there is something
  /// to send.
  bool get _changed =>
      _stars != null &&
      (_stars != _saved?.stars ||
          _comment.text.trim() != (_saved?.comment ?? ''));

  @override
  void initState() {
    super.initState();
    if (_canWrite) {
      _loading = true;
      _load();
    }
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    Rating? saved;
    try {
      saved = await context.read<PlaceService?>()!.myRating(widget.place.id);
    } on PlaceException {
      // Offline: the form shows, and sending says what failed.
    }
    if (!mounted) return;
    setState(() {
      _show(saved);
      _loading = false;
    });
  }

  /// Shows [saved], and puts it in the form for when it is changed.
  void _show(Rating? saved) {
    _saved = saved;
    _editing = false;
    _stars = saved?.stars;
    _comment.text = saved?.comment ?? '';
  }

  Future<void> _send() async {
    final service = context.read<PlaceService?>()!;
    final repository = context.read<PlacesRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    setState(() => _busy = true);
    try {
      final saved = await service.saveRating(
        widget.place.id,
        stars: _stars!,
        comment: _comment.text,
      );
      if (mounted) setState(() => _show(saved));
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            saved.status == RatingStatus.approved
                ? l10n.reviewPublished
                : l10n.reviewSentWaiting,
          ),
        ),
      );
      await repository.refresh();
    } on PlaceException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.placeError(error))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await askConfirmation(
      context,
      title: context.l10n.deleteReviewTitle,
      message: context.l10n.deleteReviewMessage,
      action: context.l10n.delete,
    );
    if (!confirmed || !mounted) return;
    final service = context.read<PlaceService?>()!;
    final repository = context.read<PlacesRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    setState(() => _busy = true);
    try {
      await service.deleteRating(_saved!);
      if (mounted) setState(() => _show(null));
      await repository.refresh();
    } on PlaceException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.placeError(error))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cannotWrite = _cannotWrite(context.l10n);
    final saved = _saved;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            context.l10n.yourReview,
            style: theme.textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 4),
        if (cannotWrite != null)
          Text(
            cannotWrite,
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          )
        else if (_loading)
          const LinearProgressIndicator()
        else if (saved != null && !_editing)
          _savedReview(saved)
        else
          _form(),
      ],
    );
  }

  /// The review as sent, with where it is and what can be done with it.
  Widget _savedReview(Rating saved) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final comment = saved.comment;
    final (icon, status, explanation) = switch (saved.status) {
      RatingStatus.pending => (
        Icons.schedule,
        l10n.reviewPending,
        l10n.reviewPendingExplanation(_whenAccepted),
      ),
      RatingStatus.approved => (
        Icons.check_circle_outline,
        l10n.reviewApproved,
        l10n.reviewApprovedExplanation,
      ),
      RatingStatus.rejected => (
        Icons.block,
        l10n.reviewRejected,
        l10n.reviewRejectedExplanation(saved.statusReason ?? ''),
      ),
    };

    return Card.outlined(
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: StarRow(stars: saved.stars)),
                Chip(avatar: Icon(icon), label: Text(status)),
              ],
            ),
            if (comment != null) ...[const SizedBox(height: 4), Text(comment)],
            const SizedBox(height: 8),
            Text(
              explanation,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: OverflowBar(
                spacing: 8,
                children: [
                  TextButton(
                    onPressed: _busy ? null : _delete,
                    child: Text(l10n.deleteReview),
                  ),
                  if (saved.status == RatingStatus.rejected)
                    FilledButton.tonal(
                      onPressed: _busy
                          ? null
                          : () => setState(() => _editing = true),
                      child: Text(l10n.editReview),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The stars and the message, for a new review or a rejected one.
  Widget _form() {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final stars = _stars;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _editing
              ? l10n.reviewEditIntro(_whenPublic)
              : l10n.reviewNewIntro(_whenPublic),
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        ),
        Row(
          children: [
            for (var star = 1; star <= 5; star++)
              IconButton(
                tooltip: l10n.stars(star),
                isSelected: stars != null && star <= stars,
                icon: const Icon(Icons.star_border),
                selectedIcon: const Icon(Icons.star),
                color: theme.colorScheme.primary,
                onPressed: _busy ? null : () => setState(() => _stars = star),
              ),
          ],
        ),
        TextField(
          controller: _comment,
          enabled: !_busy,
          maxLength: 500,
          minLines: 2,
          maxLines: 5,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: l10n.reviewMessage,
            border: const OutlineInputBorder(),
          ),
          // The send button follows what is typed.
          onChanged: (_) => setState(() {}),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: OverflowBar(
            spacing: 8,
            children: [
              if (_editing)
                TextButton(
                  onPressed: _busy ? null : () => setState(() => _show(_saved)),
                  child: Text(l10n.cancel),
                ),
              FilledButton(
                onPressed: _busy || !_changed ? null : _send,
                child: Text(_editing ? l10n.sendAgain : l10n.sendReview),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The newest accepted reviews of everyone else, and a button to all of
/// them when there are more. Anyone sees them, signed in or not.
class _PublicReviews extends StatefulWidget {
  const _PublicReviews({required this.place});

  final Place place;

  @override
  State<_PublicReviews> createState() => _PublicReviewsState();
}

class _PublicReviewsState extends State<_PublicReviews> {
  /// How many reviews show here; the rest are one tap away.
  static const _preview = 3;

  late final PlaceService _service;
  late Future<List<Rating>> _ratings;

  @override
  void initState() {
    super.initState();
    _service = context.read<PlaceService?>()!;
    _ratings = _service.placeRatings(widget.place.id);
  }

  @override
  void didUpdateWidget(_PublicReviews oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A new average means a review was accepted, changed or deleted.
    final old = oldWidget.place;
    final place = widget.place;
    if (old.rating != place.rating || old.ratingCount != place.ratingCount) {
      _ratings = _service.placeRatings(place.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = TextStyle(color: theme.colorScheme.onSurfaceVariant);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            context.l10n.othersSay,
            style: theme.textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 8),
        FutureBuilder(
          future: _ratings,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.error case final error?) {
              return Text(context.l10n.error(error), style: muted);
            }
            // The reader's own review is above, with its status.
            final others = [
              for (final rating in snapshot.data!)
                if (!rating.mine) rating,
            ];
            if (others.isEmpty) {
              return Text(context.l10n.noPublishedReviews, style: muted);
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final rating in others.take(_preview))
                  ReviewTile(rating: rating),
                if (others.length > _preview)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) =>
                              AllReviewsScreen(place: widget.place),
                        ),
                      ),
                      // Every review, the reader's own included.
                      child: Text(
                        context.l10n.showMoreReviews(snapshot.data!.length),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
