import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:psc_cinema_app/main.dart' as app;
import 'package:flutter/material.dart';

import 'package:psc_cinema_app/firebase_options.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets("Login and Navigate to Dashboard", (WidgetTester tester) async {
    // ✅ Initialize Firebase first
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // ✅ Then sign out any existing user
    await FirebaseAuth.instance.signOut();

    // ✅ Launch the app
    app.main();
    await tester.pumpAndSettle();

    // ✅ Look for widgets by key
    final emailField = find.byKey(const Key('emailField'));
    final passwordField = find.byKey(const Key('passwordField'));
    final loginButton = find.byKey(const Key('loginButton'));

    expect(emailField, findsOneWidget, reason: 'Email field not found');
    expect(passwordField, findsOneWidget, reason: 'Password field not found');
    expect(loginButton, findsOneWidget, reason: 'Login button not found');

    await tester.enterText(emailField, 'manager@gmail.com');
    await tester.pump();
    await tester.enterText(passwordField, 'manager1234');
    await tester.pump();

    await tester.tap(loginButton);
    await tester.pumpAndSettle();

  });
}
