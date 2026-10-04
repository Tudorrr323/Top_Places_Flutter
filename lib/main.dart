import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:top_places/app.dart';
import 'package:top_places/services/account_service.dart';
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
  // The same for accounts: no Supabase values, no accounts.
  AccountService? accounts;
  if (supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty) {
    // Also brings back the session saved on the device, if there is one.
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabasePublishableKey,
    );
    accounts = SupabaseAccountService(Supabase.instance.client);
  }
  runApp(
    TopPlacesApp(repository: repository, gemini: gemini, accounts: accounts),
  );
}
