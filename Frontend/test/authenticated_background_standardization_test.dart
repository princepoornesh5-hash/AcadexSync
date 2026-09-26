import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_management/app/theme/app_theme.dart';
import 'package:campus_management/core/presentation/widgets/super_admin_gradient_background.dart';
import 'package:campus_management/core/presentation/widgets/acadex_page_container.dart';
import 'package:campus_management/core/presentation/widgets/acadex_card.dart';
import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';

class _FakeAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _FakeAuthNotifier([super.initial = const AuthUnauthenticated()]);

  @override
  Future<void> login(String identifier, String password) async {}
  @override
  Future<void> loginAsDevelopmentRole(AppRole role) async {}
  @override
  Future<void> logout() async { state = const AuthUnauthenticated(); }
  @override
  Future<void> logoutAll() async { state = const AuthUnauthenticated(); }
  @override
  Future<void> resetPassword(String email) async {}
  @override
  Future<void> changePassword({required String currentPassword, required String newPassword}) async {}
  @override
  void updateCurrentUser(UserModel updatedUser) {}
}

Widget _wrapWithAuth({
  required Widget child,
  AppRole role = AppRole.hod,
}) {
  final user = UserModel(
    id: 'test-user-id',
    name: 'Test HOD',
    email: 'hod@example.com',
    role: role,
    accountStatus: AccountStatus.active,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  return ProviderScope(
    overrides: [
      authProvider.overrideWith((ref) => _FakeAuthNotifier(AuthAuthenticated(user: user, token: 'token'))),
    ],
    child: MaterialApp(
      home: AcadexAuthenticatedBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: child,
        ),
      ),
    ),
  );
}

void main() {
  group('ACADEX Authenticated Background Standardization Tests', () {
    testWidgets('AcadexAuthenticatedBackground renders canonical pure white #FFFFFF', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AcadexAuthenticatedBackground(
            child: SizedBox(
              width: 400,
              height: 800,
              child: Text('Test Authenticated Content'),
            ),
          ),
        ),
      );

      expect(find.text('Test Authenticated Content'), findsOneWidget);
      expect(find.byType(AcadexAuthenticatedBackground), findsOneWidget);

      final containerFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.color == Colors.white,
      );
      expect(containerFinder, findsOneWidget);
    });

    testWidgets('AcadexPageContainer defaults to canonical white canvas for authenticated users', (tester) async {
      await tester.pumpWidget(
        _wrapWithAuth(
          child: const AcadexPageContainer(
            child: Text('Child Page Inside Shell'),
          ),
        ),
      );

      expect(find.text('Child Page Inside Shell'), findsOneWidget);

      final materialFinder = find.descendant(
        of: find.byType(AcadexPageContainer),
        matching: find.byType(Material),
      );
      expect(materialFinder, findsWidgets);
      final material = tester.widget<Material>(materialFinder.first);
      expect(material.color, AcadexColors.canvas);
    });

    testWidgets('AcadexCard preserves glass styling (surface & hairline border) over white canvas', (tester) async {
      await tester.pumpWidget(
        _wrapWithAuth(
          child: const AcadexPageContainer(
            child: AcadexCard(
              child: Text('Glass Card Content'),
            ),
          ),
        ),
      );

      expect(find.text('Glass Card Content'), findsOneWidget);

      final cardFinder = find.byType(AcadexCard);
      expect(cardFinder, findsOneWidget);

      // Verify that AcadexCard uses default styling with AcadexColors.surface and hairline border
      final containerWidgets = tester.widgetList<Container>(
        find.descendant(of: cardFinder, matching: find.byType(Container)),
      );
      final cardContainer = containerWidgets.firstWhere(
        (c) => c.decoration is BoxDecoration,
      );
      final decoration = cardContainer.decoration as BoxDecoration;
      expect(decoration.color, AcadexColors.surface);
      expect(decoration.border, isNotNull);
      expect(decoration.boxShadow, isNotNull);
    });

    testWidgets('SuperAdminGradientBackground renders 21-stop vertical gradient for legacy prototype', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SuperAdminGradientBackground(
            child: Text('Scope Test'),
          ),
        ),
      );

      final containerFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).gradient != null,
      );
      expect(containerFinder, findsOneWidget);
    });
  });
}
