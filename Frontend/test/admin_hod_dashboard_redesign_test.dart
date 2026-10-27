import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_management/features/academic_structure/domain/models/academic_models.dart';
import 'package:campus_management/features/academic_structure/presentation/providers/academic_providers.dart';
import 'package:campus_management/features/dashboard/domain/models/home_dashboard_models.dart';
import 'package:campus_management/features/dashboard/data/repositories/dashboard_repository.dart';
import 'package:campus_management/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:campus_management/features/dashboard/presentation/screens/college_admin_dashboard.dart';
import 'package:campus_management/features/dashboard/presentation/screens/hod_dashboard.dart';
import 'package:campus_management/features/timetable/presentation/providers/timetable_providers.dart';
import 'package:campus_management/features/timetable/domain/models/timetable_models.dart';
import 'package:campus_management/core/presentation/widgets/acadex_card.dart';
import 'package:campus_management/core/presentation/widgets/acadex_feedback.dart';
import 'package:campus_management/features/dashboard/presentation/widgets/home_dashboard_widgets.dart';
import 'package:go_router/go_router.dart';

// -----------------------------------------------------------------------------
// FAKE AUTH & REPO HELPERS
// -----------------------------------------------------------------------------
class _FakeAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _FakeAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeDashboardRepository implements DashboardRepository {
  HomeDashboardModel? mockData;
  Exception? throwError;

  FakeDashboardRepository({this.mockData, this.throwError});

  @override
  Future<HomeDashboardModel> getHomeDashboard({String? date}) async {
    if (throwError != null) throw throwError!;
    return mockData!;
  }
}

// -----------------------------------------------------------------------------
// MOCK DATA FACTORIES
// -----------------------------------------------------------------------------
final testCollegeAdminUser = UserModel(
  id: 'usr_admin_1',
  name: 'Dean Katherine Johnson',
  email: 'admin@apex.edu',
  role: AppRole.collegeAdmin,
  collegeId: 'clg_apex_1',
);

final testHodUser = UserModel(
  id: 'usr_hod_1',
  name: 'Prof. Grace Hopper',
  email: 'hod.cse@apex.edu',
  role: AppRole.hod,
  collegeId: 'clg_apex_1',
  departmentId: 'dept_cse_1',
);

HomeDashboardModel createTestCollegeAdminDashboard({
  bool emptyActivity = false,
  double? attendance = 92.4,
}) {
  return HomeDashboardModel(
    role: 'COLLEGE_ADMIN',
    greeting: const DashboardGreetingModel(
      greetingText: 'Welcome back',
      displayName: 'Dean Katherine Johnson',
      role: 'COLLEGE_ADMIN',
    ),
    context: const DashboardContextModel(
      collegeName: 'Apex Institute of Technology',
      collegeCode: 'APEX',
      academicYearName: '2026-2027 Academic Year',
      administrativeScope: 'College-wide',
    ),
    alerts: const [
      DashboardAlertModel(
        id: 'alt_1',
        title: 'Midterm Submission Window Closes Friday',
        message: 'Ensure all departments finalize mark entries.',
        type: 'WARNING',
        severity: 'HIGH',
      ),
    ],
    pendingActions: const [
      DashboardPendingActionModel(
        id: 'act_1',
        title: 'Semester Timetable Approval',
        description: 'Mechanical Engineering timetable ready for signoff',
        type: 'TIMETABLE',
        priority: 'HIGH',
        route: '/timetable',
        actionLabel: 'Approve',
      ),
      DashboardPendingActionModel(
        id: 'act_2',
        title: 'Faculty Recruitment Request',
        description: 'Computer Science requested 2 assistant professors',
        type: 'REQUEST',
        priority: 'NORMAL',
        route: '/requests',
        actionLabel: 'Review',
      ),
    ],
    upcoming: const [
      DashboardUpcomingItemModel(
        id: 'up_1',
        title: 'Academic Council Quarterly Meeting',
        subtitle: 'Conference Hall A',
        startTime: '10:00 AM',
        endTime: '12:30 PM',
        type: 'MEETING',
        location: 'Conference Hall A',
      ),
    ],
    quickActions: const [
      DashboardQuickActionModel(
        id: 'qa_1',
        label: 'Academic Structure',
        route: '/academics/setup',
        icon: 'layers',
      ),
      DashboardQuickActionModel(
        id: 'qa_2',
        label: 'Faculty Directory',
        route: '/academics/faculty',
        icon: 'users',
      ),
      DashboardQuickActionModel(
        id: 'qa_3',
        label: 'Student Directory',
        route: '/academics/students',
        icon: 'graduationCap',
      ),
      DashboardQuickActionModel(
        id: 'qa_4',
        label: 'Institutional Timetable',
        route: '/timetable',
        icon: 'calendar',
      ),
    ],
    summary: DashboardSummaryModel(
      departmentsCount: 8,
      studentsCount: 3200,
      facultyCount: 160,
      coursesCount: 12,
      sectionsCount: 32,
      attendancePercentage: attendance,
      pendingRequestsCount: 5,
    ),
    recent: emptyActivity
        ? const []
        : const [
            DashboardRecentActivityModel(
              id: 'rec_1',
              title: 'New Department Approved: Data Science',
              description: 'Effective Academic Year 2026-2027',
              timestamp: '2 hours ago',
              type: 'ACADEMIC',
            ),
          ],
  );
}

