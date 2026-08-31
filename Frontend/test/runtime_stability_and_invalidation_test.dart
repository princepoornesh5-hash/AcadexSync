import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:campus_management/core/firebase/firebase_initializer.dart';
import 'package:campus_management/core/presentation/utils/navigation_extensions.dart';
import 'package:campus_management/features/analytics/data/repositories/api_analytics_repository.dart';
import 'package:campus_management/features/analytics/presentation/providers/analytics_providers.dart';
import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_management/features/auth/repositories/auth_repository.dart';
import 'package:campus_management/features/auth/services/session_manager.dart';

class MockTestAuthRepo implements AuthRepository {
  bool logoutCalled = false;
  UserModel? loggedInUser;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<UserModel> login(String identifier, String password) async {
    loggedInUser = UserModel(
      id: identifier.contains('admin') ? 'usr_admin' : 'usr_faculty',
      name: identifier.contains('admin') ? 'Admin User' : 'Faculty User',
      email: identifier,
      role: identifier.contains('admin') ? AppRole.collegeAdmin : AppRole.faculty,
      collegeId: 'coll_1',
    );
    return loggedInUser!;
  }

  @override
  Future<UserModel?> getCurrentUser() async => loggedInUser;

  @override
  Future<void> logout() async {
    logoutCalled = true;
    loggedInUser = null;
  }

  @override
  Future<void> logoutAll() async {
    logoutCalled = true;
    loggedInUser = null;
  }

  @override
  Future<UserModel> loginAsDevelopmentRole(AppRole role) async {
    loggedInUser = UserModel(
      id: 'usr_dev',
      name: 'Dev User',
      email: 'dev@acadex.com',
      role: role,
    );
    return loggedInUser!;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ACADEX Master Runtime Stability Tests', () {
    testWidgets('1. safePop safely falls back when nothing to pop without throwing assertion', (tester) async {
      final router = GoRouter(
        initialLocation: '/details',
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const Scaffold(body: Text('Home Screen')),
          ),
          GoRoute(
            path: '/details',
            builder: (context, state) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    // SafePop must safely navigate to /home fallback instead of throwing
                    context.safePop(fallbackRoute: '/home');
                  },
                  child: const Text('Back Button'),
                ),
              ),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Back Button'), findsOneWidget);
      expect(find.text('Home Screen'), findsNothing);

      // Tap back button
      await tester.tap(find.text('Back Button'));
      await tester.pumpAndSettle();

      // Successfully redirected to fallback /home without "Component Load Error" or "Bad state: There is nothing to pop"
      expect(find.text('Home Screen'), findsOneWidget);
    });

    test('2. ApiAnalyticsRepository returns accurate zero-state metrics on empty backend', () {
      final repo = ApiAnalyticsRepository();

      final studentMetrics = repo.getEmptyMetricsForRole(AppRole.student);
      expect(studentMetrics['Overall Attendance'], '0.0%');
      expect(studentMetrics['Classes Attended'], '0 / 0');
      expect(studentMetrics['Classes Missed'], '0');

      final collegeAdminMetrics = repo.getEmptyMetricsForRole(AppRole.collegeAdmin);
      expect(collegeAdminMetrics['College Attendance'], '0.0%');
      expect(collegeAdminMetrics['Total Students At Risk'], '0');
      expect(collegeAdminMetrics['Best Department'], 'None');

      final superAdminMetrics = repo.getEmptyMetricsForRole(AppRole.superAdmin);
      expect(superAdminMetrics['Platform Attendance'], '0.0%');
      expect(superAdminMetrics['Active Colleges'], '0');
      expect(superAdminMetrics['Total Records Today'], '0');
    });

    test('3. Auth login and logout purge user-scoped cache across user switches', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final storage = const FlutterSecureStorage();
      final sessionManager = SessionManager(storage);
      final mockRepo = MockTestAuthRepo();

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepo),
          sessionManagerProvider.overrideWithValue(sessionManager),
        ],
      );

      final authNotifier = container.read(authProvider.notifier);

      // User A (Faculty) logs in
      await authNotifier.login('faculty@acadex.com', 'Pass123!');
      expect(container.read(currentUserRoleProvider), AppRole.faculty);
      expect(container.read(currentUserProvider)?.email, 'faculty@acadex.com');

      // Logout User A
      await authNotifier.logout();
      expect(container.read(authProvider), isA<AuthUnauthenticated>());
      expect(container.read(currentUserProvider), isNull);

      // User B (Admin) logs in
      await authNotifier.login('admin@acadex.com', 'Pass123!');
      expect(container.read(currentUserRoleProvider), AppRole.collegeAdmin);
      expect(container.read(currentUserProvider)?.email, 'admin@acadex.com');
      expect(container.read(currentUserProvider)?.role, AppRole.collegeAdmin);

      container.dispose();
    });

    test('4. analyticsRepositoryProvider resolves ApiAnalyticsRepository in production mode', () {
      FirebaseInitializer.overrideShouldUseMock = false;
      final container = ProviderContainer();
      final repo = container.read(analyticsRepositoryProvider);
      expect(repo, isA<ApiAnalyticsRepository>());
      final apiRepo = container.read(apiAnalyticsRepositoryProvider);
      expect(apiRepo, isA<ApiAnalyticsRepository>());
      container.dispose();
      FirebaseInitializer.overrideShouldUseMock = null;
    });
  });
}
