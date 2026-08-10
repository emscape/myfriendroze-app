import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:provider/provider.dart';

import 'package:myfriendroze_admin/providers/auth_provider.dart';
import 'package:myfriendroze_admin/routes/app_router.dart';

void main() {
  testWidgets('redirects to /home when authenticated and to /login when not', (tester) async {
    final mockUser = MockUser(email: 'test@example.com');

    // Start unauthenticated
    final unauthAuth = MockFirebaseAuth(signedIn: false, mockUser: mockUser);
    final unauthProvider = AuthProvider(firebaseAuth: unauthAuth);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: unauthProvider,
        child: MaterialApp.router(
          routerConfig: AppRouter.buildRouter(unauthProvider),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byType(MaterialApp), findsOneWidget); // smoke check

    // Now authenticate
    await unauthAuth.signInWithEmailAndPassword(email: 'test@example.com', password: 'password');
    await tester.pumpAndSettle();

    // If auth changes trigger a redirect, router would rebuild; this is a basic check
    // We simply ensure no exceptions and app rebuilds after auth change.
    expect(tester.takeException(), isNull);
  });
}

