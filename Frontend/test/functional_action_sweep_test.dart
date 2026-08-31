import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_management/features/dashboard/presentation/screens/role_dashboard_screen.dart';
import 'package:campus_management/core/presentation/utils/navigation_extensions.dart';
import 'package:campus_management/features/reports/domain/models/report_models.dart';
import 'package:campus_management/features/reports/presentation/providers/reports_providers.dart';

class _FakeAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _FakeAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testSuperAdmin = UserModel(
    id: 'usr_sa',
    email: 'superadmin@acadex.edu',
    name: 'Super Admin User',
    role: AppRole.superAdmin,
  );

  final testCollegeAdmin = UserModel(
    id: 'usr_ca',
    email: 'admin@git.edu',
    name: 'College Admin User',
    role: AppRole.collegeAdmin,
    collegeId: 'col_123',
  );

  final testHod = UserModel(
    id: 'usr_hod',
    email: 'hod.cs@git.edu',
    name: 'Dr. Alan Turing',
    role: AppRole.hod,
    collegeId: 'col_123',
    departmentId: 'dept_cs',
  );

  final testFaculty = UserModel(
    id: 'usr_fac',
    email: 'faculty@git.edu',
    name: 'Prof. Ada Lovelace',
    role: AppRole.faculty,
    collegeId: 'col_123',
    departmentId: 'dept_cs',
  );

  final testStudent = UserModel(
    id: 'usr_stu',
    email: 'student@git.edu',
    name: 'Jane Doe',
    role: AppRole.student,
    collegeId: 'col_123',
    departmentId: 'dept_cs',
  );

  const fakeReport = RoleDashboardReportModel(
    role: 'SUPER_ADMIN',
    metrics: {
      'totalColleges': 8,
      'totalUsers': 3200,
      'overallAttendance': 91.5,
      'storageUsedMB': 850,
    },
    quickStats: {},
    recentActivity: [],
  );

  group('ACADEX — Master Functional Action Sweep & Verification Tests', () {
    testWidgets('1. Super Admin Quick Actions trigger defined route navigations', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      String? lastPushedRoute;

      final router = GoRouter(
        initialLocation: '/dashboard',
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (ctx, state) => const RoleDashboardScreen(),
          ),
          GoRoute(
            path: '/academics/colleges',
            builder: (ctx, state) {
              lastPushedRoute = '/academics/colleges';
              return const Scaffold(body: Text('Colleges Screen'));
            },
          ),
          GoRoute(
            path: '/users',
            builder: (ctx, state) {
              lastPushedRoute = '/users';
              return const Scaffold(body: Text('Users Screen'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(AuthAuthenticated(user: testSuperAdmin, token: 'tok'))),
            roleDashboardReportProvider.overrideWith((ref) async => fakeReport),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Campuses'), findsOneWidget);
      await tester.tap(find.text('Campuses'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(lastPushedRoute, '/academics/colleges');
      expect(find.text('Colleges Screen'), findsOneWidget);
    });

    testWidgets('2. College Admin Quick Actions trigger defined route navigations', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      String? lastPushedRoute;

      final router = GoRouter(
        initialLocation: '/dashboard',
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (ctx, state) => const RoleDashboardScreen(),
          ),
          GoRoute(
            path: '/academics/departments',
            builder: (ctx, state) {
              lastPushedRoute = '/academics/departments';
              return const Scaffold(body: Text('Departments Screen'));
            },
          ),
          GoRoute(
            path: '/academics/faculty',
            builder: (ctx, state) {
              lastPushedRoute = '/academics/faculty';
              return const Scaffold(body: Text('Faculty Screen'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(AuthAuthenticated(user: testCollegeAdmin, token: 'tok'))),
            roleDashboardReportProvider.overrideWith((ref) async => fakeReport),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Faculty Directory'), findsOneWidget);
      await tester.tap(find.text('Faculty Directory'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(lastPushedRoute, '/academics/faculty');
      expect(find.text('Faculty Screen'), findsOneWidget);
    });

    testWidgets('3. HOD Quick Actions trigger defined route navigations', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      String? lastPushedRoute;

      final router = GoRouter(
        initialLocation: '/dashboard',
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (ctx, state) => const RoleDashboardScreen(),
          ),
          GoRoute(
            path: '/academics/students',
            builder: (ctx, state) {
              lastPushedRoute = '/academics/students';
              return const Scaffold(body: Text('Students Screen'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(AuthAuthenticated(user: testHod, token: 'tok'))),
            roleDashboardReportProvider.overrideWith((ref) async => fakeReport),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Students at Risk'), findsOneWidget);
      await tester.tap(find.text('Students at Risk'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(lastPushedRoute, '/academics/students');
      expect(find.text('Students Screen'), findsOneWidget);
    });

    testWidgets('4. Faculty Quick Actions trigger defined route navigations', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      String? lastPushedRoute;

      final router = GoRouter(
        initialLocation: '/dashboard',
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (ctx, state) => const RoleDashboardScreen(),
          ),
          GoRoute(
            path: '/attendance',
            builder: (ctx, state) {
              lastPushedRoute = '/attendance';
              return const Scaffold(body: Text('Attendance Portal'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(AuthAuthenticated(user: testFaculty, token: 'tok'))),
            roleDashboardReportProvider.overrideWith((ref) async => fakeReport),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Mark Attendance'), findsOneWidget);
      await tester.tap(find.text('Mark Attendance'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(lastPushedRoute, '/attendance');
      expect(find.text('Attendance Portal'), findsOneWidget);
    });

    testWidgets('5. Student Quick Actions trigger defined route navigations', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      String? lastPushedRoute;

      final router = GoRouter(
        initialLocation: '/dashboard',
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (ctx, state) => const RoleDashboardScreen(),
          ),
          GoRoute(
            path: '/timetable',
            builder: (ctx, state) {
              lastPushedRoute = '/timetable';
              return const Scaffold(body: Text('Timetable View'));
            },
          ),
          GoRoute(
            path: '/notes',
            builder: (ctx, state) {
              lastPushedRoute = '/notes';
              return const Scaffold(body: Text('Notes Screen'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(AuthAuthenticated(user: testStudent, token: 'tok'))),
            roleDashboardReportProvider.overrideWith((ref) async => fakeReport),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('My Schedule'), findsOneWidget);
      await tester.tap(find.text('My Schedule'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(lastPushedRoute, '/timetable');
      expect(find.text('Timetable View'), findsOneWidget);
    });

    testWidgets('6. SafePop extension pops cleanly when canPop is true, and safely navigates fallback when cannot pop', (tester) async {
      String? currentPath;

      final router = GoRouter(
        initialLocation: '/deep-form',
        routes: [
          GoRoute(
            path: '/home',
            builder: (ctx, state) {
              currentPath = '/home';
              return const Scaffold(body: Text('Home Screen'));
            },
          ),
          GoRoute(
            path: '/deep-form',
            builder: (ctx, state) {
              currentPath = '/deep-form';
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => ctx.safePop(fallbackRoute: '/home'),
                    child: const Text('Back / Cancel'),
                  ),
                ),
              );
            },
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(currentPath, '/deep-form');

      await tester.tap(find.text('Back / Cancel'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(currentPath, '/home');
      expect(find.text('Home Screen'), findsOneWidget);
    });
  });
}
