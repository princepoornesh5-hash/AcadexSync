import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_management/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:campus_management/features/dashboard/presentation/widgets/acadex_drawer.dart';
import 'package:campus_management/app/router/app_router.dart';

class _FakeAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _FakeAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildDrawerApp(AppRole role) {
    final user = UserModel(
      id: 'test-user',
      email: 'test@college.edu',
      name: 'Test User',
      role: role,
      collegeId: 'COL-001',
      departmentId: 'DEP-CSE',
    );

    return ProviderScope(
      key: ValueKey(role),
      overrides: [
        authProvider.overrideWith((ref) => _FakeAuthNotifier(AuthAuthenticated(user: user, token: 'fake-token'))),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: AcadexDrawer(activeRoute: '/dashboard'),
        ),
      ),
    );
  }

  group('ACADEX Feature Removal & Scope Cleanup Tests', () {
    testWidgets('1. College Admin cannot access Official Certificates in Navigation Drawer', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildDrawerApp(AppRole.collegeAdmin));
      await tester.pumpAndSettle();

      expect(find.text('Official Certificates'), findsNothing);
    });

    testWidgets('2. College Admin cannot access Achievements in Navigation Drawer', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildDrawerApp(AppRole.collegeAdmin));
      await tester.pumpAndSettle();

      expect(find.text('Achievements'), findsNothing);
    });

    testWidgets('3. HOD cannot access Official Certificates in Navigation Drawer', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildDrawerApp(AppRole.hod));
      await tester.pumpAndSettle();

      expect(find.text('Official Certificates'), findsNothing);
    });

    testWidgets('4. HOD cannot access Achievements in Navigation Drawer', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildDrawerApp(AppRole.hod));
      await tester.pumpAndSettle();

      expect(find.text('Achievements'), findsNothing);
    });

    testWidgets('5. Faculty cannot access Official Certificates in Navigation Drawer', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildDrawerApp(AppRole.faculty));
      await tester.pumpAndSettle();

      expect(find.text('Official Certificates'), findsNothing);
    });

    testWidgets('6. Faculty cannot access Achievements in Navigation Drawer', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildDrawerApp(AppRole.faculty));
      await tester.pumpAndSettle();

      expect(find.text('Achievements'), findsNothing);
    });

    test('7. Removed routes (/official-certificates, /achievements) are unavailable in router configuration', () {
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith((ref) => _FakeAuthNotifier(
            AuthAuthenticated(
              user: UserModel(
                id: 'u1',
                email: 'u1@test.com',
                name: 'User 1',
                role: AppRole.collegeAdmin,
              ),
              token: 'fake-token',
            ),
          )),
        ],
      );

      final router = container.read(appRouterProvider);
      final registeredPaths = router.configuration.routes
          .whereType<GoRoute>()
          .map((r) => r.path)
          .toList();

      expect(registeredPaths.contains('/official-certificates'), isFalse);
      expect(registeredPaths.contains('/achievements'), isFalse);
      expect(registeredPaths.contains('/certificates'), isFalse);
    });

    test('8. Removed dashboard actions are absent from all role quick action providers', () {
      final container = ProviderContainer();

      final superAdminActions = container.read(superAdminQuickActionsProvider);
      final collegeAdminActions = container.read(collegeAdminQuickActionsProvider);
      final hodActions = container.read(hodQuickActionsProvider);
      final facultyActions = container.read(facultyQuickActionsProvider);
      final studentActions = container.read(studentQuickActionsProvider);

      final allActions = [
        ...superAdminActions,
        ...collegeAdminActions,
        ...hodActions,
        ...facultyActions,
        ...studentActions,
      ];

      for (final action in allActions) {
        expect(action.route, isNot(equals('/official-certificates')));
        expect(action.route, isNot(equals('/achievements')));
        expect(action.route, isNot(equals('/certificates')));
        expect(action.label.toLowerCase().contains('official cert'), isFalse);
        expect(action.label.toLowerCase().contains('achievement'), isFalse);
      }
    });

    testWidgets('9. Existing Attendance navigation still works across all roles', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildDrawerApp(AppRole.collegeAdmin));
      await tester.pumpAndSettle();
      expect(find.text('Attendance'), findsOneWidget);

      await tester.pumpWidget(buildDrawerApp(AppRole.hod));
      await tester.pumpAndSettle();
      expect(find.text('Attendance'), findsOneWidget);

      await tester.pumpWidget(buildDrawerApp(AppRole.faculty));
      await tester.pumpAndSettle();
      expect(find.text('Attendance'), findsOneWidget);

      await tester.pumpWidget(buildDrawerApp(AppRole.student));
      await tester.pumpAndSettle();
      expect(find.text('Attendance'), findsOneWidget);
    });

    testWidgets('10. Existing Timetable navigation still works across all roles', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildDrawerApp(AppRole.collegeAdmin));
      await tester.pumpAndSettle();
      expect(find.text('Manage Timetable'), findsOneWidget);

      await tester.pumpWidget(buildDrawerApp(AppRole.hod));
      await tester.pumpAndSettle();
      expect(find.text('Manage Timetable'), findsOneWidget);

      await tester.pumpWidget(buildDrawerApp(AppRole.faculty));
      await tester.pumpAndSettle();
      expect(find.text('Timetable'), findsOneWidget);

      await tester.pumpWidget(buildDrawerApp(AppRole.student));
      await tester.pumpAndSettle();
      expect(find.text('Timetable'), findsOneWidget);
    });

    testWidgets('11. Existing Notes navigation still works across all roles', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildDrawerApp(AppRole.collegeAdmin));
      await tester.pumpAndSettle();
      expect(find.text('Notes & Resources'), findsOneWidget);

      await tester.pumpWidget(buildDrawerApp(AppRole.faculty));
      await tester.pumpAndSettle();
      expect(find.text('Notes & Resources'), findsOneWidget);

      await tester.pumpWidget(buildDrawerApp(AppRole.student));
      await tester.pumpAndSettle();
      expect(find.text('Notes & Resources'), findsOneWidget);
    });

    testWidgets('12. Existing Academic Structure navigation still works for privileged roles', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildDrawerApp(AppRole.collegeAdmin));
      await tester.pumpAndSettle();
      expect(find.text('Academic Structure'), findsOneWidget);
      expect(find.text('Faculty & Staff'), findsOneWidget);
      expect(find.text('Students'), findsOneWidget);
    });

    test('13. Student functionality is preserved in student quick actions', () {
      final container = ProviderContainer();
      final studentActions = container.read(studentQuickActionsProvider);

      final routes = studentActions.map((a) => a.route).toList();
      expect(routes.contains('/attendance'), isTrue);
      expect(routes.contains('/timetable'), isTrue);
      expect(routes.contains('/notes'), isTrue);
      expect(routes.contains('/profile'), isTrue);
      expect(routes.contains('/ai-assistant'), isTrue);
    });

    test('14. Existing role permissions remain intact without certificate/achievement contamination', () {
      expect(AppRole.superAdmin.value, 'SUPER_ADMIN');
      expect(AppRole.collegeAdmin.value, 'COLLEGE_ADMIN');
      expect(AppRole.hod.value, 'HOD');
      expect(AppRole.faculty.value, 'FACULTY');
      expect(AppRole.student.value, 'STUDENT');
    });

    testWidgets('15. No dead navigation references remain in student drawer', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildDrawerApp(AppRole.student));
      await tester.pumpAndSettle();

      expect(find.text('Official Certificates'), findsNothing);
      expect(find.text('Achievements'), findsNothing);
      expect(find.text('Official Docs'), findsNothing);
    });
  });
}
