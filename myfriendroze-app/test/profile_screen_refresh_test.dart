// "Refresh App" button on the Profile screen.
//
// Reported 2026-09-06: after a redeploy, Emily and Roze had to remove the
// PWA from their phone's home screen and re-add it just to see the new
// build — Flutter web's service worker caches aggressively, and iOS
// Safari's home-screen PWA mode has no visible "clear cache" control the
// way a normal browser tab does. This button unregisters the service
// worker, clears the Cache Storage entries it populated, and reloads —
// all from inside the app, no bookmark surgery needed.
//
// The actual browser/service-worker interop (lib/services/
// app_refresh_service.dart) only exists on web and can't be meaningfully
// unit-tested outside a real browser, so ProfileScreen takes it as an
// injectable callback (same DI pattern as packageInfoLoader) — these tests
// verify the button wires to that callback and respects visibility, not
// the real browser side effects.
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import 'package:myfriendroze_admin/providers/auth_provider.dart';
import 'package:myfriendroze_admin/screens/profile/profile_screen.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {
  MockFirebaseAuth(this._authStateStream);

  final Stream<User?> _authStateStream;

  @override
  Stream<User?> authStateChanges() => _authStateStream;
}

Future<void> _pumpProfileScreen(
  WidgetTester tester, {
  required bool showRefreshButton,
  Future<void> Function()? onRefreshApp,
}) async {
  final authStateController = StreamController<User?>.broadcast();
  addTearDown(authStateController.close);
  final authProvider = AuthProvider(
    firebaseAuth: MockFirebaseAuth(authStateController.stream),
  );

  await tester.pumpWidget(
    ChangeNotifierProvider<AuthProvider>.value(
      value: authProvider,
      child: MaterialApp(
        home: ProfileScreen(
          packageInfoLoader: () async => PackageInfo(
            appName: 'myfriendroze_admin',
            packageName: 'com.myfriendroze.admin',
            version: '1.0.0',
            buildNumber: '1',
          ),
          showRefreshButton: showRefreshButton,
          onRefreshApp: onRefreshApp,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Refresh App button is hidden when showRefreshButton is false',
      (tester) async {
    await _pumpProfileScreen(tester, showRefreshButton: false);

    expect(find.text('Refresh App'), findsNothing);
  });

  testWidgets(
      'tapping Refresh App calls the injected refresh callback exactly once',
      (tester) async {
    var callCount = 0;
    await _pumpProfileScreen(
      tester,
      showRefreshButton: true,
      onRefreshApp: () async {
        callCount++;
      },
    );

    expect(find.text('Refresh App'), findsOneWidget);

    await tester.tap(find.text('Refresh App'));
    await tester.pumpAndSettle();

    expect(callCount, 1);
  });

  testWidgets(
      'button re-enables (not stuck disabled) if the refresh callback throws',
      (tester) async {
    await _pumpProfileScreen(
      tester,
      showRefreshButton: true,
      onRefreshApp: () async => throw StateError('JS interop failure'),
    );

    // Real onRefreshApp implementations reload the page as their last
    // step, so a thrown error means something earlier (getRegistrations,
    // cache access) failed before ever reaching reload — the button must
    // not stay stuck in the disabled/spinner state in that case.
    await tester.tap(find.text('Refresh App'));
    await tester.pumpAndSettle();

    // find.byType(OutlinedButton) would find nothing here: the .icon()
    // constructor returns a private OutlinedButton subclass, and byType
    // matches exact runtime type, not `is`. byWidgetPredicate checks the
    // actual type relationship instead.
    final button = tester.widget(
      find.byWidgetPredicate((widget) => widget is OutlinedButton),
    ) as OutlinedButton;
    expect(button.onPressed, isNotNull);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
