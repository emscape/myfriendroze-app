// Regression test for: admin app login not persisting on reload.
//
// Root cause: AppRouter's GoRouter redirect reads AuthProvider.isAuthenticated
// but was never given `refreshListenable`, so it only re-evaluates on a
// navigation event. Firebase restores a persisted session *asynchronously*
// after startup (AuthProvider's authStateChanges() listener fires later and
// calls notifyListeners()) — with no navigation happening, the router never
// notices and leaves the user stuck on /login even though Firebase Auth did
// restore their session correctly.
//
// This test simulates exactly that: a session restored via the auth-state
// stream with no navigation event, and asserts the router redirects away
// from /login to /home on its own.
import 'dart:async';

// `firebase_auth` exports its own unrelated `AuthProvider` class (the base
// type for federated sign-in providers like GoogleAuthProvider) — hide it so
// it doesn't collide with our app's AuthProvider below.
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'package:myfriendroze_admin/providers/auth_provider.dart';
import 'package:myfriendroze_admin/routes/app_router.dart';

// Plain (non-codegen) mockito Mocks can't stub authStateChanges() via
// when(...) — `when()` needs a registered dummy value for any non-primitive
// return type (Stream<User?> has none by default), so the recording call
// throws before the stub is even set up. Overriding the method directly
// sidesteps that entirely.
class MockFirebaseAuth extends Mock implements FirebaseAuth {
  MockFirebaseAuth(this._authStateStream);

  final Stream<User?> _authStateStream;

  @override
  Stream<User?> authStateChanges() => _authStateStream;
}

class MockUser extends Mock implements User {}

void main() {
  testWidgets(
    'restoring a persisted Firebase session (no navigation) redirects away from /login',
    (tester) async {
      // Broadcast so `close()` in tearDown completes immediately even if
      // this specific test never attaches a listener (a single-subscription
      // controller's close() can wait indefinitely for one).
      final authStateController = StreamController<User?>.broadcast();
      addTearDown(authStateController.close);

      final mockAuth = MockFirebaseAuth(authStateController.stream);

      final authProvider = AuthProvider(firebaseAuth: mockAuth);
      final router = AppRouter.createRouter(authProvider);

      await tester.pumpWidget(
        ChangeNotifierProvider<AuthProvider>.value(
          value: authProvider,
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      // Session not yet restored: still on the login screen.
      expect(find.text('Login'), findsOneWidget);
      expect(find.text('Welcome back!'), findsNothing);

      // Simulate Firebase restoring a persisted session on page load, with
      // no user-initiated navigation in between.
      final mockUser = MockUser();
      when(mockUser.email).thenReturn('roze@example.com');
      authStateController.add(mockUser);
      await tester.pumpAndSettle();

      expect(find.text('Welcome back!'), findsOneWidget);
      expect(find.text('Login'), findsNothing);
    },
  );
}
