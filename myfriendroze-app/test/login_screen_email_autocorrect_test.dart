// Regression test for: iOS Safari mangling a typed email address.
//
// Reported 2026-08-31: typing "myfriendroze.store@gmail.com" into the admin
// app's login email field came out as "my friend Roze.store@gmail.com" — iOS
// Safari's predictive-text bar split/autocorrected the run-together word
// "myfriendroze" into recognized dictionary words mid-typing. Flutter's
// TextFormField defaults `autocorrect`/`enableSuggestions` to true, and
// nothing in CustomTextField or its callers overrode that for email fields.
import 'dart:async';

// `firebase_auth` exports its own unrelated `AuthProvider` class (the base
// type for federated sign-in providers) — hide it so it doesn't collide with
// our app's AuthProvider below.
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'package:myfriendroze_admin/providers/auth_provider.dart';
import 'package:myfriendroze_admin/screens/auth/login_screen.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {
  MockFirebaseAuth(this._authStateStream);

  final Stream<User?> _authStateStream;

  @override
  Stream<User?> authStateChanges() => _authStateStream;
}

void main() {
  testWidgets(
    'email field disables autocorrect and suggestions',
    (tester) async {
      final authStateController = StreamController<User?>.broadcast();
      addTearDown(authStateController.close);
      final authProvider = AuthProvider(
        firebaseAuth: MockFirebaseAuth(authStateController.stream),
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<AuthProvider>.value(
          value: authProvider,
          child: const MaterialApp(home: LoginScreen()),
        ),
      );

      // Email field is the first text field on the login screen. TextFormField
      // itself doesn't expose autocorrect/enableSuggestions — it builds a
      // TextField internally, which does.
      final emailField = tester
          .widgetList<TextField>(find.byType(TextField))
          .first;

      expect(
        emailField.autocorrect,
        isFalse,
        reason: 'autocorrect must be off on the email field',
      );
      expect(
        emailField.enableSuggestions,
        isFalse,
        reason: 'enableSuggestions must be off on the email field',
      );
    },
  );
}