HomeDashboardModel createTestHodDashboard({
  bool emptyUpcoming = false,
  double? attendance = 89.6,
}) {
  return HomeDashboardModel(
    role: 'HOD',
    greeting: const DashboardGreetingModel(
      greetingText: 'Good morning',
      displayName: 'Prof. Grace Hopper',
      role: 'HOD',
    ),
    context: const DashboardContextModel(
      collegeName: 'Apex Institute of Technology',
      departmentName: 'Computer Science & Engineering',
      departmentCode: 'CSE',
      academicYearName: '2026-2027 Academic Year',
      designation: 'Head of Department',
    ),
    alerts: const [
      DashboardAlertModel(
        id: 'alt_hod_1',
        title: 'Lab 3 Hardware Maintenance',
        message: 'Scheduled maintenance from 2 PM to 5 PM today.',
        type: 'INFO',
        severity: 'NORMAL',
      ),
    ],
    pendingActions: const [
      DashboardPendingActionModel(
        id: 'act_hod_1',
        title: 'Faculty Leave Application',
        description: 'Dr. Alan Turing requested 2 days casual leave',
        type: 'REQUEST',
        priority: 'HIGH',
        route: '/requests',
        actionLabel: 'Review',
      ),
    ],
    upcoming: emptyUpcoming
        ? const []
        : const [
            DashboardUpcomingItemModel(
              id: 'up_hod_1',
              title: 'Operating Systems Lecture',
              subtitle: 'Section B • Room 402',
              startTime: '11:00 AM',
              endTime: '12:00 PM',
              type: 'CLASS',
              location: 'Room 402',
            ),
          ],
    quickActions: const [
      DashboardQuickActionModel(
        id: 'qa_h1',
        label: 'Faculty Management',
        route: '/faculty-management',
        icon: 'users',
      ),
      DashboardQuickActionModel(
        id: 'qa_h2',
        label: 'Curriculum & Structure',
        route: '/academic-structure',
        icon: 'network',
      ),
      DashboardQuickActionModel(
        id: 'qa_h3',
        label: 'Department Timetable',
        route: '/timetable',
        icon: 'calendar',
      ),
      DashboardQuickActionModel(
        id: 'qa_h4',
        label: 'Attendance Review',
        route: '/attendance/review',
        icon: 'checkSquare',
      ),
    ],
    summary: DashboardSummaryModel(
      activeFacultyCount: 24,
      activeStudentsCount: 480,
      subjectsCount: 18,
      attendancePercentage: attendance,
      pendingDepartmentRequests: 3,
    ),
    recent: const [
      DashboardRecentActivityModel(
        id: 'rec_hod_1',
        title: 'Database Systems Unit Test Completed',
        description: 'Section A - 58 submissions evaluated',
        timestamp: '1 hour ago',
        type: 'ASSESSMENT',
      ),
    ],
  );
}

Widget buildTestableWidget({
  required Widget child,
  required UserModel user,
  required DashboardRepository repository,
  List<TimetableModel> todaySchedule = const [],
}) {
  return ProviderScope(
    overrides: [
      authProvider.overrideWith(
        (ref) => _FakeAuthNotifier(AuthAuthenticated(user: user, token: 'mock_jwt')),
      ),
      dashboardRepositoryProvider.overrideWithValue(repository),
      todayScheduleProvider.overrideWithValue(AsyncValue.data(todaySchedule)),
      facultyAssignmentsProvider.overrideWith(() => _TestFacultyNotifier()),
    ],
    child: MaterialApp(
      home: Scaffold(body: child),
    ),
  );
}

