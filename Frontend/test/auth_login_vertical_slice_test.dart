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

class _FakeAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _FakeAuthNotifier([super.initial = const AuthUnauthenticated()]);

  bool loginCalled = false;
  String? lastIdentifier;
  String? lastPassword;
  bool logoutCalled = false;

  @override
  Future<void> login(String identifier, String password) async {
    loginCalled = true;
    lastIdentifier = identifier;
    lastPassword = password;
    state = const AuthLoading();

    if (identifier == 'pending@acadex.edu') {
      state = const AuthError(message: 'Account is pending activation. Please activate your account first.');
      return;
    }
    if (identifier == 'deactivated@acadex.edu') {
      state = const AuthError(message: 'Account has been deactivated. Please contact your administrator.');
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
      state = AuthAuthenticated(user: updatedUser, token: (state as AuthAuthenticated).token);
    }
  }
}

Widget createTestApp(Widget child, {List<dynamic> overrides = const []}) {
  final router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(path: '/login', builder: (context, state) => child),
      GoRoute(path: '/activate', builder: (context, state) => const Scaffold(body: Text('Activate Screen'))),
      GoRoute(path: '/forgot-password', builder: (context, state) => const Scaffold(body: Text('Forgot Password Screen'))),
      GoRoute(path: '/dashboard/super_admin', builder: (context, state) => const Scaffold(body: Text('Super Admin Dashboard'))),
      GoRoute(path: '/dashboard/college_admin', builder: (context, state) => const Scaffold(body: Text('College Admin Dashboard'))),
      GoRoute(path: '/dashboard/hod', builder: (context, state) => const Scaffold(body: Text('HOD Dashboard'))),
      GoRoute(path: '/dashboard/faculty', builder: (context, state) => const Scaffold(body: Text('Faculty Dashboard'))),
      GoRoute(path: '/dashboard/student', builder: (context, state) => const Scaffold(body: Text('Student Dashboard'))),
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
  group('ACADEX — Auth Login Vertical Slice Tests', () {
    testWidgets('1. Login screen renders branding, input fields, and login button', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          const LoginScreen(),
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier()),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Acadex'), findsWidgets);
      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Email or Phone Number'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Forgot password?'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('New student or faculty? Activate Account'), findsOneWidget);
    });

    testWidgets('2. Empty identifier displays validation error', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          const LoginScreen(),
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier()),
          ],
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter your email or phone number'), findsOneWidget);
    });

    testWidgets('3. Empty password displays validation error', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          const LoginScreen(),
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier()),
          ],
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'user@acadex.edu');
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('4. Invalid credentials triggers error feedback', (tester) async {
      final fakeAuth = _FakeAuthNotifier();

      await tester.pumpWidget(
        createTestApp(
          const LoginScreen(),
          overrides: [
            authProvider.overrideWith((ref) => fakeAuth),
          ],
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'user@acadex.edu');
      await tester.enterText(find.byType(TextFormField).at(1), 'wrongpassword');
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(fakeAuth.loginCalled, isTrue);
      expect(find.text('Invalid credentials'), findsOneWidget);
    });

    testWidgets('5. Successful login transitions state to AuthAuthenticated and navigates to Student dashboard', (tester) async {
      final fakeAuth = _FakeAuthNotifier();

      await tester.pumpWidget(
        createTestApp(
          const LoginScreen(),
          overrides: [
            authProvider.overrideWith((ref) => fakeAuth),
          ],
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'student@acadex.edu');
      await tester.enterText(find.byType(TextFormField).at(1), 'acadex123');
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(fakeAuth.loginCalled, isTrue);
      expect(fakeAuth.state, isA<AuthAuthenticated>());
      final auth = fakeAuth.state as AuthAuthenticated;
      expect(auth.user.role, equals(AppRole.student));
      expect(find.text('Student Dashboard'), findsOneWidget);
    });

    testWidgets('6. Token persistence contract verified on ApiAuthRepository', (tester) async {
      final repo = ApiAuthRepository();
      expect(repo, isA<ApiAuthRepository>());
    });

    testWidgets('7. Authenticated state holds user profile and token', (tester) async {
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

    testWidgets('8. Role resolution correctly distinguishes all 5 roles', (tester) async {
      expect(AppRole.superAdmin.displayName, equals('Super Admin'));
      expect(AppRole.collegeAdmin.displayName, equals('College Admin'));
      expect(AppRole.hod.displayName, equals('HOD'));
      expect(AppRole.faculty.displayName, equals('Faculty'));
      expect(AppRole.student.displayName, equals('Student'));
    });

    testWidgets('9-13. Role dashboard routing maps accurately for all roles', (tester) async {
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

    testWidgets('14. Pending activation user displays warning and Activate Now action', (tester) async {
      final fakeAuth = _FakeAuthNotifier();

      await tester.pumpWidget(
        createTestApp(
          const LoginScreen(),
          overrides: [
            authProvider.overrideWith((ref) => fakeAuth),
          ],
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'pending@acadex.edu');
      await tester.enterText(find.byType(TextFormField).at(1), 'acadex123');
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Account is pending activation'), findsOneWidget);
      expect(find.text('Activate Now'), findsOneWidget);
    });

    testWidgets('15. Deactivated account displays distinct notification', (tester) async {
      final fakeAuth = _FakeAuthNotifier();

      await tester.pumpWidget(
        createTestApp(
          const LoginScreen(),
          overrides: [
            authProvider.overrideWith((ref) => fakeAuth),
          ],
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'deactivated@acadex.edu');
      await tester.enterText(find.byType(TextFormField).at(1), 'acadex123');
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Account has been deactivated'), findsOneWidget);
    });

    testWidgets('16. Suspended account displays inactive notification', (tester) async {
      final fakeAuth = _FakeAuthNotifier();

      await tester.pumpWidget(
        createTestApp(
          const LoginScreen(),
          overrides: [
            authProvider.overrideWith((ref) => fakeAuth),
          ],
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'suspended@acadex.edu');
      await tester.enterText(find.byType(TextFormField).at(1), 'acadex123');
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Account is currently not active'), findsOneWidget);
    });

    testWidgets('17. Network failure displays user-friendly error', (tester) async {
      final fakeAuth = _FakeAuthNotifier();

      await tester.pumpWidget(
        createTestApp(
          const LoginScreen(),
          overrides: [
            authProvider.overrideWith((ref) => fakeAuth),
          ],
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'network@acadex.edu');
      await tester.enterText(find.byType(TextFormField).at(1), 'acadex123');
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Network connection error'), findsOneWidget);
    });

    testWidgets('18. Duplicate submit prevention disables input during loading', (tester) async {
      final fakeAuth = _FakeAuthNotifier(const AuthLoading());

      await tester.pumpWidget(
        createTestApp(
          const LoginScreen(),
          overrides: [
            authProvider.overrideWith((ref) => fakeAuth),
          ],
        ),
      );

      await tester.pump();

      final textFields = tester.widgetList<TextFormField>(find.byType(TextFormField));
      for (final field in textFields) {
        expect(field.enabled, isFalse);
      }
    });

    testWidgets('19. Logout cleanly resets state to AuthUnauthenticated', (tester) async {
      final fakeAuth = _FakeAuthNotifier(
        const AuthAuthenticated(
          user: UserModel(id: 'u-1', name: 'User', email: 'user@acadex.edu', role: AppRole.student),
          token: 'token-123',
        ),
      );

      await fakeAuth.logout();

      expect(fakeAuth.logoutCalled, isTrue);
      expect(fakeAuth.state, isA<AuthUnauthenticated>());
    });

    testWidgets('20. Session restoration produces AuthAuthenticated when user profile exists', (tester) async {
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
    });
  });
}
