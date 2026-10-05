import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_management/app/theme/app_theme.dart';
import 'package:campus_management/core/errors/acadex_error.dart';
import 'package:campus_management/core/presentation/utils/acadex_entity_formatters.dart';
import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_management/features/dashboard/domain/models/home_dashboard_models.dart';
import 'package:campus_management/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:campus_management/features/dashboard/presentation/screens/student_dashboard.dart';
import 'package:campus_management/features/dashboard/presentation/screens/hod_dashboard.dart';
import 'package:campus_management/features/assignments/domain/models/assignment_models.dart';
import 'package:campus_management/features/assignments/presentation/providers/assignments_providers.dart';
import 'package:campus_management/features/assignments/presentation/screens/faculty_assignments_list_screen.dart';

class _FakeAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _FakeAuthNotifier(super.initial);

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

HomeDashboardModel _createMockDashboard({
  required String role,
  required String name,
  List<DashboardUpcomingItemModel> upcoming = const [],
  List<DashboardRecentActivityModel> recent = const [],
}) {
  return HomeDashboardModel(
    role: role,
    greeting: DashboardGreetingModel(
      displayName: name,
      role: role,
      greetingText: 'Welcome back',
    ),
    context: const DashboardContextModel(
      courseName: 'B.Tech Computer Science',
      semesterNumber: 6,
      sectionName: 'A',
      departmentName: 'Computer Science and Engineering',
      departmentCode: 'CSE',
      collegeName: 'Apex Institute of Technology',
    ),
    summary: const DashboardSummaryModel(
      attendancePercentage: 84.5,
      assignmentsCompleted: 6,
      assignmentsPending: 1,
      practicalsCompleted: 4,
      practicalsScheduled: 1,
      latestResultStatus: 'AVAILABLE',
      departmentsCount: 5,
      facultyCount: 28,
      activeFacultyCount: 28,
      studentsCount: 640,
      activeStudentsCount: 640,
      pendingRequestsCount: 2,
      pendingAttendanceCount: 1,
      pendingAssessmentsCount: 0,
      collegesCount: 1,
      usersCount: 680,
      activeCollegesCount: 1,
      systemStatus: 'OPERATIONAL',
      assignedClassesCount: 3,
    ),
    alerts: const [],
    upcoming: upcoming,
    quickActions: const [
      DashboardQuickActionModel(
        id: 'act-1',
        label: 'Mark Attendance',
        route: '/attendance/mark',
        icon: 'checkSquare',
        isPrimary: true,
      ),
      DashboardQuickActionModel(
        id: 'act-2',
        label: 'Timetable',
        route: '/timetable',
        icon: 'calendar',
      ),
    ],
    pendingActions: const [],
    recent: recent,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Prompt 5 — AcadexEntityFormatters Unit Tests', () {
    test('Correctly identifies 24-character hex MongoDB ObjectIds', () {
      expect(AcadexEntityFormatters.isRawIdentifier('6ab93f466ccb2ae627689bbc'), isTrue);
      expect(AcadexEntityFormatters.isRawIdentifier('507f1f77bcf86cd799439011'), isTrue);
      expect(AcadexEntityFormatters.isRawIdentifier('Section A'), isFalse);
      expect(AcadexEntityFormatters.isRawIdentifier('Computer Science'), isFalse);
      expect(AcadexEntityFormatters.isRawIdentifier('CS101'), isFalse);
    });

    test('Correctly identifies UUIDs and prefixed database identifiers', () {
      expect(AcadexEntityFormatters.isRawIdentifier('c3b5a74e-5f9a-4c28-86d1-4d32f7a90b41'), isTrue);
      expect(AcadexEntityFormatters.isRawIdentifier('sec_6ab93f466ccb2ae627689bbc'), isTrue);
      expect(AcadexEntityFormatters.isRawIdentifier('sub_99a8b7c6d5e4'), isTrue);
      expect(AcadexEntityFormatters.isRawIdentifier('crs_1029384756'), isTrue);
      expect(AcadexEntityFormatters.isRawIdentifier('dept_cse'), isTrue);
    });

    test('formatSectionLabel replaces raw ObjectIds with human-readable labels', () {
      expect(
        AcadexEntityFormatters.formatSectionLabel('Section A', rawId: '6ab93f466ccb2ae627689bbc'),
        equals('Section A'),
      );
      expect(
        AcadexEntityFormatters.formatSectionLabel('A', rawId: '6ab93f466ccb2ae627689bbc'),
        equals('Section A'),
      );
      expect(
        AcadexEntityFormatters.formatSectionLabel(null, rawId: '6ab93f466ccb2ae627689bbc'),
        equals('Assigned Section'),
      );
      expect(
        AcadexEntityFormatters.formatSectionLabel('6ab93f466ccb2ae627689bbc'),
        equals('Assigned Section'),
      );
      expect(
        AcadexEntityFormatters.formatSectionLabel(null, fallback: 'Section Not Assigned'),
        equals('Section Not Assigned'),
      );
    });

    test('formatSubjectLabel avoids raw ID exposure', () {
      expect(
        AcadexEntityFormatters.formatSubjectLabel('Data Structures', code: 'CS201', rawId: '6ab93f466ccb2ae627689bbc'),
        equals('Data Structures'),
      );
      expect(
        AcadexEntityFormatters.formatSubjectLabel(null, rawId: '6ab93f466ccb2ae627689bbc'),
        equals('Assigned Subject'),
      );
    });

    test('formatCourseLabel and formatDepartmentLabel sanitize properly', () {
      expect(
        AcadexEntityFormatters.formatCourseLabel('B.Tech CSE', code: 'CSE'),
        equals('B.Tech CSE'),
      );
      expect(
        AcadexEntityFormatters.formatCourseLabel('6ab93f466ccb2ae627689bbc'),
        equals('Academic Program'),
      );
      expect(
        AcadexEntityFormatters.formatDepartmentLabel('6ab93f466ccb2ae627689bbc'),
        equals('Academic Department'),
      );
      expect(
        AcadexEntityFormatters.formatDepartmentLabel('Computer Science and Engineering'),
        equals('Computer Science and Engineering'),
      );
    });

    test('formatSemesterLabel renders human-readable ordinal', () {
      expect(AcadexEntityFormatters.formatSemesterLabel(null, semesterNumber: 4), equals('Semester 4'));
      expect(AcadexEntityFormatters.formatSemesterLabel('Semester 3'), equals('Semester 3'));
      expect(AcadexEntityFormatters.formatSemesterLabel('6ab93f466ccb2ae627689bbc'), equals('Current Semester'));
    });
  });

  group('Prompt 5 — Error & Timeout Sanitization Tests', () {
    test('AcadexException sanitizes timeout messages without leaking technical text', () {
      final exc = AcadexException.fromError('DioException [receive timeout]: The request took longer than 30000ms');
      expect(exc.userMessage, equals('Connection timed out. Please check your network connection and try again.'));
      expect(exc.userMessage.contains('DioException'), isFalse);
      expect(exc.userMessage.contains('30000ms'), isFalse);
    });

    testWidgets('Student Dashboard displays friendly timeout error and Try Again button', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));

      final testUser = UserModel(
        id: 'usr-1',
        collegeId: 'col-1',
        name: 'Arjun Sharma',
        email: 'arjun@campus.edu',
        role: AppRole.student,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(AuthAuthenticated(user: testUser, token: 'mock-jwt'))),
            homeDashboardProvider.overrideWith(
              (ref) => Future.error(
                'DioException [receive timeout]',
                StackTrace.current,
              ),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: StudentDashboard(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify user-facing friendly message is shown
      expect(find.text('Unable to load your academic overview.'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);

      // Verify technical DioException leak is NOT on screen
      expect(find.textContaining('DioException'), findsNothing);
      expect(find.textContaining('[receive timeout]'), findsNothing);
    });
  });

  group('Prompt 5 — Dashboard Spacing & Content-Driven Layout Tests', () {
    testWidgets('HOD Dashboard renders compact empty strips instead of giant empty states', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));

      final testUser = UserModel(
        id: 'usr-hod-1',
        collegeId: 'col-1',
        departmentId: 'dept-cse',
        name: 'Dr. Ramesh Kumar',
        email: 'ramesh@campus.edu',
        role: AppRole.hod,
        createdAt: DateTime.now(),
      );

      final emptyMock = _createMockDashboard(
        role: 'HOD',
        name: 'Dr. Ramesh Kumar',
        upcoming: [],
        recent: [],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(AuthAuthenticated(user: testUser, token: 'mock-jwt'))),
            homeDashboardProvider.overrideWith((ref) async => emptyMock),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: HodDashboard(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Department Status metrics are elevated and present
      expect(find.text('Department Status'), findsOneWidget);
      expect(find.text('Active Students'), findsOneWidget);
      expect(find.text('640'), findsOneWidget);

      // Verify compact strip for empty upcoming timetable
      expect(find.text('No classes scheduled today'), findsOneWidget);

      // Verify compact strip for empty recent activity
      expect(find.text("You're all caught up. No recent updates right now."), findsOneWidget);

      // Confirm no exception occurred during rendering
      expect(tester.takeException(), isNull);
    });

    testWidgets('Assignments Screen uses content-driven layout without nested Scaffold', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));

      final testUser = UserModel(
        id: 'usr-fac-1',
        collegeId: 'col-1',
        departmentId: 'dept-cse',
        name: 'Prof. S Kalyan',
        email: 'kalyan@campus.edu',
        role: AppRole.faculty,
        createdAt: DateTime.now(),
      );

      final sampleAssignment = AssignmentModel(
        id: 'asgn-1',
        collegeId: 'col-1',
        departmentId: 'dept-cse',
        courseId: 'crs-1',
        academicYearId: 'ay-2026',
        semesterId: 'sem-6',
        sectionId: 'sec-a',
        subjectId: 'sub-dbms',
        facultyId: 'usr-fac-1',
        facultyName: 'Prof. S Kalyan',
        title: 'Database Normalization Assignment',
        description: 'Complete 3NF and BCNF normalization exercises.',
        dueDate: '2026-10-15',
        dueTime: '23:59',
        dueDateTime: DateTime(2026, 10, 15, 23, 59),
        maximumMarks: 25,
        status: AssignmentStatus.published,
        subjectName: 'Database Management Systems',
        sectionName: 'A',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(AuthAuthenticated(user: testUser, token: 'mock-jwt'))),
            facultyCourseAssignmentsProvider.overrideWith(
              (ref) async => [sampleAssignment],
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: FacultyAssignmentsListScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Top title and assignment content are immediately reachable
      expect(find.text('Assignments'), findsOneWidget);
      expect(find.text('Database Normalization Assignment'), findsOneWidget);
      expect(find.textContaining('Database Management Systems'), findsOneWidget);
      expect(find.textContaining('Sec A'), findsOneWidget);

      // Ensure no overflow
      expect(tester.takeException(), isNull);
    });
  });

  group('Prompt 5 — Responsive Viewport Adaptability', () {
    const viewports = [
      Size(360, 640),  // Compact Mobile
      Size(390, 844),  // Standard Modern Mobile
      Size(412, 915),  // Large Android Device
      Size(768, 1024), // Tablet Portrait
      Size(1280, 800), // Desktop / Web Landscape
    ];

    for (final size in viewports) {
      testWidgets('HOD Dashboard renders without overflow at ${size.width.toInt()}x${size.height.toInt()}', (tester) async {
        await tester.binding.setSurfaceSize(size);

        final testUser = UserModel(
          id: 'usr-hod-1',
          collegeId: 'col-1',
          departmentId: 'dept-cse',
          name: 'Dr. Ramesh Kumar',
          email: 'ramesh@campus.edu',
          role: AppRole.hod,
          createdAt: DateTime.now(),
        );

        final mock = _createMockDashboard(
          role: 'HOD',
          name: 'Dr. Ramesh Kumar',
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authProvider.overrideWith((ref) => _FakeAuthNotifier(AuthAuthenticated(user: testUser, token: 'mock-jwt'))),
              homeDashboardProvider.overrideWith((ref) async => mock),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const Scaffold(
                body: HodDashboard(),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });
    }
  });
}
