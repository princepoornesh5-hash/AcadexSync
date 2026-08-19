import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_management/features/auth/presentation/screens/login_screen.dart';

void main() {
  group('Login UI Tests', () {
    testWidgets('Empty fields show validation errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      // Find login button and tap it
      final loginButton = find.text('Sign In');
      expect(loginButton, findsOneWidget);
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Verify validation errors appear
      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('Malformed email shows validation error', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      // Find email field and enter invalid email
      final emailField = find.byType(TextFormField).first;
      await tester.enterText(emailField, 'not-an-email');
      
      final passwordField = find.byType(TextFormField).last;
      await tester.enterText(passwordField, 'password123');

      final loginButton = find.text('Sign In');
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Verify validation error
      expect(find.text('Invalid email address'), findsOneWidget);
    });
  });
}
