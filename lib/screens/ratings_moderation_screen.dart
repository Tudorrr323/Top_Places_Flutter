import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:top_places/l10n/l10n.dart';
import 'package:top_places/models/profile.dart';
import 'package:top_places/models/rating.dart';
import 'package:top_places/services/place_service.dart';
import 'package:top_places/services/places_repository.dart';
import 'package:top_places/view_models/account_view_model.dart';
import 'package:top_places/widgets/dialogs.dart';
import 'package:top_places/widgets/list_search_field.dart';

/// For operators and admins: the reviews they decide about. An operator sees
/// those of their own places, an admin those of every place, and only an
/// admin deletes them. The database allows exactly that.
class RatingsModerationScreen extends StatefulWidget {
  const RatingsModerationScreen({super.key});

  @override
  State<RatingsModerationScreen> createState() =>
      _RatingsModerationScreenState();
}

class _RatingsModerationScreenState extends State<RatingsModerationScreen> {
  RatingStatus _shown = RatingStatus.pending;
  String _query = '';
  late Future<List<Rating>> _ratings;

  @override
  void initState() {
    super.initState();
    _ratings = _load();
  }

  Future<List<Rating>> _load() =>
      context.read<PlaceService?>()?.ratingsToModerate() ??
      Future.value(const []);

  void _reload() {
    setState(() {
      _ratings = _load();
    });
  }

  /// Runs [change] on the server, then shows its effect here and in the
  /// averages of Explore.
  Future<void> _apply(
    Future<void> Function(PlaceService service) change,
  ) async {
    final service = context.read<PlaceService?>()!;
    final repository = context.read<PlacesRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    try {
      await change(service);
      await repository.refresh();
      if (mounted) _reload();
    } on PlaceException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.placeError(error))));
    }
  }

  Future<void> _accept(Rating rating) async {
    final confirmed = await askConfirmation(
      context,
      title: context.l10n.acceptReviewTitle(rating.author),
      message: context.l10n.acceptReviewMessage,
      action: context.l10n.accept,
    );
    if (!confirmed) return;
    await _apply(
      (service) => service.decideRating(rating, RatingDecision.approve()),
    );
  }

  Future<void> _reject(Rating rating) async {
    final reason = await askReason(
      context,
      title: context.l10n.rejectReviewTitle(rating.author),
      action: context.l10n.reject,
    );
    if (reason == null) return;
    await _apply(
      (service) => service.decideRating(rating, RatingDecision.reject(reason)),
    );
  }

  Future<void> _delete(Rating rating) async {
    final confirmed = await askConfirmation(
      context,
      title: context.l10n.deleteOthersReviewTitle(rating.author),
      message: context.l10n.deleteOthersReviewMessage,
      action: context.l10n.delete,
    );
    if (!confirmed) return;
    await _apply((service) => service.deleteRating(rating));
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin =
        context.watch<AccountViewModel>().profile?.role == Role.admin;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.reviewsTitle)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: ListSearchField(
                  hint: context.l10n.searchReviews,
                  onChanged: (query) => setState(() => _query = query),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final status in RatingStatus.values)
                      ChoiceChip(
                        label: Text(_filterLabel(context.l10n, status)),
                        selected: _shown == status,
                        onSelected: (_) => setState(() => _shown = status),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder(
                  future: _ratings,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.error case final error?) {
                      return Center(child: Text(context.l10n.error(error)));
                    }
                    final ratings = [
                      for (final rating in snapshot.data!)
                        if (rating.status == _shown &&
                            matchesSearch(_query, [
                              rating.placeName,
                              rating.author,
                              rating.comment ?? '',
                            ]))
                          rating,
                    ];
                    if (ratings.isEmpty) {
                      return Center(child: Text(context.l10n.noReviewsHere));
                    }
                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        for (final rating in ratings)
                          _RatingCard(
                            rating: rating,
                            actions: _actionsFor(rating, isAdmin: isAdmin),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The decisions that make sense for a review, given where it is.
  List<Widget> _actionsFor(Rating rating, {required bool isAdmin}) {
    Widget button(String label, VoidCallback onPressed) =>
        TextButton(onPressed: onPressed, child: Text(label));
    final l10n = context.l10n;

    return [
      if (isAdmin) button(l10n.delete, () => _delete(rating)),
      ...switch (rating.status) {
        RatingStatus.pending => [
          button(l10n.reject, () => _reject(rating)),
          FilledButton(
            onPressed: () => _accept(rating),
            child: Text(l10n.accept),
          ),
        ],
        RatingStatus.approved => [button(l10n.reject, () => _reject(rating))],
        RatingStatus.rejected => [button(l10n.accept, () => _accept(rating))],
      },
    ];
  }

  static String _filterLabel(AppLocalizations l10n, RatingStatus status) =>
      switch (status) {
        RatingStatus.pending => l10n.filterToCheck,
        RatingStatus.approved => l10n.filterAccepted,
        RatingStatus.rejected => l10n.filterRejected,
      };
}

/// One review in the list, with its decisions under it.
class _RatingCard extends StatelessWidget {
  const _RatingCard({required this.rating, required this.actions});

  final Rating rating;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final reason = rating.statusReason;
    final comment = rating.comment;
    final l10n = context.l10n;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              rating.placeName,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              [
                rating.author,
                l10n.stars(rating.stars),
                if (rating.updatedAt != null) l10n.date(rating.updatedAt),
              ].join(' · '),
            ),
            if (comment != null) ...[
              const SizedBox(height: 4),
              Text(l10n.quoted(comment)),
            ],
            if (reason != null) Text(l10n.reason(reason)),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: OverflowBar(spacing: 4, children: actions),
            ),
          ],
        ),
      ),
    );
  }
}
