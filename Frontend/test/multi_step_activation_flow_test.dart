import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:campus_management/features/auth/domain/models/activation_model.dart';
import 'package:campus_management/features/auth/domain/repositories/activation_repository.dart';
import 'package:campus_management/features/auth/presentation/providers/activation_providers.dart';
import 'package:campus_management/features/auth/presentation/screens/activation_screen.dart';

class _FakeActivationRepository implements ActivationRepository {
  bool validateCodeCalled = false;
  String? lastValidatedCode;

  bool sendOtpCalled = false;
  String? lastFlowId;
  String? lastContactMethod;

  bool verifyOtpCalled = false;
  String? lastOtp;

  bool completeActivationCalled = false;
  String? lastActivationToken;
  String? lastPassword;
  String? lastConfirmPassword;

  ActivationValidationResult? validationResultToReturn;
  SendOtpResult? sendOtpResultToReturn;
  VerifyOtpResult? verifyOtpResultToReturn;
  CompleteActivationResult? completeResultToReturn;

  Exception? validateCodeException;
  Exception? sendOtpException;
  Exception? verifyOtpException;
  Exception? completeActivationException;

  @override
  Future<ActivationValidationResult> validateActivationCode(
    String activationCode,
  ) async {
    validateCodeCalled = true;
    lastValidatedCode = activationCode;
    if (validateCodeException != null) throw validateCodeException!;
    return validationResultToReturn ??
        const ActivationValidationResult(
          activationFlowId: 'flow-jwt-12345',
          displayName: 'Jane Doe',
          institutionName: 'SVGP Engineering College',
          collegeCode: 'SVGP',
          role: 'STUDENT',
          isExistingUser: false,
          contactOptions: [
            ContactOption(method: 'email', maskedValue: 'j***e@svgp.edu'),
            ContactOption(method: 'phone', maskedValue: '+919 ••••• ••210'),
          ],
          permittedNextAction: 'CONFIRM_IDENTITY_AND_SELECT_CONTACT',
        );
  }

  @override
  Future<SendOtpResult> sendActivationOtp({
    required String activationFlowId,
    required String contactMethod,
  }) async {
    sendOtpCalled = true;
    lastFlowId = activationFlowId;
    lastContactMethod = contactMethod;
    if (sendOtpException != null) throw sendOtpException!;
    return sendOtpResultToReturn ??
        const SendOtpResult(
          message: 'Verification code sent',
          maskedDestination: 'j***e@svgp.edu',
          cooldownSeconds: 60,
          expiresInSeconds: 600,
        );
  }

  @override
  Future<VerifyOtpResult> verifyActivationOtp({
    required String activationFlowId,
    required String contactMethod,
    required String otp,
  }) async {
    verifyOtpCalled = true;
    lastOtp = otp;
    if (verifyOtpException != null) throw verifyOtpException!;
    return verifyOtpResultToReturn ??
        const VerifyOtpResult(
          activationToken: 'token-completion-xyz789',
          isExistingActiveUser: false,
          message: 'Code verified successfully',
        );
  }

  @override
  Future<CompleteActivationResult> completeActivation({
    required String activationToken,
    String? password,
    String? confirmPassword,
  }) async {
    completeActivationCalled = true;
    lastActivationToken = activationToken;
    lastPassword = password;
    lastConfirmPassword = confirmPassword;
    if (completeActivationException != null) throw completeActivationException!;
    return completeResultToReturn ??
        const CompleteActivationResult(
          success: true,
          message:
              'Account activated successfully. You may now log in with your credentials.',
          user: {
            'id': 'u-1',
            'instituteId': 'STU-001',
            'role': 'STUDENT',
            'accountStatus': 'active',
          },
        );
  }
}

