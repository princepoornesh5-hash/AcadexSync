import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_management/features/auth/presentation/screens/registration_screen.dart';

class _FakeRegistrationAuthNotifier extends StateNotifier<AuthState>
    implements AuthNotifier {
  _FakeRegistrationAuthNotifier([super.initial = const AuthUnauthenticated()]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  bool requestOtpCalled = false;
  String? lastRequestedEmail;
  bool verifyOtpCalled = false;
  String? lastVerifiedEmail;
  String? lastVerifiedOtp;
  bool completeRegistrationCalled = false;
  String? lastRegistrationToken;
  String? lastPassword;
  String? lastName;

  bool shouldFailOtp = false;
  bool shouldFailCompletion = false;

  Future<void> requestRegistrationOtp(String email) async {
    requestOtpCalled = true;
    lastRequestedEmail = email;
  }

  Future<String> verifyRegistrationOtp({
    required String email,
    required String otp,
  }) async {
    verifyOtpCalled = true;
    lastVerifiedEmail = email;
    lastVerifiedOtp = otp;
    if (shouldFailOtp || otp == '999999') {
      throw Exception('Invalid or expired verification code');
    }
    return 'valid-reg-token-xyz-123';
  }

  Future<void> completeRegistration({
    required String registrationToken,
    required String password,
    required String confirmPassword,
    String? name,
  }) async {
    completeRegistrationCalled = true;
    lastRegistrationToken = registrationToken;
    lastPassword = password;
    lastName = name;

    if (shouldFailCompletion) {
      state = const AuthError(message: 'Registration request failed');
      throw Exception('Registration request failed');
    }

    state = AuthAuthenticated(
      user: UserModel(
        id: 'new-user-1',
        name: name ?? 'New User',
        email: lastRequestedEmail ?? 'student@example.com',
        role: AppRole.student,
        accountStatus: AccountStatus.active,
      ),
      token: 'new-user-jwt-token',
    );
  }
}

Widget createRegistrationTestApp(
  Widget child, {
  List<dynamic> overrides = const [],
}) {
  final router = GoRouter(
    initialLocation: '/register',
    routes: [
      GoRoute(path: '/register', builder: (context, state) => child),
      GoRoute(
        path: '/login',
        builder: (context, state) => const Scaffold(body: Text('Login Screen')),
      ),
      GoRoute(
        path: '/dashboard/student',
        builder: (context, state) =>
            const Scaffold(body: Text('Student Dashboard')),
      ),
    ],
  );

  return ProviderScope(
    overrides: overrides.cast(),
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  group('ACADEX — Screen 3 Registration Flow Tests', () {
    testWidgets(
      '1. Screen 3 renders Step 1 with ACADEXSYNC branding, name, email and action',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 1000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final fakeAuth = _FakeRegistrationAuthNotifier();

        await tester.pumpWidget(
          createRegistrationTestApp(
            const RegistrationScreen(),
            overrides: [authProvider.overrideWith((ref) => fakeAuth)],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('ACADEXSYNC'), findsWidgets);
        expect(find.text('Create Account'), findsOneWidget);
        expect(find.byKey(const Key('reg_name_field')), findsOneWidget);
        expect(find.byKey(const Key('reg_email_field')), findsOneWidget);
        expect(find.byKey(const Key('reg_request_otp_button')), findsOneWidget);
        expect(find.text('Already have an account? Sign In'), findsOneWidget);
      },
    );

    testWidgets(
      '2. Empty name and email trigger validation feedback in Step 1',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 1000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final fakeAuth = _FakeRegistrationAuthNotifier();

        await tester.pumpWidget(
          createRegistrationTestApp(
            const RegistrationScreen(),
            overrides: [authProvider.overrideWith((ref) => fakeAuth)],
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('reg_request_otp_button')));
        await tester.pumpAndSettle();

        expect(find.text('Please enter your full name'), findsOneWidget);
        expect(find.text('Please enter your email address'), findsOneWidget);
        expect(fakeAuth.requestOtpCalled, isFalse);
      },
    );

    testWidgets('3. Invalid email syntax triggers validation error', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final fakeAuth = _FakeRegistrationAuthNotifier();

      await tester.pumpWidget(
        createRegistrationTestApp(
          const RegistrationScreen(),
          overrides: [authProvider.overrideWith((ref) => fakeAuth)],
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('reg_name_field')),
        'Pooja Verma',
      );
      await tester.enterText(
        find.byKey(const Key('reg_email_field')),
        'pooja-not-an-email',
      );
      await tester.tap(find.byKey(const Key('reg_request_otp_button')));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid email address'), findsOneWidget);
      expect(fakeAuth.requestOtpCalled, isFalse);
    });

    testWidgets(
      '4. Valid name and email requests OTP and transitions to Step 2',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 1000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final fakeAuth = _FakeRegistrationAuthNotifier();

        await tester.pumpWidget(
          createRegistrationTestApp(
            const RegistrationScreen(),
            overrides: [authProvider.overrideWith((ref) => fakeAuth)],
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('reg_name_field')),
          'Pooja Verma',
        );
        await tester.enterText(
          find.byKey(const Key('reg_email_field')),
          'pooja.verma@example.com',
        );
        await tester.tap(find.byKey(const Key('reg_request_otp_button')));
        await tester.pumpAndSettle();

        expect(fakeAuth.requestOtpCalled, isTrue);
        expect(fakeAuth.lastRequestedEmail, equals('pooja.verma@example.com'));

        // Step 2 elements visible
        expect(find.text('Verify Your Email'), findsOneWidget);
        expect(find.byKey(const Key('reg_otp_field')), findsOneWidget);
        expect(find.byKey(const Key('reg_verify_otp_button')), findsOneWidget);
        expect(find.textContaining('Resend available in'), findsOneWidget);
      },
    );

    testWidgets(
      '5. Step 2 back button returns to Step 1 preserving entered details',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 1000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final fakeAuth = _FakeRegistrationAuthNotifier();

        await tester.pumpWidget(
          createRegistrationTestApp(
            const RegistrationScreen(),
            overrides: [authProvider.overrideWith((ref) => fakeAuth)],
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('reg_name_field')),
          'Pooja Verma',
        );
        await tester.enterText(
          find.byKey(const Key('reg_email_field')),
          'pooja.verma@example.com',
        );
        await tester.tap(find.byKey(const Key('reg_request_otp_button')));
        await tester.pumpAndSettle();

        // Tap back arrow on Step 2
        await tester.tap(find.byIcon(LucideIcons.arrowLeft).first);
        await tester.pumpAndSettle();

        expect(find.text('Create Account'), findsOneWidget);
        expect(find.byKey(const Key('reg_name_field')), findsOneWidget);
        expect(find.text('Pooja Verma'), findsOneWidget);
        expect(find.text('pooja.verma@example.com'), findsOneWidget);
      },
    );

    testWidgets('6. Invalid OTP in Step 2 shows error and stays on Step 2', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final fakeAuth = _FakeRegistrationAuthNotifier();
      fakeAuth.shouldFailOtp = true;

      await tester.pumpWidget(
        createRegistrationTestApp(
          const RegistrationScreen(),
          overrides: [authProvider.overrideWith((ref) => fakeAuth)],
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('reg_name_field')),
        'Pooja Verma',
      );
      await tester.enterText(
        find.byKey(const Key('reg_email_field')),
        'pooja.verma@example.com',
      );
      await tester.tap(find.byKey(const Key('reg_request_otp_button')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('reg_otp_field')), '999999');
      await tester.tap(find.byKey(const Key('reg_verify_otp_button')));
      await tester.pumpAndSettle();

      expect(fakeAuth.verifyOtpCalled, isTrue);
      expect(
        find.textContaining('Invalid or expired verification code'),
        findsOneWidget,
      );
      expect(find.text('Secure Your Account'), findsNothing);
    });

    testWidgets(
      '7. Valid OTP verifies and advances to Step 3 (Password Setup)',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 1000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final fakeAuth = _FakeRegistrationAuthNotifier();

        await tester.pumpWidget(
          createRegistrationTestApp(
            const RegistrationScreen(),
            overrides: [authProvider.overrideWith((ref) => fakeAuth)],
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('reg_name_field')),
          'Pooja Verma',
        );
        await tester.enterText(
          find.byKey(const Key('reg_email_field')),
          'pooja.verma@example.com',
        );
        await tester.tap(find.byKey(const Key('reg_request_otp_button')));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('reg_otp_field')),
          '123456',
        );
        await tester.tap(find.byKey(const Key('reg_verify_otp_button')));
        await tester.pumpAndSettle();

        expect(fakeAuth.verifyOtpCalled, isTrue);
        expect(find.text('Secure Your Account'), findsOneWidget);
        expect(find.byKey(const Key('reg_password_field')), findsOneWidget);
        expect(
          find.byKey(const Key('reg_confirm_password_field')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('reg_complete_button')), findsOneWidget);
      },
    );

    testWidgets(
      '8. Password validation checks minimum length and matching passwords',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 1000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final fakeAuth = _FakeRegistrationAuthNotifier();

        await tester.pumpWidget(
          createRegistrationTestApp(
            const RegistrationScreen(),
            overrides: [authProvider.overrideWith((ref) => fakeAuth)],
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('reg_name_field')),
          'Pooja Verma',
        );
        await tester.enterText(
          find.byKey(const Key('reg_email_field')),
          'pooja.verma@example.com',
        );
        await tester.tap(find.byKey(const Key('reg_request_otp_button')));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('reg_otp_field')),
          '123456',
        );
        await tester.tap(find.byKey(const Key('reg_verify_otp_button')));
        await tester.pumpAndSettle();

        // Test short password
        await tester.enterText(
          find.byKey(const Key('reg_password_field')),
          'short',
        );
        await tester.enterText(
          find.byKey(const Key('reg_confirm_password_field')),
          'short',
        );
        await tester.ensureVisible(
          find.byKey(const Key('reg_complete_button')),
        );
        await tester.tap(find.byKey(const Key('reg_complete_button')));
        await tester.pumpAndSettle();

        expect(
          find.text('Password must be at least 8 characters long'),
          findsOneWidget,
        );
        expect(fakeAuth.completeRegistrationCalled, isFalse);

        // Test mismatch password
        await tester.enterText(
          find.byKey(const Key('reg_password_field')),
          'ValidPassword1',
        );
        await tester.enterText(
          find.byKey(const Key('reg_confirm_password_field')),
          'MismatchPass2',
        );
        await tester.tap(find.byKey(const Key('reg_complete_button')));
        await tester.pumpAndSettle();

        expect(find.text('Passwords do not match'), findsOneWidget);
        expect(fakeAuth.completeRegistrationCalled, isFalse);
      },
    );

    testWidgets(
      '9. Successful registration completes and navigates to Student dashboard',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 1000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final fakeAuth = _FakeRegistrationAuthNotifier();

        await tester.pumpWidget(
          createRegistrationTestApp(
            const RegistrationScreen(),
            overrides: [authProvider.overrideWith((ref) => fakeAuth)],
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('reg_name_field')),
          'Pooja Verma',
        );
        await tester.enterText(
          find.byKey(const Key('reg_email_field')),
          'pooja.verma@example.com',
        );
        await tester.tap(find.byKey(const Key('reg_request_otp_button')));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('reg_otp_field')),
          '123456',
        );
        await tester.tap(find.byKey(const Key('reg_verify_otp_button')));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('reg_password_field')),
          'SecureP@ssword123',
        );
        await tester.enterText(
          find.byKey(const Key('reg_confirm_password_field')),
          'SecureP@ssword123',
        );
        await tester.ensureVisible(
          find.byKey(const Key('reg_complete_button')),
        );
        await tester.tap(find.byKey(const Key('reg_complete_button')));
        await tester.pumpAndSettle();

        expect(fakeAuth.completeRegistrationCalled, isTrue);
        expect(fakeAuth.lastName, equals('Pooja Verma'));
        expect(fakeAuth.state, isA<AuthAuthenticated>());
        final auth = fakeAuth.state as AuthAuthenticated;
        expect(auth.user.role, equals(AppRole.student));
        expect(find.text('Student Dashboard'), findsOneWidget);
      },
    );

    testWidgets(
      '10. Responsive layout renders cleanly on small screen without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final fakeAuth = _FakeRegistrationAuthNotifier();

        await tester.pumpWidget(
          createRegistrationTestApp(
            const RegistrationScreen(),
            overrides: [authProvider.overrideWith((ref) => fakeAuth)],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('reg_name_field')), findsOneWidget);
        expect(find.byKey(const Key('reg_email_field')), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
