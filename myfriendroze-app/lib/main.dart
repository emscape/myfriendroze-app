import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
// ...existing code...

import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'providers/event_provider.dart';
import 'providers/order_provider.dart';
import 'providers/subscription_provider.dart';
import 'providers/gallery_provider.dart';
import 'routes/app_router.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Created once here (rather than inside a provider's `create:` callback)
  // so the SAME instance can be handed to both the provider tree and
  // AppRouter.createRouter below — the router needs it directly as a
  // Listenable so it can react to a persisted session being restored
  // asynchronously, with no navigation event to otherwise trigger a
  // redirect re-check.
  final authProvider = AuthProvider();
  final router = AppRouter.createRouter(authProvider);

  runApp(MyFriendRozeAdminApp(authProvider: authProvider, router: router));
}

class MyFriendRozeAdminApp extends StatelessWidget {
  final AuthProvider authProvider;
  final GoRouter router;

  const MyFriendRozeAdminApp({
    super.key,
    required this.authProvider,
    required this.router,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => EventProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
        ChangeNotifierProvider(create: (_) => GalleryProvider()),
      ],
      child: MaterialApp.router(
        title: 'MyFriendRoze Admin',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
