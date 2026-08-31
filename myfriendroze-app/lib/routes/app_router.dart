import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/products/products_screen.dart';
import '../screens/products/add_product_screen.dart';
import '../models/product.dart';
import '../screens/events/events_screen.dart';
import '../screens/events/add_event_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/gallery/gallery_screen.dart';
import '../screens/gallery/add_gallery_photo_screen.dart';
import '../models/gallery_photo.dart';

class AppRouter {
  // Builds a router bound to a specific AuthProvider instance. Callers must
  // pass the SAME AuthProvider instance used elsewhere in the widget tree
  // (e.g. via ChangeNotifierProvider.value in main.dart) so `refreshListenable`
  // actually observes the app's real auth state.
  //
  // `refreshListenable` is required here, not optional: Firebase restores a
  // persisted login session asynchronously after startup (AuthProvider's
  // authStateChanges() listener fires later and calls notifyListeners()),
  // with no navigation event happening. Without refreshListenable, GoRouter
  // only re-runs `redirect` on navigation, so it never notices the session
  // was restored and leaves the user stuck on /login.
  static GoRouter createRouter(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: '/login',
      refreshListenable: authProvider,
      redirect: (BuildContext context, GoRouterState state) {
        final isAuthenticated = authProvider.isAuthenticated;
        final isAuthRoute =
            state.uri.path == '/login' || state.uri.path == '/register';

        if (!isAuthenticated && !isAuthRoute) {
          return '/login';
        }

        if (isAuthenticated && isAuthRoute) {
          return '/home';
        }

        return null;
      },
      routes: [
        // Auth routes
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),

        // Main app routes
        GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/products',
          builder: (context, state) => const ProductsScreen(),
        ),
        GoRoute(
          path: '/products/add',
          builder: (context, state) {
            final extra = state.extra;
            if (extra is Product) {
              return AddProductScreen(productToEdit: extra);
            }
            return const AddProductScreen();
          },
        ),
        GoRoute(
          path: '/events',
          builder: (context, state) => const EventsScreen(),
        ),
        GoRoute(
          path: '/events/add',
          builder: (context, state) => const AddEventScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/gallery',
          builder: (context, state) => const GalleryScreen(),
        ),
        GoRoute(
          path: '/gallery/add',
          builder: (context, state) {
            final extra = state.extra;
            if (extra is GalleryPhoto) {
              return AddGalleryPhotoScreen(photoToEdit: extra);
            }
            return const AddGalleryPhotoScreen();
          },
        ),
      ],
    );
  }
}
