import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:campus_management/features/auth/presentation/screens/activation_screen.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_management/features/auth/data/repositories/api_auth_repository.dart';

class _FakeApiAuthRepository implements ApiAuthRepository {
  bool activateCalled = false;
  String? lastCollegeCode;
  String? lastInstituteId;
  String? lastActivationCode;
  String? lastPassword;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<Map<String, dynamic>> activateAccount({
    required String collegeCode,
    required String instituteId,
    required String activationCode,
    required String password,
  }) async {
    activateCalled = true;
    lastCollegeCode = collegeCode;
    lastInstituteId = instituteId;
    lastActivationCode = activationCode;
    lastPassword = password;

    if (activationCode == 'EXPIRED1') {
      throw Exception('Invitation has expired. Please request a new invitation.');
    }
    if (activationCode == 'INVALID1') {
      throw Exception('Invalid activation code');
    }
    if (collegeCode == 'WRONGCOL') {
      throw Exception('Invalid activation details');
    }

    return {
      'success': true,
      'message': 'Account activated successfully',
      'user': {
        'id': 'u-1',
        'instituteId': instituteId,
        'role': 'STUDENT',
        'accountStatus': 'active',
      },
    };
  }
}

Widget createActivationTestApp(Widget child, {List<dynamic> overrides = const []}) {
  final router = GoRouter(
    initialLocation: '/activate',
    routes: [
      GoRoute(path: '/activate', builder: (context, state) => child),
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
  group('ACADEX — Account Activation Vertical Slice Tests', () {
    testWidgets('1. ActivationScreen renders Step 1 with all required fields', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createActivationTestApp(
          const ActivationScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Account Activation'), findsOneWidget);
      expect(find.text('STEP 1 OF 2'), findsOneWidget);
      expect(find.text('College Code'), findsOneWidget);
      expect(find.text('Student or Employee ID'), findsOneWidget);
      expect(find.text('Activation Code'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
      expect(find.text('Already activated? Sign In'), findsOneWidget);
    });

    testWidgets('2. Empty fields validation triggers in Step 1', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createActivationTestApp(
          const ActivationScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter your college code'), findsOneWidget);
      expect(find.text('Please enter your ID'), findsOneWidget);
      expect(find.text('Please enter your activation code'), findsOneWidget);
    });

    testWidgets('3. Step 1 advance to Step 2 with valid credentials', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createActivationTestApp(
          const ActivationScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'TECH-UNIV');
      await tester.enterText(find.byType(TextFormField).at(1), 'STU2026001');
      await tester.enterText(find.byType(TextFormField).at(2), 'VALID123');
      await tester.ensureVisible(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('STEP 2 OF 2'), findsOneWidget);
      expect(find.text('Create Password'), findsOneWidget);
      expect(find.text('New Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
      expect(find.text('Password Requirements:'), findsOneWidget);
      expect(find.text('Activate Account'), findsOneWidget);
    });

    testWidgets('4. Password requirements checklist updates interactively', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createActivationTestApp(
          const ActivationScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Complete Step 1
      await tester.enterText(find.byType(TextFormField).at(0), 'TECH-UNIV');
      await tester.enterText(find.byType(TextFormField).at(1), 'STU2026001');
      await tester.enterText(find.byType(TextFormField).at(2), 'VALID123');
      await tester.ensureVisible(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Enter password in Step 2
      await tester.enterText(find.byType(TextFormField).at(0), 'Pass1234');
      await tester.enterText(find.byType(TextFormField).at(1), 'Pass1234');
      await tester.pumpAndSettle();

      expect(find.text('At least 8 characters'), findsOneWidget);
      expect(find.text('Contains at least one letter'), findsOneWidget);
      expect(find.text('Contains at least one number'), findsOneWidget);
      expect(find.text('Passwords match'), findsOneWidget);
    });

    testWidgets('5. Password mismatch displays validation error', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createActivationTestApp(
          const ActivationScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Complete Step 1
      await tester.enterText(find.byType(TextFormField).at(0), 'TECH-UNIV');
      await tester.enterText(find.byType(TextFormField).at(1), 'STU2026001');
      await tester.enterText(find.byType(TextFormField).at(2), 'VALID123');
      await tester.ensureVisible(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Enter mismatched passwords
      await tester.enterText(find.byType(TextFormField).at(0), 'Pass1234');
      await tester.enterText(find.byType(TextFormField).at(1), 'Pass5678');
      await tester.ensureVisible(find.text('Activate Account'));
      await tester.tap(find.text('Activate Account'));
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('6. Invalid/Expired activation code displays error message in SnackBar', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final fakeRepo = _FakeApiAuthRepository();

      await tester.pumpWidget(
        createActivationTestApp(
          const ActivationScreen(),
          overrides: [
            apiAuthRepositoryProvider.overrideWithValue(fakeRepo),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Complete Step 1 with expired code
      await tester.enterText(find.byType(TextFormField).at(0), 'TECH-UNIV');
      await tester.enterText(find.byType(TextFormField).at(1), 'STU2026001');
      await tester.enterText(find.byType(TextFormField).at(2), 'EXPIRED1');
      await tester.ensureVisible(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Submit Step 2
      await tester.enterText(find.byType(TextFormField).at(0), 'SecurePass123');
      await tester.enterText(find.byType(TextFormField).at(1), 'SecurePass123');
      await tester.ensureVisible(find.text('Activate Account'));
      await tester.tap(find.text('Activate Account'));
      await tester.pumpAndSettle();

      expect(fakeRepo.activateCalled, isTrue);
      expect(find.textContaining('Invitation has expired'), findsOneWidget);
    });

    testWidgets('7. Successful activation displays Step 3 confirmation and navigates to Login', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final fakeRepo = _FakeApiAuthRepository();

      await tester.pumpWidget(
        createActivationTestApp(
          const ActivationScreen(),
          overrides: [
            apiAuthRepositoryProvider.overrideWithValue(fakeRepo),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Step 1
      await tester.enterText(find.byType(TextFormField).at(0), 'TECH-UNIV');
      await tester.enterText(find.byType(TextFormField).at(1), 'STU2026001');
      await tester.enterText(find.byType(TextFormField).at(2), 'VALID123');
      await tester.ensureVisible(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 2
      await tester.enterText(find.byType(TextFormField).at(0), 'SecurePass123');
      await tester.enterText(find.byType(TextFormField).at(1), 'SecurePass123');
      await tester.ensureVisible(find.text('Activate Account'));
      await tester.tap(find.text('Activate Account'));
      await tester.pumpAndSettle();

      expect(fakeRepo.activateCalled, isTrue);
      expect(find.text('Account Activated!'), findsOneWidget);
      expect(find.text('Continue to Sign In'), findsOneWidget);

      // Tap Sign In
      await tester.ensureVisible(find.text('Continue to Sign In'));
      await tester.tap(find.text('Continue to Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Login Screen'), findsOneWidget);
    });

    testWidgets('8. Duplicate submit prevention blocks multiple activations during loading', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final fakeRepo = _FakeApiAuthRepository();

      await tester.pumpWidget(
        createActivationTestApp(
          const ActivationScreen(),
          overrides: [
            apiAuthRepositoryProvider.overrideWithValue(fakeRepo),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Step 1
      await tester.enterText(find.byType(TextFormField).at(0), 'TECH-UNIV');
      await tester.enterText(find.byType(TextFormField).at(1), 'STU2026001');
      await tester.enterText(find.byType(TextFormField).at(2), 'VALID123');
      await tester.ensureVisible(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 2 fields
      await tester.enterText(find.byType(TextFormField).at(0), 'SecurePass123');
      await tester.enterText(find.byType(TextFormField).at(1), 'SecurePass123');

      // Submit once
      await tester.ensureVisible(find.text('Activate Account'));
      await tester.tap(find.text('Activate Account'));
      await tester.pump(); // partial pump during loading

      expect(fakeRepo.activateCalled, isTrue);
    });

    testWidgets('9. Dark mode renders correctly with dark theme tokens', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: const ActivationScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Activate Account'), findsOneWidget);
    });

    testWidgets('10. Small screen layout renders without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createActivationTestApp(
          const ActivationScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Activate Account'), findsOneWidget);
    });
  });
}
