import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:top_places/models/place.dart';
import 'package:top_places/models/profile.dart';
import 'package:top_places/models/rating.dart';
import 'package:top_places/services/place_service.dart';
import 'package:top_places/services/places_repository.dart';
import 'package:top_places/utils/plural.dart';
import 'package:top_places/view_models/account_view_model.dart';
import 'package:top_places/widgets/dialogs.dart';

/// The "Recenzii" tab: what the rating is made of, the signed-in account's
/// own review, and the accepted reviews of everyone else. The database
/// checks the same rules as the screen.
class PlaceReviews extends StatelessWidget {
  const PlaceReviews({super.key, required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
            Text(place.ratingText, style: theme.textTheme.headlineSmall),
            const SizedBox(width: 12),
            Expanded(child: Text(_ratingSource(place))),
          ],
        ),
        const SizedBox(height: 16),
        if (!available)
          Text(
            'Recenziile se văd doar când aplicația e conectată la Supabase.',
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
  static String _ratingSource(Place place) => switch (place.ratingCount) {
    0 when place.isRated =>
      'Ratingul vine din aplicația originală, până la primele recenzii.',
    0 => 'Nicio recenzie încă.',
    1 => 'Ratingul vine dintr-o singură recenzie.',
    final count =>
      'Ratingul e media celor ${countLabel(count, 'recenzie', 'recenzii')}.',
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
  String? get _cannotWrite {
    final me = widget.me;
    if (me == null) {
      return 'Intră în cont, din tab-ul Profil, ca să scrii o recenzie.';
    }
    if (me.isSuspended) {
      return 'Contul tău e suspendat: nu poți scrie recenzii.';
    }
    if (widget.place.ownerId == me.id) {
      return 'Nu poți scrie recenzii la propriul local.';
    }
    return null;
  }

  /// When a waiting review becomes public: once the place's operator
  /// accepts it, or an admin for a place without one.
  String get _whenAccepted => widget.place.ownerId == null
      ? 'Apare după ce o acceptă un administrator.'
      : 'Apare după ce o acceptă operatorul localului.';

  /// When a review sent from this form becomes public. The database decides
  /// the same way: an admin's review is public at once.
  String get _whenPublic => widget.me?.role == Role.admin
      ? 'Ca administrator, recenzia ta apare imediat.'
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
    if (_cannotWrite == null) {
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
                ? 'Recenzia ta a fost publicată.'
                : 'Recenzia ta a fost trimisă și e în așteptare.',
          ),
        ),
      );
      await repository.refresh();
    } on PlaceException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await askConfirmation(
      context,
      title: 'Ștergi recenzia?',
      message: 'Nota și mesajul tău dispar de pe pagina localului.',
      action: 'Șterge',
    );
    if (!confirmed || !mounted) return;
    final service = context.read<PlaceService?>()!;
    final repository = context.read<PlacesRepository>();
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await service.deleteRating(_saved!);
      if (mounted) setState(() => _show(null));
      await repository.refresh();
    } on PlaceException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cannotWrite = _cannotWrite;
    final saved = _saved;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text('Recenzia ta', style: theme.textTheme.titleMedium),
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
    final comment = saved.comment;
    final (icon, status, explanation) = switch (saved.status) {
      RatingStatus.pending => (
        Icons.schedule,
        'În așteptare',
        '$_whenAccepted Până atunci o vezi doar tu.',
      ),
      RatingStatus.approved => (
        Icons.check_circle_outline,
        'Publicată',
        'O vede oricine deschide localul.',
      ),
      RatingStatus.rejected => (
        Icons.block,
        'Respinsă',
        'Motiv: ${saved.statusReason}. O poți modifica și trimite din nou.',
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
                Expanded(child: _Stars(stars: saved.stars)),
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
                    child: const Text('Șterge recenzia'),
                  ),
                  if (saved.status == RatingStatus.rejected)
                    FilledButton.tonal(
                      onPressed: _busy
                          ? null
                          : () => setState(() => _editing = true),
                      child: const Text('Modifică'),
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
    final stars = _stars;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _editing
              ? 'Schimbă ce trebuie, apoi trimite din nou. $_whenPublic'
              : 'Alege stelele și, dacă vrei, scrie câteva cuvinte. '
                    '$_whenPublic',
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        ),
        Row(
          children: [
            for (var star = 1; star <= 5; star++)
              IconButton(
                tooltip: Rating.starsText(star),
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
          decoration: const InputDecoration(
            labelText: 'Mesaj (opțional)',
            border: OutlineInputBorder(),
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
                  child: const Text('Renunță'),
                ),
              FilledButton(
                onPressed: _busy || !_changed ? null : _send,
                child: Text(_editing ? 'Trimite din nou' : 'Trimite recenzia'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The accepted reviews of everyone else, newest first. Anyone sees them,
/// signed in or not.
class _PublicReviews extends StatefulWidget {
  const _PublicReviews({required this.place});

  final Place place;

  @override
  State<_PublicReviews> createState() => _PublicReviewsState();
}

class _PublicReviewsState extends State<_PublicReviews> {
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
          child: Text('Ce spun ceilalți', style: theme.textTheme.titleMedium),
        ),
        const SizedBox(height: 8),
        FutureBuilder(
          future: _ratings,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.error case final error?) {
              return Text(error.toString(), style: muted);
            }
            // The reader's own review is above, with its status.
            final others = [
              for (final rating in snapshot.data!)
                if (!rating.mine) rating,
            ];
            if (others.isEmpty) {
              return Text('Nicio recenzie publicată încă.', style: muted);
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final rating in others) _ReviewTile(rating: rating),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// One accepted review: who wrote it and when, the stars and the message.
class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.rating});

  final Rating rating;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(rating.author, style: theme.textTheme.titleSmall),
              ),
              Text(
                rating.dateText,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          _Stars(stars: rating.stars),
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
class _Stars extends StatelessWidget {
  const _Stars({required this.stars});

  final int stars;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: Rating.starsText(stars),
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
