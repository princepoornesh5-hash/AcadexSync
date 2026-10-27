import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_management/features/dashboard/domain/models/home_dashboard_models.dart';
import 'package:campus_management/features/dashboard/data/repositories/dashboard_repository.dart';
import 'package:campus_management/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:campus_management/features/dashboard/presentation/screens/student_dashboard.dart';
import 'package:campus_management/features/dashboard/presentation/screens/faculty_dashboard.dart';
import 'package:campus_management/features/dashboard/presentation/widgets/home_dashboard_widgets.dart';

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
// FAKE DASHBOARD REPOSITORY
// -----------------------------------------------------------------------------
class _FakeDashboardRepository implements DashboardRepository {
  final HomeDashboardModel? mockData;
  final Exception? throwError;

  _FakeDashboardRepository({this.mockData, this.throwError});

  @override
  Future<HomeDashboardModel> getHomeDashboard({String? date}) async {
    if (throwError != null) throw throwError!;
    return mockData!;
  }
}

// -----------------------------------------------------------------------------
// TEST DATA FACTORIES
// -----------------------------------------------------------------------------
HomeDashboardModel _createStudentMock({bool empty = false}) {
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
    alerts: empty
        ? []
        : const [
            DashboardAlertModel(
              id: 'alt_std_1',
              type: 'ATTENDANCE',
              severity: 'WARNING',
              title: 'Low Attendance Warning',
              message: 'Your overall attendance is below 75%.',
            ),
          ],
    pendingActions: empty
        ? []
        : const [
            DashboardPendingActionModel(
              id: 'pa_std_1',
              title: 'Lab Exercise: Socket Programming',
              description: 'Due tonight at 11:59 PM.',
              type: 'ASSIGNMENT',
              priority: 'HIGH',
              route: '/assignments',
              actionLabel: 'Submit',
            ),
          ],
    upcoming: empty
        ? []
        : const [
            DashboardUpcomingItemModel(
              id: 'up_std_1',
              title: 'Distributed Systems Lecture',
              startTime: '2026-10-27T10:00:00Z',
              endTime: '2026-10-27T11:00:00Z',
              type: 'CLASS',
              location: 'Room 402',
              route: '/timetable',
            ),
          ],
    quickActions: const [
      DashboardQuickActionModel(
        id: 'qa_s1',
        label: 'Timetable',
        route: '/timetable',
        icon: 'calendar',
        isPrimary: true,
      ),
      DashboardQuickActionModel(
        id: 'qa_s2',
        label: 'Attendance',
        route: '/attendance',
        icon: 'checkSquare',
      ),
      DashboardQuickActionModel(
        id: 'qa_s3',
        label: 'Assignments',
        route: '/assignments',
        icon: 'penTool',
      ),
      DashboardQuickActionModel(
        id: 'qa_s4',
        label: 'Results',
        route: '/academic-results',
        icon: 'award',
      ),
    ],
    summary: const DashboardSummaryModel(
      attendancePercentage: 86.4,
      assignmentsCompleted: 8,
      assignmentsPending: 2,
      practicalsCompleted: 5,
      practicalsScheduled: 1,
      latestResultStatus: 'AVAILABLE',
    ),
    recent: const [],
  );
}

