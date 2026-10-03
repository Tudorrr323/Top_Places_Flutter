import 'package:go_router/go_router.dart';
import 'package:top_places/screens/explore_screen.dart';
import 'package:top_places/screens/not_found_screen.dart';
import 'package:top_places/screens/place_details_screen.dart';

/// Every screen of the app and its address (the URL on the web).
GoRouter createRouter() {
  return GoRouter(
    initialLocation: '/explore',
    errorBuilder: (context, state) => const NotFoundScreen(),
    routes: [
      GoRoute(path: '/', redirect: (context, state) => '/explore'),
      GoRoute(
        path: '/explore',
        builder: (context, state) => const ExploreScreen(),
      ),
      GoRoute(
        path: '/locations/:id',
        builder: (context, state) =>
            PlaceDetailsScreen(placeId: state.pathParameters['id']!),
      ),
    ],
  );
}