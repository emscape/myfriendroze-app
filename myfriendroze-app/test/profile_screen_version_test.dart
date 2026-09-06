// Regression test for: the Profile screen's "Version: 1.0.0" was a hardcoded
// literal string, not read from the app's real package/build info. It would
// have shown "1.0.0" forever regardless of how many releases shipped —
// reported 2026-09-05 alongside a request to auto-increment the build number
// on deploy. Fixed by reading PackageInfo.fromPlatform() (version + build
// number) instead.
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:package_info_plus_platform_interface/package_info_data.dart';
import 'package:package_info_plus_platform_interface/package_info_platform_interface.dart';
import 'package:provider/provider.dart';

import 'package:myfriendroze_admin/providers/auth_provider.dart';
import 'package:myfriendroze_admin/screens/profile/profile_screen.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {
  MockFirebaseAuth(this._authStateStream);

  final Stream<User?> _authStateStream;

  @override
  Stream<User?> authStateChanges() => _authStateStream;
}

// Simulates PackageInfo.fromPlatform() failing (platform channel/plugin
// init issue) — package_info_plus has no setMockInitialValues equivalent
// for the error path, so this overrides the platform interface directly.
class ThrowingPackageInfoPlatform extends PackageInfoPlatform {
  @override
  Future<PackageInfoData> getAll({String? baseUrl}) {
    throw StateError('platform channel unavailable');
  }
}

void main() {
  // Ordering matters here: PackageInfo.fromPlatform() memoizes its result in
  // a private static field with no public reset, so once any test resolves
  // it successfully, every later fromPlatform() call in this same test
  // binary returns that cached value regardless of PackageInfoPlatform's
  // current instance. The failure-path test must run before the
  // setMockInitialValues test populates that cache, or it would silently
  // see the earlier test's cached success value instead of the injected
  // failure.
  testWidgets(
    'Profile screen shows a safe fallback, not an unhandled error, when '
    'PackageInfo.fromPlatform() fails',
    (tester) async {
      final originalPlatform = PackageInfoPlatform.instance;
      PackageInfoPlatform.instance = ThrowingPackageInfoPlatform();
      addTearDown(() => PackageInfoPlatform.instance = originalPlatform);

      final authStateController = StreamController<User?>.broadcast();
      addTearDown(authStateController.close);
      final authProvider = AuthProvider(
        firebaseAuth: MockFirebaseAuth(authStateController.stream),
      );

      // No FlutterError.onError override here — an uncaught async error
      // from initState's future would fail this test on its own.
      await tester.pumpWidget(
        ChangeNotifierProvider<AuthProvider>.value(
          value: authProvider,
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Version unavailable'), findsOneWidget);
    },
  );

  testWidgets(
    'Profile screen shows the real build version/number, not a hardcoded string',
    (tester) async {
      PackageInfo.setMockInitialValues(
        appName: 'myfriendroze_admin',
        packageName: 'com.myfriendroze.admin',
        version: '1.2.0',
        buildNumber: '42',
        buildSignature: '',
      );

      final authStateController = StreamController<User?>.broadcast();
      addTearDown(authStateController.close);
      final authProvider = AuthProvider(
        firebaseAuth: MockFirebaseAuth(authStateController.stream),
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<AuthProvider>.value(
          value: authProvider,
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Version 1.2.0 (42)'), findsOneWidget);
      expect(find.text('Version: 1.0.0'), findsNothing);
    },
  );
}
