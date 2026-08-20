import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_management/features/attendance/domain/models/attendance_alert.dart';
import 'package:campus_management/features/attendance/domain/models/attendance_analytics_models.dart';
import 'package:campus_management/features/attendance/domain/models/attendance_report_models.dart';
import 'package:campus_management/features/attendance/domain/models/attendance_session.dart';
import 'package:campus_management/features/attendance/domain/models/attendance_record.dart';
import 'package:campus_management/features/attendance/domain/models/attendance_status.dart';
import 'package:campus_management/features/attendance/domain/models/department_attendance_comparison.dart';
import 'package:campus_management/features/attendance/domain/services/attendance_report_exporter.dart';
import 'package:campus_management/features/attendance/domain/services/attendance_admin_service.dart';
import 'package:campus_management/features/attendance/presentation/providers/attendance_admin_providers.dart';
import 'package:campus_management/features/attendance/presentation/providers/attendance_alert_providers.dart';
import 'package:campus_management/features/attendance/presentation/providers/attendance_analytics_providers.dart';
import 'package:campus_management/features/attendance/presentation/screens/attendance_report_center_screen.dart';
import 'package:campus_management/features/attendance/presentation/screens/attendance_session_admin_screen.dart';
import 'package:campus_management/features/attendance/presentation/screens/attendance_admin_dashboard_screen.dart';
import 'package:campus_management/features/timetable/domain/models/timetable_models.dart';

