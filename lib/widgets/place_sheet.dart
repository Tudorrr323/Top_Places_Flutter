import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:top_places/models/place.dart';
import 'package:top_places/services/places_repository.dart';
import 'package:top_places/utils/plural.dart';
import 'package:top_places/widgets/place_photo.dart';
import 'package:top_places/widgets/place_tabs.dart';

/// Opens [place] in a sheet over the map. It starts small, with the photo,
/// the name, the address, the rating and the start of the description.
/// Dragged up, or with its button, it covers the screen with everything the
/// place's page has, tabs included. Returns when it closes.
Future<void> showPlaceSheet(BuildContext context, Place place) {
  return showModalBottomSheet<void>(
    context: context,
    // Over the navigation bar too, so that it can cover the whole screen.
    useRootNavigator: true,
    useSafeArea: true,
    isScrollControlled: true,
    // The map stays clear behind the small sheet; a tap on it closes it.
    barrierColor: Colors.transparent,
    // The sheet draws its own background, which grows with it.
    backgroundColor: Colors.transparent,
    elevation: 0,
    builder: (context) => _PlaceSheet(placeId: place.id),
  );
}

class _PlaceSheet extends StatefulWidget {
  const _PlaceSheet({required this.placeId});

  final String placeId;

  @override
  State<_PlaceSheet> createState() => _PlaceSheetState();
}

class _PlaceSheetState extends State<_PlaceSheet> {
  final _size = DraggableScrollableController();

  /// The height of the small sheet, as a share of the screen.
  double _small = 0.3;

  /// The sizes the sheet settles at, besides closed and full: the small one.
  /// Kept as the same list while the small size stays: a new list makes the
  /// sheet settle again, which would stop a drag halfway.
  List<double> _snapSizes = const [0.3];

  /// True when the sheet covers the screen. Only the resize button follows
  /// it, so the sheet itself is not rebuilt while it is being dragged.
  final _full = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _size.addListener(_sizeChanged);
  }

  @override
  void dispose() {
    _size.dispose();
    _full.dispose();
    super.dispose();
  }

  void _sizeChanged() {
    // The size can change in the middle of a frame; the button follows
    // right after it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _size.isAttached) _full.value = _size.size > 0.99;
    });
  }

  /// The resize button: the whole screen, or back to small.
  void _resize() {
    _size.animateTo(
      _full.value ? _small : 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watched, so a new average shows here as soon as it is saved.
    final place = context.watch<PlacesRepository>().placeById(widget.placeId);
    if (place == null) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        // About 240 pixels: the photo, the name and the start of the
        // description.
        final small = (240 / constraints.maxHeight).clamp(0.2, 0.8);
        if (small != _small) {
          _small = small;
          _snapSizes = [small];
        }
        return DraggableScrollableSheet(
          controller: _size,
          expand: false,
          initialChildSize: _small,
          // Dragged below the small size, the sheet closes.
          minChildSize: 0,
          snap: true,
          snapSizes: _snapSizes,
          builder: (context, scrollController) => Material(
            color: Theme.of(context).colorScheme.surface,
            elevation: 3,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            clipBehavior: Clip.antiAlias,
            // A mouse drags the sheet too, on the web and on Windows.
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context)
                  .copyWith(dragDevices: PointerDeviceKind.values.toSet()),
              child: CustomScrollView(
                controller: scrollController,
                slivers: [
                  SliverToBoxAdapter(
                    child: _Summary(
                      place: place,
                      full: _full,
                      onResize: _resize,
                    ),
                  ),
                  PlaceTabs(place: place),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The top of the sheet, which is all of the small one: the photo, the
/// name, the address, the rating and the start of the description, with the
/// buttons that close and resize the sheet.
class _Summary extends StatelessWidget {
  const _Summary({
    required this.place,
    required this.full,
    required this.onResize,
  });

  final Place place;

  /// True when the sheet covers the screen.
  final ValueListenable<bool> full;
  final VoidCallback onResize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The handle says that the sheet can be dragged.
          Center(
            child: Container(
              width: 32,
              height: 4,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: muted.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox.square(
                  dimension: 88,
                  child: PlacePhoto(place: place, width: 300),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        place.name,
                        style: theme.textTheme.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      place.address,
                      style: theme.textTheme.bodySmall?.copyWith(color: muted),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Semantics(
                      label: _ratingLine(place, forScreenReader: true),
                      excludeSemantics: true,
                      child: Text(_ratingLine(place)),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    tooltip: 'Închide',
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  ValueListenableBuilder(
                    valueListenable: full,
                    builder: (context, full, child) => IconButton(
                      tooltip: full ? 'Micșorează' : 'Toate detaliile',
                      icon: Icon(full ? Icons.expand_more : Icons.expand_less),
                      onPressed: onResize,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 8, 8, 0),
            child: Text(
              place.descriptionRo ?? place.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// "★ 4.6 · 12 recenzii", or "4.6 stele, 12 recenzii" for a screen
  /// reader.
  static String _ratingLine(Place place, {bool forScreenReader = false}) {
    if (!place.isRated) return 'Local nou, fără recenzii încă';
    final rating = forScreenReader
        ? place.ratingLabel
        : '★ ${place.ratingText}';
    final count = place.ratingCount;
    if (count == 0) return rating;
    final reviews = countLabel(count, 'recenzie', 'recenzii');
    return forScreenReader ? '$rating, $reviews' : '$rating · $reviews';
  }
}
