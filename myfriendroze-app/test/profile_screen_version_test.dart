// Regression test for: the Profile screen's "Version: 1.0.0" was a hardcoded
// literal string, not read from the app's real package/build info. It would
// have shown "1.0.0" forever regardless of how many releases shipped —
// reported 2026-09-05 alongside a request to auto-increment the build number
// on deploy. Fixed by reading PackageInfo.fromPlatform() (version + build
// number) instead.
//
// ProfileScreen takes an injectable packageInfoLoader (defaulting to
// PackageInfo.fromPlatform in production) so these tests can supply a
// resolving/throwing loader directly, rather than swapping
// PackageInfoPlatform.instance and relying on PackageInfo.fromPlatform()'s
// global memoization — that first approach made the failure-path test's
// outcome depend on running before any test that resolves successfully, an
// ordering dependency that `flutter test --test-randomize-ordering-seed`
// could break.
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
  required Future<PackageInfo> Function() packageInfoLoader,
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
        home: ProfileScreen(packageInfoLoader: packageInfoLoader),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Profile screen shows the real build version/number, not a hardcoded string',
    (tester) async {
      await _pumpProfileScreen(
        tester,
        packageInfoLoader: () async => PackageInfo(
          appName: 'myfriendroze_admin',
          packageName: 'com.myfriendroze.admin',
          version: '1.2.0',
          buildNumber: '42',
        ),
      );

      expect(find.text('Version 1.2.0 (42)'), findsOneWidget);
      expect(find.text('Version: 1.0.0'), findsNothing);
    },
  );

  testWidgets(
    'Profile screen shows a safe fallback, not an unhandled error, when '
    'the package info loader fails',
    (tester) async {
      // No FlutterError.onError override here — an uncaught async error
      // from initState's future would fail this test on its own.
      await _pumpProfileScreen(
        tester,
        packageInfoLoader: () async =>
            throw StateError('platform channel unavailable'),
      );

      expect(find.text('Version unavailable'), findsOneWidget);
    },
  );
}
