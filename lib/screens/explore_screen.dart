import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:top_places/models/filters.dart';
import 'package:top_places/models/place.dart';
import 'package:top_places/utils/plural.dart';
import 'package:top_places/view_models/explore_view_model.dart';
import 'package:top_places/widgets/filter_sheet.dart';
import 'package:top_places/widgets/place_card.dart';
import 'package:top_places/widgets/places_map.dart';

/// The Explore tab. Narrow screens show the list or the map, wide windows
/// show both side by side.
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  // Holds the text of the search bar. Created once, disposed with the screen.
  final _searchController = TextEditingController();
  late final ExploreViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    // The assistant can change the search too, so the search bar follows
    // the view model instead of only feeding it.
    _viewModel = context.read<ExploreViewModel>()..addListener(_showQuery);
    _showQuery();
  }

  @override
  void dispose() {
    _viewModel.removeListener(_showQuery);
    _searchController.dispose();
    super.dispose();
  }

  void _showQuery() {
    if (_searchController.text != _viewModel.query) {
      _searchController.text = _viewModel.query;
    }
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<ExploreViewModel>().setQuery('');
  }

  Future<void> _openFilters() async {
    final viewModel = context.read<ExploreViewModel>();
    final chosen = await showModalBottomSheet<Filters>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) =>
          FilterSheet(initial: viewModel.filters, cities: viewModel.cities),
    );
    // null means the sheet was closed without choosing anything.
    if (chosen != null) {
      viewModel.applyFilters(chosen);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ExploreViewModel>();
    final places = viewModel.visiblePlaces;

    return Scaffold(
      body: SafeArea(
        // LayoutBuilder gives the space this screen has, without the
        // navigation rail.
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 840) {
              return Row(
                children: [
                  SizedBox(
                    width: 420,
                    child: _buildPanel(viewModel, places, isWide: true),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: PlacesMap(places: places)),
                ],
              );
            }
            return Center(
              // On a tablet the column stays readable instead of stretching.
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: _buildPanel(viewModel, places, isWide: false),
              ),
            );
          },
        ),
      ),
    );
  }

  /// The search bar and the result count, with the list (or, on a narrow
  /// screen in map mode, the map) below them.
  Widget _buildPanel(
    ExploreViewModel viewModel,
    List<Place> places, {
    required bool isWide,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: SearchBar(
                  controller: _searchController,
                  hintText: 'Caută locații sau orașe...',
                  leading: const Icon(Icons.search),
                  trailing: [
                    if (viewModel.query.isNotEmpty)
                      IconButton(
                        tooltip: 'Șterge căutarea',
                        icon: const Icon(Icons.close),
                        onPressed: _clearSearch,
                      ),
                  ],
                  onChanged: viewModel.setQuery,
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: 'Filtrează și sortează',
                onPressed: _openFilters,
                icon: Badge(
                  isLabelVisible: viewModel.filters.isActive,
                  child: const Icon(Icons.tune),
                ),
              ),
              // Wide windows always show the map, so no switch there.
              if (!isWide) ...[
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: viewModel.showMap ? 'Arată lista' : 'Arată harta',
                  onPressed: viewModel.toggleMap,
                  icon: Icon(
                    viewModel.showMap ? Icons.view_list : Icons.map_outlined,
                  ),
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Locații',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Text(resultsLabel(places.length)),
            ],
          ),
        ),
        // Said in words too, not only by the dot on the filter button.
        if (viewModel.filters.isActive)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.filter_alt_outlined, size: 18),
                const SizedBox(width: 4),
                const Expanded(child: Text('Filtre active')),
                TextButton(
                  onPressed: viewModel.resetFilters,
                  child: const Text('Resetează'),
                ),
              ],
            ),
          ),
        Expanded(
          child: _buildContent(places, showMap: !isWide && viewModel.showMap),
        ),
      ],
    );
  }

  Widget _buildContent(List<Place> places, {required bool showMap}) {
    if (places.isEmpty) {
      return const _EmptyState();
    }
    if (showMap) {
      return PlacesMap(places: places);
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: places.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: PlaceCard(place: places[index]),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 48),
          SizedBox(height: 8),
          Text('Nu am găsit locații.'),
        ],
      ),
    );
  }
}
