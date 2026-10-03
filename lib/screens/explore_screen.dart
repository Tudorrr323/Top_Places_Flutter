import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:top_places/models/filters.dart';
import 'package:top_places/utils/plural.dart';
import 'package:top_places/view_models/explore_view_model.dart';
import 'package:top_places/widgets/filter_sheet.dart';
import 'package:top_places/widgets/place_card.dart';

/// The Explore tab: a search bar, a filter button and the list of places.
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  // Holds the text of the search bar. Created once, disposed with the screen.
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
        child: Center(
          // On wide windows the content stays readable instead of stretching.
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
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
                  child: places.isEmpty
                      ? const _EmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: places.length,
                          itemBuilder: (context, index) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: PlaceCard(place: places[index]),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
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