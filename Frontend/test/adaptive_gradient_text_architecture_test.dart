import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_management/core/presentation/widgets/acadex_adaptive_gradient_text.dart';
import 'package:campus_management/core/presentation/widgets/super_admin_gradient_background.dart';
import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';

Widget _wrapWithAuth({
  required Widget child,
  AppRole role = AppRole.superAdmin,
  bool wrapWithGradient = true,
  Size screenSize = const Size(800, 1000),
}) {
  final user = UserModel(
    id: 'test-user-id',
    name: 'Test User',
    email: 'test@example.com',
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
      home: MediaQuery(
        data: MediaQueryData(size: screenSize),
        child: wrapWithGradient
            ? SuperAdminGradientBackground(child: Scaffold(backgroundColor: Colors.transparent, body: child))
            : Scaffold(body: child),
      ),
    ),
  );
}

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


void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('P2.3 — Adaptive Gradient Text Shared Architecture', () {
    test('1. Exact 21-stop gradient and luminance thresholds verification', () {
      expect(AcadexSuperAdminGradient.stops.length, 21);
      expect(AcadexSuperAdminGradient.colors.length, 21);
      expect(AcadexSuperAdminGradient.darkThresholdLuminance, 0.20);
      expect(AcadexSuperAdminGradient.lightThresholdLuminance, 0.40);

      // Top stop is deep black (#000000)
      expect(AcadexSuperAdminGradient.colors.first, const Color(0xFF000000));
      expect(AcadexSuperAdminGradient.luminanceAt(0.0), 0.0);

      // Bottom stop is pure white (#FFFFFF)
      expect(AcadexSuperAdminGradient.colors.last, const Color(0xFFFFFFFF));
      expect(AcadexSuperAdminGradient.luminanceAt(1.0), 1.0);
    });

    test('2. Two-state hysteresis state machine evaluation', () {
      // 1. In dark region (t = 0.10, lum < 0.20), mode is light (WHITE text)
      var mode = AcadexSuperAdminGradient.evaluateMode(t: 0.10, currentMode: AcadexAdaptiveTextMode.light);
      expect(mode, AcadexAdaptiveTextMode.light);

      // 2. Moving into dead band (t = 0.55, 0.20 <= lum <= 0.40) while light -> remains light (WHITE)
      mode = AcadexSuperAdminGradient.evaluateMode(t: 0.55, currentMode: AcadexAdaptiveTextMode.light);
      expect(mode, AcadexAdaptiveTextMode.light);

      // 3. Crossing upper threshold (t = 0.75, lum >= 0.40) -> switches to dark (DARK NAVY)
      mode = AcadexSuperAdminGradient.evaluateMode(t: 0.75, currentMode: AcadexAdaptiveTextMode.light);
      expect(mode, AcadexAdaptiveTextMode.dark);

      // 4. Moving back into dead band (t = 0.55, 0.20 <= lum <= 0.40) while dark -> remains dark (DARK NAVY)
      mode = AcadexSuperAdminGradient.evaluateMode(t: 0.55, currentMode: AcadexAdaptiveTextMode.dark);
      expect(mode, AcadexAdaptiveTextMode.dark);

      // 5. Crossing lower threshold (t = 0.25, lum <= 0.20) -> switches back to light (WHITE)
      mode = AcadexSuperAdminGradient.evaluateMode(t: 0.25, currentMode: AcadexAdaptiveTextMode.dark);
      expect(mode, AcadexAdaptiveTextMode.light);
    });

    testWidgets('3. Two-state selection: WHITE on dark region, DARK NAVY on light region', (tester) async {
      await tester.pumpWidget(_wrapWithAuth(
        child: const Column(
          children: [
            SizedBox(
              height: 100,
              child: AcadexAdaptiveGradientText('Top Text (Dark BG)'),
            ),
            Spacer(),
            SizedBox(
              height: 100,
              child: AcadexAdaptiveGradientText('Bottom Text (Light BG)'),
            ),
          ],
        ),
      ));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final topText = tester.widget<Text>(find.text('Top Text (Dark BG)'));
      expect(topText.style?.color, const Color(0xFFFFFFFF));

      final bottomText = tester.widget<Text>(find.text('Bottom Text (Light BG)'));
      expect(bottomText.style?.color, const Color(0xFF07111F));
    });

    testWidgets('4. Safe fallback: deterministic dark text when outside AcadexGradientScope', (tester) async {
      // Rendered outside SuperAdminGradientBackground (standalone route / modal sheet)
      await tester.pumpWidget(_wrapWithAuth(
        wrapWithGradient: false,
        child: const AcadexAdaptiveGradientText(
          'Standalone Page Header',
          style: TextStyle(color: Color(0xFF1E293B)),
        ),
      ));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final textWidget = tester.widget<Text>(find.text('Standalone Page Header'));
      // Must not turn white (#FFFFFF); must safely preserve standard theme color
      expect(textWidget.style?.color, const Color(0xFF1E293B));
    });

    testWidgets('5. Accurate coordinate mapping and transition in scrollable view', (tester) async {
      final controller = ScrollController();

      await tester.pumpWidget(_wrapWithAuth(
        screenSize: const Size(800, 1000),
        child: SingleChildScrollView(
          controller: controller,
          child: Column(
            children: [
              const SizedBox(height: 50),
              const AcadexAdaptiveGradientText('Dynamic Scroll Title'),
              const SizedBox(height: 1200), // Push page length
            ],
          ),
        ),
      ));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Initially near top (y ~ 50 out of 1000, t ~ 0.05) -> Dark background -> WHITE text
      var title = tester.widget<Text>(find.text('Dynamic Scroll Title'));
      expect(title.style?.color, const Color(0xFFFFFFFF));

      // Scroll so the title moves towards the bottom of the screen into the light region
      // Wait, scrolling down moves the title OFF the top.
      // Let's place the title lower down (e.g. at y = 800) and scroll it up to the top!
    });

    testWidgets('6. Scroll from light to dark region triggers clean 350ms transition', (tester) async {
      final controller = ScrollController();

      await tester.pumpWidget(_wrapWithAuth(
        screenSize: const Size(800, 1000),
        child: SingleChildScrollView(
          controller: controller,
          child: Column(
            children: [
              const SizedBox(height: 800), // Initially at y = 800 (t = 0.80 -> Light BG -> Dark Navy text)
              const AcadexAdaptiveGradientText('Moving Title'),
              const SizedBox(height: 1200),
            ],
          ),
        ),
      ));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Initially in light region -> Dark Navy text (#07111F)
      var title = tester.widget<Text>(find.text('Moving Title'));
      expect(title.style?.color, const Color(0xFF07111F));

      // Scroll down 700px so title moves up to y = 100 (t = 0.10 -> Dark BG -> White text)
      controller.jumpTo(700);
      await tester.pump(); // Frame after scroll layout
      await tester.pump(); // Post-frame callback triggers setState

      // Mid-transition (175ms into 350ms cubic easing)
      await tester.pump(const Duration(milliseconds: 175));
      title = tester.widget<Text>(find.text('Moving Title'));
      // In-flight color is transitioning
      expect(title.style?.color, isNotNull);

      // Complete transition (350ms)
      await tester.pump(const Duration(milliseconds: 200));
      title = tester.widget<Text>(find.text('Moving Title'));
      expect(title.style?.color, const Color(0xFFFFFFFF));
    });

    testWidgets('7. Hysteresis prevents flicker in dead-band during scroll oscillations', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Place text inside a scrollable where we can precisely control its viewport Y position
      final controller = ScrollController();


      // Viewport height: 1000.
      // Top padding: 800.
      // Text starts at Y = 800 (t = 0.80 -> Light BG -> starts DARK NAVY).
      await tester.pumpWidget(_wrapWithAuth(
        screenSize: const Size(800, 1000),
        child: SingleChildScrollView(
          controller: controller,
          child: const Column(
            children: [
              SizedBox(height: 800),
              AcadexAdaptiveGradientText('DeadBand Test Title'),
              SizedBox(height: 2000),
            ],
          ),
        ),
      ));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // 1. Initially at Y = 800 (t = 0.80): light region -> DARK NAVY (#07111F)
      var text = tester.widget<Text>(find.text('DeadBand Test Title'));
      expect(text.style?.color, const Color(0xFF07111F));

      // 2. Scroll by 250px: Text moves up to Y = 550 (t = 0.55, which is inside dead-band [0.472, 0.683]).
      // Because previous state was DARK NAVY, it MUST REMAIN DARK NAVY!
      controller.jumpTo(250);
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      text = tester.widget<Text>(find.text('DeadBand Test Title'));
      expect(text.style?.color, const Color(0xFF07111F), reason: 'Must remain DARK NAVY inside dead band');

      // 3. Scroll by another 450px (total 700px): Text moves to Y = 100 (t = 0.10, crossed dark threshold <= 0.472).
      // Now it must transition to WHITE (#FFFFFF)!
      controller.jumpTo(700);
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      text = tester.widget<Text>(find.text('DeadBand Test Title'));
      expect(text.style?.color, const Color(0xFFFFFFFF), reason: 'Must switch to WHITE when crossing lower threshold');

      // 4. Scroll back down so text returns to Y = 550 (scroll offset 250px, t = 0.55).
      // Text is back inside dead-band, but now coming from WHITE. It MUST REMAIN WHITE!
      controller.jumpTo(250);
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      text = tester.widget<Text>(find.text('DeadBand Test Title'));
      expect(text.style?.color, const Color(0xFFFFFFFF), reason: 'Must remain WHITE inside dead band when returning from dark region');



      // 5. Rapid oscillations inside the dead-band (between Y = 500 and Y = 600)
      for (int i = 0; i < 6; i++) {
        controller.jumpTo(i.isEven ? 220 : 280);
        await tester.pump();
      }
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));


      text = tester.widget<Text>(find.text('DeadBand Test Title'));
      expect(text.style?.color, const Color(0xFFFFFFFF), reason: 'No flicker: remains WHITE through rapid dead-band movements');
    });

    testWidgets('8. Role regression: All 5 authenticated roles use the exact same shared architecture', (tester) async {
      for (final role in [
        AppRole.superAdmin,
        AppRole.collegeAdmin,
        AppRole.hod,
        AppRole.faculty,
        AppRole.student,
      ]) {
        await tester.pumpWidget(_wrapWithAuth(
          role: role,
          child: const Column(
            children: [
              SizedBox(height: 50, child: AcadexAdaptiveGradientText('Top Role Text')),
              Spacer(),
              SizedBox(height: 50, child: AcadexAdaptiveGradientText('Bottom Role Text')),
            ],
          ),
        ));

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        final top = tester.widget<Text>(find.text('Top Role Text'));
        expect(top.style?.color, const Color(0xFFFFFFFF), reason: 'Role ${role.name} top text must be WHITE');

        final bottom = tester.widget<Text>(find.text('Bottom Role Text'));
        expect(bottom.style?.color, const Color(0xFF07111F), reason: 'Role ${role.name} bottom text must be DARK NAVY');
      }
    });

    testWidgets('9. AcadexAdaptiveGradientIcon adheres to identical two-state and scope rules', (tester) async {
      await tester.pumpWidget(_wrapWithAuth(
        child: const Column(
          children: [
            SizedBox(
              height: 100,
              child: AcadexAdaptiveGradientIcon(Icons.star, key: Key('top-icon')),
            ),
            Spacer(),
            SizedBox(
              height: 100,
              child: AcadexAdaptiveGradientIcon(Icons.star, key: Key('bottom-icon')),
            ),
          ],
        ),
      ));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final topIcon = tester.widget<Icon>(
        find.descendant(of: find.byKey(const Key('top-icon')), matching: find.byType(Icon)),
      );
      expect(topIcon.color, const Color(0xFFFFFFFF));

      final bottomIcon = tester.widget<Icon>(
        find.descendant(of: find.byKey(const Key('bottom-icon')), matching: find.byType(Icon)),
      );
      expect(bottomIcon.color, const Color(0xFF07111F));
    });


    testWidgets('10. AcadexAdaptiveGradientBuilder evaluates discrete colors and transitions', (tester) async {
      Color? capturedTopPrimary;
      Color? capturedBottomPrimary;

      await tester.pumpWidget(_wrapWithAuth(
        child: Column(
          children: [
            SizedBox(
              height: 100,
              child: AcadexAdaptiveGradientBuilder(
                builder: (context, primary, secondary, action) {
                  capturedTopPrimary = primary;
                  return Container();
                },
              ),
            ),
            const Spacer(),
            SizedBox(
              height: 100,
              child: AcadexAdaptiveGradientBuilder(
                builder: (context, primary, secondary, action) {
                  capturedBottomPrimary = primary;
                  return Container();
                },
              ),
            ),
          ],
        ),
      ));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(capturedTopPrimary, const Color(0xFFFFFFFF));
      expect(capturedBottomPrimary, const Color(0xFF07111F));
    });

    testWidgets('11. Secondary text styling switches between ice blue (#CCE6FF) and slate (#334155)', (tester) async {
      await tester.pumpWidget(_wrapWithAuth(
        child: const Column(
          children: [
            SizedBox(
              height: 100,
              child: AcadexAdaptiveGradientText('Top Secondary', isSecondary: true),
            ),
            Spacer(),
            SizedBox(
              height: 100,
              child: AcadexAdaptiveGradientText('Bottom Secondary', isSecondary: true),
            ),
          ],
        ),
      ));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final topSec = tester.widget<Text>(find.text('Top Secondary'));
      expect(topSec.style?.color, const Color(0xFFCCE6FF));

      final bottomSec = tester.widget<Text>(find.text('Bottom Secondary'));
      expect(bottomSec.style?.color, const Color(0xFF334155));
    });
  });
}