Widget createActivationTestApp({required ActivationRepository repository}) {
  final router = GoRouter(
    initialLocation: '/activate',
    routes: [
      GoRoute(
        path: '/activate',
        builder: (context, state) => const ActivationScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) =>
            const Scaffold(body: Text('Common Login Screen')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [activationRepositoryProvider.overrideWithValue(repository)],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  group('ACADEX Multi-Step Account Activation Flow (Prompt 4)', () {
    late _FakeActivationRepository fakeRepo;

    setUp(() {
      fakeRepo = _FakeActivationRepository();
    });

    testWidgets('A. Valid activation code proceeds after backend success', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createActivationTestApp(repository: fakeRepo));
      await tester.pumpAndSettle();

      expect(find.text('Activate Your Account'), findsOneWidget);
      expect(find.text('STEP 1 OF 5'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), 'SVGP-A1B2-C3D4');
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(fakeRepo.validateCodeCalled, isTrue);
      expect(fakeRepo.lastValidatedCode, equals('SVGP-A1B2-C3D4'));

      // Transitions to Step 2
      expect(find.text('Confirm Your Identity'), findsOneWidget);
      expect(find.text('STEP 2 OF 5'), findsOneWidget);
      expect(find.text('Jane Doe'), findsOneWidget);
      expect(find.text('SVGP Engineering College'), findsOneWidget);
      expect(find.text('Is this you?'), findsOneWidget);
    });

    testWidgets(
      'B. Invalid activation code displays an error and stays on Step 1',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 1000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        fakeRepo.validateCodeException = Exception(
          'Invalid or unknown activation code',
        );

        await tester.pumpWidget(createActivationTestApp(repository: fakeRepo));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextFormField), 'WRONG-CODE');
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        expect(
          find.text('Invalid or unknown activation code'),
          findsAtLeastNWidgets(1),
        );
        expect(find.text('Activate Your Account'), findsOneWidget);
        expect(find.text('STEP 1 OF 5'), findsOneWidget);
      },
    );

    testWidgets(
      'C. Expired invitation does not proceed and displays clear message',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 1000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        fakeRepo.validateCodeException = Exception(
          'This activation code has expired. Please contact your campus administrator for a new code.',
        );

        await tester.pumpWidget(createActivationTestApp(repository: fakeRepo));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextFormField), 'EXPIRED-CODE');
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        expect(
          find.text(
            'This activation code has expired. Please contact your campus administrator for a new code.',
          ),
          findsAtLeastNWidgets(1),
        );
        expect(find.text('Confirm Your Identity'), findsNothing);
      },
    );

    testWidgets(
      'D & E. Identity confirmation displays details and "This Isn\'t Me" clears state',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 1000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(createActivationTestApp(repository: fakeRepo));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextFormField), 'SVGP-A1B2-C3D4');
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        expect(find.text('Jane Doe'), findsOneWidget);
        expect(find.text('SVGP Engineering College'), findsOneWidget);
        expect(find.text('STUDENT'), findsOneWidget);

        // User selects "This Isn't Me"
        await tester.tap(find.text("This Isn't Me"));
        await tester.pumpAndSettle();

        // Returns to Step 1
        expect(find.text('Activate Your Account'), findsOneWidget);
        expect(find.text('STEP 1 OF 5'), findsOneWidget);
      },
    );

    testWidgets(
      'F & G. Contact selection sends OTP and OTP failure blocks password creation',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 1000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        fakeRepo.verifyOtpException = Exception(
          'Invalid verification code. 4 attempt(s) remaining.',
        );

        await tester.pumpWidget(createActivationTestApp(repository: fakeRepo));
        await tester.pumpAndSettle();

        // Step 1
        await tester.enterText(find.byType(TextFormField), 'SVGP-A1B2-C3D4');
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        // Step 2 -> Confirm identity
        await tester.tap(find.text('Yes, Continue'));
        await tester.pumpAndSettle();

        // Step 3 -> Select contact
        expect(find.text('Select Contact Method'), findsOneWidget);
        expect(find.text('STEP 3 OF 5'), findsOneWidget);
        expect(find.text('j***e@svgp.edu'), findsOneWidget);
        expect(find.text('+919 ••••• ••210'), findsOneWidget);

        await tester.tap(find.text('Send Verification Code'));
        await tester.pumpAndSettle();

        expect(fakeRepo.sendOtpCalled, isTrue);
        expect(fakeRepo.lastContactMethod, equals('email'));

        // Step 4 -> OTP Verification
        expect(find.text('Enter Verification Code'), findsOneWidget);
        expect(find.text('STEP 4 OF 5'), findsOneWidget);

        await tester.enterText(find.byType(TextFormField), '000000');
        await tester.tap(find.text('Verify Code'));
        await tester.pumpAndSettle();

        expect(fakeRepo.verifyOtpCalled, isTrue);
        expect(
          find.text('Invalid verification code. 4 attempt(s) remaining.'),
          findsAtLeastNWidgets(1),
        );

        // Remains on Step 4; Step 5 (Password) is inaccessible
        expect(find.text('Create Your Password'), findsNothing);
        expect(find.text('STEP 4 OF 5'), findsOneWidget);
      },
    );

    testWidgets(
      'H. OTP verification success unlocks password creation (Step 5)',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 1000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(createActivationTestApp(repository: fakeRepo));
        await tester.pumpAndSettle();

        // Steps 1 -> 2 -> 3 -> 4
        await tester.enterText(find.byType(TextFormField), 'SVGP-A1B2-C3D4');
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Yes, Continue'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Send Verification Code'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextFormField), '123456');
        await tester.tap(find.text('Verify Code'));
        await tester.pumpAndSettle();

        expect(fakeRepo.verifyOtpCalled, isTrue);
        expect(find.text('Create Your Password'), findsOneWidget);
        expect(find.text('STEP 5 OF 5'), findsOneWidget);
      },
    );

    testWidgets('J, K, L & M. Password matching and policy validation behavior', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createActivationTestApp(repository: fakeRepo));
      await tester.pumpAndSettle();

      // Navigate to Step 5
      await tester.enterText(find.byType(TextFormField), 'SVGP-A1B2-C3D4');
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Yes, Continue'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Send Verification Code'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), '123456');
      await tester.tap(find.text('Verify Code'));
      await tester.pumpAndSettle();

      // K. Both empty -> "Passwords matched" NOT displayed
      expect(find.text('Passwords matched'), findsNothing);

      final textFields = find.byType(TextFormField);
      expect(textFields, findsNWidgets(2));

      // J. Mismatched passwords -> "Passwords do not match" displayed, "Passwords matched" NOT displayed
      await tester.enterText(textFields.at(0), 'ValidPassword123!');
      await tester.enterText(textFields.at(1), 'DifferentPassword456!');
      await tester.pumpAndSettle();

      expect(find.text('Passwords matched'), findsNothing);
      expect(find.text('Passwords do not match'), findsOneWidget);

      // M. Matching but violates policy (< 8 chars) -> "Passwords matched" NOT displayed
      await tester.enterText(textFields.at(0), 'short');
      await tester.enterText(textFields.at(1), 'short');
      await tester.pumpAndSettle();

      expect(find.text('Passwords matched'), findsNothing);

      // L. Matching and meets policy -> Green "Passwords matched" IS displayed
      await tester.enterText(textFields.at(0), 'ValidActivationPass123!');
      await tester.enterText(textFields.at(1), 'ValidActivationPass123!');
      await tester.pumpAndSettle();

      expect(find.text('Passwords matched'), findsOneWidget);
      expect(find.text('Passwords do not match'), findsNothing);
    });

    testWidgets(
      'O. Completion success displays confirmation and routes to common login',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 1000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(createActivationTestApp(repository: fakeRepo));
        await tester.pumpAndSettle();

        // Steps 1 -> 2 -> 3 -> 4
        await tester.enterText(find.byType(TextFormField), 'SVGP-A1B2-C3D4');
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Yes, Continue'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Send Verification Code'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextFormField), '123456');
        await tester.tap(find.text('Verify Code'));
        await tester.pumpAndSettle();

        final textFields = find.byType(TextFormField);
        await tester.enterText(textFields.at(0), 'ValidActivationPass123!');
        await tester.enterText(textFields.at(1), 'ValidActivationPass123!');
        await tester.pumpAndSettle();

        await tester.tap(find.text('Activate Account'));
        await tester.pumpAndSettle();

        expect(fakeRepo.completeActivationCalled, isTrue);
        expect(fakeRepo.lastPassword, equals('ValidActivationPass123!'));

        // Step 6: Success state
        expect(find.text('Account Activated!'), findsOneWidget);

        // Step 7: Proceed to Sign In routes to /login
        await tester.tap(find.text('Proceed to Sign In'));
        await tester.pumpAndSettle();

        expect(find.text('Common Login Screen'), findsOneWidget);
      },
    );

    testWidgets(
      'P. Existing active user joining second workspace skips password creation',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 1000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        fakeRepo.validationResultToReturn = const ActivationValidationResult(
          activationFlowId: 'flow-jwt-col-b',
          displayName: 'Dr. Jane Existing',
          institutionName: 'Beta Institute of Technology',
          collegeCode: 'BETA',
          role: 'FACULTY',
          isExistingUser: true,
          contactOptions: [
            ContactOption(
              method: 'email',
              maskedValue: 'jane.existing@acadex.edu',
            ),
          ],
          permittedNextAction: 'CONFIRM_IDENTITY_AND_SELECT_CONTACT',
        );

        await tester.pumpWidget(createActivationTestApp(repository: fakeRepo));
        await tester.pumpAndSettle();

        // Step 1
        await tester.enterText(find.byType(TextFormField), 'BETA-FAC-001');
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        // Step 2
        expect(find.text('Dr. Jane Existing'), findsOneWidget);
        expect(find.text('Beta Institute of Technology'), findsOneWidget);
        await tester.tap(find.text('Yes, Continue'));
        await tester.pumpAndSettle();

        // Step 3
        await tester.tap(find.text('Send Verification Code'));
        await tester.pumpAndSettle();

        // Step 4
        await tester.enterText(find.byType(TextFormField), '123456');
        await tester.tap(find.text('Verify Code'));
        await tester.pumpAndSettle();

        // Step 5: Shows Workspace Access activation without password inputs
        expect(find.text('Activate Workspace Access'), findsAtLeastNWidgets(1));
        expect(find.text('Create Your Password'), findsNothing);
        expect(find.byType(TextFormField), findsNothing);

        await tester.tap(find.text('Activate Workspace Access').last);
        await tester.pumpAndSettle();

        expect(fakeRepo.completeActivationCalled, isTrue);
        expect(fakeRepo.lastPassword, isNull);
        expect(find.text('Account Activated!'), findsOneWidget);
      },
    );

    testWidgets(
      'S. Responsive layout does not overflow on small mobile screens',
      (tester) async {
        tester.view.physicalSize = const Size(
          360,
          640,
        ); // Compact mobile viewport
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(createActivationTestApp(repository: fakeRepo));
        await tester.pumpAndSettle();

        expect(find.text('Activate Your Account'), findsOneWidget);
      },
    );
  });
}
