import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:top_places/l10n/l10n.dart';
import 'package:top_places/models/place.dart';
import 'package:top_places/screens/not_found_screen.dart';
import 'package:top_places/services/places_repository.dart';
import 'package:top_places/widgets/place_photo.dart';
import 'package:top_places/widgets/place_tabs.dart';

/// One place: a big photo that shrinks into the app bar when scrolling, then
/// the name, address and rating, the WhatsApp and directions buttons, and
/// the tabs with the description and the reviews.
class PlaceDetailsScreen extends StatelessWidget {
  const PlaceDetailsScreen({super.key, required this.placeId});

  final String placeId;

  @override
  Widget build(BuildContext context) {
    final place = context.watch<PlacesRepository>().placeById(placeId);
    if (place == null) {
      return const NotFoundScreen();
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 300,
            leading: Center(
              child: BackButton(
                // A filled circle keeps the arrow visible on any photo.
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.surface,
                ),
                onPressed: () {
                  // A page opened from a link (on the web) has no page
                  // behind it, so the button leads to Explore instead.
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/explore');
                  }
                },
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: PlacePhoto(place: place, width: 1200),
            ),
          ),
          // On wide windows the text stays readable instead of stretching.
          SliverLayoutBuilder(
            builder: (context, constraints) => SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: math.max(
                  0,
                  (constraints.crossAxisExtent - 720) / 2,
                ),
              ),
              // Fades in and slides up once when the page opens. The old
              // app needed two Animated values and a useEffect for this.
              sliver: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                // No motion when the system settings ask for less of it.
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) => SliverPadding(
                  padding: EdgeInsets.only(top: 40 * (1 - value)),
                  sliver: SliverOpacity(opacity: value, sliver: child),
                ),
                child: SliverMainAxisGroup(
                  slivers: [
                    SliverToBoxAdapter(child: _Header(place: place)),
                    PlaceTabs(place: place),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The name and address, with the rating next to them.
class _Header extends StatelessWidget {
  const _Header({required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(place.name, style: theme.textTheme.headlineSmall),
                ),
                const SizedBox(height: 4),
                Text(
                  place.address,
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Read as "4.7 stele" instead of only "4.7".
          Semantics(
            label: context.l10n.placeRatingLabel(place),
            excludeSemantics: true,
            child: Chip(
              avatar: Icon(
                place.isRated ? Icons.star : Icons.fiber_new_outlined,
              ),
              label: Text(context.l10n.placeRating(place)),
            ),
          ),
        ],
      ),
    );
  }
}
