import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_management/features/attendance/domain/models/attendance_alert.dart';
import 'package:campus_management/features/attendance/domain/models/attendance_analytics_models.dart';
import 'package:campus_management/features/attendance/domain/models/attendance_record.dart';
import 'package:campus_management/features/attendance/domain/models/attendance_session.dart';
import 'package:campus_management/features/attendance/domain/models/attendance_status.dart';
import 'package:campus_management/features/attendance/domain/services/attendance_risk_evaluator.dart';
import 'package:campus_management/features/attendance/domain/repositories/attendance_alert_repository.dart';
import 'package:campus_management/features/attendance/data/repositories/mock_attendance_alert_repository.dart';
import 'package:campus_management/features/attendance/presentation/providers/attendance_alert_providers.dart';
import 'package:campus_management/features/attendance/presentation/widgets/alerts/attendance_alert_summary_card.dart';
import 'package:campus_management/features/attendance/presentation/screens/attendance_alerts_screen.dart';
import 'package:campus_management/features/attendance/presentation/screens/attendance_alert_detail_screen.dart';
import 'package:campus_management/features/timetable/domain/models/timetable_models.dart';

class _FakeAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _FakeAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testStudent = UserModel(
    id: 'STU-001',
    email: 'rahul@campus.edu',
    name: 'Rahul Kumar',
    role: AppRole.student,
    collegeId: 'COL-001',
    departmentId: 'DEP-CSE',
  );

  final testFaculty = UserModel(
    id: 'FAC-001',
    email: 'faculty@campus.edu',
    name: 'Prof. Sharma',
    role: AppRole.faculty,
    collegeId: 'COL-001',
    departmentId: 'DEP-CSE',
  );

  final testHod = UserModel(
    id: 'HOD-001',
    email: 'hod@campus.edu',
    name: 'Dr. Verma',
    role: AppRole.hod,
    collegeId: 'COL-001',
    departmentId: 'DEP-CSE',
  );

  final testCollegeAdmin = UserModel(
    id: 'ADM-001',
    email: 'admin@campus.edu',
    name: 'Dean Admin',
    role: AppRole.collegeAdmin,
    collegeId: 'COL-001',
  );

  final otherCollegeStudent = UserModel(
    id: 'STU-999',
    email: 'other@othercollege.edu',
    name: 'Other Student',
    role: AppRole.student,
    collegeId: 'COL-002',
    departmentId: 'DEP-ECE',
  );


  Widget buildTestApp({
    required Widget child,
    required UserModel user,
    AttendanceAlertRepository? repository,
    List<Override> overrides = const [],
    ThemeMode themeMode = ThemeMode.light,
    double width = 1200,
    double height = 800,
  }) {
    return ProviderScope(
      overrides: [
        authProvider.overrideWith((ref) => _FakeAuthNotifier(AuthAuthenticated(user: user, token: 'mock-token'))),
        if (repository != null)
          attendanceAlertRepositoryProvider.overrideWithValue(repository),
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

  group('ACADEX Phase 8D: Domain Early-Warning Evaluator Tests', () {
    final evaluator = AttendanceRiskEvaluator();

    test('1. Low-attendance alert generated when percentage < 75%', () {
      const studentAnalytics = StudentAttendanceAnalytics(
        studentId: 'STU-001',
        studentName: 'Rahul Kumar',
        rollNumber: 'CS2026-01',
        sectionId: 'SEC-A',
        totalSessions: 10,
        presentCount: 6, // 60% < 75%
        absentCount: 4,
        attendancePercentage: 60.0,
        isLowAttendance: true,
      );

      final alerts = evaluator.evaluateStudent(
        studentAnalytics: studentAnalytics,
        collegeId: 'COL-001',
        departmentId: 'DEP-CSE',
      );

      expect(alerts, isNotEmpty);
      final lowAlert = alerts.firstWhere((a) => a.alertType == AttendanceAlertType.lowAttendance);
      expect(lowAlert.studentId, 'STU-001');
      expect(lowAlert.attendancePercentage, 60.0);
      expect(lowAlert.threshold, 75.0);
      expect(lowAlert.status, AttendanceAlertStatus.active);
    });

    test('2. No alert when attendance is >= 75%', () {
      const studentAnalytics = StudentAttendanceAnalytics(
        studentId: 'STU-002',
        studentName: 'Priya Singh',
        rollNumber: 'CS2026-02',
        sectionId: 'SEC-A',
        totalSessions: 10,
        presentCount: 8, // 80% >= 75%
        absentCount: 2,
        attendancePercentage: 80.0,
        isLowAttendance: false,
      );

      final alerts = evaluator.evaluateStudent(
        studentAnalytics: studentAnalytics,
        collegeId: 'COL-001',
        departmentId: 'DEP-CSE',
      );

      expect(alerts, isEmpty);
    });

    test('3. Critical severity calculated correctly (< 70% or drop >= 10% or >= 3 consecutive absences)', () {
      const criticalStudent = StudentAttendanceAnalytics(
        studentId: 'STU-003',
        studentName: 'Amit Patel',
        rollNumber: 'CS2026-03',
        sectionId: 'SEC-A',
        totalSessions: 10,
        presentCount: 5, // 50% < 70%
        absentCount: 5,
        attendancePercentage: 50.0,
        isLowAttendance: true,
      );

      final alerts = evaluator.evaluateStudent(
        studentAnalytics: criticalStudent,
        collegeId: 'COL-001',
        departmentId: 'DEP-CSE',
      );

      final alert = alerts.first;
      expect(alert.severity, AttendanceAlertSeverity.critical);
    });

    test('4. Warning severity calculated correctly (70% - 74.99%)', () {
      const warningStudent = StudentAttendanceAnalytics(
        studentId: 'STU-004',
        studentName: 'Neha Gupta',
        rollNumber: 'CS2026-04',
        sectionId: 'SEC-A',
        totalSessions: 100,
        presentCount: 72, // 72.0% (between 70% and 74.99%)
        absentCount: 28,
        attendancePercentage: 72.0,
        isLowAttendance: true,
      );

      final alerts = evaluator.evaluateStudent(
        studentAnalytics: warningStudent,
        collegeId: 'COL-001',
        departmentId: 'DEP-CSE',
      );

      final alert = alerts.first;
      expect(alert.severity, AttendanceAlertSeverity.warning);
    });

    test('5. Attendance drop detected when previous % exceeds current by >= 5%', () {
      const droppingStudent = StudentAttendanceAnalytics(
        studentId: 'STU-005',
        studentName: 'Rohan Joshi',
        rollNumber: 'CS2026-05',
        sectionId: 'SEC-A',
        totalSessions: 20,
        presentCount: 16, // 80.0%
        absentCount: 4,
        attendancePercentage: 80.0,
        isLowAttendance: false,
      );

      final alerts = evaluator.evaluateStudent(
        studentAnalytics: droppingStudent,
        collegeId: 'COL-001',
        departmentId: 'DEP-CSE',
        previousOverallPercentage: 92.0, // Drop of 12.0% -> Critical Drop
      );

      expect(alerts, isNotEmpty);
      final dropAlert = alerts.firstWhere((a) => a.alertType == AttendanceAlertType.attendanceDrop);
      expect(dropAlert.dropPercentage, 12.0);
      expect(dropAlert.previousPercentage, 92.0);
      expect(dropAlert.severity, AttendanceAlertSeverity.critical);
    });

    test('6. Repeated absence detected when consecutive absences >= 2 or 3', () {
      const student = StudentAttendanceAnalytics(
        studentId: 'STU-006',
        studentName: 'Karan Mehra',
        rollNumber: 'CS2026-06',
        sectionId: 'SEC-A',
        totalSessions: 10,
        presentCount: 7,
        absentCount: 3,
        attendancePercentage: 70.0,
        isLowAttendance: true,
      );

      final recentSessions = [
        AttendanceSession(
          id: 'SES-1',
          collegeId: 'COL-001',
          departmentId: 'DEP-CSE',
          facultyId: 'FAC-001',
          subjectId: 'SUB-DBMS',
          subjectName: 'DBMS',
          sectionId: 'SEC-A',
          sectionName: 'Section A',
          timeSlot: '09:00 - 10:00',
          date: DateTime(2026, 8, 16),
          records: [
            AttendanceRecord(
              id: 'REC-1',
              studentId: 'STU-006',
              studentName: 'Karan Mehra',
              rollNumber: 'CS2026-06',
              sectionId: 'SEC-A',
              status: AttendanceStatus.absent,
            ),
          ],
        ),
        AttendanceSession(
          id: 'SES-2',
          collegeId: 'COL-001',
          departmentId: 'DEP-CSE',
          facultyId: 'FAC-001',
          subjectId: 'SUB-DBMS',
          subjectName: 'DBMS',
          sectionId: 'SEC-A',
          sectionName: 'Section A',
          timeSlot: '09:00 - 10:00',
          date: DateTime(2026, 8, 14),
          records: [
            AttendanceRecord(
              id: 'REC-2',
              studentId: 'STU-006',
              studentName: 'Karan Mehra',
              rollNumber: 'CS2026-06',
              sectionId: 'SEC-A',
              status: AttendanceStatus.absent,
            ),
          ],
        ),
        AttendanceSession(
          id: 'SES-3',
          collegeId: 'COL-001',
          departmentId: 'DEP-CSE',
          facultyId: 'FAC-001',
          subjectId: 'SUB-DBMS',
          subjectName: 'DBMS',
          sectionId: 'SEC-A',
          sectionName: 'Section A',
          timeSlot: '09:00 - 10:00',
          date: DateTime(2026, 8, 12),
          records: [
            AttendanceRecord(
              id: 'REC-3',
              studentId: 'STU-006',
              studentName: 'Karan Mehra',
              rollNumber: 'CS2026-06',
              sectionId: 'SEC-A',
              status: AttendanceStatus.absent,
            ),
          ],
        ),
      ];

      final alerts = evaluator.evaluateStudent(
        studentAnalytics: student,
        collegeId: 'COL-001',
        departmentId: 'DEP-CSE',
        recentSessions: recentSessions,
      );

      final repAlert = alerts.firstWhere((a) => a.alertType == AttendanceAlertType.repeatedAbsence);
      expect(repAlert.consecutiveAbsences, 3);
      expect(repAlert.severity, AttendanceAlertSeverity.critical);
    });

    test('7. Unmarked attendance detection behaves correctly when scheduled timetable slot has no session', () {
      final scheduledEntries = [
        TimetableModel(
          id: 'TT-01',
          academicYearId: 'AY-2026',
          courseId: 'CRS-CSE',
          departmentId: 'DEP-CSE',
          semesterId: 'SEM-4',
          sectionId: 'SEC-A',
          subjectId: 'SUB-DBMS',
          facultyId: 'FAC-001',
          roomNumber: 'Lab-1',
          dayOfWeek: TimetableDay.monday,
          startTime: '09:00',
          endTime: '10:00',
          sessionType: TimetableSessionType.lecture,
          collegeId: 'COL-001',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final alerts = evaluator.evaluateUnmarkedClasses(
        scheduledEntries: scheduledEntries,
        conductedSessionTimetableIds: [], // None conducted
        referenceDate: DateTime(2026, 8, 17),
        collegeId: 'COL-001',
        departmentId: 'DEP-CSE',
      );

      expect(alerts, isNotEmpty);
      final unmarkedAlert = alerts.first;
      expect(unmarkedAlert.alertType, AttendanceAlertType.unmarkedAttendance);
      expect(unmarkedAlert.relatedTimetableEntryId, 'TT-01');
      expect(unmarkedAlert.facultyId, 'FAC-001');
    });

    test('8. Duplicate alerts prevented via deduplication key', () {
      const studentAnalytics = StudentAttendanceAnalytics(
        studentId: 'STU-001',
        studentName: 'Rahul Kumar',
        rollNumber: 'CS2026-01',
        sectionId: 'SEC-A',
        totalSessions: 10,
        presentCount: 6,
        absentCount: 4,
        attendancePercentage: 60.0,
        isLowAttendance: true,
      );

      final existingAlert = AttendanceAlert.createLowAttendance(
        id: 'EXISTING-001',
        collegeId: 'COL-001',
        departmentId: 'DEP-CSE',
        studentId: 'STU-001',
        studentName: 'Rahul Kumar',
        rollNumber: 'CS2026-01',
        sectionId: 'SEC-A',
        attendancePercentage: 62.0,
        presentCount: 6,
        totalSessions: 10,
      );

      final alerts = evaluator.evaluateStudent(
        studentAnalytics: studentAnalytics,
        collegeId: 'COL-001',
        departmentId: 'DEP-CSE',
        existingAlerts: [existingAlert],
      );

      expect(alerts.length, 1);
      expect(alerts.first.id, 'EXISTING-001'); // Preserved identity rather than new ID
      expect(alerts.first.deduplicationKey, existingAlert.deduplicationKey);
    });

    test('9. Alert acknowledged (status transitions to acknowledged)', () async {
      final repo = MockAttendanceAlertRepository();
      final alert = AttendanceAlert.createLowAttendance(
        id: 'ALT-ACK',
        collegeId: 'COL-001',
        departmentId: 'DEP-CSE',
        studentId: 'STU-001',
        studentName: 'Rahul Kumar',
        rollNumber: 'CS2026-01',
        attendancePercentage: 68.0,
        presentCount: 6,
        totalSessions: 9,
      );
      await repo.saveAlert(alert);

      await repo.acknowledgeAlert('ALT-ACK');
      final fetched = await repo.getAlertById('ALT-ACK');

      expect(fetched?.status, AttendanceAlertStatus.acknowledged);
      expect(fetched?.acknowledgedAt, isNotNull);
    });

    test('10. Alert resolved (status transitions to resolved and resolvedAt timestamp set)', () async {
      final repo = MockAttendanceAlertRepository();
      final alert = AttendanceAlert.createLowAttendance(
        id: 'ALT-RES',
        collegeId: 'COL-001',
        departmentId: 'DEP-CSE',
        studentId: 'STU-001',
        studentName: 'Rahul Kumar',
        rollNumber: 'CS2026-01',
        attendancePercentage: 68.0,
        presentCount: 6,
        totalSessions: 9,
      );
      await repo.saveAlert(alert);

      await repo.resolveAlert('ALT-RES');
      final fetched = await repo.getAlertById('ALT-RES');

      expect(fetched?.status, AttendanceAlertStatus.resolved);
      expect(fetched?.resolvedAt, isNotNull);
    });

    test('23. Recovery calculation is mathematically correct: ceil(3 * Total - 4 * Present)', () {
      // 10 sessions, 6 present (60%) -> ceil((75 * 10 - 100 * 6) / 25) = (750 - 600) / 25 = 6 sessions needed
      final sessionsNeeded = AttendanceAnalyticsConstants.calculateSessionsNeededToReachThreshold(
        presentCount: 6,
        totalSessions: 10,
      );
      expect(sessionsNeeded, 6);

      // Verify: with +6 present, total = 16, present = 12 -> 12 / 16 = 75.0%
      expect((6 + 6) / (10 + 6) * 100.0, 75.0);
    });

    test('24. Attendance improvement resolves alert when attendance reaches >= 75%', () {
      final existingAlert = AttendanceAlert.createLowAttendance(
        id: 'ALT-RECOVERY',
        collegeId: 'COL-001',
        departmentId: 'DEP-CSE',
        studentId: 'STU-001',
        studentName: 'Rahul Kumar',
        rollNumber: 'CS2026-01',
        sectionId: 'SEC-A',
        attendancePercentage: 68.0,
        presentCount: 13,
        totalSessions: 19,
      );

      // Now student attends class -> present = 14, total = 20 (70% -> 75%)
      const recoveredAnalytics = StudentAttendanceAnalytics(
        studentId: 'STU-001',
        studentName: 'Rahul Kumar',
        rollNumber: 'CS2026-01',
        sectionId: 'SEC-A',
        totalSessions: 20,
        presentCount: 15, // 75.0%
        absentCount: 5,
        attendancePercentage: 75.0,
        isLowAttendance: false,
      );

      final alerts = evaluator.evaluateStudent(
        studentAnalytics: recoveredAnalytics,
        collegeId: 'COL-001',
        departmentId: 'DEP-CSE',
        existingAlerts: [existingAlert],
      );

      expect(alerts, isNotEmpty);
      final resolved = alerts.firstWhere((a) => a.id == 'ALT-RECOVERY');
      expect(resolved.status, AttendanceAlertStatus.resolved);
      expect(resolved.resolvedAt, isNotNull);
    });
  });

  group('ACADEX Phase 8D: Scoping, Security & Repository Tests', () {
    late MockAttendanceAlertRepository repo;

    setUp(() {
      repo = MockAttendanceAlertRepository([
        // Student 1 Alert (CSE, College 1)
        AttendanceAlert.createLowAttendance(
          id: 'A1',
          collegeId: 'COL-001',
          departmentId: 'DEP-CSE',
          studentId: 'STU-001',
          studentName: 'Rahul Kumar',
          rollNumber: 'CS2026-01',
          sectionId: 'SEC-A',
          subjectId: 'SUB-DBMS',
          subjectName: 'DBMS',
          facultyId: 'FAC-001',
          attendancePercentage: 65.0,
          presentCount: 13,
          totalSessions: 20,
        ),
        // Student 2 Alert (CSE, College 1)
        AttendanceAlert.createLowAttendance(
          id: 'A2',
          collegeId: 'COL-001',
          departmentId: 'DEP-CSE',
          studentId: 'STU-002',
          studentName: 'Priya Singh',
          rollNumber: 'CS2026-02',
          sectionId: 'SEC-B',
          subjectId: 'SUB-OS',
          subjectName: 'Operating Systems',
          facultyId: 'FAC-002',
          attendancePercentage: 72.0,
          presentCount: 14,
          totalSessions: 20,
        ),
        // Other College Student Alert (College 2)
        AttendanceAlert.createLowAttendance(
          id: 'A3',
          collegeId: 'COL-002',
          departmentId: 'DEP-ECE',
          studentId: 'STU-999',
          studentName: 'Other Student',
          rollNumber: 'EC2026-99',
          attendancePercentage: 50.0,
          presentCount: 5,
          totalSessions: 10,
        ),
      ]);
    });

    test('11. Student sees only own alerts', () async {
      final alerts = await repo.getAlerts(user: testStudent);
      expect(alerts.length, 1);
      expect(alerts.first.studentId, 'STU-001');
    });

    test('12. Faculty sees only authorized alerts', () async {
      final alerts = await repo.getAlerts(user: testFaculty);
      expect(alerts.length, 1);
      expect(alerts.first.facultyId, 'FAC-001');
    });

    test('13. HOD sees only department alerts', () async {
      final alerts = await repo.getAlerts(user: testHod);
      expect(alerts.length, 2);
      expect(alerts.every((a) => a.departmentId == 'DEP-CSE'), isTrue);
    });

    test('14. College Admin sees only college alerts', () async {
      final alerts = await repo.getAlerts(user: testCollegeAdmin);
      expect(alerts.length, 2);
      expect(alerts.every((a) => a.collegeId == 'COL-001'), isTrue);
    });

    test('30. No unauthorized data leaks across tenant boundaries', () async {
      final alerts = await repo.getAlerts(user: otherCollegeStudent);
      expect(alerts.length, 1);
      expect(alerts.first.collegeId, 'COL-002');
    });

    test('15. Search works across student name, roll, subject, section', () async {
      final searchByName = await repo.getAlerts(user: testHod, searchQuery: 'Rahul');
      expect(searchByName.length, 1);
      expect(searchByName.first.studentName, 'Rahul Kumar');

      final searchByRoll = await repo.getAlerts(user: testHod, searchQuery: 'CS2026-02');
      expect(searchByRoll.length, 1);
      expect(searchByRoll.first.rollNumber, 'CS2026-02');

      final searchBySubject = await repo.getAlerts(user: testHod, searchQuery: 'DBMS');
      expect(searchBySubject.length, 1);
      expect(searchBySubject.first.subjectName, 'DBMS');
    });

    test('16. Severity filtering works', () async {
      final criticalOnly = await repo.getAlerts(
        user: testHod,
        filter: const AttendanceAlertFilter(severity: AttendanceAlertSeverity.critical),
      );
      expect(criticalOnly.length, 1);
      expect(criticalOnly.first.severity, AttendanceAlertSeverity.critical);

      final warningOnly = await repo.getAlerts(
        user: testHod,
        filter: const AttendanceAlertFilter(severity: AttendanceAlertSeverity.warning),
      );
      expect(warningOnly.length, 1);
      expect(warningOnly.first.severity, AttendanceAlertSeverity.warning);
    });

    test('17. Unread filtering works', () async {
      await repo.markAsRead('A1');

      final unreadAlerts = await repo.getAlerts(
        user: testHod,
        filter: const AttendanceAlertFilter(unreadOnly: true),
      );
      expect(unreadAlerts.length, 1);
      expect(unreadAlerts.first.id, 'A2');
    });

    test('18. Active/resolved filtering works', () async {
      await repo.resolveAlert('A1');

      final activeAlerts = await repo.getAlerts(
        user: testHod,
        filter: const AttendanceAlertFilter(status: AttendanceAlertStatus.active),
      );
      expect(activeAlerts.length, 1);
      expect(activeAlerts.first.id, 'A2');

      final resolvedAlerts = await repo.getAlerts(
        user: testHod,
        filter: const AttendanceAlertFilter(status: AttendanceAlertStatus.resolved),
      );
      expect(resolvedAlerts.length, 1);
      expect(resolvedAlerts.first.id, 'A1');
    });

    test('19. Mark as read works', () async {
      await repo.markAsRead('A1');
      final alert = await repo.getAlertById('A1');
      expect(alert?.isRead, isTrue);
      expect(alert?.readAt, isNotNull);
    });

    test('20. Mark all as read works', () async {
      await repo.markAllAsRead(user: testHod);
      final alerts = await repo.getAlerts(user: testHod);
      expect(alerts.every((a) => a.isRead == true), isTrue);
    });

    test('21. Dashboard alert counts (summary) are correct', () async {
      final summary = await repo.getAlertSummary(user: testHod);
      expect(summary.totalAlerts, 2);
      expect(summary.criticalCount, 1);
      expect(summary.warningCount, 1);
      expect(summary.unreadCount, 2);
      expect(summary.activeCount, 2);
    });
  });

  group('ACADEX Phase 8D: Presentation & UI Widget Tests', () {
    late MockAttendanceAlertRepository repo;

    setUp(() {
      repo = MockAttendanceAlertRepository([
        AttendanceAlert.createLowAttendance(
          id: 'ALERT-01',
          collegeId: 'COL-001',
          departmentId: 'DEP-CSE',
          studentId: 'STU-001',
          studentName: 'Rahul Kumar',
          rollNumber: 'CS2026-01',
          sectionId: 'SEC-A',
          subjectId: 'SUB-DBMS',
          subjectName: 'DBMS',
          facultyId: 'FAC-001',
          attendancePercentage: 65.0,
          presentCount: 13,
          totalSessions: 20,
        ),
      ]);
    });

    testWidgets('21. AttendanceAlertSummaryCard renders metrics and navigates', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          child: const AttendanceAlertSummaryCard(),
          user: testHod,
          repository: repo,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Attendance Early Warnings'), findsOneWidget);
      expect(find.text('Critical Risk'), findsOneWidget);
      expect(find.text('Unread Alerts'), findsOneWidget);
      expect(find.text('1'), findsNWidgets(2));
    });

    testWidgets('22. AttendanceAlertDetailScreen renders diagnosis and recovery actions', (tester) async {
      final alert = AttendanceAlert.createLowAttendance(
        id: 'ALERT-01',
        collegeId: 'COL-001',
        departmentId: 'DEP-CSE',
        studentId: 'STU-001',
        studentName: 'Rahul Kumar',
        rollNumber: 'CS2026-01',
        sectionId: 'SEC-A',
        subjectId: 'SUB-DBMS',
        subjectName: 'DBMS',
        facultyId: 'FAC-001',
        attendancePercentage: 65.0,
        presentCount: 13,
        totalSessions: 20,
      );

      await tester.pumpWidget(
        buildTestApp(
          child: AttendanceAlertDetailScreen(alert: alert),
          user: testHod,
          repository: repo,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Attendance Alert Details'), findsOneWidget);
      expect(find.text('Current Attendance'), findsOneWidget);
      expect(find.text('65.0%'), findsOneWidget);
      expect(find.text('Attendance Recovery Projection'), findsOneWidget);
      expect(find.text('View Attendance Details'), findsOneWidget);
    });

    testWidgets('25. Real-time / provider invalidation works', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          child: const AttendanceAlertsScreen(),
          user: testHod,
          repository: repo,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Rahul Kumar'), findsAtLeastNWidgets(1));

      // Add a new alert to repository and refresh
      await repo.saveAlert(
        AttendanceAlert.createLowAttendance(
          id: 'ALERT-02',
          collegeId: 'COL-001',
          departmentId: 'DEP-CSE',
          studentId: 'STU-002',
          studentName: 'Ananya Sharma',
          rollNumber: 'CS2026-02',
          sectionId: 'SEC-A',
          attendancePercentage: 60.0,
          presentCount: 6,
          totalSessions: 10,
        ),
      );

      // Refresh provider
      final element = tester.element(find.byType(AttendanceAlertsScreen));
      final container = ProviderScope.containerOf(element);
      container.invalidate(attendanceAlertsProvider);
      await tester.pumpAndSettle();

      expect(find.textContaining('Ananya Sharma'), findsAtLeastNWidgets(1));
    });

    testWidgets('26. Empty state works cleanly when no alerts exist', (tester) async {
      final emptyRepo = MockAttendanceAlertRepository([]);

      await tester.pumpWidget(
        buildTestApp(
          child: const AttendanceAlertsScreen(),
          user: testHod,
          repository: emptyRepo,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('All Students Compliant'), findsOneWidget);
      expect(find.textContaining('No attendance alerts right now.'), findsOneWidget);
    });

    testWidgets('27. Error state renders with retry CTA', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          child: const AttendanceAlertsScreen(),
          user: testHod,
          overrides: [
            attendanceAlertsProvider.overrideWith((ref) => Future.error('Network failure')),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Failed to load attendance alerts'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('28. Mobile layout renders cleanly at 360px without overflow', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          child: const AttendanceAlertsScreen(),
          user: testHod,
          repository: repo,
          width: 360,
          height: 640,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Attendance Early-Warning Center'), findsOneWidget);
    });

    testWidgets('29. Dark mode renders cleanly without styling errors', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          child: const AttendanceAlertsScreen(),
          user: testHod,
          repository: repo,
          themeMode: ThemeMode.dark,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Attendance Early-Warning Center'), findsOneWidget);
    });
  });
}
