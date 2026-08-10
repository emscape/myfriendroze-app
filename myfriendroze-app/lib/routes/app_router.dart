import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

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
  static final GoRouter router = GoRouter(
    initialLocation: '/login',
  redirect: (BuildContext context, GoRouterState state) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final isAuthenticated = authProvider.isAuthenticated;
  final isAuthRoute = state.uri.path == '/login' || state.uri.path == '/register';
      
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
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
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
