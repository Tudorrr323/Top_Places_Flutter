import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:top_places/screens/not_found_screen.dart';
import 'package:top_places/services/places_repository.dart';

/// For now only the text of one place. M5 adds the photo, translation and
/// the WhatsApp and directions buttons.
class PlaceDetailsScreen extends StatelessWidget {
  const PlaceDetailsScreen({super.key, required this.placeId});

  final String placeId;

  @override
  Widget build(BuildContext context) {
    final place = context.watch<PlacesRepository>().placeById(placeId);
    if (place == null) {
      return const NotFoundScreen();
    }

    return Scaffold(
      appBar: AppBar(title: Text(place.name)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(place.address),
            const SizedBox(height: 8),
            Text('★ ${place.rating.toStringAsFixed(1)}'),
            const SizedBox(height: 16),
            Text(place.description),
          ],
        ),
      ),
    );
  }
}