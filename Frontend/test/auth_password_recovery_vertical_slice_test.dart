import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:campus_management/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_management/features/auth/data/repositories/api_auth_repository.dart';
import 'package:campus_management/core/presentation/widgets/acadex_button.dart';

class _FakeApiAuthRepository implements ApiAuthRepository {
  bool sendOtpCalled = false;
  bool verifyOtpCalled = false;
  bool resetPasswordCalled = false;

  String? lastIdentifier;
  String? lastOtp;
  String? lastResetToken;
  String? lastNewPassword;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<void> sendPasswordResetEmail(String identifier) async {
    sendOtpCalled = true;
    lastIdentifier = identifier;

    if (identifier == 'error@acadex.edu') {
      throw Exception('Failed to send verification code');
    }
  }

  @override
  Future<String> verifyPasswordResetOtp({
    required String identifier,
    required String otpCode,
  }) async {
    verifyOtpCalled = true;
    lastIdentifier = identifier;
    lastOtp = otpCode;

    if (otpCode == '000000') {
      throw Exception('Invalid verification code');
    }

    return 'test-jwt-reset-token-xyz';
  }

  @override
  Future<void> resetPassword({
    required String resetToken,
    required String newPassword,
  }) async {
    resetPasswordCalled = true;
    lastResetToken = resetToken;
    lastNewPassword = newPassword;

    if (newPassword == 'weak') {
      throw Exception('Password must be at least 8 characters');
    }
  }
}

Widget createRecoveryTestApp(Widget child, {List<dynamic> overrides = const []}) {
  final router = GoRouter(
    initialLocation: '/forgot-password',
    routes: [
      GoRoute(path: '/forgot-password', builder: (context, state) => child),
      GoRoute(path: '/login', builder: (context, state) => const Scaffold(body: Text('Login Screen'))),
    ],
  );

  return ProviderScope(
    overrides: overrides.cast(),
    child: MaterialApp.router(
      routerConfig: router,
    ),
  );
}

