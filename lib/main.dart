import 'package:flutter/material.dart';
import 'package:top_places/app.dart';
import 'package:top_places/services/places_repository.dart';

Future<void> main() async {
  // Needed before reading assets with rootBundle, which happens before runApp.
  WidgetsFlutterBinding.ensureInitialized();
  final repository = await PlacesRepository.load();
  runApp(TopPlacesApp(repository: repository));
}