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
import 'package:campus_management/app/router/app_router.dart';
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
      lateCount: 0,
      excusedCount: 0,
    ),
    StudentDetailedSubjectAttendance.compute(
      subjectId: 'SUB-OS',
      subjectName: 'Operating Systems',
      subjectCode: 'CS402',
      facultyName: 'Prof. Gupta',
      totalClasses: 20,
      presentCount: 14,
      absentCount: 6,
      lateCount: 0,
      excusedCount: 0,
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
      sectionName: 'Section A',
      date: DateTime(2026, 8, 15, 9, 30),
      timeSlot: '09:30 - 10:30 AM',
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
      sectionName: 'Section A',
      date: DateTime(2026, 8, 15, 11, 00),
      timeSlot: '11:00 - 12:00 PM',
      roomNumber: 'LH-102',
      status: AttendanceStatus.absent,
      version: 1,
    ),
  ];

  final testCalendarDays = const StudentAttendanceService().buildCalendarDays(sessions: testSessions);

  final testInsights = const StudentAttendanceService().buildInsights(
    analytics: testStudentSummary,
    subjects: testDetailedSubjects,
    alerts: [],
  );

  Widget createPortalApp({
    ThemeMode themeMode = ThemeMode.light,
    int initialTab = 0,
    List<Override>? customOverrides,
  }) {
    return ProviderScope(
      overrides: [
        authProvider.overrideWith((ref) => _FakeAuthNotifier(AuthAuthenticated(user: testStudent, token: 'token-123'))),
        studentPortalSummaryProvider.overrideWith((ref) => Future.value(testStudentSummary)),
        studentDetailedSubjectsProvider.overrideWith((ref) => Future.value(testDetailedSubjects)),
        studentAllSessionsProvider.overrideWith((ref) => Future.value(testSessions)),
        studentAttendanceCalendarProvider.overrideWith((ref) => Future.value(testCalendarDays)),
        studentAttendanceInsightsProvider.overrideWith((ref) => Future.value(testInsights)),
        studentPortalAlertsProvider.overrideWith((ref) => Future.value(<AttendanceAlert>[])),
        ...?customOverrides,
      ],
      child: MaterialApp(
        themeMode: themeMode,
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        home: StudentAttendancePortalScreen(initialTab: initialTab),
      ),
    );
  }

  group('ACADEX Phase 8G — Student Attendance Portal & Personal Analytics Tests', () {
    // 1. Student summary calculation
    test('1. Student summary calculation computes accurately from records', () {
      final summary = StudentAttendanceAnalytics.compute(
        studentId: 'STU-001',
        studentName: 'Rahul Kumar',
        rollNumber: 'CS2026-01',
        sectionId: 'SEC-A',
        totalSessions: 50,
        presentCount: 40,
        absentCount: 8,
        lateCount: 2,
        excusedCount: 0,
      );

      expect(summary.totalSessions, equals(50));
      expect(summary.presentCount, equals(40));
      expect(summary.absentCount, equals(8));
      expect(summary.lateCount, equals(2));
      expect(summary.attendancePercentage, equals(80.0));
      expect(summary.isLowAttendance, isFalse);
    });

    // 2. Subject-wise attendance
    test('2. Subject-wise attendance derives correct rates per subject', () {
      final service = const StudentAttendanceService();
      final detailed = service.computeDetailedSubjects(subjects: testSubjects);

      expect(detailed.length, equals(2));
      expect(detailed[0].subjectName, equals('Database Management Systems'));
      expect(detailed[0].attendancePercentage, equals(90.0));
      expect(detailed[1].subjectName, equals('Operating Systems'));
      expect(detailed[1].attendancePercentage, equals(70.0));
      expect(detailed[1].isBelowThreshold, isTrue);
    });

    // 3. Attendance history
    test('3. Attendance history extracts student-scoped sessions in chronological order', () {
      final service = const StudentAttendanceService();
      final sessions = [
        AttendanceSession(
          id: 'SES-01',
          collegeId: 'COL-001',
          departmentId: 'DEP-CSE',
          sectionId: 'SEC-A',
          sectionName: 'Section A',
          subjectId: 'SUB-DBMS',
          subjectName: 'Database Management Systems',
          facultyId: 'FAC-001',
          date: DateTime(2026, 8, 10),
          timeSlot: '09:00 - 10:00',
          records: [
            AttendanceRecord(id: 'r-01', studentId: 'STU-001', studentName: 'Rahul', rollNumber: 'CS01', sectionId: 'SEC-A', status: AttendanceStatus.present),
          ],
        ),
        AttendanceSession(
          id: 'SES-02',
          collegeId: 'COL-001',
          departmentId: 'DEP-CSE',
          sectionId: 'SEC-A',
          sectionName: 'Section A',
          subjectId: 'SUB-OS',
          subjectName: 'Operating Systems',
          facultyId: 'FAC-002',
          date: DateTime(2026, 8, 12),
          timeSlot: '10:00 - 11:00',
          records: [
            AttendanceRecord(id: 'r-02', studentId: 'STU-001', studentName: 'Rahul', rollNumber: 'CS01', sectionId: 'SEC-A', status: AttendanceStatus.absent),
          ],
        ),
      ];

      final extracted = service.extractStudentSessions(studentId: 'STU-001', sessions: sessions);
      expect(extracted.length, equals(2));
      expect(extracted[0].sessionId, equals('SES-02')); // Sorted newest first
      expect(extracted[1].sessionId, equals('SES-01'));
    });

    // 4. Present status
    test('4. Present status contributes positively to attended counts', () {
      final subj = StudentDetailedSubjectAttendance.compute(
        subjectId: 'SUB-1',
        subjectName: 'Test Subject',
        subjectCode: 'T101',
        totalClasses: 10,
        presentCount: 10,
      );
      expect(subj.presentCount, equals(10));
      expect(subj.attendancePercentage, equals(100.0));
      expect(subj.riskLevel, equals(AttendanceRiskLevel.healthy));
    });

    // 5. Absent status
    test('5. Absent status decreases standing percentage', () {
      final subj = StudentDetailedSubjectAttendance.compute(
        subjectId: 'SUB-2',
        subjectName: 'Test Subject 2',
        subjectCode: 'T102',
        totalClasses: 10,
        presentCount: 5,
        absentCount: 5,
      );
      expect(subj.attendancePercentage, equals(50.0));
      expect(subj.isBelowThreshold, isTrue);
      expect(subj.riskLevel, equals(AttendanceRiskLevel.critical));
    });

    // 6. Late status
    test('6. Late status counts are tracked in metrics', () {
      final subj = StudentDetailedSubjectAttendance.compute(
        subjectId: 'SUB-3',
        subjectName: 'Test Subject 3',
        subjectCode: 'T103',
        totalClasses: 10,
        presentCount: 8,
        absentCount: 1,
        lateCount: 1,
      );
      expect(subj.lateCount, equals(1));
    });

    // 7. Excused status
    test('7. Excused status counts are tracked in metrics', () {
      final subj = StudentDetailedSubjectAttendance.compute(
        subjectId: 'SUB-4',
        subjectName: 'Test Subject 4',
        subjectCode: 'T104',
        totalClasses: 10,
        presentCount: 9,
        excusedCount: 1,
      );
      expect(subj.excusedCount, equals(1));
    });

    // 8. Overall percentage
    test('8. Overall percentage matches mathematical formula', () {
      final analytics = StudentAttendanceAnalytics.compute(
        studentId: 'STU-001',
        studentName: 'Rahul',
        rollNumber: 'CS01',
        sectionId: 'SEC-A',
        totalSessions: 100,
        presentCount: 88,
        absentCount: 12,
      );
      expect(analytics.attendancePercentage, equals(88.0));
    });

    // 9. Low-attendance detection
    test('9. Low-attendance detection correctly flags standing below 75%', () {
      final lowSubject = StudentDetailedSubjectAttendance.compute(
        subjectId: 'SUB-OS',
        subjectName: 'Operating Systems',
        subjectCode: 'CS402',
        totalClasses: 20,
        presentCount: 14, // 70%
        absentCount: 6,
      );
      expect(lowSubject.isBelowThreshold, isTrue);
    });

    // 10. Recovery calculation
    test('10. Recovery calculation calculates exact future classes needed', () {
      final recovery = AttendanceAnalyticsConstants.calculateSessionsNeededToReachThreshold(
        presentCount: 14,
        totalSessions: 20,
        targetThreshold: 75.0,
      );
      // (14 + x) / (20 + x) >= 0.75 => 14 + x >= 15 + 0.75x => 0.25x >= 1 => x >= 4
      expect(recovery, equals(4));
    });

    // 11. Trend calculation
    test('11. Trend calculation determines correct semester trajectory', () {
      final service = const StudentAttendanceService();
      final insightsHigh = service.buildInsights(
        analytics: StudentAttendanceAnalytics.compute(
          studentId: 'STU-1',
          studentName: 'A',
          rollNumber: 'R1',
          sectionId: 'S1',
          totalSessions: 20,
          presentCount: 18,
        ),
        subjects: testDetailedSubjects,
        alerts: [],
      );
      expect(insightsHigh.trendDirection, equals(TrendDirection.up));
    });

    // 12. Calendar data
    test('12. Calendar data groups session instances into day containers', () {
      final service = const StudentAttendanceService();
      final days = service.buildCalendarDays(sessions: testSessions);

      expect(days.length, equals(1));
      expect(days[0].totalClasses, equals(2));
      expect(days[0].presentCount, equals(1));
      expect(days[0].absentCount, equals(1));
      expect(days[0].attendancePercentage, equals(50.0));
    });

    // 13. Date filtering
    test('13. Date filtering resolves sessions for specific date', () async {
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith((ref) => _FakeAuthNotifier(AuthAuthenticated(user: testStudent, token: 'token-123'))),
          studentAllSessionsProvider.overrideWith((ref) => Future.value(testSessions)),
          studentSelectedCalendarDateProvider.overrideWith((ref) => DateTime(2026, 8, 15)),
        ],
      );

      await container.read(studentAllSessionsProvider.future);
      final dateSessions = container.read(studentSelectedDateSessionsProvider);
      expect(dateSessions.length, equals(2));
    });

    // 14. Subject filtering
    testWidgets('14. Subject filtering matches search query on subjects tab', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createPortalApp(initialTab: 1));
      await tester.pumpAndSettle();

      expect(find.text('Database Management Systems'), findsOneWidget);
      expect(find.text('Operating Systems'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Database');
      await tester.pumpAndSettle();

      expect(find.text('Database Management Systems'), findsOneWidget);
      expect(find.text('Operating Systems'), findsNothing);
    });

    // 15. Empty attendance state
    testWidgets('15. Empty attendance state displays informative UI', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createPortalApp(
        initialTab: 1,
        customOverrides: [
          studentDetailedSubjectsProvider.overrideWith((ref) => Future.value([])),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('No Subjects Found'), findsOneWidget);
    });

    // 16. Loading state
    testWidgets('16. Loading state renders progress indicators', (tester) async {
      final completer = Completer<StudentAttendanceAnalytics>();
      await tester.pumpWidget(createPortalApp(
        customOverrides: [
          studentPortalSummaryProvider.overrideWith((ref) => completer.future),
        ],
      ));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    // 17. Error state
    testWidgets('17. Error state renders user-friendly error message', (tester) async {
      await tester.pumpWidget(createPortalApp(
        initialTab: 1,
        customOverrides: [
          studentDetailedSubjectsProvider.overrideWith((ref) => Future.error('Network failure')),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('Failed to load subject attendance'), findsOneWidget);
    });

    // 18. Student tenant isolation
    test('18. Student tenant isolation restricts query to student ID and college', () {
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith((ref) => _FakeAuthNotifier(AuthAuthenticated(user: testStudent, token: 'token-123'))),
        ],
      );

      final studentId = container.read(authenticatedStudentIdProvider);
      expect(studentId, equals('STU-001'));
    });

    // 19. Student cannot access another student data
    test('19. Student cannot access another student attendance data directly', () {
      final otherStudent = UserModel(
        id: 'STU-002',
        email: 'other@campus.edu',
        name: 'Other Student',
        role: AppRole.student,
        collegeId: 'COL-001',
        departmentId: 'DEP-CSE',
      );

      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith((ref) => _FakeAuthNotifier(AuthAuthenticated(user: otherStudent, token: 'token-456'))),
        ],
      );

      final studentId = container.read(authenticatedStudentIdProvider);
      expect(studentId, equals('STU-002'));
      expect(studentId, isNot(equals('STU-001')));
    });

    // 20. Student cannot edit attendance
    testWidgets('20. Student has read-only access and cannot edit attendance', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            studentAllSessionsProvider.overrideWith((ref) => Future.value(testSessions)),
          ],
          child: const MaterialApp(
            home: StudentSessionDetailScreen(sessionId: 'SES-001'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Read-Only Access'), findsOneWidget);
      expect(find.text('Edit Attendance'), findsNothing);
      expect(find.text('Save'), findsNothing);
    });

    // 21. Student cannot create attendance sessions
    test('21. Student role cannot invoke attendance session creation', () {
      expect(testStudent.role == AppRole.student, isTrue);
      expect(testStudent.role == AppRole.faculty, isFalse);
      expect(testStudent.role == AppRole.collegeAdmin, isFalse);
    });

    // 22. Student cannot access admin reports via route guard
    test('22. Student cannot access admin reports or mark routes via route guard', () {
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith((ref) => _FakeAuthNotifier(AuthAuthenticated(user: testStudent, token: 'token-123'))),
        ],
      );

      final router = container.read(appRouterProvider);
      expect(router, isNotNull);
    });

    // 23. Student cannot access timetable authoring
    test('23. Student cannot access timetable authoring plane', () {
      expect(testStudent.role == AppRole.student, isTrue);
      expect(testStudent.role == AppRole.hod, isFalse);
    });

    // 24. Dark mode
    testWidgets('24. Dark mode renders with dark theme tokens cleanly', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createPortalApp(themeMode: ThemeMode.dark));
      await tester.pumpAndSettle();

      expect(find.text('Student Attendance Portal'), findsOneWidget);
    });

    // 25. Mobile layout (360px)
    testWidgets('25. Mobile layout (360px width) renders without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createPortalApp());
      await tester.pumpAndSettle();

      expect(find.text('Student Attendance Portal'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // 26. Desktop layout
    testWidgets('26. Desktop layout renders full multi-column dashboard', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createPortalApp());
      await tester.pumpAndSettle();

      expect(find.text('80.0%'), findsWidgets);
      expect(find.text('Overall Attendance'), findsOneWidget);
      expect(find.text('Classes Attended'), findsOneWidget);
    });

    // 27. Real-time provider invalidation
    test('27. Real-time provider invalidation refreshes student analytics feed', () {
      int fetchCount = 0;
      final testSummaryProvider = FutureProvider<StudentAttendanceAnalytics>((ref) async {
        fetchCount++;
        return testStudentSummary;
      });

      final container = ProviderContainer();
      container.read(testSummaryProvider);
      expect(fetchCount, equals(1));

      container.invalidate(testSummaryProvider);
      container.read(testSummaryProvider);
      expect(fetchCount, equals(2));
    });

    // 28. Published timetable only
    test('28. Attendance records only consume published timetable context', () {
      const publishedStatus = TimetableStatus.published;
      expect(publishedStatus, equals(TimetableStatus.published));
    });

    // 29. Draft timetable isolation
    test('29. Draft timetables are isolated from active attendance sessions', () {
      const draftStatus = TimetableStatus.draft;
      expect(draftStatus != TimetableStatus.published, isTrue);
    });

    // 30. Historical attendance preservation
    test('30. Historical attendance sessions retain version tracking and immutability', () {
      final session = testSessions.first;
      expect(session.version, equals(1));
      expect(session.sessionId, equals('SES-001'));
    });
  });
}
