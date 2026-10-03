import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:top_places/services/places_repository.dart';

/// For now a plain list of every place. M3 adds search, filters and cards.
class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final places = context.watch<PlacesRepository>().places;

    return Scaffold(
      appBar: AppBar(title: const Text('Explorează')),
      body: ListView.builder(
        itemCount: places.length,
        itemBuilder: (context, index) {
          final place = places[index];
          return ListTile(
            leading: const Icon(Icons.place_outlined),
            title: Text(place.name),
            subtitle: Text(place.city),
            trailing: Text('★ ${place.rating.toStringAsFixed(1)}'),
            onTap: () => context.push('/locations/${place.id}'),
          );
        },
      ),
    );
  }
}
