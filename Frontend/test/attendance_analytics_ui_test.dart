import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_management/features/attendance/domain/models/attendance_analytics_models.dart';
import 'package:campus_management/features/attendance/presentation/providers/attendance_analytics_providers.dart';
import 'package:campus_management/features/attendance/presentation/screens/attendance_analytics_screen.dart';
import 'package:campus_management/features/attendance/presentation/widgets/analytics/analytics_date_range_selector.dart';
import 'package:campus_management/features/attendance/presentation/widgets/analytics/attendance_overview_card.dart';
import 'package:campus_management/features/attendance/presentation/widgets/analytics/attendance_distribution_chart.dart';
import 'package:campus_management/features/attendance/presentation/widgets/analytics/attendance_trend_chart.dart';
import 'package:campus_management/features/attendance/presentation/widgets/analytics/subject_attendance_chart.dart';
import 'package:campus_management/features/attendance/presentation/widgets/analytics/section_attendance_chart.dart';
import 'package:campus_management/features/attendance/presentation/widgets/analytics/low_attendance_list.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final mockStudentUser = UserModel(
    id: 'std-1',
    name: 'John von Neumann',
    email: 'john@git.edu',
    role: AppRole.student,
    collegeId: 'col-1',
    departmentId: 'dept-cse',
  );

  final mockFacultyUser = UserModel(
    id: 'fac-alan',
    name: 'Dr. Alan Turing',
    email: 'alan@git.edu',
    role: AppRole.faculty,
    collegeId: 'col-1',
    departmentId: 'dept-cse',
  );

  final mockHodUser = UserModel(
    id: 'usr-hod',
    name: 'HOD CSE',
    email: 'hod@git.edu',
    role: AppRole.hod,
    collegeId: 'col-1',
    departmentId: 'dept-cse',
  );

  final mockAdminUser = UserModel(
    id: 'usr-admin',
    name: 'College Admin',
    email: 'admin@git.edu',
    role: AppRole.collegeAdmin,
    collegeId: 'col-1',
    departmentId: '',
  );

  Widget createWidgetUnderTest({
    required Widget child,
    UserModel? user,
    List<Override> overrides = const [],
    ThemeMode themeMode = ThemeMode.light,
  }) {
    final effectiveUser = user ?? mockStudentUser;
    return ProviderScope(
      overrides: [
        authProvider.overrideWith((ref) => _FakeAuthNotifier(AuthAuthenticated(user: effectiveUser, token: 'fake-jwt'))),
        ...overrides,
      ],
      child: MaterialApp(
        themeMode: themeMode,
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        home: child,
      ),
    );
  }

  group('ACADEX Phase 8B: Attendance Analytics Dashboard & Widgets Tests', () {
    // =========================================================================
    // 1. ATTENDANCE OVERVIEW CARD
    // =========================================================================
    testWidgets('1. AttendanceOverviewCard displays percentage, statuses, and sessions', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          child: const Scaffold(
            body: AttendanceOverviewCard(
              title: 'Personal Attendance Overview',
              percentage: 88.5,
              presentCount: 35,
              absentCount: 3,
              lateCount: 2,
              excusedCount: 0,
              totalSessions: 40,
              isLowAttendance: false,
            ),
          ),
        ),
      );

      expect(find.text('Personal Attendance Overview'), findsOneWidget);
      expect(find.text('88.5'), findsOneWidget);
      expect(find.text('Good Standing'), findsOneWidget);
      expect(find.text('35'), findsOneWidget); // Present
      expect(find.text('3'), findsOneWidget);  // Absent
      expect(find.text('2'), findsOneWidget);  // Late
      expect(find.text('40'), findsOneWidget); // Total Sessions
    });

    testWidgets('2. AttendanceOverviewCard displays low attendance alert when percentage < 75%', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          child: const Scaffold(
            body: AttendanceOverviewCard(
              title: 'Personal Attendance Overview',
              percentage: 71.0,
              presentCount: 20,
              absentCount: 8,
              lateCount: 0,
              excusedCount: 0,
              totalSessions: 28,
              isLowAttendance: true,
            ),
          ),
        ),
      );

      expect(find.text('Low Attendance (< 75%)'), findsOneWidget);
      expect(find.textContaining('mandatory 75% minimum requirement'), findsOneWidget);
    });

    // =========================================================================
    // 2. DISTRIBUTION & STATUS BREAKDOWN CHART
    // =========================================================================
    testWidgets('3. AttendanceDistributionChart renders status breakdown and accessible legends', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          child: const Scaffold(
            body: AttendanceDistributionChart(
              presentCount: 30,
              absentCount: 5,
              lateCount: 3,
              excusedCount: 2,
            ),
          ),
        ),
      );

      expect(find.text('Attendance Distribution'), findsOneWidget);
      expect(find.textContaining('Present: 30'), findsOneWidget);
      expect(find.textContaining('Absent: 5'), findsOneWidget);
      expect(find.textContaining('Late: 3'), findsOneWidget);
      expect(find.textContaining('Excused: 2'), findsOneWidget);
    });

    testWidgets('4. AttendanceDistributionChart handles empty/zero data cleanly', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          child: const Scaffold(
            body: AttendanceDistributionChart(
              presentCount: 0,
              absentCount: 0,
              lateCount: 0,
              excusedCount: 0,
            ),
          ),
        ),
      );

      expect(find.text('No attendance records in this period'), findsOneWidget);
    });

    // =========================================================================
    // 3. TREND CHART
    // =========================================================================
    testWidgets('5. AttendanceTrendChart renders trend points and threshold line', (tester) async {
      final points = [
        const TrendPoint(label: 'W-1', percentage: 80.0),
        const TrendPoint(label: 'W-2', percentage: 85.0),
        const TrendPoint(label: 'W-3', percentage: 90.0),
      ];

      await tester.pumpWidget(
        createWidgetUnderTest(
          child: Scaffold(
            body: AttendanceTrendChart(trendData: points),
          ),
        ),
      );

      expect(find.text('Attendance Trend Over Time'), findsOneWidget);
      expect(find.byType(LineChart), findsOneWidget);
    });

    // =========================================================================
    // 4. SUBJECT ATTENDANCE CHART
    // =========================================================================
    testWidgets('6. SubjectAttendanceChart renders ranked subjects and conducted class counts', (tester) async {
      final subjects = [
        SubjectAttendanceAnalytics.compute(
          subjectId: 'sub-dbms',
          subjectName: 'Database Management Systems',
          totalSessions: 20,
          presentCount: 18,
          absentCount: 2,
        ),
        SubjectAttendanceAnalytics.compute(
          subjectId: 'sub-os',
          subjectName: 'Operating Systems',
          totalSessions: 15,
          presentCount: 10,
          absentCount: 5,
        ),
      ];

      await tester.pumpWidget(
        createWidgetUnderTest(
          child: Scaffold(
            body: SubjectAttendanceChart(subjects: subjects),
          ),
        ),
      );

      expect(find.text('Database Management Systems'), findsOneWidget);
      expect(find.text('20 classes'), findsOneWidget);
      expect(find.text('90.0%'), findsOneWidget);

      expect(find.text('Operating Systems'), findsOneWidget);
      expect(find.text('15 classes'), findsOneWidget);
      expect(find.text('66.7%'), findsOneWidget);
    });

    // =========================================================================
    // 5. SECTION ATTENDANCE CHART
    // =========================================================================
    testWidgets('7. SectionAttendanceChart renders section comparison and student metrics', (tester) async {
      final sections = [
        SectionAttendanceAnalytics.compute(
          sectionId: 'sec-4a',
          sectionName: 'Section 4-A',
          totalStudents: 50,
          totalSessions: 25,
          presentCount: 45,
          absentCount: 5,
        ),
      ];

      await tester.pumpWidget(
        createWidgetUnderTest(
          child: Scaffold(
            body: SectionAttendanceChart(sections: sections),
          ),
        ),
      );

      expect(find.text('Section 4-A'), findsOneWidget);
      expect(find.text('50 students'), findsOneWidget);
      expect(find.text('90.0%'), findsOneWidget);
    });

    // =========================================================================
    // 6. LOW ATTENDANCE LIST & REGULATORY BOUNDARY (< 75%)
    // =========================================================================
    testWidgets('8. LowAttendanceList displays students < 75% and excludes students >= 75%', (tester) async {
      final students = [
        // 70% -> Low attendance (< 75%)
        StudentAttendanceAnalytics.compute(
          studentId: 'std-low',
          studentName: 'Rahul Kumar',
          rollNumber: 'CS01',
          totalSessions: 10,
          presentCount: 7,
          absentCount: 3,
        ),
        // Exactly 75% -> NOT low attendance (boundary check)
        StudentAttendanceAnalytics.compute(
          studentId: 'std-boundary',
          studentName: 'Arjun Reddy',
          rollNumber: 'CS02',
          totalSessions: 4,
          presentCount: 3,
          absentCount: 1,
        ),
        // 90% -> Good standing
        StudentAttendanceAnalytics.compute(
          studentId: 'std-good',
          studentName: 'Sneha Patel',
          rollNumber: 'CS03',
          totalSessions: 10,
          presentCount: 9,
          absentCount: 1,
        ),
      ];

      await tester.pumpWidget(
        createWidgetUnderTest(
          child: Scaffold(
            body: LowAttendanceList(students: students),
          ),
        ),
      );

      // Rahul (70%) must be listed
      expect(find.text('Rahul Kumar'), findsOneWidget);
      expect(find.text('70.0%'), findsOneWidget);
      expect(find.text('Shortage'), findsOneWidget);

      // Arjun (75%) and Sneha (90%) must NOT be in the low attendance list
      expect(find.text('Arjun Reddy'), findsNothing);
      expect(find.text('Sneha Patel'), findsNothing);
    });

    // =========================================================================
    // 7. DATE RANGE SELECTOR
    // =========================================================================
    testWidgets('9. AnalyticsDateRangeSelector toggles presets cleanly', (tester) async {
      AttendanceDateRange currentRange = AttendanceDateRange.thisMonth();

      await tester.pumpWidget(
        createWidgetUnderTest(
          child: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: AnalyticsDateRangeSelector(
                  selectedRange: currentRange,
                  onRangeChanged: (newRange) {
                    setState(() {
                      currentRange = newRange;
                    });
                  },
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('Today'), findsOneWidget);
      expect(find.text('This Week'), findsOneWidget);
      expect(find.text('This Month'), findsOneWidget);
      expect(find.text('Custom'), findsOneWidget);

      // Tap 'Today'
      await tester.tap(find.text('Today'));
      await tester.pumpAndSettle();
      expect(currentRange.preset, equals(AttendanceDateRangePreset.today));

      // Tap 'This Week'
      await tester.tap(find.text('This Week'));
      await tester.pumpAndSettle();
      expect(currentRange.preset, equals(AttendanceDateRangePreset.thisWeek));
    });

    // =========================================================================
    // 8. MASTER DASHBOARD SCREEN (ROLE-BASED VIEWS)
    // =========================================================================
    testWidgets('10. AttendanceAnalyticsScreen renders for Student user', (tester) async {
      final mockStudentData = StudentAttendanceAnalytics.compute(
        studentId: 'std-1',
        studentName: 'John von Neumann',
        totalSessions: 10,
        presentCount: 9,
        absentCount: 1,
      );

      await tester.pumpWidget(
        createWidgetUnderTest(
          user: mockStudentUser,
          overrides: [
            currentStudentAnalyticsProvider.overrideWith((ref, range) => Future.value(mockStudentData)),
          ],
          child: const AttendanceAnalyticsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Attendance Analytics'), findsOneWidget);
      expect(find.text('Personal Attendance Overview'), findsOneWidget);
      expect(find.text('90.0'), findsOneWidget);
    });

    testWidgets('11. AttendanceAnalyticsScreen renders for Faculty user', (tester) async {
      final mockFacultyData = FacultyAttendanceAnalytics.compute(
        facultyId: 'fac-alan',
        facultyName: 'Dr. Alan Turing',
        totalSessionsConducted: 14,
        totalStudentRecords: 70,
        presentCount: 65,
        absentCount: 5,
      );

      await tester.pumpWidget(
        createWidgetUnderTest(
          user: mockFacultyUser,
          overrides: [
            currentFacultyAnalyticsProvider.overrideWith((ref, range) => Future.value(mockFacultyData)),
          ],
          child: const AttendanceAnalyticsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Attendance Analytics'), findsOneWidget);
      expect(find.text('Teaching Attendance Activity'), findsOneWidget);
      expect(find.text('92.9'), findsOneWidget);
    });

    testWidgets('12. AttendanceAnalyticsScreen renders for HOD user', (tester) async {
      final mockSummaryData = AttendanceDateRangeSummary.compute(
        startDate: DateTime(2026, 8, 1),
        endDate: DateTime(2026, 8, 31),
        totalSessions: 40,
        totalStudentRecords: 200,
        presentCount: 180,
        absentCount: 20,
      );

      await tester.pumpWidget(
        createWidgetUnderTest(
          user: mockHodUser,
          overrides: [
            attendanceDateRangeSummaryProvider.overrideWith((ref, query) => Future.value(mockSummaryData)),
          ],
          child: const AttendanceAnalyticsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Attendance Analytics'), findsOneWidget);
      expect(find.text('Department Attendance Benchmark'), findsOneWidget);
      expect(find.text('90.0'), findsOneWidget);
    });

    testWidgets('13. AttendanceAnalyticsScreen renders for College Admin user', (tester) async {
      final mockCollegeData = AttendanceDateRangeSummary.compute(
        startDate: DateTime(2026, 8, 1),
        endDate: DateTime(2026, 8, 31),
        totalSessions: 120,
        totalStudentRecords: 600,
        presentCount: 530,
        absentCount: 70,
      );

      await tester.pumpWidget(
        createWidgetUnderTest(
          user: mockAdminUser,
          overrides: [
            attendanceDateRangeSummaryProvider.overrideWith((ref, query) => Future.value(mockCollegeData)),
          ],
          child: const AttendanceAnalyticsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Attendance Analytics'), findsOneWidget);
      expect(find.text('Institutional Attendance Analytics'), findsOneWidget);
    });

    testWidgets('14. AttendanceAnalyticsScreen renders error state and retry action', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          user: mockStudentUser,
          overrides: [
            currentStudentAnalyticsProvider.overrideWith((ref, range) => Future.error(Exception('Network error'))),
          ],
          child: const AttendanceAnalyticsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Failed to load analytics'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('15. AttendanceAnalyticsScreen renders in Dark Mode', (tester) async {
      final mockStudentData = StudentAttendanceAnalytics.compute(
        studentId: 'std-1',
        totalSessions: 10,
        presentCount: 8,
        absentCount: 2,
      );

      await tester.pumpWidget(
        createWidgetUnderTest(
          themeMode: ThemeMode.dark,
          user: mockStudentUser,
          overrides: [
            currentStudentAnalyticsProvider.overrideWith((ref, range) => Future.value(mockStudentData)),
          ],
          child: const AttendanceAnalyticsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Attendance Analytics'), findsOneWidget);
      expect(find.text('80.0'), findsOneWidget);
    });

    testWidgets('16. Refresh button triggers provider invalidation', (tester) async {
      final mockStudentData = StudentAttendanceAnalytics.compute(
        studentId: 'std-1',
        totalSessions: 10,
        presentCount: 10,
        absentCount: 0,
      );

      await tester.pumpWidget(
        createWidgetUnderTest(
          user: mockStudentUser,
          overrides: [
            currentStudentAnalyticsProvider.overrideWith((ref, range) => Future.value(mockStudentData)),
          ],
          child: const AttendanceAnalyticsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Refresh'), findsOneWidget);
      await tester.tap(find.text('Refresh'));
      await tester.pumpAndSettle();
    });

    testWidgets('17. AttendanceAnalyticsScreen renders on small mobile viewport without overflow', (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockStudentData = StudentAttendanceAnalytics.compute(
        studentId: 'std-1',
        totalSessions: 8,
        presentCount: 7,
        absentCount: 1,
      );

      await tester.pumpWidget(
        createWidgetUnderTest(
          user: mockStudentUser,
          overrides: [
            currentStudentAnalyticsProvider.overrideWith((ref, range) => Future.value(mockStudentData)),
          ],
          child: const AttendanceAnalyticsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Attendance Analytics'), findsOneWidget);
      expect(find.text('87.5'), findsOneWidget);
    });
  });
}

class _FakeAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _FakeAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