HomeDashboardModel _createFacultyMock({bool empty = false}) {
  return HomeDashboardModel(
    role: 'FACULTY',
    greeting: const DashboardGreetingModel(
      greetingText: 'Good morning',
      displayName: 'Dr. Alan Turing',
      role: 'FACULTY',
    ),
    context: const DashboardContextModel(
      collegeName: 'Apex Institute of Technology',
      departmentName: 'Computer Science & Engineering',
      designation: 'Professor',
    ),
    alerts: empty
        ? []
        : const [
            DashboardAlertModel(
              id: 'alt_fac_1',
              type: 'ATTENDANCE',
              severity: 'WARNING',
              title: 'Attendance Submission Pending',
              message: 'Section A attendance is pending for today.',
            ),
          ],
    pendingActions: empty
        ? []
        : const [
            DashboardPendingActionModel(
              id: 'pa_fac_1',
              title: 'Grade Unit Test 2 Submissions',
              description: '14 submissions waiting for assessment marks.',
              type: 'EVALUATION',
              priority: 'HIGH',
              route: '/assignments',
              actionLabel: 'Grade',
            ),
          ],
    upcoming: empty
        ? []
        : const [
            DashboardUpcomingItemModel(
              id: 'up_fac_1',
              title: 'Advanced Algorithms (CSE-A)',
              startTime: '2026-10-27T09:00:00Z',
              endTime: '2026-10-27T10:00:00Z',
              type: 'CLASS',
              location: 'Hall B',
              route: '/timetable',
            ),
          ],
    quickActions: const [
      DashboardQuickActionModel(
        id: 'qa_f1',
        label: 'Take Attendance',
        route: '/attendance',
        icon: 'checkSquare',
        isPrimary: true,
      ),
      DashboardQuickActionModel(
        id: 'qa_f2',
        label: 'Grade Assignments',
        route: '/assignments',
        icon: 'penTool',
      ),
      DashboardQuickActionModel(
        id: 'qa_f3',
        label: 'Teaching Timetable',
        route: '/timetable',
        icon: 'calendar',
      ),
    ],
    summary: const DashboardSummaryModel(
      assignedClassesCount: 4,
      submissionsAwaitingReview: 14,
      pendingAttendanceSessions: 2,
      pendingAssessmentMarks: 1,
    ),
    recent: const [],
  );
}

