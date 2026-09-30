import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_management/features/dashboard/domain/models/home_dashboard_models.dart';
import 'package:campus_management/features/dashboard/data/repositories/dashboard_repository.dart';
import 'package:campus_management/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:campus_management/features/dashboard/presentation/screens/student_dashboard.dart';
import 'package:campus_management/features/dashboard/presentation/screens/faculty_dashboard.dart';
import 'package:campus_management/features/dashboard/presentation/screens/hod_dashboard.dart';
import 'package:campus_management/features/dashboard/presentation/screens/college_admin_dashboard.dart';
import 'package:campus_management/features/dashboard/presentation/screens/super_admin_dashboard.dart';
import 'package:campus_management/core/realtime/models/realtime_event.dart';
import 'package:campus_management/core/realtime/presentation/providers/realtime_providers.dart';

// -----------------------------------------------------------------------------
// FAKE AUTH NOTIFIER
// -----------------------------------------------------------------------------
class _FakeAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _FakeAuthNotifier(super.state);

  @override
  void updateCurrentUser(UserModel user) {
    if (state is AuthAuthenticated) {
      state = AuthAuthenticated(
        user: user,
        token: (state as AuthAuthenticated).token,
      );
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// -----------------------------------------------------------------------------
// FAKE REPOSITORY
// -----------------------------------------------------------------------------
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
HomeDashboardModel createMockStudentDashboard({
  bool emptyLists = false,
}) {
  return HomeDashboardModel(
    role: 'STUDENT',
    greeting: const DashboardGreetingModel(
      greetingText: 'Good morning',
      displayName: 'Aarav Patel',
      role: 'STUDENT',
    ),
    context: const DashboardContextModel(
      isEnrollmentAvailable: true,
      collegeName: 'Apex Institute of Technology',
      departmentName: 'Computer Science & Engineering',
      courseName: 'B.Tech CSE',
      academicStage: 'Year 3',
      semesterNumber: 6,
      sectionName: 'Section A',
    ),
    alerts: emptyLists
        ? []
        : [
            const DashboardAlertModel(
              id: 'alert_1',
              type: 'ATTENDANCE',
              severity: 'WARNING',
              title: 'Low Attendance Warning',
              message: 'Your overall attendance is at 72%, below the 75% threshold.',
            ),
          ],
    pendingActions: emptyLists
        ? []
        : [
            const DashboardPendingActionModel(
              id: 'act_1',
              title: 'Assignment 1: Distributed Algorithms',
              description: 'Due on Oct 2, 2026. Submit before midnight.',
              type: 'ASSIGNMENT',
              priority: 'HIGH',
              route: '/assignments',
              actionLabel: 'Submit',
              deadline: '2026-10-02T23:59:59Z',
            ),
          ],
    upcoming: emptyLists
        ? []
        : [
            const DashboardUpcomingItemModel(
              id: 'up_1',
              title: 'Distributed Systems Lecture',
              subtitle: 'Room 402 • Prof. Alan Turing',
              startTime: '2026-09-29T10:00:00Z',
              endTime: '2026-09-29T11:00:00Z',
              type: 'CLASS',
              location: 'Room 402',
            ),
          ],
    quickActions: [
      const DashboardQuickActionModel(
        id: 'qa_tt',
        label: 'Timetable',
        route: '/timetable',
        icon: 'calendar',
      ),
      const DashboardQuickActionModel(
        id: 'qa_att',
        label: 'Attendance',
        route: '/attendance',
        icon: 'checkSquare',
      ),
      const DashboardQuickActionModel(
        id: 'qa_assign',
        label: 'Assignments',
        route: '/assignments',
        icon: 'fileText',
      ),
      const DashboardQuickActionModel(
        id: 'qa_results',
        label: 'Results',
        route: '/results',
        icon: 'award',
      ),
    ],
    summary: const DashboardSummaryModel(
      attendancePercentage: 84.5,
      assignmentsPending: 1,
      latestResultStatus: 'AVAILABLE',
    ),
    recent: emptyLists
        ? []
        : [
            const DashboardRecentActivityModel(
              id: 'rec_1',
              title: 'Internal Assessment 1 Marks Published',
              description: 'Algorithms & Data Structures',
              timestamp: '2026-09-28T14:30:00Z',
              type: 'ASSESSMENT',
            ),
          ],
  );
}

HomeDashboardModel createMockFacultyDashboard() {
  return const HomeDashboardModel(
    role: 'FACULTY',
    greeting: DashboardGreetingModel(
      greetingText: 'Good morning',
      displayName: 'Dr. Alan Turing',
      role: 'FACULTY',
    ),
    context: DashboardContextModel(
      collegeName: 'Apex Institute of Technology',
      departmentName: 'Computer Science & Engineering',
      designation: 'Professor',
      activeTeachingAssignmentsCount: 3,
    ),
    alerts: [],
    pendingActions: [
      DashboardPendingActionModel(
        id: 'act_fac_1',
        title: 'Grade Unit Test 1 Submissions',
        description: '14 pending submissions awaiting evaluation',
        type: 'GRADING',
        priority: 'HIGH',
        route: '/assessments',
        actionLabel: 'Grade',
      ),
    ],
    upcoming: [
      DashboardUpcomingItemModel(
        id: 'up_fac_1',
        title: 'Algorithms Lecture - Section A',
        subtitle: 'Room 301',
        startTime: '2026-09-29T11:00:00Z',
        endTime: '2026-09-29T12:00:00Z',
        type: 'CLASS',
        location: 'Room 301',
      ),
    ],
    quickActions: [
      DashboardQuickActionModel(
        id: 'qa_f1',
        label: 'Take Attendance',
        route: '/attendance/mark',
        icon: 'checkSquare',
      ),
      DashboardQuickActionModel(
        id: 'qa_f2',
        label: 'Grade Assignments',
        route: '/assignments',
        icon: 'award',
      ),
    ],
    summary: DashboardSummaryModel(
      assignedClassesCount: 3,
      submissionsAwaitingReview: 14,
    ),
    recent: [],
  );
}

HomeDashboardModel createMockHODDashboard() {
  return const HomeDashboardModel(
    role: 'HOD',
    greeting: DashboardGreetingModel(
      greetingText: 'Good morning',
      displayName: 'Prof. Grace Hopper',
      role: 'HOD',
    ),
    context: DashboardContextModel(
      collegeName: 'Apex Institute of Technology',
      departmentName: 'Computer Science & Engineering',
      departmentCode: 'CSE',
      designation: 'Head of Department',
    ),
    alerts: [],
    pendingActions: [
      DashboardPendingActionModel(
        id: 'act_hod_1',
        title: 'Faculty Leave Application',
        description: 'Dr. Turing requested 2 days casual leave',
        type: 'REQUEST',
        priority: 'HIGH',
        route: '/requests',
        actionLabel: 'Review',
      ),
    ],
    upcoming: [],
    quickActions: [
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
    ],
    summary: DashboardSummaryModel(
      activeFacultyCount: 24,
      activeStudentsCount: 480,
      pendingDepartmentRequests: 5,
    ),
    recent: [],
  );
}

HomeDashboardModel createMockCollegeAdminDashboard() {
  return const HomeDashboardModel(
    role: 'COLLEGE_ADMIN',
    greeting: DashboardGreetingModel(
      greetingText: 'Welcome back',
      displayName: 'Dean Katherine Johnson',
      role: 'COLLEGE_ADMIN',
    ),
    context: DashboardContextModel(
      collegeName: 'Apex Institute of Technology',
      collegeCode: 'APEX',
      administrativeScope: 'College-wide',
    ),
    alerts: [],
    pendingActions: [
      DashboardPendingActionModel(
        id: 'act_ca_1',
        title: 'Semester Timetable Approval',
        description: 'Mechanical Engineering timetable ready for signoff',
        type: 'TIMETABLE',
        priority: 'HIGH',
        route: '/timetable',
        actionLabel: 'Approve',
      ),
    ],
    upcoming: [],
    quickActions: [
      DashboardQuickActionModel(
        id: 'qa_ca1',
        label: 'Manage Departments',
        route: '/departments',
        icon: 'building',
      ),
      DashboardQuickActionModel(
        id: 'qa_ca2',
        label: 'User Management',
        route: '/users',
        icon: 'users',
      ),
    ],
    summary: DashboardSummaryModel(
      departmentsCount: 8,
      studentsCount: 3200,
      facultyCount: 160,
    ),
    recent: [],
  );
}

HomeDashboardModel createMockSuperAdminDashboard() {
  return const HomeDashboardModel(
    role: 'SUPER_ADMIN',
    greeting: DashboardGreetingModel(
      greetingText: 'Platform Overview',
      displayName: 'Platform Administrator',
      role: 'SUPER_ADMIN',
    ),
    context: DashboardContextModel(
      scope: 'Multi-Tenant Global Platform',
    ),
    alerts: [],
    pendingActions: [],
    upcoming: [],
    quickActions: [
      DashboardQuickActionModel(
        id: 'qa_sa1',
        label: 'College Tenants',
        route: '/colleges',
        icon: 'building',
      ),
      DashboardQuickActionModel(
        id: 'qa_sa2',
        label: 'System Logs',
        route: '/audit-logs',
        icon: 'receipt',
      ),
    ],
    summary: DashboardSummaryModel(
      collegesCount: 15,
      activeCollegesCount: 15,
      systemStatus: 'OPERATIONAL',
    ),
    recent: [],
  );
}

// -----------------------------------------------------------------------------
// TEST SUITE
// -----------------------------------------------------------------------------
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testStudentUser = UserModel(
    id: 'user_1',
    name: 'Aarav Patel',
    email: 'aarav@apex.edu',
    role: AppRole.student,
    collegeId: 'college_1',
  );

  Widget buildTestableWidget({
    required Widget child,
    required DashboardRepository repository,
    Size surfaceSize = const Size(390, 844),
  }) {
    return ProviderScope(
      overrides: [
        dashboardRepositoryProvider.overrideWithValue(repository),
        authProvider.overrideWith(
          (ref) => _FakeAuthNotifier(
            AuthAuthenticated(user: testStudentUser, token: 'mock_jwt'),
          ),
        ),
      ],
      child: MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: MediaQuery(
          data: MediaQueryData(size: surfaceSize),
          child: Scaffold(body: child),
        ),
      ),
    );
  }

  group('Prompt 49 - Student Dashboard Tests', () {
    testWidgets('renders student greeting, context card, alerts, and quick actions', (tester) async {
      final repo = FakeDashboardRepository(mockData: createMockStudentDashboard());

      await tester.pumpWidget(
        buildTestableWidget(
          child: const StudentDashboard(),
          repository: repo,
        ),
      );
      await tester.pumpAndSettle();

      // 1. Greeting
      expect(find.text('Good morning'), findsOneWidget);
      expect(find.text('Aarav Patel'), findsOneWidget);

      // 2. Academic Context
      expect(find.text('B.Tech CSE'), findsOneWidget);
      expect(find.text('Semester 6'), findsOneWidget);
      expect(find.text('Section A'), findsOneWidget);

      // 3. Alert
      expect(find.text('Low Attendance Warning'), findsOneWidget);

      // 4. Pending Action
      expect(find.text('Assignment 1: Distributed Algorithms'), findsOneWidget);

      // 5. Upcoming Schedule
      expect(find.text('Distributed Systems Lecture'), findsOneWidget);
      expect(find.text('Room 402'), findsOneWidget);

      // 6. Quick Actions
      expect(find.text('Timetable'), findsOneWidget);
      expect(find.text('Attendance'), findsNWidgets(2)); // Quick action + summary card
      expect(find.text('Assignments'), findsNWidgets(2)); // Quick action + summary card
      expect(find.text('Results'), findsOneWidget);

      // 7. Academic Summary Metrics
      expect(find.text('84.5%'), findsOneWidget);
      expect(find.text('Available'), findsOneWidget);

      // 8. Recent Activity
      expect(find.text('Internal Assessment 1 Marks Published'), findsOneWidget);
    });

    testWidgets('handles empty state arrays gracefully without crashing', (tester) async {
      final repo = FakeDashboardRepository(
        mockData: createMockStudentDashboard(emptyLists: true),
      );

      await tester.pumpWidget(
        buildTestableWidget(
          child: const StudentDashboard(),
          repository: repo,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Actions Requiring Attention'), findsNothing);
      expect(find.text('No classes or events scheduled right now.'), findsOneWidget);
      expect(find.text("You're all caught up."), findsOneWidget);
      // Alerts section should be hidden when empty
      expect(find.text('Important Alerts'), findsNothing);
    });

    for (final size in [
      const Size(360, 800), // Standard compact Android
      const Size(390, 844), // iPhone 12/13/14
      const Size(412, 915), // Pixel / Flagship Android
    ]) {
      testWidgets('renders student dashboard at ${size.width}x${size.height} without RenderFlex overflow', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final repo = FakeDashboardRepository(mockData: createMockStudentDashboard());

        await tester.pumpWidget(
          buildTestableWidget(
            child: const StudentDashboard(),
            repository: repo,
            surfaceSize: size,
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Aarav Patel'), findsOneWidget);
      });
    }
  });

  group('Prompt 49 - Faculty Dashboard Tests', () {
    testWidgets('renders faculty greeting, teaching context, metrics, and actions', (tester) async {
      final repo = FakeDashboardRepository(mockData: createMockFacultyDashboard());

      await tester.pumpWidget(
        buildTestableWidget(
          child: const FacultyDashboard(),
          repository: repo,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Good morning'), findsOneWidget);
      expect(find.text('Dr. Alan Turing'), findsOneWidget);
      expect(find.text('Computer Science & Engineering'), findsOneWidget);
      expect(find.text('Professor'), findsOneWidget);
      expect(find.text('Grade Unit Test 1 Submissions'), findsOneWidget);
      expect(find.text('Take Attendance'), findsOneWidget);
      expect(find.text('Grade Assignments'), findsOneWidget);

      // Metrics
      expect(find.text('3'), findsOneWidget); // Assigned Classes
      expect(find.text('14'), findsOneWidget); // Submissions Awaiting Review
    });

    testWidgets('renders faculty dashboard without RenderFlex overflow at 360px', (tester) async {
      final size = const Size(360, 800);
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = FakeDashboardRepository(mockData: createMockFacultyDashboard());
      await tester.pumpWidget(
        buildTestableWidget(
          child: const FacultyDashboard(),
          repository: repo,
          surfaceSize: size,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('Prompt 49 - HOD Dashboard Tests', () {
    testWidgets('renders HOD department overview, metrics, and quick actions', (tester) async {
      final repo = FakeDashboardRepository(mockData: createMockHODDashboard());

      await tester.pumpWidget(
        buildTestableWidget(
          child: const HodDashboard(),
          repository: repo,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Good morning'), findsOneWidget);
      expect(find.text('Prof. Grace Hopper'), findsOneWidget);
      expect(find.text('Computer Science & Engineering'), findsOneWidget);
      expect(find.text('Head of Department'), findsOneWidget);
      expect(find.text('CSE'), findsOneWidget);
      expect(find.text('Faculty Leave Application'), findsOneWidget);
      expect(find.text('Faculty Management'), findsOneWidget);
      expect(find.text('Curriculum & Structure'), findsOneWidget);

      // Department Metrics
      expect(find.text('24'), findsOneWidget); // Department Faculty
      expect(find.text('480'), findsOneWidget); // Department Students
    });

    testWidgets('renders HOD dashboard without RenderFlex overflow at 360px', (tester) async {
      final size = const Size(360, 800);
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = FakeDashboardRepository(mockData: createMockHODDashboard());
      await tester.pumpWidget(
        buildTestableWidget(
          child: const HodDashboard(),
          repository: repo,
          surfaceSize: size,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('Prompt 49 - College Admin & Super Admin Dashboard Tests', () {
    testWidgets('renders College Admin institutional context and metrics', (tester) async {
      final repo = FakeDashboardRepository(mockData: createMockCollegeAdminDashboard());

      await tester.pumpWidget(
        buildTestableWidget(
          child: const CollegeAdminDashboard(),
          repository: repo,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Dean Katherine Johnson'), findsOneWidget);
      expect(find.text('Apex Institute of Technology'), findsOneWidget);
      expect(find.text('College Administration'), findsOneWidget);
      expect(find.text('Semester Timetable Approval'), findsOneWidget);
      expect(find.text('Manage Departments'), findsOneWidget);
      expect(find.text('User Management'), findsOneWidget);

      // Institutional Metrics
      expect(find.text('8'), findsOneWidget); // Total Departments
      expect(find.text('3200'), findsOneWidget); // Total Students
      expect(find.text('160'), findsOneWidget); // Total Faculty
    });

    testWidgets('renders Super Admin platform metrics and quick actions', (tester) async {
      final repo = FakeDashboardRepository(mockData: createMockSuperAdminDashboard());

      await tester.pumpWidget(
        buildTestableWidget(
          child: const SuperAdminDashboard(),
          repository: repo,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Platform Administrator'), findsOneWidget);
      expect(find.text('ACADEX Platform Administration'), findsOneWidget);
      expect(find.text('College Tenants'), findsOneWidget);
      expect(find.text('System Logs'), findsOneWidget);

      // Super Admin Summary
      expect(find.text('15'), findsNWidgets(2)); // Colleges Count and Active Tenants
      expect(find.text('OPERATIONAL'), findsOneWidget);
    });
  });

  group('Prompt 49 - State Handling (Loading & Error)', () {
    testWidgets('displays loading indicator while homeDashboardProvider is loading', (tester) async {
      final completer = Completer<HomeDashboardModel>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            homeDashboardProvider.overrideWith((ref) => completer.future),
            authProvider.overrideWith(
              (ref) => _FakeAuthNotifier(
                AuthAuthenticated(user: testStudentUser, token: 'mock_jwt'),
              ),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: StudentDashboard()),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete(createMockStudentDashboard());
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Aarav Patel'), findsOneWidget);
    });

    testWidgets('displays error state with retry button on error', (tester) async {
      final repo = FakeDashboardRepository(
        throwError: Exception('Connection timed out'),
      );

      await tester.pumpWidget(
        buildTestableWidget(
          child: const StudentDashboard(),
          repository: repo,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Unable to load dashboard'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
    });
  });

  group('Prompt 49 - Realtime Dispatcher Invalidation Tests', () {
    test('invalidates homeDashboardProvider upon receiving domain events', () async {
      final container = ProviderContainer(
        overrides: [
          dashboardRepositoryProvider.overrideWithValue(
            FakeDashboardRepository(mockData: createMockStudentDashboard()),
          ),
          authProvider.overrideWith(
            (ref) => _FakeAuthNotifier(
              AuthAuthenticated(user: testStudentUser, token: 'mock_jwt'),
            ),
          ),
        ],
      );

      // Pre-warm the provider
      final initialData = await container.read(homeDashboardProvider.future);
      expect(initialData.greeting.displayName, equals('Aarav Patel'));

      final streamController = StreamController<RealtimeEvent>.broadcast();
      final dispatcher = container.read(realtimeDispatcherProvider);
      dispatcher.start(streamController.stream);

      // Dispatch domain events
      final events = [
        RealtimeEvent(
          eventId: 'evt_dash_1',
          eventVersion: 1,
          eventType: 'dashboard.refreshed',
          aggregateType: 'dashboard',
          aggregateId: 'dash_1',
          action: 'refreshed',
          occurredAt: DateTime.now(),
          collegeId: 'college_1',
          scope: {},
          payload: {},
        ),
        RealtimeEvent(
          eventId: 'evt_note_1',
          eventVersion: 1,
          eventType: 'note.published',
          aggregateType: 'note',
          aggregateId: 'note_1',
          action: 'published',
          occurredAt: DateTime.now(),
          collegeId: 'college_1',
          scope: {},
          payload: {},
        ),
      ];

      for (final event in events) {
        streamController.add(event);
      }

      // Allow debounce window (300ms) to fire
      await Future<void>.delayed(const Duration(milliseconds: 350));

      // Test authoritative resync
      dispatcher.triggerAuthoritativeResync();

      dispatcher.stop();
      await streamController.close();
      container.dispose();
    });
  });
}