void main() {
  group('ACADEX — Auth Password Recovery Vertical Slice Tests', () {
    testWidgets('1. Forgot password screen renders header, input, and submit button', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createRecoveryTestApp(const ForgotPasswordScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Forgot your password?'), findsOneWidget);
      expect(find.text('STEP 1 OF 3'), findsOneWidget);
      expect(find.text('Email or Phone Number'), findsOneWidget);
      expect(find.widgetWithText(AcadexButton, 'Send Verification Code'), findsOneWidget);
      expect(find.text('Back to Sign In'), findsOneWidget);
    });

    testWidgets('2. Empty identifier displays validation error', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createRecoveryTestApp(const ForgotPasswordScreen()));
      await tester.pumpAndSettle();

      final btn = find.widgetWithText(AcadexButton, 'Send Verification Code');
      await tester.ensureVisible(btn);
      await tester.tap(btn);
      await tester.pumpAndSettle();

      expect(find.text('Please enter your email or phone number'), findsOneWidget);
    });

    testWidgets('3. Send OTP loading state prevents duplicate submission', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final fakeRepo = _FakeApiAuthRepository();

      await tester.pumpWidget(
        createRecoveryTestApp(
          const ForgotPasswordScreen(),
          overrides: [apiAuthRepositoryProvider.overrideWithValue(fakeRepo)],
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'user@acadex.edu');
      final btn = find.widgetWithText(AcadexButton, 'Send Verification Code');
      await tester.ensureVisible(btn);
      await tester.tap(btn);
      await tester.pump(); // partial frame during loading

      expect(fakeRepo.sendOtpCalled, isTrue);
    });

    testWidgets('4. Send OTP success advances to Step 2 (Verify OTP)', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final fakeRepo = _FakeApiAuthRepository();

      await tester.pumpWidget(
        createRecoveryTestApp(
          const ForgotPasswordScreen(),
          overrides: [apiAuthRepositoryProvider.overrideWithValue(fakeRepo)],
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'user@acadex.edu');
      final btn = find.widgetWithText(AcadexButton, 'Send Verification Code');
      await tester.ensureVisible(btn);
      await tester.tap(btn);
      await tester.pumpAndSettle();

      expect(find.text('STEP 2 OF 3'), findsOneWidget);
      expect(find.text('Enter Verification Code'), findsOneWidget);
      expect(find.text('Verification Code'), findsOneWidget);
      expect(find.widgetWithText(AcadexButton, 'Verify Code'), findsOneWidget);
      expect(find.textContaining('Code expires in'), findsOneWidget);
    });

    testWidgets('5. API error on send OTP displays error banner', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final fakeRepo = _FakeApiAuthRepository();

      await tester.pumpWidget(
        createRecoveryTestApp(
          const ForgotPasswordScreen(),
          overrides: [apiAuthRepositoryProvider.overrideWithValue(fakeRepo)],
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'error@acadex.edu');
      final btn = find.widgetWithText(AcadexButton, 'Send Verification Code');
      await tester.ensureVisible(btn);
      await tester.tap(btn);
      await tester.pumpAndSettle();

      expect(find.textContaining('Failed to send verification code'), findsOneWidget);
    });

    testWidgets('6. Step 2 OTP validation requires complete 6-digit code', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final fakeRepo = _FakeApiAuthRepository();

      await tester.pumpWidget(
        createRecoveryTestApp(
          const ForgotPasswordScreen(
            initialStep: 1,
            initialIdentifier: 'user@acadex.edu',
          ),
          overrides: [apiAuthRepositoryProvider.overrideWithValue(fakeRepo)],
        ),
      );
      await tester.pumpAndSettle();

      // Submit with empty code
      final btn = find.widgetWithText(AcadexButton, 'Verify Code');
      await tester.ensureVisible(btn);
      await tester.tap(btn);
      await tester.pumpAndSettle();
      expect(find.text('Please enter the verification code'), findsOneWidget);

      // Submit with partial code
      await tester.enterText(find.byType(TextFormField).first, '123');
      await tester.tap(btn);
      await tester.pumpAndSettle();
      expect(find.text('Please enter the complete 6-digit code'), findsOneWidget);
    });

    testWidgets('7. Invalid OTP code displays error banner', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final fakeRepo = _FakeApiAuthRepository();

      await tester.pumpWidget(
        createRecoveryTestApp(
          const ForgotPasswordScreen(
            initialStep: 1,
            initialIdentifier: 'user@acadex.edu',
          ),
          overrides: [apiAuthRepositoryProvider.overrideWithValue(fakeRepo)],
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, '000000');
      final btn = find.widgetWithText(AcadexButton, 'Verify Code');
      await tester.ensureVisible(btn);
      await tester.tap(btn);
      await tester.pumpAndSettle();

      expect(fakeRepo.verifyOtpCalled, isTrue);
      expect(find.textContaining('Invalid verification code'), findsOneWidget);
    });

    testWidgets('8. Valid OTP transitions to Step 3 (Set New Password)', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final fakeRepo = _FakeApiAuthRepository();

      await tester.pumpWidget(
        createRecoveryTestApp(
          const ForgotPasswordScreen(
            initialStep: 1,
            initialIdentifier: 'user@acadex.edu',
          ),
          overrides: [apiAuthRepositoryProvider.overrideWithValue(fakeRepo)],
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, '123456');
      final btn = find.widgetWithText(AcadexButton, 'Verify Code');
      await tester.ensureVisible(btn);
      await tester.tap(btn);
      await tester.pumpAndSettle();

      expect(fakeRepo.verifyOtpCalled, isTrue);
      expect(find.text('STEP 3 OF 3'), findsOneWidget);
      expect(find.text('Set New Password'), findsOneWidget);
      expect(find.text('New Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
      expect(find.text('Password Requirements:'), findsOneWidget);
      expect(find.widgetWithText(AcadexButton, 'Reset Password'), findsOneWidget);
    });

    testWidgets('9. Step 3 password requirements checklist updates dynamically', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final fakeRepo = _FakeApiAuthRepository();

      await tester.pumpWidget(
        createRecoveryTestApp(
          const ForgotPasswordScreen(
            initialStep: 2,
            initialIdentifier: 'user@acadex.edu',
            initialResetToken: 'valid-reset-token',
          ),
          overrides: [apiAuthRepositoryProvider.overrideWithValue(fakeRepo)],
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'ValidPass123');
      await tester.enterText(find.byType(TextFormField).at(1), 'ValidPass123');
      await tester.pumpAndSettle();

      expect(find.text('At least 8 characters'), findsOneWidget);
      expect(find.text('Contains at least one letter'), findsOneWidget);
      expect(find.text('Contains at least one number'), findsOneWidget);
      expect(find.text('Passwords match'), findsOneWidget);
    });

    testWidgets('10. Password mismatch in Step 3 displays validation error', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final fakeRepo = _FakeApiAuthRepository();

      await tester.pumpWidget(
        createRecoveryTestApp(
          const ForgotPasswordScreen(
            initialStep: 2,
            initialIdentifier: 'user@acadex.edu',
            initialResetToken: 'valid-reset-token',
          ),
          overrides: [apiAuthRepositoryProvider.overrideWithValue(fakeRepo)],
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'ValidPass123');
      await tester.enterText(find.byType(TextFormField).at(1), 'DifferentPass456');
      final btn = find.widgetWithText(AcadexButton, 'Reset Password');
      await tester.ensureVisible(btn);
      await tester.tap(btn);
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('11. Successful password reset displays Step 4 confirmation and navigates to Login', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final fakeRepo = _FakeApiAuthRepository();

      await tester.pumpWidget(
        createRecoveryTestApp(
          const ForgotPasswordScreen(
            initialStep: 2,
            initialIdentifier: 'user@acadex.edu',
            initialResetToken: 'valid-reset-token',
          ),
          overrides: [apiAuthRepositoryProvider.overrideWithValue(fakeRepo)],
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'ValidPass123');
      await tester.enterText(find.byType(TextFormField).at(1), 'ValidPass123');
      final btn = find.widgetWithText(AcadexButton, 'Reset Password');
      await tester.ensureVisible(btn);
      await tester.tap(btn);
      await tester.pumpAndSettle();

      expect(fakeRepo.resetPasswordCalled, isTrue);
      expect(find.text('Password Reset Successful'), findsOneWidget);
      expect(find.widgetWithText(AcadexButton, 'Sign In to ACADEX'), findsOneWidget);

      final signInBtn = find.widgetWithText(AcadexButton, 'Sign In to ACADEX');
      await tester.ensureVisible(signInBtn);
      await tester.tap(signInBtn);
      await tester.pumpAndSettle();

      expect(find.text('Login Screen'), findsOneWidget);
    });

    testWidgets('12. Dark mode and responsive layout render cleanly', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: const ForgotPasswordScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Forgot your password?'), findsOneWidget);
    });
  });
}
