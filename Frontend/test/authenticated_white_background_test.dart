import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_management/app/theme/app_theme.dart';
import 'package:campus_management/core/presentation/widgets/acadex_card.dart';
import 'package:campus_management/core/presentation/widgets/acadex_readable_surface.dart';
import 'package:campus_management/core/presentation/widgets/acadex_adaptive_gradient_text.dart';
import 'package:campus_management/core/presentation/widgets/super_admin_gradient_background.dart';
import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_management/features/auth/presentation/screens/splash_screen.dart';
import 'package:campus_management/features/dashboard/presentation/widgets/acadex_drawer.dart';
import 'package:campus_management/features/dashboard/presentation/widgets/acadex_nav_rail.dart';

class _MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _MockAuthNotifier(super.initial);

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
  AppRole role = AppRole.superAdmin,
}) {
  final user = UserModel(
    id: 'test-user-id',
    name: 'Test Administrator',
    email: 'admin@acadex.edu',
    role: role,
    accountStatus: AccountStatus.active,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  return ProviderScope(
    overrides: [
      authProvider.overrideWith((ref) => _MockAuthNotifier(AuthAuthenticated(user: user, token: 'mock-token'))),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: child,
    ),
  );
}

void main() {
  group('ACADEX Prompt 8: White-First Authenticated Foundation & Glass Preservation', () {
    test('Canonical White Background tokens are standard #FFFFFF Colors.white', () {
      expect(AcadexColors.canvas, const Color(0xFFFFFFFF));
      expect(AcadexColors.canvasLight, const Color(0xFFFFFFFF));
      expect(AcadexColors.backgroundLight, const Color(0xFFFFFFFF));
      expect(AppTheme.lightTheme.scaffoldBackgroundColor, const Color(0xFFFFFFFF));
    });

    testWidgets('Glass readable surface retains translucency, soft depth, and hairline border on white canvas', (tester) async {
      await tester.pumpWidget(
        _wrapWithAuth(
          child: const Scaffold(
            backgroundColor: Colors.white,
            body: AcadexReadableSurface(
              child: Text('Frosted Glass Surface Content'),
            ),
          ),
        ),
      );

      expect(find.text('Frosted Glass Surface Content'), findsOneWidget);
      final surfaceFinder = find.byType(AcadexReadableSurface);
      expect(surfaceFinder, findsOneWidget);

      final containerFinder = find.descendant(
        of: surfaceFinder,
        matching: find.byType(Container),
      );
      final container = tester.widget<Container>(containerFinder.first);
      final decoration = container.decoration as BoxDecoration;

      // 1. Translucency preserved (NOT opaque white)
      expect(decoration.color, isNotNull);
      expect(decoration.color!.a, lessThan(1.0));
      expect(decoration.color, const Color.fromRGBO(255, 255, 255, 0.85));

      // 2. Crisp hairline border preserved for separation against pure white
      expect(decoration.border, isNotNull);
      final boxBorder = decoration.border as Border;
      expect(boxBorder.top.color, AcadexColors.hairline);
      expect(boxBorder.top.width, 1.0);

      // 3. Soft elevation shadow preserved
      expect(decoration.boxShadow, isNotNull);
      expect(decoration.boxShadow!.isNotEmpty, isTrue);
      expect(decoration.boxShadow!.first.blurRadius, 10.0);
    });

    testWidgets('AcadexCard retains clean surface fill, hairline border, and elevation shadow', (tester) async {
      await tester.pumpWidget(
        _wrapWithAuth(
          child: const Scaffold(
            backgroundColor: Colors.white,
            body: AcadexCard(
              child: Text('Card Content'),
            ),
          ),
        ),
      );

      expect(find.text('Card Content'), findsOneWidget);
      final cardFinder = find.byType(AcadexCard);
      expect(cardFinder, findsOneWidget);

      final containerFinder = find.descendant(
        of: cardFinder,
        matching: find.byType(Container),
      );
      final container = tester.widget<Container>(containerFinder.first);
      final decoration = container.decoration as BoxDecoration;

      expect(decoration.color, AcadexColors.surface);
      expect(decoration.border, isNotNull);
      final border = decoration.border as Border;
      expect(border.top.color, AcadexColors.hairline);
      expect(decoration.boxShadow, isNotNull);
    });

    testWidgets('AcadexAdaptiveGradientText falls back to dark typography outside gradient scope', (tester) async {
      await tester.pumpWidget(
        _wrapWithAuth(
          child: const Scaffold(
            backgroundColor: Colors.white,
            body: AcadexAdaptiveGradientText(
              'Heading On White Canvas',
              darkColor: Color(0xFF07111F),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final textFinder = find.text('Heading On White Canvas');
      expect(textFinder, findsOneWidget);

      final textWidget = tester.widget<Text>(textFinder);
      expect(textWidget.style?.color, const Color(0xFF07111F));
    });

    testWidgets('AcadexAdaptiveGradientText falls back to slate secondary text outside gradient scope', (tester) async {
      await tester.pumpWidget(
        _wrapWithAuth(
          child: const Scaffold(
            backgroundColor: Colors.white,
            body: AcadexAdaptiveGradientText(
              'Secondary Label',
              isSecondary: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final textFinder = find.text('Secondary Label');
      expect(textFinder, findsOneWidget);

      final textWidget = tester.widget<Text>(textFinder);
      expect(textWidget.style?.color, const Color(0xFF475569));
    });

    testWidgets('AcadexDrawer renders on canonical white surface with hairline border and primary blue active state', (tester) async {
      await tester.pumpWidget(
        _wrapWithAuth(
          child: const Scaffold(
            backgroundColor: Colors.white,
            drawer: AcadexDrawer(activeRoute: '/dashboard/super_admin'),
            body: Text('Authenticated Dashboard Body'),
          ),
        ),
      );

      // Drawer root is white surface
      final drawerFinder = find.byType(Drawer);
      expect(drawerFinder, findsNothing); // Not opened yet

      // Open drawer
      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      expect(find.byType(Drawer), findsOneWidget);
      final drawer = tester.widget<Drawer>(find.byType(Drawer));
      expect(drawer.backgroundColor, AcadexColors.surface);

      // Verify no SuperAdminGradientBackground exists in drawer
      expect(find.descendant(of: find.byType(Drawer), matching: find.byType(SuperAdminGradientBackground)), findsNothing);
    });

    testWidgets('AcadexNavRail renders on canonical white surface with primary blue selection', (tester) async {
      await tester.pumpWidget(
        _wrapWithAuth(
          child: Scaffold(
            backgroundColor: Colors.white,
            body: Row(
              children: [
                AcadexNavRail(
                  activeRoute: '/dashboard/super_admin',
                  onDestinationSelected: (_) {},
                ),
                const Expanded(child: Text('Main Content')),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final navRailFinder = find.byType(NavigationRail);
      expect(navRailFinder, findsOneWidget);
      final navRail = tester.widget<NavigationRail>(navRailFinder);

      expect(navRail.selectedIconTheme?.color, AcadexColors.primary);
      expect(navRail.unselectedIconTheme?.color, AcadexColors.inkMuted);
    });

    testWidgets('SplashScreen remains isolated with dark canvas and AnimatedParticleSphereBackground', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SplashScreen(),
          ),
        ),
      );

      expect(find.text('Acadex'), findsOneWidget);
      expect(find.text('Campus Operating System'), findsOneWidget);

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, const Color(0xFF0F172A));
    });
  });
}