Widget buildRouterTestableWidget({
  required Widget child,
  required UserModel user,
  required DashboardRepository repository,
  required List<RouteBase> extraRoutes,
  List<TimetableModel> todaySchedule = const [],
}) {
  final router = GoRouter(
    initialLocation: '/dashboard',
    routes: [
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => Scaffold(body: child),
      ),
      ...extraRoutes,
    ],
  );

  return ProviderScope(
    overrides: [
      authProvider.overrideWith(
        (ref) => _FakeAuthNotifier(AuthAuthenticated(user: user, token: 'mock_jwt')),
      ),
      dashboardRepositoryProvider.overrideWithValue(repository),
      todayScheduleProvider.overrideWithValue(AsyncValue.data(todaySchedule)),
      facultyAssignmentsProvider.overrideWith(() => _TestFacultyNotifier()),
    ],
    child: MaterialApp.router(
      routerConfig: router,
    ),
  );
}

class _TestFacultyNotifier extends AutoDisposeAsyncNotifier<List<FacultyAssignment>> implements FacultyAssignmentsNotifier {
  @override
  Future<List<FacultyAssignment>> build() async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// -----------------------------------------------------------------------------
// TESTS
// -----------------------------------------------------------------------------
void main() {
  group('College Admin Institutional Command Centre Tests', () {
    testWidgets('renders complete institutional overview with all 6 metrics and academic year context', (tester) async {
      final repo = FakeDashboardRepository(mockData: createTestCollegeAdminDashboard());

      await tester.pumpWidget(
        buildTestableWidget(
          child: const CollegeAdminDashboard(),
          user: testCollegeAdminUser,
          repository: repo,
        ),
      );
      await tester.pumpAndSettle();

      // 1. Greeting & Context
      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Dean Katherine Johnson'), findsOneWidget);
      expect(find.text('Apex Institute of Technology'), findsOneWidget);
      expect(find.text('College Administration'), findsOneWidget);
      expect(find.text('2026-2027 Academic Year'), findsOneWidget);

      // 2. Institutional Overview Heading
      expect(find.text('Institutional Overview'), findsOneWidget);
      expect(find.text('College Scope'), findsOneWidget);

      // 3. 6 Authoritative Metrics
      expect(find.text('Departments'), findsOneWidget);
      expect(
        find.descendant(
          of: find.ancestor(
            of: find.text('Departments'),
            matching: find.byType(AcadexCard),
          ),
          matching: find.text('8'),
        ),
        findsOneWidget,
      );

      expect(find.text('Total Students'), findsOneWidget);
      expect(find.text('3200'), findsOneWidget);

      expect(find.text('Total Faculty'), findsOneWidget);
      expect(find.text('160'), findsOneWidget);

      expect(find.text('Programmes'), findsOneWidget);
      expect(
        find.descendant(
          of: find.ancestor(
            of: find.text('Programmes'),
            matching: find.byType(AcadexCard),
          ),
          matching: find.text('12'),
        ),
        findsOneWidget,
      );

      expect(find.text('Active Sections'), findsOneWidget);
      expect(
        find.descendant(
          of: find.ancestor(
            of: find.text('Active Sections'),
            matching: find.byType(AcadexCard),
          ),
          matching: find.text('32'),
        ),
        findsOneWidget,
      );

      expect(find.text('Campus Attendance'), findsOneWidget);
      expect(find.text('92.4%'), findsOneWidget);

      // 4. Academic Operations Grid
      expect(find.text('Academic Operations'), findsOneWidget);
      expect(find.text('Academic Structure'), findsOneWidget);
      expect(find.text('Faculty Directory'), findsOneWidget);
      expect(find.text('Student Directory'), findsOneWidget);
      expect(find.text('Institutional Timetable'), findsOneWidget);

      // 5. Actions Requiring Attention
      expect(find.text('Actions Requiring Attention'), findsOneWidget);
      expect(find.text('Semester Timetable Approval'), findsOneWidget);
      expect(find.text('Faculty Recruitment Request'), findsOneWidget);

      // 6. Institutional Calendar & Recent Activity
      expect(find.text('Today & Upcoming'), findsOneWidget);
      expect(find.text('Academic Council Quarterly Meeting'), findsOneWidget);
      expect(find.text('Recent Activity'), findsOneWidget);
      expect(find.text('New Department Approved: Data Science'), findsOneWidget);
    });

    testWidgets('omits optional metrics cleanly when not provided by backend without inventing values', (tester) async {
      const minimalData = HomeDashboardModel(
        role: 'COLLEGE_ADMIN',
        greeting: DashboardGreetingModel(
          greetingText: 'Welcome back',
          displayName: 'Dean Katherine Johnson',
          role: 'COLLEGE_ADMIN',
        ),
        context: DashboardContextModel(
          collegeName: 'Apex Institute of Technology',
          collegeCode: 'APEX',
        ),
        alerts: [],
        pendingActions: [],
        upcoming: [],
        quickActions: [],
        summary: DashboardSummaryModel(
          departmentsCount: 8,
          studentsCount: 3200,
          facultyCount: 160,
          pendingRequestsCount: 4,
        ),
        recent: [],
      );
      final repo = FakeDashboardRepository(mockData: minimalData);

      await tester.pumpWidget(
        buildTestableWidget(
          child: const CollegeAdminDashboard(),
          user: testCollegeAdminUser,
          repository: repo,
        ),
      );
      await tester.pumpAndSettle();

      // Core metrics exist
      expect(
        find.descendant(
          of: find.ancestor(
            of: find.text('Departments'),
            matching: find.byType(AcadexCard),
          ),
          matching: find.text('8'),
        ),
        findsOneWidget,
      );
      expect(find.text('3200'), findsOneWidget);
      expect(find.text('160'), findsOneWidget);

      // Optional unreturned metrics are omitted rather than fabricated
      expect(find.text('Programmes'), findsNothing);
      expect(find.text('Active Sections'), findsNothing);
      expect(find.text('Campus Attendance'), findsNothing);

      // Pending requests card is shown when positive
      expect(find.text('Pending Requests'), findsOneWidget);
      expect(
        find.descendant(
          of: find.ancestor(
            of: find.text('Pending Requests'),
            matching: find.byType(AcadexCard),
          ),
          matching: find.text('4'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders College Admin dashboard without overflow on narrow 320px screen', (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = FakeDashboardRepository(mockData: createTestCollegeAdminDashboard());

      await tester.pumpWidget(
        buildTestableWidget(
          child: const CollegeAdminDashboard(),
          user: testCollegeAdminUser,
          repository: repo,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Institutional Overview'), findsOneWidget);
    });

    testWidgets('renders College Admin dashboard without clipping at 1.5x font scale', (tester) async {
      final repo = FakeDashboardRepository(mockData: createTestCollegeAdminDashboard());

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: buildTestableWidget(
            child: const CollegeAdminDashboard(),
            user: testCollegeAdminUser,
            repository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Institutional Overview'), findsOneWidget);
      expect(find.text('Dean Katherine Johnson'), findsOneWidget);
    });
  });

  group('HOD Department Command Centre Tests', () {
    testWidgets('renders complete departmental overview with scoped department metrics and context', (tester) async {
      final repo = FakeDashboardRepository(mockData: createTestHodDashboard());

      await tester.pumpWidget(
        buildTestableWidget(
          child: const HodDashboard(),
          user: testHodUser,
          repository: repo,
        ),
      );
      await tester.pumpAndSettle();

      // 1. Identity & Department Context
      expect(find.text('Good morning'), findsOneWidget);
      expect(find.text('Prof. Grace Hopper'), findsOneWidget);
      expect(find.text('Computer Science & Engineering'), findsOneWidget);
      expect(find.text('Head of Department'), findsOneWidget);
      expect(find.text('CSE'), findsOneWidget);

      // 2. Hero Card Eyebrow and Actions
      expect(find.text('DEPARTMENT HEALTH & OPERATIONS'), findsOneWidget);
      expect(find.text('Department Analytics'), findsOneWidget);
      expect(find.text('Faculty Workload'), findsOneWidget);

      // 3. Quick Operations
      expect(find.text('Faculty Management'), findsOneWidget);
      expect(find.text('Curriculum & Structure'), findsOneWidget);
      expect(find.text('Department Timetable'), findsOneWidget);
      expect(find.text('Attendance Review'), findsOneWidget);

      // 4. Department Overview 4 Metrics
      expect(find.text('Department Overview'), findsOneWidget);
      expect(find.text('Department Faculty'), findsOneWidget);
      expect(
        find.descendant(
          of: find.ancestor(
            of: find.text('Department Faculty'),
            matching: find.byType(AcadexCard),
          ),
          matching: find.text('24'),
        ),
        findsOneWidget,
      );

      expect(find.text('Department Students'), findsOneWidget);
      expect(find.text('480'), findsOneWidget);

      expect(find.text('Department Subjects'), findsOneWidget);
      expect(
        find.descendant(
          of: find.ancestor(
            of: find.text('Department Subjects'),
            matching: find.byType(AcadexCard),
          ),
          matching: find.text('18'),
        ),
        findsOneWidget,
      );

      expect(find.text('Department Attendance'), findsOneWidget);
      expect(find.text('89.6%'), findsOneWidget);

      // 5. Actions & Timetable
      expect(find.text('Faculty Leave Application'), findsOneWidget);
      expect(find.text("Today's Department Timetable"), findsOneWidget);
      expect(find.text('Operating Systems Lecture'), findsOneWidget);
    });

    testWidgets('renders HOD dashboard without overflow on narrow 320px screen', (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = FakeDashboardRepository(mockData: createTestHodDashboard());

      await tester.pumpWidget(
        buildTestableWidget(
          child: const HodDashboard(),
          user: testHodUser,
          repository: repo,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Department Overview'), findsOneWidget);
    });

    testWidgets('renders HOD dashboard without clipping at 1.5x font scale', (tester) async {
      final repo = FakeDashboardRepository(mockData: createTestHodDashboard());

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: buildTestableWidget(
            child: const HodDashboard(),
            user: testHodUser,
            repository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Prof. Grace Hopper'), findsOneWidget);
      expect(find.text('Department Overview'), findsOneWidget);
    });

    testWidgets('displays empty state when no timetable sessions are scheduled for department today', (tester) async {
      final repo = FakeDashboardRepository(mockData: createTestHodDashboard(emptyUpcoming: true));

      await tester.pumpWidget(
        buildTestableWidget(
          child: const HodDashboard(),
          user: testHodUser,
          repository: repo,
          todaySchedule: const [],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No timetable published yet'), findsOneWidget);
      expect(find.text('Manage Timetable'), findsOneWidget);
    });
  });

  group('Multi-Breakpoint Layout & Cross-Tenant Role Isolation Tests', () {
    testWidgets('renders College Admin across phone, tablet, and desktop viewports', (tester) async {
      final repo = FakeDashboardRepository(mockData: createTestCollegeAdminDashboard());

      // 1. Phone 360px
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      await tester.pumpWidget(
        buildTestableWidget(
          child: const CollegeAdminDashboard(),
          user: testCollegeAdminUser,
          repository: repo,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // 2. Tablet 768px
      tester.view.physicalSize = const Size(768, 1024);
      await tester.pumpWidget(
        buildTestableWidget(
          child: const CollegeAdminDashboard(),
          user: testCollegeAdminUser,
          repository: repo,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // 3. Desktop 1200px
      tester.view.physicalSize = const Size(1200, 900);
      await tester.pumpWidget(
        buildTestableWidget(
          child: const CollegeAdminDashboard(),
          user: testCollegeAdminUser,
          repository: repo,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('HOD dashboard never renders college-wide metrics or unauthorized cross-tenant data', (tester) async {
      final repo = FakeDashboardRepository(mockData: createTestHodDashboard());

      await tester.pumpWidget(
        buildTestableWidget(
          child: const HodDashboard(),
          user: testHodUser,
          repository: repo,
        ),
      );
      await tester.pumpAndSettle();

      // HOD scope metrics are present
      expect(find.text('Department Faculty'), findsOneWidget);
      expect(find.text('Department Students'), findsOneWidget);

      // College-wide aggregate headings must NOT appear in HOD dashboard
      expect(find.text('Institutional Overview'), findsNothing);
      expect(find.text('Total Colleges'), findsNothing);
      expect(find.text('Platform Scope'), findsNothing);
    });

    testWidgets('handles error state gracefully with retry button', (tester) async {
      final repo = FakeDashboardRepository(throwError: Exception('Network connection timed out'));

      await tester.pumpWidget(
        buildTestableWidget(
          child: const CollegeAdminDashboard(),
          user: testCollegeAdminUser,
          repository: repo,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AcadexErrorState), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
    });
  });

  group('Prompt V2 Spacing & Navigation Repair Tests', () {
    testWidgets('HOD Department Overview renders 4 compact tiles in a single row at supported widths', (tester) async {
      final repo = FakeDashboardRepository(mockData: createTestHodDashboard());
      final widths = [360.0, 393.0, 430.0, 768.0, 1200.0];

      for (final w in widths) {
        tester.view.physicalSize = Size(w, 800);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          buildTestableWidget(
            child: const HodDashboard(),
            user: testHodUser,
            repository: repo,
          ),
        );
        await tester.pumpAndSettle();

        final overviewGrid = tester.widget<GridView>(
          find.descendant(
            of: find.byType(HodDashboard),
            matching: find.byType(GridView),
          ).first,
        );
        final delegate = overviewGrid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
        expect(delegate.crossAxisCount, 4, reason: 'Expected 4 columns at width $w');
      }

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('HOD Department Overview metrics navigate to authorized destinations on tap', (tester) async {
      final repo = FakeDashboardRepository(mockData: createTestHodDashboard());
      String? lastNavigatedRoute;

      await tester.pumpWidget(
        buildRouterTestableWidget(
          child: const HodDashboard(),
          user: testHodUser,
          repository: repo,
          extraRoutes: [
            GoRoute(
              path: '/academics/faculty',
              builder: (ctx, state) {
                lastNavigatedRoute = '/academics/faculty';
                return const Scaffold(body: Text('Faculty Directory Screen'));
              },
            ),
            GoRoute(
              path: '/academics/students',
              builder: (ctx, state) {
                lastNavigatedRoute = '/academics/students';
                return const Scaffold(body: Text('Students Directory Screen'));
              },
            ),
            GoRoute(
              path: '/academics/subjects',
              builder: (ctx, state) {
                lastNavigatedRoute = '/academics/subjects';
                return const Scaffold(body: Text('Subjects Screen'));
              },
            ),
            GoRoute(
              path: '/attendance',
              builder: (ctx, state) {
                lastNavigatedRoute = '/attendance';
                return const Scaffold(body: Text('Attendance Oversight Screen'));
              },
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // 1. Tap Department Faculty
      await tester.tap(find.text('Department Faculty'));
      await tester.pumpAndSettle();
      expect(lastNavigatedRoute, '/academics/faculty');

      // Return to dashboard and test Department Students
      await tester.pumpWidget(
        buildRouterTestableWidget(
          child: const HodDashboard(),
          user: testHodUser,
          repository: repo,
          extraRoutes: [
            GoRoute(
              path: '/academics/students',
              builder: (ctx, state) {
                lastNavigatedRoute = '/academics/students';
                return const Scaffold(body: Text('Students Directory Screen'));
              },
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Department Students'));
      await tester.pumpAndSettle();
      expect(lastNavigatedRoute, '/academics/students');
    });

    testWidgets('College Admin Departments metric navigates to department directory', (tester) async {
      final repo = FakeDashboardRepository(mockData: createTestCollegeAdminDashboard());
      String? lastNavigatedRoute;

      await tester.pumpWidget(
        buildRouterTestableWidget(
          child: const CollegeAdminDashboard(),
          user: testCollegeAdminUser,
          repository: repo,
          extraRoutes: [
            GoRoute(
              path: '/academics/departments',
              builder: (ctx, state) {
                lastNavigatedRoute = '/academics/departments';
                return const Scaffold(body: Text('Departments Screen'));
              },
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Tap Departments metric in overview
      await tester.tap(find.text('Departments').first);
      await tester.pumpAndSettle();
      expect(lastNavigatedRoute, '/academics/departments');
    });

    testWidgets('Quick Operations tiles use compact layout and 4 columns on mobile', (tester) async {
      final repo = FakeDashboardRepository(mockData: createTestHodDashboard());
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestableWidget(
          child: const HodDashboard(),
          user: testHodUser,
          repository: repo,
        ),
      );
      await tester.pumpAndSettle();

      // The second GridView is Quick Operations
      final grids = tester.widgetList<GridView>(find.byType(GridView)).toList();
      expect(grids.length, greaterThanOrEqualTo(2));
      final opsGrid = grids[1];
      final delegate = opsGrid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 4);

      // Verify compact action cards are rendered
      final actionCards = tester.widgetList<DashboardActionCard>(find.byType(DashboardActionCard)).toList();
      expect(actionCards.isNotEmpty, isTrue);
      for (final card in actionCards) {
        expect(card.isCompact, isTrue);
      }
    });
  });
}
