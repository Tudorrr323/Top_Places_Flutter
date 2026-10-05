import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:top_places/l10n/l10n.dart';
import 'package:top_places/models/place.dart';
import 'package:top_places/screens/my_places_screen.dart';
import 'package:top_places/screens/place_form_screen.dart';
import 'package:top_places/services/place_service.dart';

/// Opens the form to add a place, or to edit [place]. Navigator.push
/// answers as soon as the form is closed.
Future<void> openPlaceForm(BuildContext context, {Place? place}) =>
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => PlaceFormScreen(place: place),
      ),
    );

/// An operator's newest places, on the Profil tab, with the button to add
/// one. When there are more, a button opens all of them, with a search and
/// filters, so the tab stays short. [canEdit] is false for a suspended
/// account.
class MyPlaces extends StatefulWidget {
  const MyPlaces({super.key, required this.canEdit});

  final bool canEdit;

  @override
  State<MyPlaces> createState() => _MyPlacesState();
}

class _MyPlacesState extends State<MyPlaces> {
  /// How many places show here; the rest are one tap away.
  static const _preview = 3;

  late Future<List<Place>> _places;

  @override
  void initState() {
    super.initState();
    _places = _load();
  }

  Future<List<Place>> _load() {
    final service = context.read<PlaceService?>();
    return service?.myPlaces() ?? Future.value(const []);
  }

  /// Runs [open], a page over the Profil tab; the places load again when it
  /// closes, as they may have changed there.
  Future<void> _thenReload(Future<void> Function() open) async {
    await open();
    // A block, not an arrow: "_places = _load()" is a Future, and setState
    // refuses a callback that returns one.
    if (mounted) {
      setState(() {
        _places = _load();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(l10n.myPlaces, style: theme.textTheme.titleMedium),
        ),
        const SizedBox(height: 8),
        FutureBuilder(
          future: _places,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const LinearProgressIndicator();
            }
            if (snapshot.error case final error?) {
              return Text(
                l10n.error(error),
                style: TextStyle(color: theme.colorScheme.error),
              );
            }
            // The newest first: the ones most likely to need attention.
            final places = snapshot.data!.reversed.toList();
            if (places.isEmpty) return Text(l10n.noOwnPlaces);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final place in places.take(_preview))
                  MyPlaceCard(
                    place: place,
                    onEdit: canEditPlace(widget.canEdit, place)
                        ? () => _thenReload(
                            () => openPlaceForm(context, place: place),
                          )
                        : null,
                  ),
                if (places.length > _preview)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton(
                      onPressed: () => _thenReload(
                        () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) =>
                                MyPlacesScreen(canEdit: widget.canEdit),
                          ),
                        ),
                      ),
                      child: Text(l10n.seeAllPlaces(places.length)),
                    ),
                  ),
              ],
            );
          },
        ),
        if (widget.canEdit) ...[
          const SizedBox(height: 8),
          FilledButton.tonalIcon(
            onPressed: () => _thenReload(() => openPlaceForm(context)),
            icon: const Icon(Icons.add_business),
            label: Text(l10n.addPlace),
          ),
        ],
      ],
    );
  }
}

/// True when the operator may edit [place]: never while suspended, and a
/// suspended place stays as it is until an admin looks at it again.
bool canEditPlace(bool canEdit, Place place) =>
    canEdit && place.status != PlaceStatus.suspended;

/// One of the operator's places: its city, where it is in the review, and
/// the button to edit it, unless [onEdit] is null.
class MyPlaceCard extends StatelessWidget {
  const MyPlaceCard({super.key, required this.place, required this.onEdit});

  final Place place;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final onEdit = this.onEdit;

    return Card(
      child: ListTile(
        title: Text(place.name),
        subtitle: Text('${place.city}\n${_statusText(l10n)}'),
        isThreeLine: true,
        trailing: onEdit == null
            ? null
            : IconButton(
                tooltip: l10n.editPlace(place.name),
                icon: const Icon(Icons.edit),
                onPressed: onEdit,
              ),
      ),
    );
  }

  String _statusText(AppLocalizations l10n) => switch (place.status) {
    PlaceStatus.pending => l10n.placePending,
    PlaceStatus.approved => l10n.placeApproved,
    PlaceStatus.rejected => l10n.placeRejected(place.statusReason ?? ''),
    PlaceStatus.suspended => l10n.placeSuspended(place.statusReason ?? ''),
  };
}
