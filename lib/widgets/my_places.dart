import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:top_places/l10n/l10n.dart';
import 'package:top_places/models/place.dart';
import 'package:top_places/screens/place_form_screen.dart';
import 'package:top_places/services/place_service.dart';
import 'package:top_places/widgets/list_search_field.dart';

/// An operator's own places, each with where it is in the review, and the
/// buttons to add or edit one. [canEdit] is false for a suspended account.
class MyPlaces extends StatefulWidget {
  const MyPlaces({super.key, required this.canEdit});

  final bool canEdit;

  @override
  State<MyPlaces> createState() => _MyPlacesState();
}

class _MyPlacesState extends State<MyPlaces> {
  late Future<List<Place>> _places;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _places = _load();
  }

  Future<List<Place>> _load() {
    final service = context.read<PlaceService?>();
    return service?.myPlaces() ?? Future.value(const []);
  }

  /// Opens the form over the Profil tab; the list loads again when it
  /// closes. Navigator.push answers as soon as the form is closed.
  Future<void> _open({Place? place}) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => PlaceFormScreen(place: place),
      ),
    );
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
        ListSearchField(
          hint: l10n.searchMyPlaces,
          onChanged: (query) => setState(() => _query = query),
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
            final all = snapshot.data!;
            if (all.isEmpty) {
              return Text(l10n.noOwnPlaces);
            }
            final places = all
                .where(
                  (place) => matchesSearch(_query, [
                    place.name,
                    place.city,
                    place.address,
                  ]),
                )
                .toList();
            if (places.isEmpty) {
              return Text(l10n.noMatchingPlaces);
            }
            return Column(
              children: [
                for (final place in places)
                  Card(
                    child: ListTile(
                      title: Text(place.name),
                      subtitle: Text(
                        '${place.city}\n${_statusText(l10n, place)}',
                      ),
                      isThreeLine: true,
                      // A suspended place stays as it is until an admin
                      // looks at it again.
                      trailing:
                          widget.canEdit &&
                              place.status != PlaceStatus.suspended
                          ? IconButton(
                              tooltip: l10n.editPlace(place.name),
                              icon: const Icon(Icons.edit),
                              onPressed: () => _open(place: place),
                            )
                          : null,
                    ),
                  ),
              ],
            );
          },
        ),
        if (widget.canEdit) ...[
          const SizedBox(height: 8),
          FilledButton.tonalIcon(
            onPressed: _open,
            icon: const Icon(Icons.add_business),
            label: Text(l10n.addPlace),
          ),
        ],
      ],
    );
  }

  static String _statusText(AppLocalizations l10n, Place place) =>
      switch (place.status) {
        PlaceStatus.pending => l10n.placePending,
        PlaceStatus.approved => l10n.placeApproved,
        PlaceStatus.rejected => l10n.placeRejected(place.statusReason ?? ''),
        PlaceStatus.suspended => l10n.placeSuspended(place.statusReason ?? ''),
      };
}
