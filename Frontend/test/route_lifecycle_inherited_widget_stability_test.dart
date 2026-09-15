import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:campus_management/core/firebase/firebase_initializer.dart';
import 'package:campus_management/app/router/app_router.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_management/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:campus_management/features/dashboard/domain/models/dashboard_stat_model.dart';
import 'package:campus_management/features/dashboard/domain/models/activity_item_model.dart';
import 'package:campus_management/features/academic_structure/presentation/providers/academic_providers.dart';
import 'package:campus_management/features/academic_structure/data/repositories/mock_academic_repository.dart';
import 'package:campus_management/features/notifications/presentation/providers/notification_providers.dart';
import 'package:campus_management/features/notifications/data/repositories/mock_notification_repository.dart';
import 'package:campus_management/core/presentation/utils/navigation_extensions.dart';
import 'package:campus_management/core/presentation/widgets/acadex_page_container.dart';

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

List<Override> testOverrides(UserModel user) {
  return [
    authProvider.overrideWith((ref) => _FakeAuthNotifier(AuthAuthenticated(user: user, token: 'token-123'))),
    academicRepositoryProvider.overrideWithValue(MockAcademicRepository()),
    notificationRepositoryProvider.overrideWithValue(MockNotificationRepository()),
    superAdminStatsProvider.overrideWith((ref) async => <DashboardStatModel>[]),
    superAdminActivityProvider.overrideWith((ref) async => <ActivityItemModel>[]),
    collegeAdminStatsProvider.overrideWith((ref) async => <DashboardStatModel>[]),
    collegeAdminActivityProvider.overrideWith((ref) async => <ActivityItemModel>[]),
    hodStatsProvider.overrideWith((ref) async => <DashboardStatModel>[]),
    hodActivityProvider.overrideWith((ref) async => <ActivityItemModel>[]),
    facultyStatsProvider.overrideWith((ref) async => <DashboardStatModel>[]),
    facultyActivityProvider.overrideWith((ref) async => <ActivityItemModel>[]),
    studentStatsProvider.overrideWith((ref) async => <DashboardStatModel>[]),
    studentActivityProvider.overrideWith((ref) async => <ActivityItemModel>[]),
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    FirebaseInitializer.overrideShouldUseMock = true;
    FlutterSecureStorage.setMockInitialValues({});
  });

  tearDownAll(() {
    FirebaseInitializer.overrideShouldUseMock = null;
  });

  group('ACADEX Priority 2 / Prompt 2 — Route Lifecycle & Inherited Widget Stability Tests', () {
    testWidgets('1. AcadexPageContainer does not produce nested Scaffold', (tester) async {
      final user = UserModel(
        id: 'usr_super',
        name: 'Super Admin',
        email: 'super@acadex.com',
        role: AppRole.superAdmin,
        collegeId: 'c1',
      );

      // Direct verification: AcadexPageContainer should NOT wrap itself in a Scaffold
      await tester.pumpWidget(
        ProviderScope(
          overrides: testOverrides(user),
          child: MaterialApp(
            home: Scaffold(
              appBar: AppBar(title: const Text('Outer Scaffold')),
              body: const AcadexPageContainer(
                child: Text('Page Content Inside Container'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure exactly ONE Scaffold exists in the entire widget tree
      expect(find.byType(Scaffold), findsNWidgets(1));
      expect(find.text('Page Content Inside Container'), findsOneWidget);
      expect(find.text('Component Load Error'), findsNothing);
    });

    testWidgets('2. Deep Navigation Flow: Dashboard -> Colleges -> Detail -> Form -> Back -> Back remains stable', (tester) async {
      final user = UserModel(
        id: 'usr_super',
        name: 'Super Admin',
        email: 'super@acadex.com',
        role: AppRole.superAdmin,
        collegeId: 'c1',
      );

      final container = ProviderContainer(
        overrides: testOverrides(user),
      );

      final router = container.read(appRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Initial State: Super Admin Dashboard
      router.go('/dashboard/super_admin');
      await tester.pumpAndSettle();
      expect(find.text('Component Load Error'), findsNothing);

      // 2. Navigate to Colleges list
      router.go('/academics/colleges');
      await tester.pumpAndSettle();
      expect(find.text('Component Load Error'), findsNothing);

      // 3. Navigate to College Detail (standalone route with Scaffold)
      router.push('/academics/colleges/c1');
      await tester.pumpAndSettle();
      expect(find.text('Component Load Error'), findsNothing);

      // 4. Navigate to Edit College (standalone form route)
      router.push('/academics/colleges/edit/c1');
      await tester.pumpAndSettle();
      expect(find.text('Component Load Error'), findsNothing);

      // 5. Back from Edit -> Detail
      final BuildContext editContext = tester.element(find.text('Edit College'));
      editContext.safePop(fallbackRoute: '/academics/colleges/c1');
      await tester.pumpAndSettle();
      expect(find.text('Component Load Error'), findsNothing);

      // 6. Back from Detail -> Colleges
      final BuildContext detailContext = tester.element(find.byType(Scaffold).first);
      detailContext.safePop(fallbackRoute: '/academics/colleges');
      await tester.pumpAndSettle();
      expect(find.text('Component Load Error'), findsNothing);

      // 7. Back from Colleges -> Dashboard
      router.go('/dashboard/super_admin');
      await tester.pumpAndSettle();
      expect(find.text('Component Load Error'), findsNothing);

      container.dispose();
    });

    testWidgets('3. Multi-Role Back Navigation Traverse Sweep: no _dependents or lifecycle assertion', (tester) async {
      for (final role in [AppRole.superAdmin, AppRole.collegeAdmin, AppRole.hod, AppRole.faculty, AppRole.student]) {
        final id = role == AppRole.student
            ? 's1'
            : (role == AppRole.faculty || role == AppRole.hod ? 'f1' : 'usr_${role.name}');

        final user = UserModel(
          id: id,
          name: '${role.displayName} User',
          email: '${role.name}@acadex.com',
          role: role,
          collegeId: 'c1',
          departmentId: 'd1',
        );

        final container = ProviderContainer(
          overrides: testOverrides(user),
        );

        final router = container.read(appRouterProvider);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(
              routerConfig: router,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final homeRoute = ShellWrapper.getHomeRouteForRole(role);
        router.go(homeRoute);
        await tester.pumpAndSettle();
        expect(find.text('Component Load Error'), findsNothing, reason: 'Failed at root for $role');

        // Traverse Notifications and pop back
        router.push('/notifications');
        await tester.pumpAndSettle();
        expect(find.text('Component Load Error'), findsNothing, reason: 'Failed in notifications for $role');

        final BuildContext notifContext = tester.element(find.byType(Scaffold).first);
        notifContext.safePop(fallbackRoute: homeRoute);
        await tester.pumpAndSettle();
        expect(find.text('Component Load Error'), findsNothing, reason: 'Failed returning from notifications for $role');

        // Traverse Profile and pop back
        router.push('/profile');
        await tester.pumpAndSettle();
        expect(find.text('Component Load Error'), findsNothing, reason: 'Failed in profile for $role');

        final BuildContext profileContext = tester.element(find.byType(Scaffold).first);
        profileContext.safePop(fallbackRoute: homeRoute);
        await tester.pumpAndSettle();
        expect(find.text('Component Load Error'), findsNothing, reason: 'Failed returning from profile for $role');

        container.dispose();
      }
    });

    testWidgets('4. Standalone Detail & Form routes have deterministic single Scaffold ownership', (tester) async {
      final user = UserModel(
        id: 'usr_admin',
        name: 'College Admin',
        email: 'admin@acadex.com',
        role: AppRole.collegeAdmin,
        collegeId: 'c1',
      );

      final container = ProviderContainer(
        overrides: testOverrides(user),
      );

      final router = container.read(appRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Go directly to department detail
      router.go('/academics/departments/d1');
      await tester.pumpAndSettle();

      // Verify no assertion, no component load error
      expect(find.text('Component Load Error'), findsNothing);
      expect(find.byType(Scaffold), findsNWidgets(1)); // Exactly 1 Scaffold, no nested child Scaffold

      // Push edit department form
      router.push('/academics/departments/edit/d1');
      await tester.pumpAndSettle();

      expect(find.text('Component Load Error'), findsNothing);
      expect(find.byType(Scaffold), findsNWidgets(1)); // Exactly 1 Scaffold, no nested child Scaffold

      // Pop back
      final BuildContext formCtx = tester.element(find.byType(Scaffold).first);
      formCtx.safePop(fallbackRoute: '/academics/departments/d1');
      await tester.pumpAndSettle();

      expect(find.text('Component Load Error'), findsNothing);
      expect(find.byType(Scaffold), findsNWidgets(1));

      container.dispose();
    });

    testWidgets('5. 10-Flow Sweep (Flows A through J) repeatedly navigated and popped', (tester) async {
      final user = UserModel(
        id: 'usr_super',
        name: 'Super Admin',
        email: 'super@acadex.com',
        role: AppRole.superAdmin,
        collegeId: 'c1',
      );

      final container = ProviderContainer(
        overrides: testOverrides(user),
      );

      final router = container.read(appRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      const homeRoute = '/dashboard/super_admin';

      // Repeat the 10 flows twice
      for (int iteration = 0; iteration < 2; iteration++) {
        // Flow A: Dashboard -> Colleges -> Detail -> Back
        router.go('/academics/colleges');
        await tester.pumpAndSettle();
        router.push('/academics/colleges/c1');
        await tester.pumpAndSettle();
        expect(find.text('Component Load Error'), findsNothing);
        router.pop();
        await tester.pumpAndSettle();
        expect(find.text('Component Load Error'), findsNothing);

        // Flow B: Dashboard -> Colleges -> Edit College -> Back
        router.push('/academics/colleges/edit/c1');
        await tester.pumpAndSettle();
        expect(find.text('Component Load Error'), findsNothing);
        router.pop();
        await tester.pumpAndSettle();
        expect(find.text('Component Load Error'), findsNothing);

        // Flow C: Dashboard -> Users -> User Detail -> Back
        router.go('/users');
        await tester.pumpAndSettle();
        router.push('/users/usr_super');
        await tester.pumpAndSettle();
        expect(find.text('Component Load Error'), findsNothing);
        router.pop();
        await tester.pumpAndSettle();

        // Flow D: Dashboard -> Users -> Edit User -> Back
        router.push('/users/edit/usr_super');
        await tester.pumpAndSettle();
        expect(find.text('Component Load Error'), findsNothing);
        router.pop();
        await tester.pumpAndSettle();

        // Flow E: Dashboard -> Profile -> Back
        router.go(homeRoute);
        await tester.pumpAndSettle();
        router.push('/profile');
        await tester.pumpAndSettle();
        expect(find.text('Component Load Error'), findsNothing);
        router.pop();
        await tester.pumpAndSettle();

        // Flow F: Dashboard -> Notifications -> Back
        router.push('/notifications');
        await tester.pumpAndSettle();
        expect(find.text('Component Load Error'), findsNothing);
        router.pop();
        await tester.pumpAndSettle();

        // Flow G: Dashboard -> Settings -> Back
        router.push('/settings');
        await tester.pumpAndSettle();
        expect(find.text('Component Load Error'), findsNothing);
        router.pop();
        await tester.pumpAndSettle();

        // Flow H: Dashboard -> Timetable -> Back
        router.go('/timetable');
        await tester.pumpAndSettle();
        expect(find.text('Component Load Error'), findsNothing);
        router.go(homeRoute);
        await tester.pumpAndSettle();

        // Flow I: Dashboard -> Attendance -> Back
        router.go('/attendance');
        await tester.pumpAndSettle();
        expect(find.text('Component Load Error'), findsNothing);
        router.go(homeRoute);
        await tester.pumpAndSettle();

        // Flow J: Dashboard -> AI Assistant -> Back
        router.push('/ai-assistant');
        await tester.pumpAndSettle();
        expect(find.text('Component Load Error'), findsNothing);
        router.pop();
        await tester.pumpAndSettle();
        expect(find.text('Component Load Error'), findsNothing);
      }

      container.dispose();
    });
  });
}
