import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:top_places/models/place.dart';
import 'package:top_places/models/profile.dart';
import 'package:top_places/services/place_service.dart';
import 'package:top_places/services/places_repository.dart';

/// "Note": where the rating comes from, and the signed-in account's own
/// stars, which it can change. The database checks the same rules: one
/// rating per account, never on one's own place, not while suspended.
class RatingSection extends StatefulWidget {
  const RatingSection({super.key, required this.place, required this.me});

  final Place place;

  /// The signed-in account, or null.
  final Profile? me;

  @override
  State<RatingSection> createState() => _RatingSectionState();
}

class _RatingSectionState extends State<RatingSection> {
  /// The stars this account gave the place, or null.
  int? _stars;

  /// True while the stars load or save; the buttons wait meanwhile.
  bool _busy = false;

  /// Why this account cannot rate the place, or null when it can.
  String? get _cannotRate {
    final me = widget.me;
    if (me == null) {
      return 'Intră în cont, din tab-ul Profil, ca să dai o notă.';
    }
    if (me.isSuspended) return 'Contul tău e suspendat: nu poți da note.';
    if (widget.place.ownerId == me.id) {
      return 'Nu îți poți nota propriul local.';
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    if (_cannotRate == null) {
      _busy = true;
      _loadMine();
    }
  }

  Future<void> _loadMine() async {
    int? stars;
    try {
      stars = await context.read<PlaceService?>()!.myRating(widget.place.id);
    } on PlaceException {
      // Offline: the stars show empty, and rating still tells what failed.
    }
    if (!mounted) return;
    setState(() {
      _stars = stars;
      _busy = false;
    });
  }

  Future<void> _rate(int stars) async {
    final service = context.read<PlaceService?>()!;
    final repository = context.read<PlacesRepository>();
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await service.ratePlace(widget.place.id, stars);
      if (mounted) setState(() => _stars = stars);
      // The new average, here and in Explore.
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
    final muted = TextStyle(color: theme.colorScheme.onSurfaceVariant);
    final cannotRate = _cannotRate;
    final stars = _stars;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text('Note', style: theme.textTheme.titleMedium),
        ),
        const SizedBox(height: 4),
        Text(_ratingSource(widget.place)),
        const SizedBox(height: 8),
        if (cannotRate != null)
          Text(cannotRate, style: muted)
        else ...[
          Row(
            children: [
              for (var star = 1; star <= 5; star++)
                IconButton(
                  tooltip: _starsText(star),
                  isSelected: stars != null && star <= stars,
                  icon: const Icon(Icons.star_border),
                  selectedIcon: const Icon(Icons.star),
                  color: theme.colorScheme.primary,
                  onPressed: _busy ? null : () => _rate(star),
                ),
            ],
          ),
          Text(
            stars == null
                ? 'Atinge o stea ca să dai o notă.'
                : 'Ai dat ${_starsText(stars)}. Poți schimba nota oricând.',
            style: muted,
          ),
        ],
      ],
    );
  }

  static String _starsText(int stars) => stars == 1 ? '1 stea' : '$stars stele';

  /// What the rating is made of.
  static String _ratingSource(Place place) => switch (place.ratingCount) {
    0 when place.isRated =>
      'Ratingul vine din aplicația originală, până la primele note.',
    0 => 'Nicio notă încă.',
    1 => 'Ratingul vine dintr-o singură notă.',
    final count => 'Ratingul e media celor ${_countText(count)}.',
  };

  /// "3 note", "20 de note": from 20 on, Romanian puts "de" before the noun,
  /// except after 101 to 119, 201 to 219 and so on.
  static String _countText(int count) {
    final lastTwo = count % 100;
    final withDe = lastTwo == 0 || lastTwo >= 20;
    return withDe ? '$count de note' : '$count note';
  }
}
