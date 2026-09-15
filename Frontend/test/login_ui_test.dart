import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_management/features/auth/presentation/screens/login_screen.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_management/features/auth/domain/models/auth_state.dart';

class _FakeAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _FakeAuthNotifier() : super(const AuthUnauthenticated());

  @override
  Future<void> login(String identifier, String password) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Login UI Tests', () {
    testWidgets('Empty fields show validation errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier()),
          ],
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find login button and tap it
      final loginButton = find.text('Sign In');
      expect(loginButton, findsOneWidget);
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Verify validation errors appear
      expect(find.text('Please enter your email or phone number'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('Empty password with identifier entered shows password validation error', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier()),
          ],
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find identifier field and enter identifier
      final identifierField = find.byType(TextFormField).first;
      await tester.enterText(identifierField, 'user@acadex.edu');

      final loginButton = find.text('Sign In');
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Verify password validation error
      expect(find.text('Please enter your password'), findsOneWidget);
    });
  });
}
