import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_management/features/auth/presentation/screens/activation_screen.dart';

class _FakeActivationAuthNotifier extends StateNotifier<AuthState>
    implements AuthNotifier {
  _FakeActivationAuthNotifier([super.initial = const AuthUnauthenticated()]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  bool requestActivationOtpCalled = false;
  String? lastRequestedEmail;
  bool verifyActivationOtpCalled = false;
  String? lastVerifiedOtp;
  bool completeActivationCalled = false;
  String? lastActivationCode;
  String? lastPassword;

  bool shouldFailOtp = false;
  bool shouldFailActivation = false;
  String? customActivationError;

  Future<void> requestInstitutionalActivationOtp(String email) async {
    requestActivationOtpCalled = true;
    lastRequestedEmail = email;
  }

  Future<String> verifyInstitutionalActivationOtp({
    required String email,
    required String otp,
  }) async {
    verifyActivationOtpCalled = true;
    lastVerifiedOtp = otp;
    if (shouldFailOtp || otp == '999999') {
      throw Exception('Invalid or expired verification code');
    }
    return 'valid-inst-verification-token-xyz';
  }

  Future<Map<String, dynamic>> completeInstitutionalActivation({
    required String emailVerificationToken,
    required String activationCode,
    String? password,
    String? confirmPassword,
  }) async {
    completeActivationCalled = true;
    lastActivationCode = activationCode;
    lastPassword = password;

    if (shouldFailActivation || activationCode == 'INVALID-CODE') {
      throw Exception(
        customActivationError ?? 'Invalid or expired activation code',
      );
    }
    if (activationCode == 'MISMATCH-CODE') {
      throw Exception('Email does not match invitation record');
    }

    return {
      'success': true,
      'message': 'Institutional account activated successfully',
      'user': {
        'id': 'inst-user-1',
        'email': lastRequestedEmail ?? 'faculty@svgp.edu',
        'role': 'FACULTY',
        'collegeCode': 'SVGP',
        'instituteId': 'FAC-2026-001',
      },
    };
  }
}

Widget createActivationTestApp(
  Widget child, {
  List<dynamic> overrides = const [],
}) {
  final router = GoRouter(
    initialLocation: '/activate',
    routes: [
      GoRoute(path: '/activate', builder: (context, state) => child),
      GoRoute(
        path: '/login',
        builder: (context, state) => const Scaffold(body: Text('Login Screen')),
      ),
      GoRoute(
        path: '/dashboard/faculty',
        builder: (context, state) =>
            const Scaffold(body: Text('Faculty Dashboard')),
      ),
    ],
  );

  return ProviderScope(
    overrides: overrides.cast(),
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  group('ACADEX — Screen 4 Institutional Account Activation Vertical Slice Tests', () {
    testWidgets(
      '1. Screen 4 renders institutional email entry step with ACADEXSYNC branding',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 1000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final fakeAuth = _FakeActivationAuthNotifier();

        await tester.pumpWidget(
          createActivationTestApp(
            const ActivationScreen(
              initialFlowMode: ActivationFlowMode.emailFirst,
            ),
            overrides: [authProvider.overrideWith((ref) => fakeAuth)],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('ACADEXSYNC'), findsWidgets);
        expect(find.text('Activate Institutional Account'), findsOneWidget);
        expect(find.byKey(const Key('inst_email_field')), findsOneWidget);
        expect(
          find.byKey(const Key('inst_request_otp_button')),
          findsOneWidget,
        );
      },
    );

    testWidgets('2. Empty institutional email displays validation error', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final fakeAuth = _FakeActivationAuthNotifier();

      await tester.pumpWidget(
        createActivationTestApp(
          const ActivationScreen(
            initialFlowMode: ActivationFlowMode.emailFirst,
          ),
          overrides: [authProvider.overrideWith((ref) => fakeAuth)],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('inst_request_otp_button')));
      await tester.pumpAndSettle();

      expect(find.text('Please enter your email address'), findsOneWidget);
      expect(fakeAuth.requestActivationOtpCalled, isFalse);
    });

    testWidgets('3. Invalid email format displays validation error', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final fakeAuth = _FakeActivationAuthNotifier();

      await tester.pumpWidget(
        createActivationTestApp(
          const ActivationScreen(
            initialFlowMode: ActivationFlowMode.emailFirst,
          ),
          overrides: [authProvider.overrideWith((ref) => fakeAuth)],
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('inst_email_field')),
        'not-an-email',
      );
      await tester.tap(find.byKey(const Key('inst_request_otp_button')));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid email address'), findsOneWidget);
      expect(fakeAuth.requestActivationOtpCalled, isFalse);
    });

    testWidgets(
      '4. Valid email requests OTP and advances to dedicated code-entry step',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 1000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final fakeAuth = _FakeActivationAuthNotifier();

        await tester.pumpWidget(
          createActivationTestApp(
            const ActivationScreen(
              initialFlowMode: ActivationFlowMode.emailFirst,
            ),
            overrides: [authProvider.overrideWith((ref) => fakeAuth)],
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('inst_email_field')),
          'prof.sharma@svgp.edu',
        );
        await tester.tap(find.byKey(const Key('inst_request_otp_button')));
        await tester.pumpAndSettle();

        expect(fakeAuth.requestActivationOtpCalled, isTrue);
        expect(fakeAuth.lastRequestedEmail, equals('prof.sharma@svgp.edu'));

        // Step 2 elements visible
        expect(find.text('Verify Institutional Email'), findsOneWidget);
        expect(find.byKey(const Key('inst_otp_field')), findsOneWidget);
        expect(find.byKey(const Key('inst_verify_otp_button')), findsOneWidget);
        expect(find.textContaining('Resend available in'), findsOneWidget);
      },
    );

    testWidgets('5. Invalid OTP displays error message and stays on Step 2', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final fakeAuth = _FakeActivationAuthNotifier();
      fakeAuth.shouldFailOtp = true;

      await tester.pumpWidget(
        createActivationTestApp(
          const ActivationScreen(
            initialFlowMode: ActivationFlowMode.emailFirst,
          ),
          overrides: [authProvider.overrideWith((ref) => fakeAuth)],
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('inst_email_field')),
        'prof.sharma@svgp.edu',
      );
      await tester.tap(find.byKey(const Key('inst_request_otp_button')));
      await tester.pumpAndSettle();

      // Enter invalid OTP
      await tester.enterText(find.byKey(const Key('inst_otp_field')), '999999');
      await tester.tap(find.byKey(const Key('inst_verify_otp_button')));
      await tester.pumpAndSettle();

      expect(fakeAuth.verifyActivationOtpCalled, isTrue);
      expect(
        find.textContaining('Invalid or expired verification code'),
        findsOneWidget,
      );
      expect(find.text('Activation Code & Security'), findsNothing);
    });

    testWidgets(
      '6. Valid OTP verifies and unlocks activation code and password entry (Step 3)',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 1000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final fakeAuth = _FakeActivationAuthNotifier();

        await tester.pumpWidget(
          createActivationTestApp(
            const ActivationScreen(
              initialFlowMode: ActivationFlowMode.emailFirst,
            ),
            overrides: [authProvider.overrideWith((ref) => fakeAuth)],
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('inst_email_field')),
          'prof.sharma@svgp.edu',
        );
        await tester.tap(find.byKey(const Key('inst_request_otp_button')));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('inst_otp_field')),
          '123456',
        );
        await tester.tap(find.byKey(const Key('inst_verify_otp_button')));
        await tester.pumpAndSettle();

        expect(fakeAuth.verifyActivationOtpCalled, isTrue);
        expect(find.text('Activation Code & Security'), findsOneWidget);
        expect(find.byKey(const Key('inst_code_field')), findsOneWidget);
        expect(find.byKey(const Key('inst_password_field')), findsOneWidget);
        expect(
          find.byKey(const Key('inst_confirm_password_field')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('inst_complete_button')), findsOneWidget);
      },
    );

    testWidgets('7. Password mismatch displays validation feedback in Step 3', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final fakeAuth = _FakeActivationAuthNotifier();

      await tester.pumpWidget(
        createActivationTestApp(
          const ActivationScreen(
            initialFlowMode: ActivationFlowMode.emailFirst,
          ),
          overrides: [authProvider.overrideWith((ref) => fakeAuth)],
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('inst_email_field')),
        'prof.sharma@svgp.edu',
      );
      await tester.tap(find.byKey(const Key('inst_request_otp_button')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('inst_otp_field')), '123456');
      await tester.tap(find.byKey(const Key('inst_verify_otp_button')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('inst_code_field')),
        'SVGP-ABCD-1234',
      );
      await tester.enterText(
        find.byKey(const Key('inst_password_field')),
        'SecureP@ss123',
      );
      await tester.enterText(
        find.byKey(const Key('inst_confirm_password_field')),
        'DifferentP@ss123',
      );

      await tester.ensureVisible(find.byKey(const Key('inst_complete_button')));
      await tester.tap(find.byKey(const Key('inst_complete_button')));
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match'), findsOneWidget);
      expect(fakeAuth.completeActivationCalled, isFalse);
    });

    testWidgets(
      '8. Mismatched email or expired code shows generic error banner without data leak',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 1000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final fakeAuth = _FakeActivationAuthNotifier();

        await tester.pumpWidget(
          createActivationTestApp(
            const ActivationScreen(
              initialFlowMode: ActivationFlowMode.emailFirst,
            ),
            overrides: [authProvider.overrideWith((ref) => fakeAuth)],
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('inst_email_field')),
          'other@svgp.edu',
        );
        await tester.tap(find.byKey(const Key('inst_request_otp_button')));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('inst_otp_field')),
          '123456',
        );
        await tester.tap(find.byKey(const Key('inst_verify_otp_button')));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('inst_code_field')),
          'MISMATCH-CODE',
        );
        await tester.enterText(
          find.byKey(const Key('inst_password_field')),
          'SecureP@ss123',
        );
        await tester.enterText(
          find.byKey(const Key('inst_confirm_password_field')),
          'SecureP@ss123',
        );

        await tester.ensureVisible(
          find.byKey(const Key('inst_complete_button')),
        );
        await tester.tap(find.byKey(const Key('inst_complete_button')));
        await tester.pumpAndSettle();

        expect(fakeAuth.completeActivationCalled, isTrue);
        expect(
          find.textContaining(
            'This activation code was issued to a different email address',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '9. Successful activation displays authoritative institution and role assignment card',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 1000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final fakeAuth = _FakeActivationAuthNotifier();

        await tester.pumpWidget(
          createActivationTestApp(
            const ActivationScreen(
              initialFlowMode: ActivationFlowMode.emailFirst,
            ),
            overrides: [authProvider.overrideWith((ref) => fakeAuth)],
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('inst_email_field')),
          'prof.sharma@svgp.edu',
        );
        await tester.tap(find.byKey(const Key('inst_request_otp_button')));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('inst_otp_field')),
          '123456',
        );
        await tester.tap(find.byKey(const Key('inst_verify_otp_button')));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('inst_code_field')),
          'SVGP-ABCD-1234',
        );
        await tester.enterText(
          find.byKey(const Key('inst_password_field')),
          'SecureP@ss123',
        );
        await tester.enterText(
          find.byKey(const Key('inst_confirm_password_field')),
          'SecureP@ss123',
        );

        await tester.ensureVisible(
          find.byKey(const Key('inst_complete_button')),
        );
        await tester.tap(find.byKey(const Key('inst_complete_button')));
        await tester.pumpAndSettle();

        expect(fakeAuth.completeActivationCalled, isTrue);
        expect(find.text('Institutional Account Activated!'), findsOneWidget);
        expect(find.text('Institution Code: SVGP'), findsOneWidget);
        expect(find.text('FACULTY'), findsOneWidget);
        expect(find.text('Institute ID: FAC-2026-001'), findsOneWidget);
        expect(
          find.byKey(const Key('inst_success_action_button')),
          findsOneWidget,
        );

        // Tap Proceed to Sign In
        await tester.tap(find.byKey(const Key('inst_success_action_button')));
        await tester.pumpAndSettle();

        expect(find.text('Login Screen'), findsOneWidget);
      },
    );

    testWidgets('10. Small mobile screen layout renders without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final fakeAuth = _FakeActivationAuthNotifier();

      await tester.pumpWidget(
        createActivationTestApp(
          const ActivationScreen(
            initialFlowMode: ActivationFlowMode.emailFirst,
          ),
          overrides: [authProvider.overrideWith((ref) => fakeAuth)],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('inst_email_field')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
