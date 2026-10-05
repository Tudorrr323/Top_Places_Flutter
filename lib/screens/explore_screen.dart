import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:top_places/l10n/l10n.dart';
import 'package:top_places/models/filters.dart';
import 'package:top_places/models/place.dart';
import 'package:top_places/view_models/explore_view_model.dart';
import 'package:top_places/widgets/filter_sheet.dart';
import 'package:top_places/widgets/place_card.dart';
import 'package:top_places/widgets/place_photo.dart';
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
  final _searchFocus = FocusNode();
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
    _searchFocus.dispose();
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

  /// A suggestion was chosen: the search did its job, and the map goes to
  /// the place.
  void _goToSuggestion(Place place) {
    _searchFocus.unfocus();
    _clearSearch();
    context.read<ExploreViewModel>().focusPlace(place);
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
                  Expanded(child: _buildMap(viewModel, places)),
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
                // Over the map, the places found show as suggestions under
                // the search bar, and the map stays where it is. Over the
                // list there are none: the list itself shows what matches.
                child: RawAutocomplete<Place>(
                  textEditingController: _searchController,
                  focusNode: _searchFocus,
                  optionsBuilder: (value) => !isWide && viewModel.showMap
                      ? viewModel.suggestionsFor(value.text)
                      : const <Place>[],
                  displayStringForOption: (place) => place.name,
                  onSelected: _goToSuggestion,
                  fieldViewBuilder:
                      (context, controller, focusNode, onSubmitted) =>
                          SearchBar(
                            controller: controller,
                            focusNode: focusNode,
                            hintText: context.l10n.searchHint,
                            leading: const Icon(Icons.search),
                            trailing: [
                              if (viewModel.query.isNotEmpty)
                                IconButton(
                                  tooltip: context.l10n.clearSearch,
                                  icon: const Icon(Icons.close),
                                  onPressed: _clearSearch,
                                ),
                            ],
                            onChanged: viewModel.setQuery,
                            // Enter picks the highlighted suggestion.
                            onSubmitted: (_) => onSubmitted(),
                          ),
                  optionsViewBuilder: (context, onSelected, places) =>
                      _Suggestions(
                        places: places.toList(),
                        onSelected: onSelected,
                      ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: context.l10n.filterTooltip,
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
                  tooltip: viewModel.showMap
                      ? context.l10n.showList
                      : context.l10n.showMap,
                  onPressed: viewModel.toggleMap,
                  icon: Icon(
                    viewModel.showMap ? Icons.view_list : Icons.map_outlined,
                  ),
                ),
              ],
            ],
          ),
        ),
        // Over the list only: the map shows the places themselves.
        if (isWide || !viewModel.showMap)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.placesTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Text(context.l10n.results(places.length)),
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
                Expanded(child: Text(context.l10n.filtersActive)),
                TextButton(
                  onPressed: viewModel.resetFilters,
                  child: Text(context.l10n.filtersReset),
                ),
              ],
            ),
          ),
        Expanded(
          child: isWide
              ? _buildList(places)
              // Both stay built, so the map is where it was left when it
              // shows again.
              : IndexedStack(
                  index: viewModel.showMap ? 1 : 0,
                  sizing: StackFit.expand,
                  children: [_buildList(places), _buildMap(viewModel, places)],
                ),
        ),
      ],
    );
  }

  Widget _buildList(List<Place> places) {
    if (places.isEmpty) {
      return const _EmptyState();
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

  Widget _buildMap(ExploreViewModel viewModel, List<Place> places) => PlacesMap(
    places: places,
    request: viewModel.mapRequest,
    onRequestShown: viewModel.mapRequestShown,
  );
}

/// The places that match the search, under the search bar: the photo, the
/// name, the city and the rating. The one picked with the arrow keys is
/// highlighted.
class _Suggestions extends StatelessWidget {
  const _Suggestions({required this.places, required this.onSelected});

  final List<Place> places;
  final ValueChanged<Place> onSelected;

  @override
  Widget build(BuildContext context) {
    final highlighted = AutocompleteHighlightedOption.of(context);

    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 360),
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              shrinkWrap: true,
              children: [
                for (final (index, place) in places.indexed)
                  ListTile(
                    selected: index == highlighted,
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox.square(
                        dimension: 40,
                        child: PlacePhoto(place: place, width: 120),
                      ),
                    ),
                    title: Text(place.name),
                    subtitle: Text(
                      place.isRated
                          ? context.l10n.suggestionRated(
                              place.city,
                              context.l10n.placeRating(place),
                            )
                          : context.l10n.suggestionNew(place.city),
                    ),
                    onTap: () => onSelected(place),
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
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off, size: 48),
          const SizedBox(height: 8),
          Text(context.l10n.noPlaces),
        ],
      ),
    );
  }
}
