import 'package:go_router/go_router.dart';
import 'package:top_places/screens/explore_screen.dart';
import 'package:top_places/screens/home_shell.dart';
import 'package:top_places/screens/not_found_screen.dart';
import 'package:top_places/screens/place_details_screen.dart';
import 'package:top_places/screens/profile_screen.dart';

/// Every screen of the app and its address (the URL on the web).
GoRouter createRouter() {
  return GoRouter(
    initialLocation: '/explore',
    errorBuilder: (context, state) => const NotFoundScreen(),
    routes: [
      GoRoute(path: '/', redirect: (context, state) => '/explore'),
      // The two tabs. Each branch keeps its own history, like the tabs in
      // Expo Router.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            HomeShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/explore',
                builder: (context, state) => const ExploreScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      // Outside the tabs, so the details page covers the navigation bar.
      GoRoute(
        path: '/locations/:id',
        builder: (context, state) =>
            PlaceDetailsScreen(placeId: state.pathParameters['id']!),
      ),
    ],
  );
}