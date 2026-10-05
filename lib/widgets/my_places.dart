import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:top_places/models/place.dart';
import 'package:top_places/screens/place_form_screen.dart';
import 'package:top_places/services/place_service.dart';

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text('Localurile mele', style: theme.textTheme.titleMedium),
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
                error.toString(),
                style: TextStyle(color: theme.colorScheme.error),
              );
            }
            final places = snapshot.data!;
            if (places.isEmpty) {
              return const Text('Încă nu ai adăugat niciun local.');
            }
            return Column(
              children: [
                for (final place in places)
                  Card(
                    child: ListTile(
                      title: Text(place.name),
                      subtitle: Text('${place.city}\n${_statusText(place)}'),
                      isThreeLine: true,
                      // A suspended place stays as it is until an admin
                      // looks at it again.
                      trailing:
                          widget.canEdit &&
                              place.status != PlaceStatus.suspended
                          ? IconButton(
                              tooltip: 'Editează ${place.name}',
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
            label: const Text('Adaugă un local'),
          ),
        ],
      ],
    );
  }

  static String _statusText(Place place) => switch (place.status) {
    PlaceStatus.pending => 'În așteptarea aprobării',
    PlaceStatus.approved => 'Aprobat: apare în Explorează',
    PlaceStatus.rejected => 'Respins: ${place.statusReason}',
    PlaceStatus.suspended => 'Suspendat: ${place.statusReason}',
  };
}
