import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:top_places/app.dart';
import 'package:top_places/services/account_service.dart';
import 'package:top_places/services/gemini_service.dart';
import 'package:top_places/services/place_service.dart';
import 'package:top_places/services/places_repository.dart';

Future<void> main() async {
  // Needed before reading assets with rootBundle, which happens before runApp.
  WidgetsFlutterBinding.ensureInitialized();
  // Without config/dev.json the key is empty, and the app runs without AI.
  final gemini = geminiApiKey.isEmpty
      ? null
      : GeminiService(apiKey: geminiApiKey);
  // The same for Supabase: without its values there are no accounts, and
  // the places come only from the JSON bundled with the app.
  AccountService? accounts;
  PlaceService? places;
  if (supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty) {
    // Also brings back the session saved on the device, if there is one.
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabasePublishableKey,
    );
    accounts = SupabaseAccountService(Supabase.instance.client);
    places = SupabasePlaceService(Supabase.instance.client);
  }
  final repository = await PlacesRepository.load(remote: places);
  // The bundled places show at once; the live list replaces them when it
  // arrives. Offline, the bundled ones stay.
  unawaited(repository.refresh());
  runApp(
    TopPlacesApp(repository: repository, gemini: gemini, accounts: accounts),
  );
}
