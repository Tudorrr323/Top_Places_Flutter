import 'package:flutter/material.dart';
import 'package:top_places/app.dart';
import 'package:top_places/services/gemini_service.dart';
import 'package:top_places/services/places_repository.dart';

Future<void> main() async {
  // Needed before reading assets with rootBundle, which happens before runApp.
  WidgetsFlutterBinding.ensureInitialized();
  final repository = await PlacesRepository.load();
  // Without config/dev.json the key is empty, and the app runs without AI.
  final gemini = geminiApiKey.isEmpty
      ? null
      : GeminiService(apiKey: geminiApiKey);
  runApp(TopPlacesApp(repository: repository, gemini: gemini));
}
