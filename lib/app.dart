import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:top_places/router.dart';
import 'package:top_places/services/account_service.dart';
import 'package:top_places/services/gemini_service.dart';
import 'package:top_places/services/location_service.dart';
import 'package:top_places/services/place_service.dart';
import 'package:top_places/services/places_repository.dart';
import 'package:top_places/view_models/account_view_model.dart';
import 'package:top_places/view_models/explore_view_model.dart';

/// The blue of the original app (#007AFF), used to generate both themes.
const _brandBlue = Color(0xFF007AFF);

class TopPlacesApp extends StatefulWidget {
  const TopPlacesApp({
    super.key,
    required this.repository,
    this.gemini,
    this.accounts,
    this.location = const DeviceLocationService(),
  });

  final PlacesRepository repository;

  /// Null without a Gemini key: the AI answers are then off, and the rest
  /// of the app works the same.
  final GeminiService? gemini;

  /// Null without the Supabase values: the app then has no accounts.
  final AccountService? accounts;

  /// Where the device is, for the GPS button on the map.
  final LocationService location;

  @override
  State<TopPlacesApp> createState() => _TopPlacesAppState();
}

class _TopPlacesAppState extends State<TopPlacesApp> {
  // Created once and kept across rebuilds, so the current page survives.
  final GoRouter _router = createRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // A ChangeNotifier: it changes when the live places arrive.
        ChangeNotifierProvider<PlacesRepository>.value(
          value: widget.repository,
        ),
        Provider<PlaceService?>.value(value: widget.repository.remote),
        Provider<AccountService?>.value(value: widget.accounts),
        Provider<GeminiService?>.value(value: widget.gemini),
        Provider<LocationService>.value(value: widget.location),
        // Gets the new places whenever the repository changes; the search
        // and the filters stay.
        ChangeNotifierProxyProvider<PlacesRepository, ExploreViewModel>(
          create: (context) => ExploreViewModel(widget.repository.places),
          update: (context, repository, explore) =>
              explore!..setPlaces(repository.places),
        ),
        ChangeNotifierProvider(
          create: (context) => AccountViewModel(widget.accounts),
        ),
      ],
      child: MaterialApp.router(
        title: 'Top Places',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: _brandBlue),
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: _brandBlue,
            brightness: Brightness.dark,
          ),
        ),
        themeMode: ThemeMode.system,
        locale: const Locale('ro'),
        supportedLocales: const [Locale('ro'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        routerConfig: _router,
      ),
    );
  }
}
