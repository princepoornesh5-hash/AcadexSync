import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:campus_management/features/academic_results/domain/models/academic_result_models.dart';
import 'package:campus_management/features/academic_results/presentation/providers/academic_result_providers.dart';
import 'package:campus_management/features/academic_results/presentation/screens/student_official_result_screen.dart';
import 'package:campus_management/features/academic_results/presentation/screens/admin_results_dashboard_screen.dart';

void main() {
  group('PROMPT 44 — Academic Finalization & Official Results Tests', () {
    test('1. Model parsing: SubjectResultModel, ResultSummaryModel, PublicationSnapshotModel', () {
      final json = {
        'subjectId': 'sub_algo',
        'subjectCode': 'CS401',
        'subjectName': 'Advanced Algorithms',
        'credits': 4.0,
        'internalMarks': 45.0,
        'attendancePercentage': 88.5,
        'attendancePassed': true,
        'practicalCompleted': true,
        'totalMarks': 88.0,
        'percentage': 88.0,
        'grade': 'A+',
        'gradePoint': 10.0,
        'status': 'PASS',
        'remarks': 'First class distinction',
      };

      final sub = SubjectResultModel.fromJson(json);
      expect(sub.subjectCode, 'CS401');
      expect(sub.credits, 4.0);
      expect(sub.grade, 'A+');
      expect(sub.gradePoint, 10.0);
      expect(sub.status, SubjectResultStatus.pass);
      expect(sub.attendancePassed, true);
      expect(sub.practicalCompleted, true);

      final summaryJson = {
        'totalCredits': 24.0,
        'earnedCredits': 24.0,
        'totalMarks': 480.0,
        'maxMarks': 600.0,
        'percentage': 80.0,
        'gpa': 9.25,
        'cgpa': 9.10,
        'overallStatus': 'PASS',
        'failedSubjectCount': 0,
      };

      final summary = ResultSummaryModel.fromJson(summaryJson);
      expect(summary.totalCredits, 24.0);
      expect(summary.earnedCredits, 24.0);
      expect(summary.gpa, 9.25);
      expect(summary.cgpa, 9.10);
      expect(summary.overallStatus, OverallResultStatus.pass);
      expect(summary.failedSubjectCount, 0);

      final snapshotJson = {
        'version': 1,
        'publishedAt': '2026-06-15T10:00:00.000Z',
        'publishedBy': 'admin_officer',
        'summary': summaryJson,
        'subjectResults': [json],
      };

      final snapshot = PublicationSnapshotModel.fromJson(snapshotJson);
      expect(snapshot.version, 1);
      expect(snapshot.publishedBy, 'admin_officer');
      expect(snapshot.summary.gpa, 9.25);
      expect(snapshot.subjectResults.length, 1);
    });

    test('2. Enum mapping for ResultLifecycleStatus and SubjectResultStatus', () {
      expect(ResultLifecycleStatus.fromValue('DRAFT'), ResultLifecycleStatus.draft);
      expect(ResultLifecycleStatus.fromValue('CALCULATED'), ResultLifecycleStatus.calculated);
      expect(ResultLifecycleStatus.fromValue('UNDER_REVIEW'), ResultLifecycleStatus.underReview);
      expect(ResultLifecycleStatus.fromValue('FINALIZED'), ResultLifecycleStatus.finalized);
      expect(ResultLifecycleStatus.fromValue('PUBLISHED'), ResultLifecycleStatus.published);
      expect(ResultLifecycleStatus.fromValue('REOPENED'), ResultLifecycleStatus.reopened);
      expect(ResultLifecycleStatus.fromValue('ARCHIVED'), ResultLifecycleStatus.archived);

      expect(SubjectResultStatus.fromValue('PASS'), SubjectResultStatus.pass);
      expect(SubjectResultStatus.fromValue('FAIL'), SubjectResultStatus.fail);
      expect(SubjectResultStatus.fromValue('INCOMPLETE'), SubjectResultStatus.incomplete);
      expect(SubjectResultStatus.fromValue('WITHHELD'), SubjectResultStatus.withheld);
      expect(SubjectResultStatus.fromValue('EXEMPTED'), SubjectResultStatus.exempted);
    });

    testWidgets('3. Renders Student Official Result Screen when unpublished (Empty State at 360px)', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            studentOfficialResultProvider('sem_1').overrideWith(
              (ref) => Future.value(null),
            ),
          ],
          child: const MaterialApp(
            home: StudentOfficialResultScreen(semesterId: 'sem_1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Official Academic Result'), findsOneWidget);
      expect(find.text('Result Not Officially Published Yet'), findsOneWidget);
    });

    testWidgets('4. Renders Student Official Result Screen with published snapshot at 360px without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final testResult = StudentOfficialResultModel(
        semesterId: 'sem_4',
        academicYearId: 'ay_2026',
        courseId: 'cse_btech',
        courseName: 'B.Tech Computer Science',
        semesterName: 'Semester 4',
        academicYearName: '2026-2027',
        version: 1,
        publishedAt: DateTime(2026, 6, 20),
        summary: const ResultSummaryModel(
          totalCredits: 22.0,
          earnedCredits: 22.0,
          totalMarks: 440.0,
          maxMarks: 500.0,
          percentage: 88.0,
          gpa: 8.90,
          cgpa: 8.75,
          overallStatus: OverallResultStatus.pass,
          failedSubjectCount: 0,
        ),
        subjectResults: const [
          SubjectResultModel(
            subjectId: 'sub_algo',
            subjectCode: 'CS401',
            subjectName: 'Design & Analysis of Algorithms',
            credits: 4.0,
            internalMarks: 45.0,
            attendancePercentage: 92.0,
            attendancePassed: true,
            practicalCompleted: true,
            totalMarks: 91.0,
            percentage: 91.0,
            grade: 'A+',
            gradePoint: 10.0,
            status: SubjectResultStatus.pass,
            remarks: null,
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            studentOfficialResultProvider(null).overrideWith(
              (ref) => Future.value(testResult),
            ),
          ],
          child: const MaterialApp(
            home: StudentOfficialResultScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Official Result — Version 1'), findsOneWidget);
      expect(find.text('B.Tech Computer Science • Semester 4'), findsOneWidget);
      expect(find.text('88.0%'), findsOneWidget);
      expect(find.text('22 / 22'), findsOneWidget);
      expect(find.text('8.90'), findsOneWidget);
      expect(find.text('8.75'), findsOneWidget);
      expect(find.text('Design & Analysis of Algorithms'), findsOneWidget);
      expect(find.text('CS401'), findsOneWidget);
      expect(find.text('Pass'), findsWidgets);
    });

    testWidgets('5. Renders Admin Results Dashboard Screen with action buttons at 390px', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final sampleResult = AcademicResultModel(
        id: 'res_123',
        collegeId: 'col_1',
        studentId: 'stu_1',
        courseId: 'crs_1',
        academicYearId: 'ay_1',
        semesterId: 'sem_1',
        status: ResultLifecycleStatus.calculated,
        calculationVersion: 1,
        studentInfo: const {
          'name': 'Alan Turing',
          'rollNumber': 'CS2026-001',
        },
        validationWarnings: const [
          'Attendance requirement barely met',
        ],
        summary: const ResultSummaryModel(
          totalCredits: 20.0,
          earnedCredits: 20.0,
          totalMarks: 400.0,
          maxMarks: 500.0,
          percentage: 80.0,
          gpa: 8.5,
          overallStatus: OverallResultStatus.pass,
        ),
        subjectResults: const [
          SubjectResultModel(
            subjectId: 'sub_1',
            subjectCode: 'CS101',
            subjectName: 'Computer Systems',
            credits: 4.0,
            internalMarks: 40.0,
            totalMarks: 80.0,
            percentage: 80.0,
            grade: 'A',
            gradePoint: 8.0,
            status: SubjectResultStatus.pass,
            remarks: null,
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            adminResultsQueryProvider.overrideWith(
              (ref) => Future.value(
                (
                  results: [sampleResult],
                  total: 1,
                  page: 1,
                  pages: 1,
                ),
              ),
            ),
          ],
          child: const MaterialApp(
            home: AdminResultsDashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Academic Finalization'), findsOneWidget);
      expect(find.text('Alan Turing'), findsOneWidget);
      expect(find.text('Roll: CS2026-001'), findsOneWidget);
      expect(find.text('Calculated'), findsWidgets);
      expect(find.text('Review'), findsOneWidget);
      expect(find.text('Finalize'), findsOneWidget);
      expect(find.text('View Breakdown'), findsOneWidget);
      expect(find.text('1 validation warning(s)'), findsOneWidget);
    });
  });
}
