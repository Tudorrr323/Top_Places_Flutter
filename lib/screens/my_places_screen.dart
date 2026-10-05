import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:top_places/l10n/l10n.dart';
import 'package:top_places/models/place.dart';
import 'package:top_places/services/place_service.dart';
import 'package:top_places/widgets/list_search_field.dart';
import 'package:top_places/widgets/my_places.dart';

/// All of an operator's places, newest first, with a search and filters:
/// by where each one is in the review, and by city when there are several.
class MyPlacesScreen extends StatefulWidget {
  const MyPlacesScreen({super.key, required this.canEdit});

  /// False for a suspended account.
  final bool canEdit;

  @override
  State<MyPlacesScreen> createState() => _MyPlacesScreenState();
}

class _MyPlacesScreenState extends State<MyPlacesScreen> {
  late Future<List<Place>> _places;
  String _query = '';

  /// The status shown, or null for all of them.
  PlaceStatus? _status;

  /// The city shown, or null for all of them.
  String? _city;

  @override
  void initState() {
    super.initState();
    _places = _load();
  }

  Future<List<Place>> _load() {
    final service = context.read<PlaceService?>();
    return service?.myPlaces() ?? Future.value(const []);
  }

  /// Opens the form, then loads the places again: one may have changed.
  Future<void> _openForm({Place? place}) async {
    await openPlaceForm(context, place: place);
    if (mounted) {
      setState(() {
        _places = _load();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.myPlaces)),
      floatingActionButton: widget.canEdit
          ? FloatingActionButton.extended(
              onPressed: _openForm,
              icon: const Icon(Icons.add_business),
              label: Text(l10n.addPlace),
            )
          : null,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Outside the list, so that the text stays while it loads.
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: ListSearchField(
                  hint: l10n.searchMyPlaces,
                  onChanged: (query) => setState(() => _query = query),
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
                      return Center(child: Text(l10n.error(error)));
                    }
                    return _list(context, snapshot.data!.reversed.toList());
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The filters, then the places that pass them.
  Widget _list(BuildContext context, List<Place> all) {
    final l10n = context.l10n;
    final cities = {for (final place in all) place.city}.toList()..sort();
    int count(PlaceStatus status) =>
        all.where((place) => place.status == status).length;
    final shown = [
      for (final place in all)
        if ((_status == null || place.status == _status) &&
            (_city == null || place.city == _city) &&
            matchesSearch(_query, [place.name, place.city, place.address]))
          place,
    ];

    return ListView(
      // Room at the end for the add button over the list.
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: Text(l10n.withCount(l10n.all, all.length)),
              selected: _status == null,
              onSelected: (_) => setState(() => _status = null),
            ),
            // Only the statuses that some place has.
            for (final status in PlaceStatus.values)
              if (count(status) > 0)
                ChoiceChip(
                  label: Text(
                    l10n.withCount(_statusLabel(l10n, status), count(status)),
                  ),
                  selected: _status == status,
                  onSelected: (_) => setState(() => _status = status),
                ),
          ],
        ),
        if (cities.length > 1) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: Text(l10n.allCities),
                selected: _city == null,
                onSelected: (_) => setState(() => _city = null),
              ),
              for (final city in cities)
                ChoiceChip(
                  label: Text(city),
                  selected: _city == city,
                  onSelected: (_) => setState(() => _city = city),
                ),
            ],
          ),
        ],
        const SizedBox(height: 8),
        if (all.isEmpty)
          Text(l10n.noOwnPlaces)
        else if (shown.isEmpty)
          Text(l10n.noMatchingPlaces)
        else
          for (final place in shown)
            MyPlaceCard(
              place: place,
              onEdit: canEditPlace(widget.canEdit, place)
                  ? () => _openForm(place: place)
                  : null,
            ),
      ],
    );
  }

  static String _statusLabel(AppLocalizations l10n, PlaceStatus status) =>
      switch (status) {
        PlaceStatus.pending => l10n.inReview,
        PlaceStatus.approved => l10n.filterPublic,
        PlaceStatus.rejected => l10n.filterRejected,
        PlaceStatus.suspended => l10n.filterSuspended,
      };
}
