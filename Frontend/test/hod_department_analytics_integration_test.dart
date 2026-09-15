import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';

import 'package:campus_management/features/analytics/domain/models/department_analytics_models.dart';
import 'package:campus_management/features/analytics/presentation/providers/department_analytics_providers.dart';
import 'package:campus_management/features/analytics/presentation/screens/department_analytics_screen.dart';
import 'package:campus_management/features/attendance/presentation/screens/attendance_dashboard_router.dart';
import 'package:campus_management/features/attendance/presentation/screens/student_attendance_portal_screen.dart';
import 'package:campus_management/features/dashboard/presentation/widgets/acadex_drawer.dart';
import 'package:campus_management/features/dashboard/presentation/screens/hod_dashboard.dart';
import 'package:campus_management/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:campus_management/features/timetable/presentation/providers/timetable_providers.dart';
import 'package:campus_management/features/dashboard/presentation/widgets/acadex_hero_card.dart';
import 'package:campus_management/core/presentation/widgets/acadex_feedback.dart';

class _FakeAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _FakeAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testHod = UserModel(
    id: 'user-hod-01',
    name: 'Dr. Ada Lovelace',
    email: 'hod.cse@alpha.edu',
    role: AppRole.hod,
    collegeId: 'col-alpha',
    departmentId: 'dept-cse',
  );

  const testStudent = UserModel(
    id: 'user-stud-01',
    name: 'Alan Turing',
    email: 'alan.turing@alpha.edu',
    role: AppRole.student,
    collegeId: 'col-alpha',
    departmentId: 'dept-cse',
  );

  final DepartmentOverviewModel sampleOverview = DepartmentOverviewModel(
    collegeId: 'col-alpha',
    departmentId: 'dept-cse',
    departmentName: 'Computer Science and Engineering',
    totalSessions: 42,
    totalStudents: 120,
    totalRecords: 5040,
    presentCount: 4320,
    absentCount: 610,
    lateCount: 80,
    excusedCount: 30,
    medicalLeaveCount: 0,
    onDutyCount: 0,
    overallAttendancePercentage: 86.5,
    atRiskCount: 6,
    atRiskThreshold: 75.0,
    courseBreakdown: const [
      CourseBreakdownModel(
        courseId: 'crs-btech',
        courseName: 'B.Tech CSE',
        courseCode: 'CSE-BT',
        sessionCount: 42,
        present: 4320,
        absent: 610,
        attendancePercentage: 86.5,
        studentCount: 120,
        atRiskCount: 6,
      ),
    ],
    semesterBreakdown: const [],
    sectionBreakdown: const [
      SectionBreakdownModel(
        sectionId: 'sec-5a',
        sectionName: '5-A',
        sessionCount: 22,
        present: 2310,
        absent: 330,
        attendancePercentage: 87.5,
        studentCount: 60,
        atRiskCount: 2,
      ),
      SectionBreakdownModel(
        sectionId: 'sec-5b',
        sectionName: '5-B',
        sessionCount: 20,
        present: 2010,
        absent: 390,
        attendancePercentage: 83.8,
        studentCount: 60,
        atRiskCount: 4,
      ),
    ],
    subjectBreakdown: const [],
  );

  final List<CourseAnalyticsModel> sampleCourses = [
    const CourseAnalyticsModel(
      courseId: 'crs-btech',
      courseName: 'B.Tech CSE',
      courseCode: 'CSE-BT',
      sessionCount: 42,
      studentCount: 120,
      attendancePercentage: 86.5,
      present: 4320,
      absent: 610,
      late: 80,
      excused: 30,
      medicalLeave: 0,
      onDuty: 0,
      atRiskCount: 6,
    ),
  ];

  final List<SectionAnalyticsModel> sampleSections = [
    const SectionAnalyticsModel(
      sectionId: 'sec-5a',
      sectionName: 'Section 5A',
      courseId: 'crs-btech',
      courseName: 'B.Tech CSE',
      semesterNumber: 5,
      enrolledStudents: 60,
      totalSessions: 22,
      attendancePercentage: 87.5,
      present: 2310,
      absent: 330,
      late: 40,
      excused: 15,
      medicalLeave: 0,
      onDuty: 0,
      atRiskStudents: 2,
    ),
  ];

  final List<SubjectAnalyticsModel> sampleSubjects = [
    const SubjectAnalyticsModel(
      subjectId: 'sub-dbms',
      subjectName: 'Database Management Systems',
      subjectCode: 'CS501',
      courseName: 'B.Tech CSE',
      semesterNumber: 5,
      assignedSections: ['Section 5A'],
      sessionCount: 14,
      attendancePercentage: 88.0,
      present: 1478,
      absent: 202,
      late: 20,
      excused: 10,
      medicalLeave: 0,
      onDuty: 0,
      atRiskCount: 1,
    ),
  ];

  final DepartmentStudentsResult sampleStudents = DepartmentStudentsResult(
    students: const [
      StudentAttendanceAnalyticsModel(
        studentId: 'stud-01',
        studentName: 'Ravi Kumar',
        rollNumber: 'CS2026-001',
        admissionNumber: 'ADM-001',
        courseId: 'crs-btech',
        courseName: 'B.Tech CSE',
        semesterId: 'sem-5',
        semesterNumber: 5,
        sectionId: 'sec-5a',
        sectionName: 'Section 5A',
        overallAttendancePercentage: 92.9,
        present: 39,
        absent: 3,
        late: 0,
        excused: 0,
        medicalLeave: 0,
        onDuty: 0,
        sessionsConsidered: 42,
        isAtRisk: false,
      ),
      StudentAttendanceAnalyticsModel(
        studentId: 'stud-02',
        studentName: 'Suresh Raina',
        rollNumber: 'CS2026-002',
        admissionNumber: 'ADM-002',
        courseId: 'crs-btech',
        courseName: 'B.Tech CSE',
        semesterId: 'sem-5',
        semesterNumber: 5,
        sectionId: 'sec-5a',
        sectionName: 'Section 5A',
        overallAttendancePercentage: 66.7,
        present: 28,
        absent: 14,
        late: 0,
        excused: 0,
        medicalLeave: 0,
        onDuty: 0,
        sessionsConsidered: 42,
        isAtRisk: true,
      ),
    ],
    total: 2,
    page: 1,
    limit: 50,
    threshold: 75.0,
  );

  final DepartmentStudentsResult sampleAtRiskStudents = DepartmentStudentsResult(
    students: const [
      StudentAttendanceAnalyticsModel(
        studentId: 'stud-02',
        studentName: 'Suresh Raina',
        rollNumber: 'CS2026-002',
        admissionNumber: 'ADM-002',
        courseId: 'crs-btech',
        courseName: 'B.Tech CSE',
        semesterId: 'sem-5',
        semesterNumber: 5,
        sectionId: 'sec-5a',
        sectionName: 'Section 5A',
        overallAttendancePercentage: 66.7,
        present: 28,
        absent: 14,
        late: 0,
        excused: 0,
        medicalLeave: 0,
        onDuty: 0,
        sessionsConsidered: 42,
        isAtRisk: true,
      ),
    ],
    total: 1,
    page: 1,
    limit: 50,
    threshold: 75.0,
  );

  final List<TrendAnalyticsModel> sampleTrends = [
    const TrendAnalyticsModel(
      date: '2026-09-01',
      label: '09/01',
      totalSessions: 8,
      totalRecords: 480,
      present: 420,
      absent: 60,
      attendancePercentage: 87.5,
    ),
    const TrendAnalyticsModel(
      date: '2026-09-02',
      label: '09/02',
      totalSessions: 8,
      totalRecords: 480,
      present: 410,
      absent: 70,
      attendancePercentage: 85.4,
    ),
  ];

  final DepartmentOverviewModel emptyOverview = const DepartmentOverviewModel(
    collegeId: 'col-alpha',
    departmentId: 'dept-cse',
    departmentName: 'Computer Science and Engineering',
    totalSessions: 0,
    totalStudents: 0,
    totalRecords: 0,
    presentCount: 0,
    absentCount: 0,
    lateCount: 0,
    excusedCount: 0,
    medicalLeaveCount: 0,
    onDutyCount: 0,
    overallAttendancePercentage: 0.0,
    atRiskCount: 0,
    atRiskThreshold: 75.0,
    courseBreakdown: [],
    semesterBreakdown: [],
    sectionBreakdown: [],
    subjectBreakdown: [],
  );

  group('ACADEX — HOD Department Analytics Integration (Prompt 6 of 6) Tests', () {
    testWidgets('1. HOD Drawer has Department Analytics and DOES NOT have Department Attendance', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(
                  const AuthAuthenticated(user: testHod, token: 'tok-hod'),
                )),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: AcadexDrawer(activeRoute: '/analytics'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Department Analytics must be present in HOD navigation
      expect(find.text('Department Analytics'), findsOneWidget);

      // Department Attendance duplicate navigation must NOT exist
      expect(find.text('Department Attendance'), findsNothing);
    });

    testWidgets('2. HOD Dashboard Hero Card has Department Analytics primary action', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(
                  const AuthAuthenticated(user: testHod, token: 'tok-hod'),
                )),
            hodStatsProvider.overrideWith((ref) async => []),
            todayScheduleProvider.overrideWithValue(const AsyncValue.data([])),
            hodActivityProvider.overrideWith((ref) async => []),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: HodDashboard(),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(AcadexHeroCard), findsOneWidget);
      expect(find.text('Department Analytics'), findsWidgets);
    });

    testWidgets('3A. AttendanceDashboardRouter routes HOD to DepartmentAnalyticsScreen', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          key: const ValueKey('router-hod-scope'),
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(
                  const AuthAuthenticated(user: testHod, token: 'tok-hod'),
                )),
            departmentOverviewProvider.overrideWith((ref) async => sampleOverview),
            departmentCoursesProvider.overrideWith((ref) async => sampleCourses),
            departmentSectionsProvider.overrideWith((ref) async => sampleSections),
            departmentSubjectsProvider.overrideWith((ref) async => sampleSubjects),
            departmentStudentsProvider.overrideWith((ref) async => sampleStudents),
            departmentAtRiskStudentsProvider.overrideWith((ref) async => sampleAtRiskStudents),
            departmentTrendsProvider.overrideWith((ref) async => sampleTrends),
          ],
          child: const MaterialApp(
            home: AttendanceDashboardRouter(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(DepartmentAnalyticsScreen), findsOneWidget);
    });

    testWidgets('3B. AttendanceDashboardRouter routes Student to StudentAttendancePortalScreen', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          key: const ValueKey('router-student-scope'),
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(
                  const AuthAuthenticated(user: testStudent, token: 'tok-stud'),
                )),
          ],
          child: const MaterialApp(
            home: AttendanceDashboardRouter(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(StudentAttendancePortalScreen), findsOneWidget);
      expect(find.byType(DepartmentAnalyticsScreen), findsNothing);
    });

    testWidgets('4. DepartmentAnalyticsScreen renders KPI cards, breakdown, and tabs accurately', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(
                  const AuthAuthenticated(user: testHod, token: 'tok-hod'),
                )),
            departmentOverviewProvider.overrideWith((ref) async => sampleOverview),
            departmentCoursesProvider.overrideWith((ref) async => sampleCourses),
            departmentSectionsProvider.overrideWith((ref) async => sampleSections),
            departmentSubjectsProvider.overrideWith((ref) async => sampleSubjects),
            departmentStudentsProvider.overrideWith((ref) async => sampleStudents),
            departmentAtRiskStudentsProvider.overrideWith((ref) async => sampleAtRiskStudents),
            departmentTrendsProvider.overrideWith((ref) async => sampleTrends),
          ],
          child: const MaterialApp(
            home: DepartmentAnalyticsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Header
      expect(find.text('Department Analytics'), findsOneWidget);

      // 6 Tabs exist
      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Courses'), findsOneWidget);
      expect(find.text('Sections'), findsOneWidget);
      expect(find.text('Subjects'), findsOneWidget);
      expect(find.text('Students'), findsOneWidget);
      expect(find.text('At-Risk Alerts'), findsOneWidget);

      // Overview KPI Card values
      expect(find.text('86.5%'), findsWidgets); // Overall Attendance
      expect(find.text('120'), findsWidgets); // Total Students
      expect(find.text('42'), findsWidgets); // Sessions Conducted
      expect(find.text('4320'), findsWidgets); // Present Marks
      expect(find.text('610'), findsWidgets); // Absent Marks
      expect(find.text('6'), findsWidgets); // At-Risk Students
    });

    testWidgets('5. Tab navigation switches between Courses, Sections, Subjects, Students, and At-Risk views', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(
                  const AuthAuthenticated(user: testHod, token: 'tok-hod'),
                )),
            departmentOverviewProvider.overrideWith((ref) async => sampleOverview),
            departmentCoursesProvider.overrideWith((ref) async => sampleCourses),
            departmentSectionsProvider.overrideWith((ref) async => sampleSections),
            departmentSubjectsProvider.overrideWith((ref) async => sampleSubjects),
            departmentStudentsProvider.overrideWith((ref) async => sampleStudents),
            departmentAtRiskStudentsProvider.overrideWith((ref) async => sampleAtRiskStudents),
            departmentTrendsProvider.overrideWith((ref) async => sampleTrends),
          ],
          child: const MaterialApp(
            home: DepartmentAnalyticsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap 'Courses' tab
      await tester.tap(find.text('Courses'));
      await tester.pumpAndSettle();
      expect(find.text('B.Tech CSE'), findsWidgets);

      // Tap 'Sections' tab
      await tester.tap(find.text('Sections'));
      await tester.pumpAndSettle();
      expect(find.text('Section 5A'), findsWidgets);

      // Tap 'Subjects' tab
      await tester.tap(find.text('Subjects'));
      await tester.pumpAndSettle();
      expect(find.text('Database Management Systems'), findsWidgets);

      // Tap 'Students' tab
      await tester.tap(find.text('Students'));
      await tester.pumpAndSettle();
      expect(find.text('Ravi Kumar'), findsOneWidget);
      expect(find.text('Suresh Raina'), findsOneWidget);
      expect(find.textContaining('CS2026-001'), findsOneWidget);
      expect(find.textContaining('CS2026-002'), findsOneWidget);

      // Tap 'At-Risk Alerts' tab
      await tester.tap(find.text('At-Risk Alerts'));
      await tester.pumpAndSettle();
      // Suresh Raina is at risk
      expect(find.text('Suresh Raina'), findsOneWidget);
      expect(find.textContaining('Student Attendance Shortage Warnings'), findsOneWidget);
    });

    testWidgets('6. Safe division-by-zero & truthful empty state when 0 records exist', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(
                  const AuthAuthenticated(user: testHod, token: 'tok-hod'),
                )),
            departmentOverviewProvider.overrideWith((ref) async => emptyOverview),
            departmentCoursesProvider.overrideWith((ref) async => <CourseAnalyticsModel>[]),
            departmentSectionsProvider.overrideWith((ref) async => <SectionAnalyticsModel>[]),
            departmentSubjectsProvider.overrideWith((ref) async => <SubjectAnalyticsModel>[]),
            departmentStudentsProvider.overrideWith((ref) async =>
                  const DepartmentStudentsResult(students: [], total: 0, page: 1, limit: 50, threshold: 75.0),
                ),
            departmentAtRiskStudentsProvider.overrideWith((ref) async =>
                  const DepartmentStudentsResult(students: [], total: 0, page: 1, limit: 50, threshold: 75.0),
                ),
            departmentTrendsProvider.overrideWith((ref) async => <TrendAnalyticsModel>[]),
          ],
          child: const MaterialApp(
            home: DepartmentAnalyticsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check for zero-division safety: must show 0.0%, NEVER NaN% or Infinity%
      expect(find.text('0.0%'), findsWidgets);
      expect(find.textContaining('NaN'), findsNothing);
      expect(find.textContaining('Infinity'), findsNothing);

      // Truthful empty states displayed for breakdowns
      expect(find.byType(AcadexEmptyState), findsWidgets);
      expect(find.text('No Course Data'), findsOneWidget);
      expect(find.text('No Section Data'), findsOneWidget);
    });

    testWidgets('7. Responsive viewports (360dp, 390dp, 412dp) and font scalers (1.0, 1.15, 1.25) with zero overflow', (tester) async {
      final testConfigs = [
        {'width': 360.0, 'height': 800.0, 'scale': 1.0},
        {'width': 390.0, 'height': 844.0, 'scale': 1.15},
        {'width': 412.0, 'height': 915.0, 'scale': 1.25},
      ];

      for (final config in testConfigs) {
        final w = config['width'] as double;
        final h = config['height'] as double;
        final s = config['scale'] as double;

        tester.view.physicalSize = Size(w * 2.0, h * 2.0);
        tester.view.devicePixelRatio = 2.0;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authProvider.overrideWith((ref) => _FakeAuthNotifier(
                    const AuthAuthenticated(user: testHod, token: 'tok-hod'),
                  )),
              departmentOverviewProvider.overrideWith((ref) async => sampleOverview),
              departmentCoursesProvider.overrideWith((ref) async => sampleCourses),
              departmentSectionsProvider.overrideWith((ref) async => sampleSections),
              departmentSubjectsProvider.overrideWith((ref) async => sampleSubjects),
              departmentStudentsProvider.overrideWith((ref) async => sampleStudents),
              departmentAtRiskStudentsProvider.overrideWith((ref) async => sampleAtRiskStudents),
              departmentTrendsProvider.overrideWith((ref) async => sampleTrends),
            ],
            child: MaterialApp(
              builder: (context, child) {
                return MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(s),
                  ),
                  child: child!,
                );
              },
              home: const DepartmentAnalyticsScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Check for no overflow exceptions
        expect(tester.takeException(), isNull, reason: 'RenderFlex overflow failed at width $w with font scale $s');

        // Check core elements present
        expect(find.text('Department Analytics'), findsOneWidget);
        expect(find.text('Overview'), findsOneWidget);
      }

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
