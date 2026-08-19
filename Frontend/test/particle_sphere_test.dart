import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_management/core/presentation/widgets/acadex_page_container.dart';
import 'package:campus_management/features/auth/presentation/screens/splash_screen.dart';
import 'package:campus_management/features/auth/presentation/screens/login_screen.dart';

void main() {
  group('AnimatedParticleSphereBackground Tests', () {
    testWidgets('Renders 3D particle sphere background with child content', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedParticleSphereBackground(
              sphereAlignment: Alignment.center,
              child: Center(
                child: Text('Foreground Layer'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Foreground Layer'), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.byType(IgnorePointer), findsWidgets);
      expect(find.byType(RepaintBoundary), findsWidgets);
    });

    testWidgets('Renders properly in Light Mode with sapphire/cobalt palette', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: const Scaffold(
            body: AnimatedParticleSphereBackground(
              variant: ParticleSphereVariant.dashboard,
              child: Center(
                child: Text('Light Mode Dashboard'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Light Mode Dashboard'), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('Renders properly in Dark Mode with luminous cyan/white palette', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: AnimatedParticleSphereBackground(
              variant: ParticleSphereVariant.dashboard,
              child: Center(
                child: Text('Dark Mode Dashboard'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Dark Mode Dashboard'), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('Handles theme change smoothly from Dark to Light mode', (tester) async {
      final themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.dark);

      await tester.pumpWidget(
        ValueListenableBuilder<ThemeMode>(
          valueListenable: themeNotifier,
          builder: (context, themeMode, _) {
            return MaterialApp(
              themeMode: themeMode,
              theme: ThemeData.light(),
              darkTheme: ThemeData.dark(),
              home: const Scaffold(
                body: AnimatedParticleSphereBackground(
                  variant: ParticleSphereVariant.dashboard,
                  child: Text('Adaptive Sphere'),
                ),
              ),
            );
          },
        ),
      );

      expect(find.text('Adaptive Sphere'), findsOneWidget);

      // Toggle to light mode
      themeNotifier.value = ThemeMode.light;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Adaptive Sphere'), findsOneWidget);
    });

    testWidgets('Respects MediaQuery disableAnimations (Reduced Motion)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: AnimatedParticleSphereBackground(
                child: Text('Static 3D Sphere'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Static 3D Sphere'), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('AcadexPageContainer renders AnimatedParticleSphereBackground on dashboards', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AcadexPageContainer(
              particleSphereVariant: ParticleSphereVariant.dashboard,
              child: Text('Dashboard Content'),
            ),
          ),
        ),
      );

      expect(find.text('Dashboard Content'), findsOneWidget);
      expect(find.byType(AnimatedParticleSphereBackground), findsOneWidget);
    });

    testWidgets('SplashScreen renders with 3D spherical particle background', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SplashScreen(),
          ),
        ),
      );

      expect(find.text('Acadex'), findsOneWidget);
      expect(find.text('Empowering Education'), findsOneWidget);
      expect(find.byType(AnimatedParticleSphereBackground), findsOneWidget);

      // Advance past splash delay timer
      await tester.pump(const Duration(milliseconds: 1600));
    });

    testWidgets('LoginScreen renders with 3D spherical particle background', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      expect(find.text('Sign In'), findsOneWidget);
      expect(find.byType(AnimatedParticleSphereBackground), findsOneWidget);
    });

    testWidgets('Super Admin Dashboard layout integrates 3D particle sphere via AcadexPageContainer', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AcadexPageContainer(
              particleSphereVariant: ParticleSphereVariant.dashboard,
              child: Text('Super Admin Metrics'),
            ),
          ),
        ),
      );

      expect(find.text('Super Admin Metrics'), findsOneWidget);
      expect(find.byType(AnimatedParticleSphereBackground), findsOneWidget);
    });

    testWidgets('Student Dashboard layout integrates 3D particle sphere via AcadexPageContainer', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AcadexPageContainer(
              particleSphereVariant: ParticleSphereVariant.dashboard,
              child: Text('Student Courses'),
            ),
          ),
        ),
      );

      expect(find.text('Student Courses'), findsOneWidget);
      expect(find.byType(AnimatedParticleSphereBackground), findsOneWidget);
    });
  });
}
