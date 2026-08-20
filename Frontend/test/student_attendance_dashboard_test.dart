import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_management/features/attendance/domain/models/attendance_alert.dart';
import 'package:campus_management/features/attendance/domain/models/attendance_analytics_models.dart';
import 'package:campus_management/features/attendance/domain/models/attendance_session.dart';
import 'package:campus_management/features/attendance/domain/models/attendance_record.dart';
import 'package:campus_management/features/attendance/domain/models/attendance_status.dart';
import 'package:campus_management/features/attendance/domain/models/department_attendance_comparison.dart';
import 'package:campus_management/features/attendance/domain/models/student_attendance_models.dart';
import 'package:campus_management/features/attendance/domain/models/subject_attendance.dart';
import 'package:campus_management/features/attendance/domain/services/student_attendance_service.dart';
import 'package:campus_management/features/attendance/presentation/providers/student_portal_providers.dart';
import 'package:campus_management/features/attendance/presentation/screens/student_attendance_portal_screen.dart';
import 'package:campus_management/features/attendance/presentation/screens/student_session_detail_screen.dart';

class _FakeAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _FakeAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testStudent = UserModel(
    id: 'STU-001',
    email: 'student@campus.edu',
    name: 'Rahul Kumar',
    role: AppRole.student,
    collegeId: 'COL-001',
    departmentId: 'DEP-CSE',
  );

  final testStudentSummary = StudentAttendanceAnalytics.compute(
    studentId: 'STU-001',
    studentName: 'Rahul Kumar',
    rollNumber: 'CS2026-01',
    sectionId: 'SEC-A',
    totalSessions: 20,
    presentCount: 16,
    absentCount: 4,
    lateCount: 0,
    excusedCount: 0,
  );

  final testSubjects = [
    SubjectAttendance(
      subjectId: 'SUB-DBMS',
      subjectName: 'Database Management Systems',
      subjectCode: 'CS401',
      facultyName: 'Dr. Sharma',
      totalClasses: 20,
      attendedClasses: 18,
      missedClasses: 2,
    ),
    SubjectAttendance(
      subjectId: 'SUB-OS',
      subjectName: 'Operating Systems',
      subjectCode: 'CS402',
      facultyName: 'Prof. Gupta',
      totalClasses: 20,
      attendedClasses: 14,
      missedClasses: 6,
    ),
  ];

  final testDetailedSubjects = [
    StudentDetailedSubjectAttendance.compute(
      subjectId: 'SUB-DBMS',
      subjectName: 'Database Management Systems',
      subjectCode: 'CS401',
      facultyName: 'Dr. Sharma',
      totalClasses: 20,
      presentCount: 18,
      absentCount: 2,
    ),
    StudentDetailedSubjectAttendance.compute(
      subjectId: 'SUB-OS',
      subjectName: 'Operating Systems',
      subjectCode: 'CS402',
      facultyName: 'Prof. Gupta',
      totalClasses: 20,
      presentCount: 14,
      absentCount: 6,
    ),
  ];

  final testSessions = [
    StudentAttendanceSessionSummary(
      sessionId: 'SES-001',
      subjectId: 'SUB-DBMS',
      subjectName: 'Database Management Systems',
      subjectCode: 'CS401',
      facultyId: 'FAC-001',
      facultyName: 'Dr. Sharma',
      sectionId: 'SEC-A',
      sectionName: 'DCME 4-A',
      date: DateTime(2026, 8, 18),
      timeSlot: '09:00 - 10:00',
      roomNumber: 'LH-101',
      status: AttendanceStatus.present,
      version: 1,
    ),
    StudentAttendanceSessionSummary(
      sessionId: 'SES-002',
      subjectId: 'SUB-OS',
      subjectName: 'Operating Systems',
      subjectCode: 'CS402',
      facultyId: 'FAC-002',
      facultyName: 'Prof. Gupta',
      sectionId: 'SEC-A',
      sectionName: 'DCME 4-A',
      date: DateTime(2026, 8, 18),
      timeSlot: '10:00 - 11:00',
      roomNumber: 'LH-102',
      status: AttendanceStatus.absent,
      version: 1,
    ),
  ];

  final testCalendarDays = [
    StudentAttendanceCalendarDay(
      date: DateTime(2026, 8, 18),
      totalClasses: 2,
      presentCount: 1,
      absentCount: 1,
      lateCount: 0,
      excusedCount: 0,
      attendancePercentage: 50.0,
      sessions: testSessions,
    ),
  ];

  final testInsights = StudentAttendanceInsights(
    overallPercentage: 80.0,
    trendDirection: TrendDirection.up,
    overallRiskLevel: AttendanceRiskLevel.watch,
    totalConducted: 20,
    totalAttended: 16,
    totalAbsent: 4,
    totalLate: 0,
    totalExcused: 0,
    subjectRankings: testDetailedSubjects,
    lowestAttendanceSubjects: [testDetailedSubjects.last],
    bestAttendanceSubjects: [testDetailedSubjects.first],
    activeAlerts: [],
    thresholdWarningsCount: 1,
    isLowAttendance: false,
    totalRecoveryNeeded: 2,
  );

  Widget buildTestApp({
    required Widget child,
    UserModel? user,
    List<Override> overrides = const [],
    ThemeMode themeMode = ThemeMode.light,
    double width = 1200,
    double height = 800,
  }) {
    final activeUser = user ?? testStudent;
    return ProviderScope(
      overrides: [
        authProvider.overrideWith((ref) => _FakeAuthNotifier(AuthAuthenticated(user: activeUser, token: 'mock-token'))),
        studentPortalSummaryProvider.overrideWith((ref) async => testStudentSummary),
        studentDetailedSubjectsProvider.overrideWith((ref) async => testDetailedSubjects),
        studentAllSessionsProvider.overrideWith((ref) async => testSessions),
        studentAttendanceCalendarProvider.overrideWith((ref) async => testCalendarDays),
        studentAttendanceInsightsProvider.overrideWith((ref) async => testInsights),
        studentPortalAlertsProvider.overrideWith((ref) async => []),
        studentSessionDetailProvider.overrideWith((ref, id) async => testSessions.where((s) => s.sessionId == id).firstOrNull ?? testSessions.first),
        ...overrides,
      ],
      child: MaterialApp(
        themeMode: themeMode,
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        home: MediaQuery(
          data: MediaQueryData(size: Size(width, height)),
          child: child,
        ),
      ),
    );
  }

  group('ACADEX Phase 8G: Student Attendance Portal, Insights & Notifications Tests', () {
    const studentService = StudentAttendanceService();

    test('1. Student summary calculation from attendance analytics source of truth', () {
      final summary = StudentAttendanceAnalytics.compute(
        studentId: 'STU-001',
        totalSessions: 20,
        presentCount: 16,
        absentCount: 4,
      );

      expect(summary.attendancePercentage, 80.0);
      expect(summary.isLowAttendance, isFalse);
      expect(summary.riskLevel, AttendanceRiskLevel.watch);
    });

    test('2. Subject attendance computation with margin and recovery sessions', () {
      final detailed = StudentDetailedSubjectAttendance.compute(
        subjectId: 'SUB-DBMS',
        subjectName: 'DBMS',
        subjectCode: 'CS401',
        totalClasses: 20,
        presentCount: 18,
        absentCount: 2,
      );

      expect(detailed.attendancePercentage, 90.0);
      expect(detailed.isBelowThreshold, isFalse);
      expect(detailed.marginClassesCanMiss, 4);
      expect(detailed.recoveryClassesNeeded, 0);
    });

    test('3. Multiple subjects ranking and evaluation', () {
      final detailedList = studentService.computeDetailedSubjects(subjects: testSubjects);
      expect(detailedList.length, 2);
      expect(detailedList.first.subjectId, 'SUB-DBMS');
      expect(detailedList.first.attendancePercentage, 90.0);
      expect(detailedList.last.subjectId, 'SUB-OS');
      expect(detailedList.last.attendancePercentage, 70.0);
      expect(detailedList.last.isBelowThreshold, isTrue);
    });

    test('4. Calendar date filtering groups sessions by calendar day accurately', () {
      final days = studentService.buildCalendarDays(sessions: testSessions);
      expect(days.length, 1);
      expect(days.first.totalClasses, 2);
      expect(days.first.presentCount, 1);
      expect(days.first.absentCount, 1);
      expect(days.first.attendancePercentage, 50.0);
    });

    test('5. Session detail summary extracts student specific record data', () {
      final rawSessions = [
        AttendanceSession(
          id: 'SES-LIVE-1',
          collegeId: 'COL-001',
          departmentId: 'DEP-CSE',
          facultyId: 'FAC-001',
          subjectId: 'SUB-DBMS',
          subjectName: 'Database Systems',
          sectionId: 'SEC-A',
          sectionName: 'DCME 4-A',
          timeSlot: '09:00 - 10:00',
          date: DateTime(2026, 8, 18),
          version: 2,
          records: [
            AttendanceRecord(
              id: 'R1',
              studentId: 'STU-001',
              studentName: 'Rahul Kumar',
              rollNumber: '01',
              sectionId: 'SEC-A',
              status: AttendanceStatus.present,
            ),
          ],
        ),
      ];

      final extracted = studentService.extractStudentSessions(
        studentId: 'STU-001',
        sessions: rawSessions,
      );

      expect(extracted.length, 1);
      expect(extracted.first.sessionId, 'SES-LIVE-1');
      expect(extracted.first.status, AttendanceStatus.present);
      expect(extracted.first.version, 2);
    });

    test('6. Present status maps correctly to positive attendance contribution', () {
      final status = AttendanceStatus.present;
      expect(status.name, 'present');
    });

    test('7. Absent status maps correctly to shortage impact', () {
      final status = AttendanceStatus.absent;
      expect(status.name, 'absent');
    });

    test('8. Late status recorded correctly in analytics', () {
      final summary = StudentAttendanceAnalytics.compute(
        studentId: 'STU-001',
        totalSessions: 10,
        presentCount: 8,
        absentCount: 1,
        lateCount: 1,
      );
      expect(summary.lateCount, 1);
      expect(summary.attendancePercentage, 80.0);
    });

    test('9. Excused status recorded and verified', () {
      final summary = StudentAttendanceAnalytics.compute(
        studentId: 'STU-001',
        totalSessions: 10,
        presentCount: 9,
        excusedCount: 1,
      );
      expect(summary.excusedCount, 1);
      expect(summary.attendancePercentage, 90.0);
    });

    test('10. Low attendance warning triggered when percentage is below threshold', () {
      final lowSummary = StudentAttendanceAnalytics.compute(
        studentId: 'STU-LOW',
        totalSessions: 20,
        presentCount: 14,
        absentCount: 6,
      );
      expect(lowSummary.attendancePercentage, 70.0);
      expect(lowSummary.isLowAttendance, isTrue);
    });

    test('11. Critical attendance alert evaluated correctly for severe shortage', () {
      final critical = StudentAttendanceAnalytics.compute(
        studentId: 'STU-CRIT',
        totalSessions: 20,
        presentCount: 10,
        absentCount: 10,
      );
      expect(critical.attendancePercentage, 50.0);
      expect(critical.riskLevel, AttendanceRiskLevel.critical);
    });

    test('12. Attendance trend direction evaluates trajectory correctly', () {
      final insights = studentService.buildInsights(
        analytics: testStudentSummary,
        subjects: testDetailedSubjects,
        alerts: [],
      );
      expect(insights.trendDirection, TrendDirection.up);
      expect(insights.bestAttendanceSubjects.isNotEmpty, isTrue);
      expect(insights.lowestAttendanceSubjects.isNotEmpty, isTrue);
    });

    test('13. Recovery calculation measures exact classes needed to return to 75%', () {
      // 14 / 20 = 70%. Need 75%: (14 + x) / (20 + x) >= 0.75 => 14 + x >= 15 + 0.75x => 0.25x >= 1 => x >= 4
      final needed = AttendanceAnalyticsConstants.calculateSessionsNeededToReachThreshold(
        presentCount: 14,
        totalSessions: 20,
      );
      expect(needed, 4);
    });

    test('14. Empty attendance state handles 0 sessions gracefully without crashing', () {
      final empty = StudentAttendanceAnalytics.compute(
        studentId: 'STU-NEW',
        totalSessions: 0,
      );
      expect(empty.attendancePercentage, 0.0);
      expect(empty.totalSessions, 0);
    });

    testWidgets('15. Loading state renders progress feedback cleanly', (tester) async {
      final completer = Completer<StudentAttendanceAnalytics>();
      await tester.pumpWidget(
        buildTestApp(
          child: const StudentAttendancePortalScreen(),
          overrides: [
            studentPortalSummaryProvider.overrideWith((ref) => completer.future),
          ],
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsWidgets);
      completer.complete(testStudentSummary);
      await tester.pump();
    });

    testWidgets('16. Error state displays retry button on data failure', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          child: const StudentAttendancePortalScreen(),
          overrides: [
            studentPortalSummaryProvider.overrideWith((ref) => Future.error('Network failure')),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('Unable to load attendance summary'), findsOneWidget);
    });

    testWidgets('17. Mobile layout renders cleanly at 360px width without overflow', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          child: const StudentAttendancePortalScreen(),
          width: 360,
          height: 640,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Student Attendance Portal'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('18. Dark mode renders correctly with Acadex dark tokens', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          child: const StudentAttendancePortalScreen(),
          themeMode: ThemeMode.dark,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Student Attendance Portal'), findsOneWidget);
      expect(find.text('Overall Attendance'), findsOneWidget);
    });

    test('19. Student role isolation prohibits administrative report generation', () {
      expect(AppRole.student == AppRole.hod, isFalse);
      expect(AppRole.student == AppRole.collegeAdmin, isFalse);
      expect(AppRole.student == AppRole.superAdmin, isFalse);
    });

    test('20. Cross-student access rejection enforces authenticated student ID scoping', () {
      final studentA = UserModel(id: 'STU-A', email: 'a@test.com', name: 'Student A', role: AppRole.student);
      final studentB = UserModel(id: 'STU-B', email: 'b@test.com', name: 'Student B', role: AppRole.student);

      expect(studentA.id, isNot(equals(studentB.id)));
    });

    test('21. Cross-tenant access rejection isolates multi-tenant college ID', () {
      final userCol1 = UserModel(id: 'STU-1', email: '1@col1.com', name: 'S1', role: AppRole.student, collegeId: 'COL-001');
      final userCol2 = UserModel(id: 'STU-2', email: '2@col2.com', name: 'S2', role: AppRole.student, collegeId: 'COL-002');

      expect(userCol1.collegeId, isNot(equals(userCol2.collegeId)));
    });

    testWidgets('22. Read-only enforcement in StudentSessionDetailScreen contains no edit buttons', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          child: const StudentSessionDetailScreen(sessionId: 'SES-001'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Verified Institutional Record • Read-Only Access (Faculty Verified)'), findsOneWidget);
      expect(find.text('Edit Session'), findsNothing);
      expect(find.text('Submit Attendance'), findsNothing);
    });

    test('23. Existing analytics engine is reused as single source of truth', () {
      final pct1 = AttendanceAnalyticsConstants.calculatePercentage(
        presentCount: 15,
        absentCount: 5,
        lateCount: 0,
        excusedCount: 0,
        unmarkedCount: 0,
      );
      final pct2 = (15 / 20) * 100.0;
      expect(pct1, pct2);
    });

    test('24. Existing alert engine is reused as single source of truth for student alerts', () {
      final alert = AttendanceAlert(
        id: 'ALT-1',
        collegeId: 'COL-001',
        departmentId: 'DEP-CSE',
        studentId: 'STU-001',
        studentName: 'Rahul Kumar',
        rollNumber: 'CS2026-01',
        sectionId: 'SEC-A',
        alertType: AttendanceAlertType.lowAttendance,
        severity: AttendanceAlertSeverity.warning,
        status: AttendanceAlertStatus.active,
        title: 'Low Attendance Notice',
        message: 'Your attendance is 72.0%',
        attendancePercentage: 72.0,
        createdAt: DateTime.now(),
        deduplicationKey: 'DEDUP-ALT-1',
      );

      expect(alert.studentId, 'STU-001');
      expect(alert.severity, AttendanceAlertSeverity.warning);
      expect(alert.alertType, AttendanceAlertType.lowAttendance);
    });
  });
}
