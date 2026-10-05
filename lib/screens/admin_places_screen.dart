import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:top_places/models/place.dart';
import 'package:top_places/screens/place_form_screen.dart';
import 'package:top_places/services/place_service.dart';
import 'package:top_places/services/places_repository.dart';
import 'package:top_places/widgets/dialogs.dart';
import 'package:top_places/widgets/list_search_field.dart';

/// For admins: every place, by where it is in the review, with the decisions
/// an admin can take on each. The database allows them to admins only.
class AdminPlacesScreen extends StatefulWidget {
  const AdminPlacesScreen({super.key});

  @override
  State<AdminPlacesScreen> createState() => _AdminPlacesScreenState();
}

class _AdminPlacesScreenState extends State<AdminPlacesScreen> {
  PlaceStatus _shown = PlaceStatus.pending;
  String _query = '';
  late Future<List<Place>> _places;

  @override
  void initState() {
    super.initState();
    _places = _load();
  }

  Future<List<Place>> _load() =>
      context.read<PlaceService?>()?.allPlaces() ?? Future.value(const []);

  void _reload() {
    setState(() {
      _places = _load();
    });
  }

  /// Asks for the decision with [ask] (a confirmation or a reason), then
  /// saves it.
  Future<void> _decide(Future<PlaceReview?> Function() ask, Place place) async {
    final review = await ask();
    if (review == null || !mounted) return;
    final service = context.read<PlaceService?>()!;
    final repository = context.read<PlacesRepository>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      await service.review(place.id, review);
      // Explore shows the change at once.
      await repository.refresh();
      if (mounted) _reload();
    } on PlaceException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<PlaceReview?> _confirmApproval(Place place) async {
    final again = place.status == PlaceStatus.suspended;
    final confirmed = await askConfirmation(
      context,
      title: again ? 'Reactivezi „${place.name}”?' : 'Aprobi „${place.name}”?',
      message: again
          ? 'Localul apare din nou în Explorează.'
          : 'Localul apare în Explorează pentru toată lumea. Ratingul îl '
                'vor da cei care îl vizitează.',
      action: again ? 'Reactivează' : 'Aprobă',
    );
    return confirmed ? PlaceReview.approve() : null;
  }

  Future<PlaceReview?> _askRejection(Place place) async {
    final reason = await askReason(
      context,
      title: 'Respingi „${place.name}”?',
      action: 'Respinge',
    );
    return reason == null ? null : PlaceReview.reject(reason);
  }

  Future<PlaceReview?> _askSuspension(Place place) async {
    final reason = await askReason(
      context,
      title: 'Suspenzi „${place.name}”?',
      action: 'Suspendă',
    );
    return reason == null ? null : PlaceReview.suspend(reason);
  }

  Future<void> _edit(Place place) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => PlaceFormScreen(place: place, asAdmin: true),
      ),
    );
    if (!mounted) return;
    await context.read<PlacesRepository>().refresh();
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Localuri')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: ListSearchField(
                  hint: 'Caută după nume, oraș sau adresă',
                  onChanged: (query) => setState(() => _query = query),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final status in PlaceStatus.values)
                      ChoiceChip(
                        label: Text(_filterLabel(status)),
                        selected: _shown == status,
                        onSelected: (_) => setState(() => _shown = status),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder(
                  future: _places,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.error case final error?) {
                      return Center(child: Text(error.toString()));
                    }
                    final places = snapshot.data!
                        .where((place) => place.status == _shown)
                        .where(
                          (place) => matchesSearch(_query, [
                            place.name,
                            place.city,
                            place.address,
                          ]),
                        )
                        .toList();
                    if (places.isEmpty) {
                      return const Center(child: Text('Niciun local aici.'));
                    }
                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        for (final place in places)
                          _PlaceCard(place: place, actions: _actionsFor(place)),
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

  /// The decisions that make sense for a place, given where it is.
  List<Widget> _actionsFor(Place place) {
    Widget button(String label, VoidCallback onPressed) =>
        TextButton(onPressed: onPressed, child: Text(label));

    final edit = button('Editează', () => _edit(place));
    return switch (place.status) {
      PlaceStatus.pending => [
        button('Respinge', () => _decide(() => _askRejection(place), place)),
        edit,
        FilledButton(
          onPressed: () => _decide(() => _confirmApproval(place), place),
          child: const Text('Aprobă'),
        ),
      ],
      PlaceStatus.approved => [
        button('Suspendă', () => _decide(() => _askSuspension(place), place)),
        edit,
      ],
      PlaceStatus.rejected => [
        edit,
        button('Aprobă', () => _decide(() => _confirmApproval(place), place)),
      ],
      PlaceStatus.suspended => [
        edit,
        button(
          'Reactivează',
          () => _decide(() => _confirmApproval(place), place),
        ),
      ],
    };
  }

  static String _filterLabel(PlaceStatus status) => switch (status) {
    PlaceStatus.pending => 'De verificat',
    PlaceStatus.approved => 'Publice',
    PlaceStatus.rejected => 'Respinse',
    PlaceStatus.suspended => 'Suspendate',
  };
}

/// One place in the admin's list, with its decisions under it.
class _PlaceCard extends StatelessWidget {
  const _PlaceCard({required this.place, required this.actions});

  final Place place;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final rating = place.isRated ? '★ ${place.ratingText}' : 'fără rating';
    final reason = place.statusReason;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(place.name, style: Theme.of(context).textTheme.titleMedium),
            Text('${place.address} · $rating'),
            if (reason != null) Text('Motiv: $reason'),
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
