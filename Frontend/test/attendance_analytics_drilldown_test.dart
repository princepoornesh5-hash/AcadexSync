import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_management/app/theme/app_theme.dart';
import 'package:campus_management/features/attendance/domain/models/attendance_analytics_models.dart';
import 'package:campus_management/features/attendance/domain/services/attendance_report_exporter.dart';
import 'package:campus_management/features/attendance/presentation/providers/attendance_analytics_providers.dart';
import 'package:campus_management/features/attendance/presentation/widgets/analytics/low_attendance_action_panel.dart';
import 'package:campus_management/features/attendance/presentation/widgets/analytics/subject_attendance_chart.dart';
import 'package:campus_management/features/attendance/presentation/widgets/analytics/section_attendance_chart.dart';
import 'package:campus_management/features/attendance/presentation/screens/student_attendance_detail_screen.dart';
import 'package:campus_management/features/attendance/presentation/screens/subject_attendance_detail_screen.dart';
import 'package:campus_management/features/attendance/presentation/screens/section_attendance_detail_screen.dart';

Widget _buildTestApp({
  required Widget child,
  List<Override> overrides = const [],
  ThemeMode themeMode = ThemeMode.light,
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ACADEX Phase 8C: Domain Calculations, Risk Classification & Recovery Projections', () {
    test('1. Institutional Risk Classification evaluates correctly across boundaries', () {
      expect(AttendanceAnalyticsConstants.evaluateRiskLevel(100.0), equals(AttendanceRiskLevel.healthy));
      expect(AttendanceAnalyticsConstants.evaluateRiskLevel(85.0), equals(AttendanceRiskLevel.healthy));
      expect(AttendanceAnalyticsConstants.evaluateRiskLevel(84.99), equals(AttendanceRiskLevel.watch));
      expect(AttendanceAnalyticsConstants.evaluateRiskLevel(75.0), equals(AttendanceRiskLevel.watch));
      expect(AttendanceAnalyticsConstants.evaluateRiskLevel(74.99), equals(AttendanceRiskLevel.critical));
      expect(AttendanceAnalyticsConstants.evaluateRiskLevel(0.0), equals(AttendanceRiskLevel.critical));
    });

    test('2. Attendance Recovery Projection calculation is mathematically exact', () {
      // Current: 18 present out of 25 total = 72%
      // To reach 75%: (18 + P) / (25 + P) >= 0.75 -> 18 + P >= 18.75 + 0.75 P -> 0.25 P >= 0.75 -> P >= 3
      final needed = AttendanceAnalyticsConstants.calculateSessionsNeededToReachThreshold(
        presentCount: 18,
        totalSessions: 25,
        targetThreshold: 75.0,
      );
      expect(needed, equals(3));

      // Verifying mathematically:
      // (18 + 3) / (25 + 3) = 21 / 28 = 75.0%
      expect((18 + needed) / (25 + needed) * 100, greaterThanOrEqualTo(75.0));

      // If already at or above 75%, 0 needed
      expect(
        AttendanceAnalyticsConstants.calculateSessionsNeededToReachThreshold(
          presentCount: 20,
          totalSessions: 25,
        ),
        equals(0),
      );

      // Total sessions 0 -> 0
      expect(
        AttendanceAnalyticsConstants.calculateSessionsNeededToReachThreshold(
          presentCount: 0,
          totalSessions: 0,
        ),
        equals(0),
      );
    });

    test('3. Domain Model getters expose risk level and recovery calculations', () {
      final studentLow = StudentAttendanceAnalytics.compute(
        studentId: 'stud-1',
        studentName: 'Aarav Sharma',
        rollNumber: '21CS01',
        sectionId: 'CS-4A',
        totalSessions: 20,
        presentCount: 14,
        absentCount: 6,
        lateCount: 0,
        excusedCount: 0,
      );

      expect(studentLow.attendancePercentage, equals(70.0));
      expect(studentLow.isLowAttendance, isTrue);
      expect(studentLow.riskLevel, equals(AttendanceRiskLevel.critical));
      expect(studentLow.recoverySessionsNeeded, equals(4)); // (14+4)/(20+4) = 18/24 = 75%

      final studentGood = StudentAttendanceAnalytics.compute(
        studentId: 'stud-2',
        studentName: 'Priya Patel',
        rollNumber: '21CS02',
        sectionId: 'CS-4A',
        totalSessions: 20,
        presentCount: 18,
        absentCount: 2,
        lateCount: 0,
        excusedCount: 0,
      );

      expect(studentGood.attendancePercentage, equals(90.0));
      expect(studentGood.isLowAttendance, isFalse);
      expect(studentGood.riskLevel, equals(AttendanceRiskLevel.healthy));
      expect(studentGood.recoverySessionsNeeded, equals(0));
    });
  });

  group('ACADEX Phase 8C: CSV Report Exporter Service Tests', () {
    test('4. Generates RFC 4180 compliant CSV for single student', () {
      final student = StudentAttendanceAnalytics.compute(
        studentId: 'stud-101',
        studentName: 'Rohan Mehta',
        rollNumber: '21CS101',
        sectionId: 'CS-4A',
        totalSessions: 30,
        presentCount: 21,
        absentCount: 9,
        lateCount: 0,
        excusedCount: 0,
      );

      final subjects = [
        SubjectAttendanceAnalytics.compute(
          subjectId: 'sub-dbms',
          subjectName: 'Database Management Systems, Advanced',
          totalSessions: 15,
          totalStudentRecords: 15,
          presentCount: 12,
          absentCount: 3,
          lateCount: 0,
          excusedCount: 0,
        ),
      ];

      final csv = AttendanceReportExporter.generateStudentAttendanceCsv(
        student: student,
        subjects: subjects,
        dateRange: AttendanceDateRange.thisMonth(),
      );

      expect(csv, contains('ACADEX STUDENT ATTENDANCE REPORT'));
      expect(csv, contains('Rohan Mehta'));
      expect(csv, contains('21CS101'));
      expect(csv, contains('70.0%'));
      expect(csv, contains('CRITICAL'));
      expect(csv, contains('"Database Management Systems, Advanced"')); // properly escaped
      expect(csv, contains('Sessions Needed for 75%'));
    });

    test('5. Generates Section CSV report with leaderboard ranking and escaping', () {
      final s1 = StudentAttendanceAnalytics.compute(
        studentId: 's1',
        studentName: 'Alice',
        rollNumber: 'R1',
        totalSessions: 10,
        presentCount: 9,
        absentCount: 1,
        lateCount: 0,
        excusedCount: 0,
      );
      final s2 = StudentAttendanceAnalytics.compute(
        studentId: 's2',
        studentName: 'Bob',
        rollNumber: 'R2',
        totalSessions: 10,
        presentCount: 6,
        absentCount: 4,
        lateCount: 0,
        excusedCount: 0,
      );

      final section = SectionAttendanceAnalytics.compute(
        sectionId: 'sec-4a',
        sectionName: 'DCME 4-A',
        totalSessions: 10,
        totalStudents: 2,
        presentCount: 15,
        absentCount: 5,
        lateCount: 0,
        excusedCount: 0,
        studentAnalytics: [s1, s2],
      );

      final csv = AttendanceReportExporter.generateSectionAttendanceCsv(section: section);

      expect(csv, contains('ACADEX SECTION ATTENDANCE REPORT'));
      expect(csv, contains('DCME 4-A'));
      expect(csv, contains('Rank,Student Name,Roll Number,Attendance %'));
      // Alice (90%) must be ranked #1, Bob (60%) ranked #2
      final alicePos = csv.indexOf('Alice');
      final bobPos = csv.indexOf('Bob');
      expect(alicePos, lessThan(bobPos));
    });

    test('6. Generates Low Attendance Shortage Report with priority sorting', () {
      final low1 = StudentAttendanceAnalytics.compute(
        studentId: 's1',
        studentName: 'Student Low 60',
        rollNumber: 'R01',
        sectionId: 'SEC-A',
        totalSessions: 10,
        presentCount: 6,
        absentCount: 4,
        lateCount: 0,
        excusedCount: 0,
      );
      final low2 = StudentAttendanceAnalytics.compute(
        studentId: 's2',
        studentName: 'Student Critical 40',
        rollNumber: 'R02',
        sectionId: 'SEC-A',
        totalSessions: 10,
        presentCount: 4,
        absentCount: 6,
        lateCount: 0,
        excusedCount: 0,
      );

      final csv = AttendanceReportExporter.generateLowAttendanceReportCsv(
        lowAttendanceStudents: [low1, low2],
        scopeTitle: 'Dept of Computer Engg',
      );

      expect(csv, contains('ACADEX LOW ATTENDANCE INTERVENTION REPORT'));
      expect(csv, contains('Dept of Computer Engg'));
      expect(csv, contains('Threshold,75.0%'));
      // The 40% student should be listed first (highest priority)
      final critPos = csv.indexOf('Student Critical 40');
      final lowPos = csv.indexOf('Student Low 60');
      expect(critPos, lessThan(lowPos));
    });

    test('7. Handles empty datasets cleanly without crashing', () {
      final emptyCsv = AttendanceReportExporter.generateLowAttendanceReportCsv(
        lowAttendanceStudents: [],
      );
      expect(emptyCsv, contains('No students in critical shortage'));

      final emptySubjectCsv = AttendanceReportExporter.generateSubjectAttendanceCsv(
        subject: SubjectAttendanceAnalytics.compute(subjectId: 'SUB-EMPTY'),
      );
      expect(emptySubjectCsv, contains('ACADEX SUBJECT ATTENDANCE REPORT'));
    });
  });

  group('ACADEX Phase 8C: Interactive Widgets & Drill-Down UI Tests', () {
    testWidgets('8. LowAttendanceActionPanel displays critical student metrics and triggers drill-down callback', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final student = StudentAttendanceAnalytics.compute(
        studentId: 'stud-test-1',
        studentName: 'Vikram Singh',
        rollNumber: '21CS099',
        sectionId: 'DCME-4A',
        totalSessions: 20,
        presentCount: 13,
        absentCount: 7,
        lateCount: 0,
        excusedCount: 0,
      );

      StudentAttendanceAnalytics? selectedStudent;

      await tester.pumpWidget(
        _buildTestApp(
          child: Scaffold(
            body: SingleChildScrollView(
              child: LowAttendanceActionPanel(
                students: [student],
                onStudentSelected: (s) => selectedStudent = s,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Low Attendance Action Center'), findsOneWidget);
      expect(find.text('Vikram Singh'), findsOneWidget);
      expect(find.text('(21CS099)'), findsOneWidget);
      expect(find.text('65.0%'), findsOneWidget);
      expect(find.text('Needs 8 consecutive classes for 75%'), findsOneWidget);

      // Tap student row
      await tester.tap(find.text('Vikram Singh'));
      await tester.pumpAndSettle();

      expect(selectedStudent, isNotNull);
      expect(selectedStudent!.studentId, equals('stud-test-1'));
    });

    testWidgets('9. LowAttendanceActionPanel shows compliant state when list is empty', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildTestApp(
          child: const Scaffold(
            body: SingleChildScrollView(
              child: LowAttendanceActionPanel(students: []),
            ),
          ),
        ),
      );

      expect(find.text('All Students Compliant'), findsOneWidget);
      expect(find.text('No students are currently in critical shortage below the 75% requirement.'), findsOneWidget);
    });

    testWidgets('10. SubjectAttendanceChart triggers onSubjectSelected drill-down callback', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final sub = SubjectAttendanceAnalytics.compute(
        subjectId: 'CS-301',
        subjectName: 'Computer Networks',
        totalSessions: 14,
        presentCount: 12,
        absentCount: 2,
        lateCount: 0,
        excusedCount: 0,
      );

      SubjectAttendanceAnalytics? clickedSub;

      await tester.pumpWidget(
        _buildTestApp(
          child: Scaffold(
            body: SingleChildScrollView(
              child: SubjectAttendanceChart(
                subjects: [sub],
                onSubjectSelected: (s) => clickedSub = s,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Computer Networks'), findsOneWidget);
      expect(find.text('85.7%'), findsOneWidget);

      await tester.tap(find.text('Computer Networks'));
      await tester.pumpAndSettle();

      expect(clickedSub, isNotNull);
      expect(clickedSub!.subjectId, equals('CS-301'));
    });

    testWidgets('11. SectionAttendanceChart triggers onSectionSelected drill-down callback', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final sec = SectionAttendanceAnalytics.compute(
        sectionId: 'SEC-4A',
        sectionName: 'DCME 4-A',
        totalStudents: 45,
        totalSessions: 22,
        presentCount: 40,
        absentCount: 5,
        lateCount: 0,
        excusedCount: 0,
      );

      SectionAttendanceAnalytics? clickedSec;

      await tester.pumpWidget(
        _buildTestApp(
          child: Scaffold(
            body: SingleChildScrollView(
              child: SectionAttendanceChart(
                sections: [sec],
                onSectionSelected: (s) => clickedSec = s,
              ),
            ),
          ),
        ),
      );

      expect(find.text('DCME 4-A'), findsOneWidget);
      expect(find.text('45 students'), findsOneWidget);

      await tester.tap(find.text('DCME 4-A'));
      await tester.pumpAndSettle();

      expect(clickedSec, isNotNull);
      expect(clickedSec!.sectionId, equals('SEC-4A'));
    });

    testWidgets('12. StudentAttendanceDetailScreen renders full student profile & recovery projection', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final student = StudentAttendanceAnalytics.compute(
        studentId: 's-detail-1',
        studentName: 'Aditya Varma',
        rollNumber: '21CS501',
        sectionId: 'DCME-4B',
        totalSessions: 25,
        presentCount: 17,
        absentCount: 8,
        lateCount: 0,
        excusedCount: 0,
      );

      await tester.pumpWidget(
        _buildTestApp(
          overrides: [
            studentAttendanceAnalyticsProvider.overrideWith((ref, query) async => student),
          ],
          child: const StudentAttendanceDetailScreen(studentId: 's-detail-1'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Student Attendance Profile'), findsOneWidget);
      expect(find.text('Aditya Varma'), findsOneWidget);
      expect(find.text('21CS501 • Section: DCME-4B'), findsOneWidget);
      expect(find.text('68.0'), findsWidgets);
      expect(find.text('Attendance Recovery Projection'), findsOneWidget);
      expect(find.textContaining('Student requires 7 consecutive attended classes'), findsOneWidget);
      expect(find.text('Export CSV'), findsOneWidget);
    });

    testWidgets('13. SubjectAttendanceDetailScreen renders subject overview and charts', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final subject = SubjectAttendanceAnalytics.compute(
        subjectId: 'SUB-DBMS',
        subjectName: 'Database Management Systems',
        totalSessions: 30,
        totalStudentRecords: 30,
        presentCount: 26,
        absentCount: 4,
        lateCount: 0,
        excusedCount: 0,
      );

      await tester.pumpWidget(
        _buildTestApp(
          overrides: [
            subjectAttendanceAnalyticsProvider.overrideWith((ref, query) async => subject),
          ],
          child: const SubjectAttendanceDetailScreen(subjectId: 'SUB-DBMS'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Subject Attendance Analytics'), findsOneWidget);
      expect(find.text('Database Management Systems'), findsOneWidget);
      expect(find.text('Code: SUB-DBMS '), findsOneWidget);
      expect(find.text('86.7'), findsWidgets);
      expect(find.text('Export CSV'), findsOneWidget);
    });

    testWidgets('14. SectionAttendanceDetailScreen renders leaderboard, search filter, and sorting', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final s1 = StudentAttendanceAnalytics.compute(
        studentId: 's1',
        studentName: 'Zack Walker',
        rollNumber: 'ROLL-10',
        totalSessions: 10,
        presentCount: 9,
        absentCount: 1,
        lateCount: 0,
        excusedCount: 0,
      );
      final s2 = StudentAttendanceAnalytics.compute(
        studentId: 's2',
        studentName: 'Aaron Bell',
        rollNumber: 'ROLL-01',
        totalSessions: 10,
        presentCount: 6,
        absentCount: 4,
        lateCount: 0,
        excusedCount: 0,
      );

      final section = SectionAttendanceAnalytics.compute(
        sectionId: 'SEC-4A',
        sectionName: 'DCME 4-A',
        totalStudents: 2,
        totalSessions: 10,
        presentCount: 15,
        absentCount: 5,
        lateCount: 0,
        excusedCount: 0,
        studentAnalytics: [s1, s2],
      );

      await tester.pumpWidget(
        _buildTestApp(
          overrides: [
            sectionAttendanceAnalyticsProvider.overrideWith((ref, query) async => section),
          ],
          child: const SectionAttendanceDetailScreen(sectionId: 'SEC-4A'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Section Attendance Analytics'), findsOneWidget);
      expect(find.text('DCME 4-A'), findsOneWidget);
      expect(find.text('Zack Walker'), findsOneWidget);
      expect(find.text('Aaron Bell'), findsWidgets);

      // Test Search
      await tester.enterText(find.byType(TextField), 'Aaron');
      await tester.pumpAndSettle();

      expect(find.text('Aaron Bell'), findsWidgets);
      expect(find.text('Zack Walker'), findsNothing);

      // Clear search
      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();
      expect(find.text('Zack Walker'), findsOneWidget);
      expect(find.text('Aaron Bell'), findsWidgets);
    });

    testWidgets('15. SectionAttendanceDetailScreen renders on mobile viewport without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final section = SectionAttendanceAnalytics.compute(
        sectionId: 'SEC-MOB',
        sectionName: 'Mobile Section',
        totalStudents: 1,
        totalSessions: 10,
        presentCount: 8,
        absentCount: 2,
        lateCount: 0,
        excusedCount: 0,
        studentAnalytics: [
          StudentAttendanceAnalytics.compute(
            studentId: 'sm1',
            studentName: 'Mobile Student',
            rollNumber: 'M01',
            totalSessions: 10,
            presentCount: 8,
            absentCount: 2,
            lateCount: 0,
            excusedCount: 0,
          ),
        ],
      );

      await tester.pumpWidget(
        _buildTestApp(
          overrides: [
            sectionAttendanceAnalyticsProvider.overrideWith((ref, query) async => section),
          ],
          child: const SectionAttendanceDetailScreen(sectionId: 'SEC-MOB'),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Section Attendance Analytics'), findsOneWidget);
    });

    testWidgets('16. Detail screens render cleanly in Dark Mode', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final subject = SubjectAttendanceAnalytics.compute(
        subjectId: 'SUB-DARK',
        subjectName: 'Dark Mode Subject',
        totalSessions: 10,
        presentCount: 9,
        absentCount: 1,
        lateCount: 0,
        excusedCount: 0,
      );

      await tester.pumpWidget(
        _buildTestApp(
          themeMode: ThemeMode.dark,
          overrides: [
            subjectAttendanceAnalyticsProvider.overrideWith((ref, query) async => subject),
          ],
          child: const SubjectAttendanceDetailScreen(subjectId: 'SUB-DARK'),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Dark Mode Subject'), findsOneWidget);
    });

    testWidgets('17. Error states render with retry CTA', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildTestApp(
          overrides: [
            studentAttendanceAnalyticsProvider.overrideWith((ref, query) => Future.error(Exception('Network failure connecting to analytics service'))),
          ],
          child: const StudentAttendanceDetailScreen(studentId: 's-err'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Failed to load student analytics'), findsOneWidget);
      expect(find.text('Exception: Network failure connecting to analytics service'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}
