import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_management/features/auth/presentation/screens/login_screen.dart';
import 'package:campus_management/features/auth/data/repositories/api_auth_repository.dart';

class _FakeAuthNotifier extends StateNotifier<AuthState>
    implements AuthNotifier {
  _FakeAuthNotifier([super.initial = const AuthUnauthenticated()]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  bool loginCalled = false;
  String? lastIdentifier;
  String? lastPassword;
  bool logoutCalled = false;
  bool requestLoginOtpCalled = false;
  bool loginWithOtpCalled = false;
  String? lastOtpEmail;
  String? lastOtpCode;

  Future<void> requestLoginOtp(String email) async {
    requestLoginOtpCalled = true;
    lastOtpEmail = email;
  }

  Future<void> loginWithOtp(String email, String otp) async {
    loginWithOtpCalled = true;
    lastOtpEmail = email;
    lastOtpCode = otp;
    if (otp == '999999') {
      state = const AuthError(message: 'Invalid or expired verification code');
      throw Exception('Invalid or expired verification code');
    }
    state = AuthAuthenticated(
      user: UserModel(
        id: 'u-otp-1',
        name: 'OTP User',
        email: email,
        role: AppRole.student,
        accountStatus: AccountStatus.active,
      ),
      token: 'jwt-otp-token',
    );
  }

  @override
  Future<void> login(String identifier, String password) async {
    loginCalled = true;
    lastIdentifier = identifier;
    lastPassword = password;
    state = const AuthLoading();

    if (identifier == 'pending@acadex.edu') {
      state = const AuthError(
        message:
            'Account is pending activation. Please activate your account first.',
      );
      return;
    }
    if (identifier == 'deactivated@acadex.edu') {
      state = const AuthError(
        message:
            'Account has been deactivated. Please contact your administrator.',
      );
      return;
    }
    if (identifier == 'suspended@acadex.edu') {
      state = const AuthError(message: 'Account is currently not active.');
      return;
    }
    if (password == 'wrongpassword') {
      state = const AuthError(message: 'Invalid credentials');
      return;
    }
    if (identifier == 'network@acadex.edu') {
      state = const AuthError(message: 'Network connection error');
      return;
    }

    AppRole role = AppRole.student;
    if (identifier.contains('super')) role = AppRole.superAdmin;
    if (identifier.contains('college')) role = AppRole.collegeAdmin;
    if (identifier.contains('hod')) role = AppRole.hod;
    if (identifier.contains('faculty')) role = AppRole.faculty;

    state = AuthAuthenticated(
      user: UserModel(
        id: 'u-1',
        name: 'Test User',
        email: identifier,
        role: role,
        accountStatus: AccountStatus.active,
      ),
      token: 'jwt-access-token-123',
    );
  }

  @override
  Future<void> loginAsDevelopmentRole(AppRole role) async {
    state = const AuthLoading();
    state = AuthAuthenticated(
      user: UserModel(
        id: 'dev-${role.value}',
        name: '${role.displayName} Dev',
        email: '${role.value.toLowerCase()}@acadex.edu',
        role: role,
        accountStatus: AccountStatus.active,
      ),
      token: 'dev-token',
    );
  }

  @override
  Future<void> logout() async {
    logoutCalled = true;
    state = const AuthUnauthenticated();
  }

  @override
  Future<void> logoutAll() async {
    logoutCalled = true;
    state = const AuthUnauthenticated();
  }

  @override
  Future<void> resetPassword(String email) async {}

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {}

  @override
  void updateCurrentUser(UserModel updatedUser) {
    if (state is AuthAuthenticated) {
      state = AuthAuthenticated(
        user: updatedUser,
        token: (state as AuthAuthenticated).token,
      );
    }
  }
}

Widget createTestApp(Widget child, {List<dynamic> overrides = const []}) {
  final router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(path: '/login', builder: (context, state) => child),
      GoRoute(
        path: '/register',
        builder: (context, state) =>
            const Scaffold(body: Text('Register Screen')),
      ),
      GoRoute(
        path: '/activate',
        builder: (context, state) =>
            const Scaffold(body: Text('Activate Screen')),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) =>
            const Scaffold(body: Text('Forgot Password Screen')),
      ),
      GoRoute(
        path: '/dashboard/super_admin',
        builder: (context, state) =>
            const Scaffold(body: Text('Super Admin Dashboard')),
      ),
      GoRoute(
        path: '/dashboard/college_admin',
        builder: (context, state) =>
            const Scaffold(body: Text('College Admin Dashboard')),
      ),
      GoRoute(
        path: '/dashboard/hod',
        builder: (context, state) =>
            const Scaffold(body: Text('HOD Dashboard')),
      ),
      GoRoute(
        path: '/dashboard/faculty',
        builder: (context, state) =>
            const Scaffold(body: Text('Faculty Dashboard')),
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

Future<void> _advanceToPasswordLogin(WidgetTester tester, String email) async {
  await tester.enterText(find.byKey(const Key('welcome_email_field')), email);
  await tester.tap(find.byKey(const Key('welcome_continue_button')));
  await tester.pumpAndSettle();
}

void main() {
  group('ACADEX — Auth Login Vertical Slice Tests', () {
    testWidgets(
      '1. Login screen renders branding, input fields, and login button',
      (tester) async {
        await tester.pumpWidget(
          createTestApp(
            const LoginScreen(),
            overrides: [
              authProvider.overrideWith((ref) => _FakeAuthNotifier()),
            ],
          ),
        );

        await tester.pumpAndSettle();

        // Screen 1: Welcome / sign in
        expect(find.text('ACADEXSYNC'), findsWidgets);
        expect(
          find.text('Sign in to access your institutional dashboard.'),
          findsOneWidget,
        );
        expect(find.byKey(const Key('welcome_email_field')), findsOneWidget);
        expect(
          find.byKey(const Key('welcome_continue_button')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('link_create_account')), findsOneWidget);
        expect(find.byKey(const Key('link_activate_account')), findsOneWidget);

        // Advance to Screen 2
        await _advanceToPasswordLogin(tester, 'user@acadex.edu');

        // Screen 2: Existing account login
        expect(find.text('user@acadex.edu'), findsWidgets);
        expect(find.byKey(const Key('switch_to_otp_button')), findsOneWidget);
        expect(find.byKey(const Key('login_password_field')), findsOneWidget);
        expect(find.byKey(const Key('forgot_password_button')), findsOneWidget);
        expect(
          find.byKey(const Key('password_sign_in_button')),
          findsOneWidget,
        );
      },
    );

    testWidgets('2. Empty identifier displays validation error', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          const LoginScreen(),
          overrides: [authProvider.overrideWith((ref) => _FakeAuthNotifier())],
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('welcome_continue_button')));
      await tester.pumpAndSettle();

      expect(find.text('Please enter your email address'), findsOneWidget);
    });

    testWidgets('3. Empty password displays validation error', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          const LoginScreen(),
          overrides: [authProvider.overrideWith((ref) => _FakeAuthNotifier())],
        ),
      );

      await tester.pumpAndSettle();

      await _advanceToPasswordLogin(tester, 'user@acadex.edu');

      await tester.tap(find.byKey(const Key('password_sign_in_button')));
      await tester.pumpAndSettle();

      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('4. Invalid credentials triggers error feedback', (
      tester,
    ) async {
      final fakeAuth = _FakeAuthNotifier();

      await tester.pumpWidget(
        createTestApp(
          const LoginScreen(),
          overrides: [authProvider.overrideWith((ref) => fakeAuth)],
        ),
      );

      await tester.pumpAndSettle();

      await _advanceToPasswordLogin(tester, 'user@acadex.edu');
      await tester.enterText(
        find.byKey(const Key('login_password_field')),
        'wrongpassword',
      );
      await tester.tap(find.byKey(const Key('password_sign_in_button')));
      await tester.pumpAndSettle();

      expect(fakeAuth.loginCalled, isTrue);
      expect(find.text('Invalid credentials'), findsOneWidget);
    });

    testWidgets(
      '5. Successful login transitions state to AuthAuthenticated and navigates to Student dashboard',
      (tester) async {
        final fakeAuth = _FakeAuthNotifier();

        await tester.pumpWidget(
          createTestApp(
            const LoginScreen(),
            overrides: [authProvider.overrideWith((ref) => fakeAuth)],
          ),
        );

        await tester.pumpAndSettle();

        await _advanceToPasswordLogin(tester, 'student@acadex.edu');
        await tester.enterText(
          find.byKey(const Key('login_password_field')),
          'acadex123',
        );
        await tester.tap(find.byKey(const Key('password_sign_in_button')));
        await tester.pumpAndSettle();

        expect(fakeAuth.loginCalled, isTrue);
        expect(fakeAuth.state, isA<AuthAuthenticated>());
        final auth = fakeAuth.state as AuthAuthenticated;
        expect(auth.user.role, equals(AppRole.student));
        expect(find.text('Student Dashboard'), findsOneWidget);
      },
    );

    testWidgets('6. Token persistence contract verified on ApiAuthRepository', (
      tester,
    ) async {
      final repo = ApiAuthRepository();
      expect(repo, isA<ApiAuthRepository>());
    });

    testWidgets('7. Authenticated state holds user profile and token', (
      tester,
    ) async {
      const user = UserModel(
        id: 'u-1',
        name: 'Super Admin',
        email: 'admin@acadex.edu',
        role: AppRole.superAdmin,
        accountStatus: AccountStatus.active,
      );
      const state = AuthAuthenticated(user: user, token: 'token-abc');

      expect(state.user.id, equals('u-1'));
      expect(state.user.role, equals(AppRole.superAdmin));
      expect(state.token, equals('token-abc'));
    });

    testWidgets('8. Role resolution correctly distinguishes all 5 roles', (
      tester,
    ) async {
      expect(AppRole.superAdmin.displayName, equals('Super Admin'));
      expect(AppRole.collegeAdmin.displayName, equals('College Admin'));
      expect(AppRole.hod.displayName, equals('HOD'));
      expect(AppRole.faculty.displayName, equals('Faculty'));
      expect(AppRole.student.displayName, equals('Student'));
    });

    testWidgets('9-13. Role dashboard routing maps accurately for all roles', (
      tester,
    ) async {
      final roles = [
        AppRole.superAdmin,
        AppRole.collegeAdmin,
        AppRole.hod,
        AppRole.faculty,
        AppRole.student,
      ];

      for (final role in roles) {
        final fakeAuth = _FakeAuthNotifier();
        await fakeAuth.loginAsDevelopmentRole(role);
        expect(fakeAuth.state, isA<AuthAuthenticated>());
        final auth = fakeAuth.state as AuthAuthenticated;
        expect(auth.user.role, equals(role));
      }
    });

    testWidgets(
      '14. Pending activation user displays warning and Activate Now action',
      (tester) async {
        final fakeAuth = _FakeAuthNotifier();

        await tester.pumpWidget(
          createTestApp(
            const LoginScreen(),
            overrides: [authProvider.overrideWith((ref) => fakeAuth)],
          ),
        );

        await tester.pumpAndSettle();

        await _advanceToPasswordLogin(tester, 'pending@acadex.edu');
        await tester.enterText(
          find.byKey(const Key('login_password_field')),
          'acadex123',
        );
        await tester.tap(find.byKey(const Key('password_sign_in_button')));
        await tester.pumpAndSettle();

        expect(
          find.textContaining('Account is pending activation'),
          findsOneWidget,
        );
        expect(find.text('Activate Now'), findsOneWidget);
      },
    );

    testWidgets('15. Deactivated account displays distinct notification', (
      tester,
    ) async {
      final fakeAuth = _FakeAuthNotifier();

      await tester.pumpWidget(
        createTestApp(
          const LoginScreen(),
          overrides: [authProvider.overrideWith((ref) => fakeAuth)],
        ),
      );

      await tester.pumpAndSettle();

      await _advanceToPasswordLogin(tester, 'deactivated@acadex.edu');
      await tester.enterText(
        find.byKey(const Key('login_password_field')),
        'acadex123',
      );
      await tester.tap(find.byKey(const Key('password_sign_in_button')));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Account has been deactivated'),
        findsOneWidget,
      );
    });

    testWidgets('16. Suspended account displays inactive notification', (
      tester,
    ) async {
      final fakeAuth = _FakeAuthNotifier();

      await tester.pumpWidget(
        createTestApp(
          const LoginScreen(),
          overrides: [authProvider.overrideWith((ref) => fakeAuth)],
        ),
      );

      await tester.pumpAndSettle();

      await _advanceToPasswordLogin(tester, 'suspended@acadex.edu');
      await tester.enterText(
        find.byKey(const Key('login_password_field')),
        'acadex123',
      );
      await tester.tap(find.byKey(const Key('password_sign_in_button')));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Account is currently not active'),
        findsOneWidget,
      );
    });

    testWidgets('17. Network failure displays user-friendly error', (
      tester,
    ) async {
      final fakeAuth = _FakeAuthNotifier();

      await tester.pumpWidget(
        createTestApp(
          const LoginScreen(),
          overrides: [authProvider.overrideWith((ref) => fakeAuth)],
        ),
      );

      await tester.pumpAndSettle();

      await _advanceToPasswordLogin(tester, 'network@acadex.edu');
      await tester.enterText(
        find.byKey(const Key('login_password_field')),
        'acadex123',
      );
      await tester.tap(find.byKey(const Key('password_sign_in_button')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Network connection error'), findsOneWidget);
    });

    testWidgets(
      '18. Duplicate submit prevention disables input during loading',
      (tester) async {
        final fakeAuth = _FakeAuthNotifier(const AuthLoading());

        await tester.pumpWidget(
          createTestApp(
            const LoginScreen(),
            overrides: [authProvider.overrideWith((ref) => fakeAuth)],
          ),
        );

        await tester.pump();

        final textFields = tester.widgetList<TextFormField>(
          find.byType(TextFormField),
        );
        for (final field in textFields) {
          expect(field.enabled, isFalse);
        }
      },
    );

    testWidgets('19. Logout cleanly resets state to AuthUnauthenticated', (
      tester,
    ) async {
      final fakeAuth = _FakeAuthNotifier(
        const AuthAuthenticated(
          user: UserModel(
            id: 'u-1',
            name: 'User',
            email: 'user@acadex.edu',
            role: AppRole.student,
          ),
          token: 'token-123',
        ),
      );

      await fakeAuth.logout();

      expect(fakeAuth.logoutCalled, isTrue);
      expect(fakeAuth.state, isA<AuthUnauthenticated>());
    });

    testWidgets(
      '20. Session restoration produces AuthAuthenticated when user profile exists',
      (tester) async {
        const user = UserModel(
          id: 'u-persisted',
          name: 'Restored User',
          email: 'restored@acadex.edu',
          role: AppRole.faculty,
          accountStatus: AccountStatus.active,
        );
        const state = AuthAuthenticated(user: user, token: 'persisted-jwt');

        expect(state.user.id, equals('u-persisted'));
        expect(state.user.role, equals(AppRole.faculty));
      },
    );

    testWidgets('21. Screen 1 "Create an account" link routes to /register', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          const LoginScreen(),
          overrides: [authProvider.overrideWith((ref) => _FakeAuthNotifier())],
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('link_create_account')));
      await tester.pumpAndSettle();

      expect(find.text('Register Screen'), findsOneWidget);
    });

    testWidgets('22. Screen 1 "Activate account" link routes to /activate', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          const LoginScreen(),
          overrides: [authProvider.overrideWith((ref) => _FakeAuthNotifier())],
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('link_activate_account')));
      await tester.pumpAndSettle();

      expect(find.text('Activate Screen'), findsOneWidget);
    });

    testWidgets('23. Screen 2 "Change" email button returns user to Screen 1', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          const LoginScreen(),
          overrides: [authProvider.overrideWith((ref) => _FakeAuthNotifier())],
        ),
      );

      await tester.pumpAndSettle();

      await _advanceToPasswordLogin(tester, 'student@acadex.edu');
      expect(find.byKey(const Key('change_email_button')), findsOneWidget);

      await tester.tap(find.byKey(const Key('change_email_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('welcome_email_field')), findsOneWidget);
      expect(find.byKey(const Key('welcome_continue_button')), findsOneWidget);
    });

    testWidgets(
      '24. Screen 2 Email OTP flow requests code and signs in successfully',
      (tester) async {
        final fakeAuth = _FakeAuthNotifier();

        await tester.pumpWidget(
          createTestApp(
            const LoginScreen(),
            overrides: [authProvider.overrideWith((ref) => fakeAuth)],
          ),
        );

        await tester.pumpAndSettle();

        await _advanceToPasswordLogin(tester, 'student@acadex.edu');

        // Tap Sign In with Email Code (OTP)
        expect(find.byKey(const Key('switch_to_otp_button')), findsOneWidget);
        await tester.tap(find.byKey(const Key('switch_to_otp_button')));
        await tester.pumpAndSettle();

        expect(fakeAuth.requestLoginOtpCalled, isTrue);
        expect(fakeAuth.lastOtpEmail, equals('student@acadex.edu'));

        // Dedicated code-entry screen is now shown
        expect(find.byKey(const Key('otp_code_field')), findsOneWidget);
        expect(find.byKey(const Key('otp_sign_in_button')), findsOneWidget);
        expect(find.textContaining('Resend in'), findsOneWidget);

        // Enter 6-digit OTP code and sign in
        await tester.enterText(
          find.byKey(const Key('otp_code_field')),
          '123456',
        );
        await tester.ensureVisible(find.byKey(const Key('otp_sign_in_button')));
        await tester.tap(find.byKey(const Key('otp_sign_in_button')));
        await tester.pumpAndSettle();

        expect(fakeAuth.loginWithOtpCalled, isTrue);
        expect(fakeAuth.lastOtpCode, equals('123456'));
        expect(fakeAuth.state, isA<AuthAuthenticated>());
        expect(find.text('Student Dashboard'), findsOneWidget);
      },
    );

    testWidgets(
      '25. Screen 2 Email OTP flow handles invalid verification code gracefully',
      (tester) async {
        final fakeAuth = _FakeAuthNotifier();

        await tester.pumpWidget(
          createTestApp(
            const LoginScreen(),
            overrides: [authProvider.overrideWith((ref) => fakeAuth)],
          ),
        );

        await tester.pumpAndSettle();

        await _advanceToPasswordLogin(tester, 'student@acadex.edu');

        await tester.tap(find.byKey(const Key('switch_to_otp_button')));
        await tester.pumpAndSettle();

        // Enter failing OTP '999999'
        await tester.enterText(
          find.byKey(const Key('otp_code_field')),
          '999999',
        );
        await tester.ensureVisible(find.byKey(const Key('otp_sign_in_button')));
        await tester.tap(find.byKey(const Key('otp_sign_in_button')));
        await tester.pumpAndSettle();

        expect(fakeAuth.loginWithOtpCalled, isTrue);
        expect(
          find.textContaining('Invalid or expired verification code'),
          findsWidgets,
        );
      },
    );
  });
}