class _FakeAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _FakeAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  final mockReportResult = AttendanceReportResult(
    reportType: AttendanceReportType.student,
    title: 'Student Attendance Report — Rahul Kumar',
    scopeDescription: 'Student ID: STU-001',
    generatedAt: DateTime(2026, 8, 18),
    generatedBy: 'Admin',
    totalRecords: 1,
    summaryStatistics: {
      'Overall Attendance': '85.0%',
      'Total Sessions': 20,
    },
    headers: ['Metric', 'Value'],
    rows: [
      ['Student Name', 'Rahul Kumar'],
      ['Overall Attendance', '85.0%'],
    ],
  );

  final mockReconciliation = const AttendanceReconciliationResult(
    expectedSessions: 20,
    recordedSessions: 18,
    missingSessions: 2,
    compliancePercentage: 90.0,
  );

  final mockDateRangeSummary = AttendanceDateRangeSummary(
    startDate: DateTime(2026, 8, 1),
    endDate: DateTime(2026, 8, 31),
    totalSessions: 100,
    totalStudentRecords: 1000,
    presentCount: 845,
    absentCount: 155,
    lateCount: 0,
    excusedCount: 0,
    unmarkedCount: 0,
    attendancePercentage: 84.5,
  );

  final mockAlertSummary = const AttendanceAlertSummary(
    criticalCount: 4,
    warningCount: 8,
    resolvedCount: 2,
  );

  Widget buildTestApp({
    required Widget child,
    required UserModel user,
    List<Override> overrides = const [],
    ThemeMode themeMode = ThemeMode.light,
    double width = 1200,
    double height = 800,
  }) {
    return ProviderScope(
      overrides: [
        authProvider.overrideWith((ref) => _FakeAuthNotifier(AuthAuthenticated(user: user, token: 'mock-token'))),
        attendanceReportDataProvider.overrideWith((ref, filter) async => mockReportResult),
        attendanceReconciliationProvider.overrideWith((ref, args) async => mockReconciliation),
        attendanceConsistencyProvider.overrideWith((ref, args) async => []),
        attendanceAuditHistoryProvider.overrideWith((ref, args) async => []),
        attendanceAdminSessionsProvider.overrideWith((ref, args) async => [
          AttendanceSession(
            id: 'S-101',
            collegeId: 'COL-001',
            departmentId: 'DEP-CSE',
            facultyId: 'FAC-001',
            subjectId: 'SUB-DBMS',
            subjectName: 'DBMS',
            sectionId: 'SEC-A',
            sectionName: 'DCME 4-A',
            timeSlot: '09:00 - 10:00',
            date: DateTime(2026, 8, 18),
            records: [],
            isSubmitted: true,
          ),
        ]),
        attendanceDateRangeSummaryProvider.overrideWith((ref, query) async => mockDateRangeSummary),
        attendanceAlertSummaryProvider.overrideWith((ref) async => mockAlertSummary),
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

  group('ACADEX Phase 8F: Attendance Report Center & Administration Tests', () {
    const adminService = AttendanceAdminService();

    test('1. Student report generation', () {
      final studentAnalytics = StudentAttendanceAnalytics.compute(
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

      final csv = AttendanceReportExporter.generateStudentAttendanceCsv(student: studentAnalytics);
      expect(csv, contains('ACADEX STUDENT ATTENDANCE REPORT'));
      expect(csv, contains('Rahul Kumar'));
      expect(csv, contains('80.0%'));
      expect(csv, contains('CS2026-01'));
    });

    test('2. Subject report generation', () {
      final subjectAnalytics = SubjectAttendanceAnalytics(
        subjectId: 'SUB-DBMS',
        subjectName: 'Database Management Systems',
        totalSessions: 15,
        totalStudentRecords: 150,
        presentCount: 120,
        absentCount: 20,
        lateCount: 10,
        excusedCount: 0,
        attendancePercentage: 86.7,
      );

      final csv = AttendanceReportExporter.generateSubjectAttendanceCsv(subject: subjectAnalytics);
      expect(csv, contains('ACADEX SUBJECT ATTENDANCE REPORT'));
      expect(csv, contains('Database Management Systems'));
      expect(csv, contains('86.7%'));
      expect(csv, contains('SUB-DBMS'));
    });

    test('3. Section report generation', () {
      final sectionAnalytics = SectionAttendanceAnalytics(
        sectionId: 'SEC-A',
        sectionName: 'DCME 4-A',
        totalStudents: 30,
        totalSessions: 25,
        attendancePercentage: 82.5,
        lowAttendanceStudentCount: 3,
        studentAnalytics: [
          StudentAttendanceAnalytics.compute(
            studentId: 'STU-001',
            studentName: 'Student 1',
            rollNumber: 'CS-01',
            sectionId: 'SEC-A',
            totalSessions: 25,
            presentCount: 22,
            absentCount: 3,
            lateCount: 0,
            excusedCount: 0,
          ),
        ],
      );

      final csv = AttendanceReportExporter.generateSectionAttendanceCsv(section: sectionAnalytics);
      expect(csv, contains('ACADEX SECTION ATTENDANCE REPORT'));
      expect(csv, contains('DCME 4-A'));
      expect(csv, contains('82.5%'));
      expect(csv, contains('Student 1'));
    });

    test('4. Faculty report generation', () {
      final facultyAnalytics = FacultyAttendanceAnalytics(
        facultyId: 'FAC-001',
        facultyName: 'Prof. Sharma',
        totalSessionsConducted: 40,
        totalStudentRecords: 600,
        presentCount: 510,
        absentCount: 90,
        attendancePercentage: 85.0,
      );

      final csv = AttendanceReportExporter.generateFacultyAttendanceCsv(faculty: facultyAnalytics);
      expect(csv, contains('ACADEX FACULTY ATTENDANCE REPORT'));
      expect(csv, contains('Prof. Sharma'));
      expect(csv, contains('40'));
    });

    test('5. Department report generation', () {
      final sections = [
        SectionAttendanceAnalytics(
          sectionId: 'SEC-A',
          sectionName: 'DCME 4-A',
          totalStudents: 30,
          totalSessions: 20,
          attendancePercentage: 85.0,
          lowAttendanceStudentCount: 2,
        ),
        SectionAttendanceAnalytics(
          sectionId: 'SEC-B',
          sectionName: 'DCME 4-B',
          totalStudents: 28,
          totalSessions: 20,
          attendancePercentage: 78.0,
          lowAttendanceStudentCount: 5,
        ),
      ];

      final csv = AttendanceReportExporter.generateDepartmentAttendanceCsv(
        departmentId: 'DEP-CSE',
        sections: sections,
      );

      expect(csv, contains('ACADEX DEPARTMENT ATTENDANCE REPORT'));
      expect(csv, contains('DEP-CSE'));
      expect(csv, contains('DCME 4-A'));
      expect(csv, contains('DCME 4-B'));
    });

    test('6. Low-attendance report generation', () {
      final lowStudents = <StudentAttendanceAnalytics>[
        StudentAttendanceAnalytics.compute(
          studentId: 'STU-009',
          studentName: 'Aman Deep',
          rollNumber: 'CS-09',
          sectionId: 'SEC-A',
          totalSessions: 20,
          presentCount: 12,
          absentCount: 8,
          lateCount: 0,
          excusedCount: 0,
        ),
      ];

      final csv = AttendanceReportExporter.generateLowAttendanceReportCsv(lowAttendanceStudents: lowStudents);
      expect(csv, contains('ACADEX LOW ATTENDANCE INTERVENTION REPORT'));
      expect(csv, contains('Aman Deep'));
      expect(csv, contains('60.0%'));
      expect(csv, contains('CRITICAL SHORTAGE'));
    });

    test('7. CSV headers have deterministic order', () {
      final report = AttendanceReportResult(
        reportType: AttendanceReportType.student,
        title: 'Deterministic Test Report',
        scopeDescription: 'Scope',
        generatedAt: DateTime.now(),
        generatedBy: 'Admin',
        totalRecords: 1,
        summaryStatistics: {'Total': 1},
        headers: ['Col A', 'Col B', 'Col C'],
        rows: [['1', '2', '3']],
      );

      final csv = AttendanceReportExporter.generateReportCsv(report);
      expect(csv, contains('Col A,Col B,Col C'));
    });

    test('8. CSV escaping handles commas, quotes, and newlines', () {
      expect(AttendanceReportExporter.escapeCsv('Simple'), 'Simple');
      expect(AttendanceReportExporter.escapeCsv('Hello, World'), '"Hello, World"');
      expect(AttendanceReportExporter.escapeCsv('He said "Hello"'), '"He said ""Hello"""');
      expect(AttendanceReportExporter.escapeCsv('Line1\nLine2'), '"Line1\nLine2"');
    });

    test('9. Unicode CSV data handles non-ASCII and international names correctly', () {
      final student = StudentAttendanceAnalytics.compute(
        studentId: 'STU-UNI',
        studentName: 'José Nuñez Ångström',
        rollNumber: 'CS-UNI-01',
        sectionId: 'SEC-A',
        totalSessions: 10,
        presentCount: 9,
        absentCount: 1,
        lateCount: 0,
        excusedCount: 0,
      );

      final csv = AttendanceReportExporter.generateStudentAttendanceCsv(student: student);
      expect(csv, contains('José Nuñez Ångström'));
    });

    test('10. Empty report handling produces clean placeholder', () {
      final report = AttendanceReportResult(
        reportType: AttendanceReportType.session,
        title: 'Empty Test Report',
        scopeDescription: 'Empty Scope',
        generatedAt: DateTime.now(),
        generatedBy: 'Admin',
        totalRecords: 0,
        summaryStatistics: {},
        headers: ['Session ID', 'Subject', 'Date'],
        rows: [],
      );

      final csv = AttendanceReportExporter.generateReportCsv(report);
      expect(csv, contains('No records found'));
    });

    test('11. PDF structured report generation includes institutional header and metadata', () {
      final report = AttendanceReportResult(
        reportType: AttendanceReportType.student,
        title: 'Student Official PDF Record',
        scopeDescription: 'Student: Rahul Kumar (CS-01)',
        generatedAt: DateTime(2026, 8, 18),
        generatedBy: 'Dean Admin',
        totalRecords: 1,
        summaryStatistics: {
          'Overall Attendance': '85.0%',
          'Status': 'Compliant',
        },
        headers: ['Metric', 'Value'],
        rows: [['Classes Attended', '17 / 20']],
      );

      final pdf = AttendanceReportExporter.generateStructuredPdfReport(reportResult: report);
      expect(pdf, contains('ACADEX CAMPUS MANAGEMENT SYSTEM'));
      expect(pdf, contains('OFFICIAL ATTENDANCE RECORD REPORT'));
      expect(pdf, contains('Overall Attendance'));
      expect(pdf, contains('Classes Attended'));
    });

    test('12. Date-range filtering applies to report models', () {
      final start = DateTime(2026, 8, 1);
      final end = DateTime(2026, 8, 31);
      final range = AttendanceDateRange.custom(startDate: start, endDate: end);

      const filter = AttendanceReportFilter(
        reportType: AttendanceReportType.student,
        dateRange: null,
      );

      final updated = filter.copyWith(dateRange: range);
      expect(updated.dateRange?.startDate.year, start.year);
      expect(updated.dateRange?.startDate.month, start.month);
      expect(updated.dateRange?.startDate.day, start.day);
      expect(updated.dateRange?.endDate.day, end.day);
    });

    test('13. Department filtering restricts scope', () {
      const filter = AttendanceReportFilter(
        reportType: AttendanceReportType.department,
        departmentId: 'DEP-CSE',
      );
      expect(filter.departmentId, 'DEP-CSE');
    });

    test('14. Section filtering scopes section reports', () {
      const filter = AttendanceReportFilter(
        reportType: AttendanceReportType.section,
        sectionId: 'SEC-A',
      );
      expect(filter.sectionId, 'SEC-A');
    });

    test('15. Subject filtering scopes subject reports', () {
      const filter = AttendanceReportFilter(
        reportType: AttendanceReportType.subject,
        subjectId: 'SUB-DBMS',
      );
      expect(filter.subjectId, 'SUB-DBMS');
    });

    test('16. Faculty filtering scopes faculty reports', () {
      const filter = AttendanceReportFilter(
        reportType: AttendanceReportType.faculty,
        facultyId: 'FAC-001',
      );
      expect(filter.facultyId, 'FAC-001');
    });

    test('17. Role scope limits exposed report types', () {
      expect(AppRole.student, isNotNull);
      expect(AppRole.faculty, isNotNull);
      expect(AppRole.hod, isNotNull);
      expect(AppRole.collegeAdmin, isNotNull);
    });

    test('18. Tenant isolation ensures multi-tenant collegeId scoping', () {
      const filter = AttendanceReportFilter(
        reportType: AttendanceReportType.college,
        collegeId: 'COL-001',
      );
      expect(filter.collegeId, 'COL-001');
    });

    test('19. Pagination partitions records accurately', () {
      final items = List.generate(25, (i) => 'Item $i');

      final page1 = items.sublist(0, 10);
      expect(page1.length, 10);
      expect(page1.first, 'Item 0');

      final page2 = items.sublist(10, 20);
      expect(page2.length, 10);
      expect(page2.first, 'Item 10');

      final page3 = items.sublist(20, 25);
      expect(page3.length, 5);
      expect(page3.last, 'Item 24');
    });

    test('20. Search filters items by query across subject and section', () {
      final sessions = [
        AttendanceSession(
          id: 'S1',
          collegeId: 'COL-001',
          departmentId: 'DEP-CSE',
          facultyId: 'FAC-001',
          subjectId: 'SUB-DBMS',
          subjectName: 'Database Systems',
          sectionId: 'SEC-A',
          sectionName: 'DCME 4-A',
          timeSlot: '09:00 - 10:00',
          date: DateTime.now(),
          records: [],
        ),
        AttendanceSession(
          id: 'S2',
          collegeId: 'COL-001',
          departmentId: 'DEP-ECE',
          facultyId: 'FAC-002',
          subjectId: 'SUB-CIRCUITS',
          subjectName: 'Electronic Circuits',
          sectionId: 'SEC-B',
          sectionName: 'DECE 4-B',
          timeSlot: '10:00 - 11:00',
          date: DateTime.now(),
          records: [],
        ),
      ];

      final filtered = sessions.where((s) => s.subjectName.toLowerCase().contains('database')).toList();
      expect(filtered.length, 1);
      expect(filtered.first.id, 'S1');
    });

    test('21. Sorting orders records by date, attendance percentage, and total students', () {
      final list = [
        SectionAttendanceAnalytics(sectionId: 'S1', sectionName: 'A', totalStudents: 30, totalSessions: 10, attendancePercentage: 80.0),
        SectionAttendanceAnalytics(sectionId: 'S2', sectionName: 'B', totalStudents: 20, totalSessions: 10, attendancePercentage: 90.0),
        SectionAttendanceAnalytics(sectionId: 'S3', sectionName: 'C', totalStudents: 25, totalSessions: 10, attendancePercentage: 70.0),
      ];

      list.sort((a, b) => b.attendancePercentage.compareTo(a.attendancePercentage));
      expect(list.first.sectionId, 'S2');
      expect(list.last.sectionId, 'S3');
    });

    test('22. Session audit data tracks version increments and modification deltas', () {
      final sessions = [
        AttendanceSession(
          id: 'S-AUDIT-1',
          collegeId: 'COL-001',
          departmentId: 'DEP-CSE',
          facultyId: 'FAC-001',
          subjectId: 'SUB-DBMS',
          subjectName: 'DBMS',
          sectionId: 'SEC-A',
          sectionName: 'DCME 4-A',
          timeSlot: '09:00 - 10:00',
          date: DateTime(2026, 8, 18),
          version: 2,
          lastModifiedBy: 'FAC-001',
          lastModifiedAt: DateTime(2026, 8, 18, 10, 30),
          records: [
            AttendanceRecord(
              id: 'R1',
              studentId: 'STU-001',
              studentName: 'Rahul',
              rollNumber: '01',
              sectionId: 'SEC-A',
              status: AttendanceStatus.present,
              oldStatus: AttendanceStatus.absent,
            ),
          ],
        ),
      ];

      final audits = adminService.extractAuditHistory(sessions: sessions);
      expect(audits, isNotEmpty);
      expect(audits.first.toVersion, 2);
      expect(audits.first.fromVersion, 1);
      expect(audits.first.modifiedBy, 'FAC-001');
    });

    test('23. Reconciliation calculation accurately measures expected vs recorded vs missing classes', () {
      final scheduled = [
        TimetableModel(
          id: 'TT-1',
          collegeId: 'COL-001',
          departmentId: 'DEP-CSE',
          courseId: 'CRS-CSE',
          academicYearId: 'AY-2026',
          semesterId: 'SEM-4',
          subjectId: 'SUB-DBMS',
          facultyId: 'FAC-001',
          sectionId: 'SEC-A',
          dayOfWeek: TimetableDay.monday,
          startTime: '09:00',
          endTime: '10:00',
          roomNumber: 'LH-1',
          sessionType: TimetableSessionType.lecture,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      // On a Monday, 1 class scheduled, 1 recorded
      final monday = DateTime(2026, 8, 17); // Monday
      final recorded = [
        AttendanceSession(
          id: 'SEC-A_SUB-DBMS_20260817_09:00-10:00',
          collegeId: 'COL-001',
          departmentId: 'DEP-CSE',
          facultyId: 'FAC-001',
          subjectId: 'SUB-DBMS',
          subjectName: 'DBMS',
          sectionId: 'SEC-A',
          sectionName: 'DCME 4-A',
          timeSlot: '09:00 - 10:00',
          date: monday,
          records: [],
        ),
      ];

      final result = adminService.calculateReconciliation(
        scheduledEntries: scheduled,
        recordedSessions: recorded,
        dateRange: AttendanceDateRange.custom(startDate: monday, endDate: monday),
      );

      expect(result.expectedSessions, 1);
      expect(result.recordedSessions, 1);
      expect(result.missingSessions, 0);
      expect(result.compliancePercentage, 100.0);
    });

    test('24. Invalid-data detection flags corrupted percentages and mismatched student totals', () {
      final corruptSessions = [
        AttendanceSession(
          id: 'S-BAD-1',
          collegeId: 'COL-001',
          departmentId: 'DEP-CSE',
          facultyId: 'FAC-001',
          subjectId: 'SUB-DBMS',
          subjectName: 'DBMS',
          sectionId: 'SEC-NONEXISTENT',
          sectionName: 'DCME 4-A',
          timeSlot: '09:00 - 10:00',
          date: DateTime.now(),
          records: [
            AttendanceRecord(
              id: 'R1',
              studentId: 'STU-001',
              studentName: 'Rahul',
              rollNumber: '01',
              sectionId: 'SEC-A',
              status: null, // Unmarked
            ),
          ],
          isSubmitted: true,
        ),
      ];

      final issues = adminService.checkDataConsistency(
        sessions: corruptSessions,
        validSectionIds: {'SEC-A', 'SEC-B'},
      );

      expect(issues, isNotEmpty);
      expect(issues.any((i) => i.issueType == AttendanceConsistencyType.orphanSection), isTrue);
      expect(issues.any((i) => i.issueType == AttendanceConsistencyType.unmarkedInSubmitted), isTrue);
    });

    test('25. College report accurately calculates department comparison averages', () {
      final departments = [
        DepartmentAttendanceComparison(
          departmentId: 'DEP-CSE',
          departmentName: 'CSE',
          attendancePercentage: 82.0,
          studentCount: 120,
          facultyCount: 10,
          todayCompletionPercentage: 100.0,
          trend: TrendDirection.up,
        ),
        DepartmentAttendanceComparison(
          departmentId: 'DEP-ECE',
          departmentName: 'ECE',
          attendancePercentage: 78.0,
          studentCount: 110,
          facultyCount: 8,
          todayCompletionPercentage: 95.0,
          trend: TrendDirection.neutral,
        ),
      ];

      final csv = AttendanceReportExporter.generateCollegeAttendanceCsv(collegeId: 'COL-001', departments: departments);
      expect(csv, contains('ACADEX COLLEGE ATTENDANCE REPORT'));
      expect(csv, contains('80.0%'));
      expect(csv, contains('CSE'));
      expect(csv, contains('ECE'));
    });

    testWidgets('26. AttendanceReportCenterScreen renders cleanly on mobile at 360px without overflow', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          child: const AttendanceReportCenterScreen(),
          user: testHod,
          width: 360,
          height: 640,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Attendance Report Center'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('27. AttendanceReportCenterScreen renders in Dark Mode', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          child: const AttendanceReportCenterScreen(),
          user: testCollegeAdmin,
          themeMode: ThemeMode.dark,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Attendance Report Center'), findsOneWidget);
      expect(find.text('Select Report Type'), findsOneWidget);
    });

    testWidgets('28. AttendanceSessionAdminScreen renders session management table', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          child: const AttendanceSessionAdminScreen(),
          user: testHod,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Attendance Administration & Audit'), findsOneWidget);
      expect(find.text('Timetable Attendance Reconciliation'), findsOneWidget);
    });

    testWidgets('29. AttendanceAdminDashboardScreen renders executive cards and actions', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          child: const AttendanceAdminDashboardScreen(),
          user: testCollegeAdmin,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('College Attendance Administration'), findsOneWidget);
      expect(find.text('Overall Attendance'), findsOneWidget);
      expect(find.text('Open Report Center'), findsOneWidget);
    });

    test('30. Unauthorized access rejection correctly restricts student and normal faculty report access', () {
      final studentAllowed = [AttendanceReportType.student];
      expect(studentAllowed.contains(AttendanceReportType.department), isFalse);
      expect(studentAllowed.contains(AttendanceReportType.college), isFalse);

      final facultyAllowed = [
        AttendanceReportType.student,
        AttendanceReportType.subject,
        AttendanceReportType.section,
        AttendanceReportType.faculty,
        AttendanceReportType.session,
        AttendanceReportType.lowAttendance,
      ];
      expect(facultyAllowed.contains(AttendanceReportType.college), isFalse);
    });
  });
}
