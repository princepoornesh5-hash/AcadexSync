import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_management/features/auth/presentation/screens/login_screen.dart';
import 'package:campus_management/core/presentation/widgets/animated_particle_sphere.dart';

class _FakeAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _FakeAuthNotifier() : super(const AuthUnauthenticated());

  @override
  Future<void> login(String identifier, String password) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget buildTestableLoginApp({
  required Size screenSize,
  double textScaleFactor = 1.0,
  double bottomInset = 0.0,
}) {
  final router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/activate', builder: (context, state) => const Scaffold(body: Text('Activate Screen Target'))),
      GoRoute(path: '/forgot-password', builder: (context, state) => const Scaffold(body: Text('Forgot Password Target'))),
    ],
  );

  return ProviderScope(
    overrides: [
      authProvider.overrideWith((ref) => _FakeAuthNotifier()),
    ],
    child: MediaQuery(
      data: MediaQueryData(
        size: screenSize,
        textScaler: TextScaler.linear(textScaleFactor),
        viewInsets: EdgeInsets.only(bottom: bottomInset),
      ),
      child: MaterialApp.router(
        routerConfig: router,
      ),
    ),
  );
}

void main() {
  group('ACADEX Login UI Refinement — Responsive & Visual Verification', () {
    final mobileWidths = [360.0, 390.0, 412.0];
    final textScales = [1.0, 1.15, 1.25];

    for (final width in mobileWidths) {
      for (final scale in textScales) {
        testWidgets('Mobile width ${width.toInt()}dp with text scale $scale renders without overflow', (tester) async {
          tester.view.physicalSize = Size(width, 800);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() => tester.view.resetPhysicalSize());

          await tester.pumpWidget(
            buildTestableLoginApp(
              screenSize: Size(width, 800),
              textScaleFactor: scale,
            ),
          );
          await tester.pumpAndSettle();

          // Verify Branding
          expect(find.text('Acadex'), findsOneWidget);
          expect(find.text('Welcome Back'), findsOneWidget);

          // Verify Form inputs
          expect(find.text('Email or Phone Number'), findsOneWidget);
          expect(find.text('Password'), findsOneWidget);
          expect(find.text('Sign In'), findsOneWidget);

          // Verify Strengthened Secondary CTA
          final activateFinder = find.text('New student or faculty? Activate Account');
          expect(activateFinder, findsOneWidget);

          // Verify Animated Particle Sphere presence
          expect(find.byType(AnimatedParticleSphereBackground), findsOneWidget);
        });
      }
    }

    testWidgets('Desktop 1200dp layout displays split-screen, hero proposition, and 3 compact feature rows', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestableLoginApp(
          screenSize: const Size(1200, 900),
          textScaleFactor: 1.0,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      // Verify Left-side Hero Showcase
      expect(find.text('CAMPUS OPERATING SYSTEM'), findsOneWidget);
      expect(find.text('The complete platform for academic institutions.'), findsOneWidget);

      // Verify the 3 Compact Feature Pills are present
      expect(find.text('Verified Attendance'), findsOneWidget);
      expect(find.text('Authoritative Timetables'), findsOneWidget);
      expect(find.text('Curriculum & Notes Hub'), findsOneWidget);

      // Verify Right-side Form Card
      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('New student or faculty? Activate Account'), findsOneWidget);
    });

    testWidgets('Keyboard occlusion (bottom inset 300dp) scrolls cleanly without RenderFlex overflow', (tester) async {
      tester.view.physicalSize = const Size(390, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestableLoginApp(
          screenSize: const Size(390, 800),
          textScaleFactor: 1.0,
          bottomInset: 300.0,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      // Tap Activate Account button to verify navigation
      final activateButton = find.text('New student or faculty? Activate Account');
      expect(activateButton, findsOneWidget);
      await tester.ensureVisible(activateButton);
      await tester.tap(activateButton);
      await tester.pumpAndSettle();

      expect(find.text('Activate Screen Target'), findsOneWidget);
    });
  });
}