// -----------------------------------------------------------------------------
// HELPER HARNESS
// -----------------------------------------------------------------------------
Widget _buildTestApp({
  required Widget child,
  required DashboardRepository repository,
  required UserModel user,
  Size surfaceSize = const Size(390, 844),
  double textScale = 1.0,
}) {
  return ProviderScope(
    overrides: [
      dashboardRepositoryProvider.overrideWithValue(repository),
      authProvider.overrideWith(
        (ref) => _FakeAuthNotifier(
          AuthAuthenticated(user: user, token: 'mock-jwt-token'),
        ),
      ),
    ],
    child: MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: MediaQuery(
        data: MediaQueryData(
          size: surfaceSize,
          textScaler: TextScaler.linear(textScale),
        ),
        child: Scaffold(body: child),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final studentUser = UserModel(
    id: 'usr_student_1',
    name: 'Aarav Patel',
    email: 'aarav@apex.edu',
    role: AppRole.student,
    collegeId: 'col_1',
  );

  final facultyUser = UserModel(
    id: 'usr_faculty_1',
    name: 'Dr. Alan Turing',
    email: 'turing@apex.edu',
    role: AppRole.faculty,
    collegeId: 'col_1',
  );

  group('Student Compact Dashboard Layout & Tiles Tests', () {
    testWidgets('renders all 4 compact centered summary tiles with real student metrics', (tester) async {
      final repo = _FakeDashboardRepository(mockData: _createStudentMock());

      await tester.pumpWidget(
        _buildTestApp(
          child: const StudentDashboard(),
          repository: repo,
          user: studentUser,
        ),
      );
      await tester.pumpAndSettle();

      // Heading and scope badge
      expect(find.text('Academic Snapshot'), findsOneWidget);
      expect(find.text('Personal Academic Status'), findsOneWidget);

      // Compact tiles presence and centered contents
      expect(find.byType(DashboardCompactTile), findsNWidgets(4));

      // 1. Attendance Tile
      expect(find.text('Attendance'), findsNWidgets(2)); // Quick Action + Tile
      expect(find.text('86.4%'), findsOneWidget);
      expect(find.text('Semester Average'), findsOneWidget);

      // 2. Assignments Tile
      expect(find.text('Assignments'), findsNWidgets(2)); // Quick Action + Tile
      expect(find.text('8 / 10'), findsOneWidget);
      expect(find.text('2 pending tasks'), findsOneWidget);

      // 3. Practicals Tile
      expect(find.text('Practicals'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('1 upcoming session'), findsOneWidget);

      // 4. Official Results Tile
      expect(find.text('Official Results'), findsOneWidget);
      expect(find.text('Available'), findsOneWidget);
      expect(find.text('Latest published term'), findsOneWidget);

      // No exception or overflow occurred
      expect(tester.takeException(), isNull);
    });

    testWidgets('Student compact tiles use centered layout and scale-down text', (tester) async {
      final repo = _FakeDashboardRepository(mockData: _createStudentMock());

      await tester.pumpWidget(
        _buildTestApp(
          child: const StudentDashboard(),
          repository: repo,
          user: studentUser,
        ),
      );
      await tester.pumpAndSettle();

      final firstTile = tester.widget<DashboardCompactTile>(
        find.byType(DashboardCompactTile).first,
      );
      expect(firstTile.title, 'Attendance');
      expect(firstTile.value, '86.4%');
      expect(firstTile.icon, LucideIcons.checkSquare);

      // Verify Column inside tile has centered cross/main axes
      final columnFinder = find.descendant(
        of: find.byType(DashboardCompactTile).first,
        matching: find.byType(Column),
      );
      expect(columnFinder, findsOneWidget);
      final column = tester.widget<Column>(columnFinder);
      expect(column.crossAxisAlignment, CrossAxisAlignment.center);
      expect(column.mainAxisAlignment, MainAxisAlignment.center);
    });
  });

  group('Faculty Compact Dashboard Layout & Tiles Tests', () {
    testWidgets('renders all 4 compact centered summary tiles with authorized faculty metrics', (tester) async {
      final repo = _FakeDashboardRepository(mockData: _createFacultyMock());

      await tester.pumpWidget(
        _buildTestApp(
          child: const FacultyDashboard(),
          repository: repo,
          user: facultyUser,
        ),
      );
      await tester.pumpAndSettle();

      // Heading and scope badge
      expect(find.text('Teaching & Evaluation Snapshot'), findsOneWidget);
      expect(find.text('Faculty Instruction Scope'), findsOneWidget);

      // Compact tiles presence
      expect(find.byType(DashboardCompactTile), findsNWidgets(4));

      // 1. Assigned Classes
      expect(find.text('Assigned Classes'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('Teaching sections'), findsOneWidget);

      // 2. Pending Reviews
      expect(find.text('Pending Reviews'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(DashboardCompactTile),
          matching: find.text('14'),
        ),
        findsOneWidget,
      );
      expect(find.text('Awaiting grading'), findsOneWidget);

      // 3. Pending Attendance
      expect(find.text('Pending Attendance'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('Sessions to complete'), findsOneWidget);

      // 4. Assessment Marks
      expect(find.text('Assessment Marks'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(DashboardCompactTile),
          matching: find.text('1'),
        ),
        findsOneWidget,
      );
      expect(find.text('Marks pending entry'), findsOneWidget);

      // No exception or overflow occurred
      expect(tester.takeException(), isNull);
    });

    testWidgets('Faculty compact tiles use centered layout and pressable interactions', (tester) async {
      final repo = _FakeDashboardRepository(mockData: _createFacultyMock());

      await tester.pumpWidget(
        _buildTestApp(
          child: const FacultyDashboard(),
          repository: repo,
          user: facultyUser,
        ),
      );
      await tester.pumpAndSettle();

      final firstTile = tester.widget<DashboardCompactTile>(
        find.byType(DashboardCompactTile).first,
      );
      expect(firstTile.title, 'Assigned Classes');
      expect(firstTile.value, '4');
      expect(firstTile.icon, LucideIcons.bookOpen);

      final columnFinder = find.descendant(
        of: find.byType(DashboardCompactTile).first,
        matching: find.byType(Column),
      );
      expect(columnFinder, findsOneWidget);
      final column = tester.widget<Column>(columnFinder);
      expect(column.crossAxisAlignment, CrossAxisAlignment.center);
      expect(column.mainAxisAlignment, MainAxisAlignment.center);
    });
  });

  group('Multi-Breakpoint Layout & Aspect Ratio Responsiveness', () {
    final testSizes = <String, Size>{
      'Narrow phone (320x640)': const Size(320, 640),
      'Standard Android (360x800)': const Size(360, 800),
      'Standard iPhone (390x844)': const Size(390, 844),
      'Tablet (768x1024)': const Size(768, 1024),
      'Desktop (1280x900)': const Size(1280, 900),
    };

    for (final entry in testSizes.entries) {
      testWidgets('Student Dashboard renders at ${entry.key} without RenderFlex overflow', (tester) async {
        tester.view.physicalSize = entry.value;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final repo = _FakeDashboardRepository(mockData: _createStudentMock());
        await tester.pumpWidget(
          _buildTestApp(
            child: const StudentDashboard(),
            repository: repo,
            user: studentUser,
            surfaceSize: entry.value,
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);

        // Verify column count
        final gridFinder = find.byWidgetPredicate(
          (w) => w is GridView && w.gridDelegate is SliverGridDelegateWithFixedCrossAxisCount,
        );
        expect(gridFinder, findsWidgets);

        final snapshotGrid = tester.widget<GridView>(
          find.descendant(
            of: find.byType(StudentDashboard),
            matching: find.byType(GridView),
          ).last,
        );
        final delegate = snapshotGrid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
        final expectedCols = entry.value.width < 320 ? 2 : 4;
        expect(delegate.crossAxisCount, expectedCols);
      });

      testWidgets('Faculty Dashboard renders at ${entry.key} without RenderFlex overflow', (tester) async {
        tester.view.physicalSize = entry.value;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final repo = _FakeDashboardRepository(mockData: _createFacultyMock());
        await tester.pumpWidget(
          _buildTestApp(
            child: const FacultyDashboard(),
            repository: repo,
            user: facultyUser,
            surfaceSize: entry.value,
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);

        final snapshotGrid = tester.widget<GridView>(
          find.descendant(
            of: find.byType(FacultyDashboard),
            matching: find.byType(GridView),
          ).last,
        );
        final delegate = snapshotGrid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
        final expectedCols = entry.value.width < 320 ? 2 : 4;
        expect(delegate.crossAxisCount, expectedCols);
      });
    }
  });

  group('Accessibility & Dynamic Text Scaling (1.5x font scale)', () {
    testWidgets('Student Dashboard renders without overflow at 1.5x font scale on mobile', (tester) async {
      final repo = _FakeDashboardRepository(mockData: _createStudentMock());

      await tester.pumpWidget(
        _buildTestApp(
          child: const StudentDashboard(),
          repository: repo,
          user: studentUser,
          surfaceSize: const Size(360, 800),
          textScale: 1.5,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(DashboardCompactTile), findsNWidgets(4));
    });

    testWidgets('Faculty Dashboard renders without overflow at 1.5x font scale on mobile', (tester) async {
      final repo = _FakeDashboardRepository(mockData: _createFacultyMock());

      await tester.pumpWidget(
        _buildTestApp(
          child: const FacultyDashboard(),
          repository: repo,
          user: facultyUser,
          surfaceSize: const Size(360, 800),
          textScale: 1.5,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(DashboardCompactTile), findsNWidgets(4));
    });
  });

  group('Role-Specific Tenant Isolation & Data Boundary Tests', () {
    testWidgets('Student Dashboard NEVER displays institutional administrative controls or faculty marking buttons', (tester) async {
      final repo = _FakeDashboardRepository(mockData: _createStudentMock());

      await tester.pumpWidget(
        _buildTestApp(
          child: const StudentDashboard(),
          repository: repo,
          user: studentUser,
        ),
      );
      await tester.pumpAndSettle();

      // Must NOT expose HOD or College Admin controls
      expect(find.text('Department Status'), findsNothing);
      expect(find.text('Institutional Overview'), findsNothing);
      expect(find.text('Manage Departments'), findsNothing);
      expect(find.text('User Management'), findsNothing);
      expect(find.text('Curriculum & Structure'), findsNothing);
      expect(find.text('Take Attendance'), findsNothing);
      expect(find.text('Grade Assignments'), findsNothing);
    });

    testWidgets('Faculty Dashboard NEVER displays college-wide admin metrics or student peer data', (tester) async {
      final repo = _FakeDashboardRepository(mockData: _createFacultyMock());

      await tester.pumpWidget(
        _buildTestApp(
          child: const FacultyDashboard(),
          repository: repo,
          user: facultyUser,
        ),
      );
      await tester.pumpAndSettle();

      // Must NOT expose college-wide admin metrics or student standing
      expect(find.text('Total Colleges'), findsNothing);
      expect(find.text('Institutional Overview'), findsNothing);
      expect(find.text('Manage Departments'), findsNothing);
      expect(find.text('Academic Snapshot'), findsNothing);
      expect(find.text('Official Results'), findsNothing);
    });

    testWidgets('Student and Faculty dashboards display user-friendly error state with retry on failure', (tester) async {
      final repo = _FakeDashboardRepository(
        throwError: Exception('Connection timed out'),
      );

      await tester.pumpWidget(
        _buildTestApp(
          child: const StudentDashboard(),
          repository: repo,
          user: studentUser,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Unable to load dashboard'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
    });
  });
}
