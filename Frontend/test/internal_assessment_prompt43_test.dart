import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_management/features/assessments/domain/models/internal_assessment_models.dart';
import 'package:campus_management/features/assessments/presentation/providers/assessment_providers.dart';
import 'package:campus_management/features/assessments/presentation/screens/internal_marks_screen.dart';
import 'package:campus_management/features/assessments/presentation/screens/student_internal_marks_screen.dart';

class _FakeAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _FakeAuthNotifier(super.initial);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final testFacultyUser = UserModel(
    id: 'user_fac_1',
    collegeId: 'col_1',
    name: 'Prof. Ada Lovelace',
    email: 'ada@example.edu',
    role: AppRole.faculty,
    departmentId: 'dept_1',
  );

  final testStudentUser = UserModel(
    id: 'user_stu_1',
    collegeId: 'col_1',
    name: 'Grace Hopper',
    email: 'grace@example.edu',
    role: AppRole.student,
    departmentId: 'dept_1',
  );

  group('PROMPT 43 — Internal Assessment Flutter Tests', () {
    test('1. SubjectAssessmentSummaryModel parsing and calculations', () {
      final json = {
        'subjectId': 'sub_101',
        'semesterId': 'sem_5',
        'studentId': 'stu_1',
        'totalAssessments': 2,
        'publishedAssessments': 2,
        'totalMaxMarks': 100.0,
        'totalObtainedMarks': 85.5,
        'percentage': 85.5,
        'assessments': [
          {
            'assessmentId': 'a_1',
            'title': 'Internal Exam 1',
            'type': 'INTERNAL_EXAM',
            'maxMarks': 50.0,
            'obtainedMarks': 42.5,
            'status': 'ENTERED',
          },
          {
            'assessmentId': 'a_2',
            'title': 'Internal Exam 2',
            'type': 'INTERNAL_EXAM',
            'maxMarks': 50.0,
            'obtainedMarks': 43.0,
            'status': 'ENTERED',
          },
        ],
      };

      final summary = SubjectAssessmentSummaryModel.fromJson(json);
      expect(summary.subjectId, 'sub_101');
      expect(summary.totalAssessments, 2);
      expect(summary.totalObtainedMarks, 85.5);
      expect(summary.percentage, 85.5);
      expect(summary.assessments.length, 2);
      expect(summary.assessments[0].obtainedMarks, 42.5);
      expect(summary.assessments[0].status, StudentMarkStatus.entered);
    });

    test('2. StudentMarkStatus and InternalAssessmentStatus enum parsing', () {
      expect(StudentMarkStatus.fromValue('ABSENT'), StudentMarkStatus.absent);
      expect(StudentMarkStatus.fromValue('EXCUSED'), StudentMarkStatus.excused);
      expect(StudentMarkStatus.fromValue('ENTERED'), StudentMarkStatus.entered);
      expect(StudentMarkStatus.fromValue('NOT_ENTERED'), StudentMarkStatus.notEntered);

      expect(InternalAssessmentStatus.fromValue('OPEN'), InternalAssessmentStatus.open);
      expect(InternalAssessmentStatus.fromValue('CLOSED'), InternalAssessmentStatus.closed);
      expect(InternalAssessmentStatus.fromValue('ARCHIVED'), InternalAssessmentStatus.archived);
      expect(InternalAssessmentStatus.fromValue('PUBLISHED'), InternalAssessmentStatus.published);
      expect(InternalAssessmentStatus.fromValue('DRAFT'), InternalAssessmentStatus.draft);
    });

    testWidgets('3. Renders Faculty Mark Entry at 360px without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockContext = AssessmentContextModel(
        subject: {'name': 'Advanced Algorithms', 'code': 'CS501'},
        section: {'name': 'Section A'},
        components: const [
          AssessmentComponentModel(key: 'test1', name: 'Internal Test 1', maxMarks: 50.0),
        ],
        assessment: const InternalAssessmentModel(
          id: 'assess_01',
          collegeId: 'col_1',
          departmentId: 'dept_1',
          courseId: 'course_1',
          semesterId: 'sem_1',
          sectionId: 'sec_1',
          subjectId: 'sub_1',
          title: 'Algorithms Midterm',
          status: InternalAssessmentStatus.open,
          entries: [
            StudentAssessmentEntryModel(
              studentId: 'stu_1',
              studentName: 'Alice Turing',
              rollNumber: 'CS01',
              componentMarks: {'test1': 37.5},
              totalMarks: 37.5,
              status: StudentMarkStatus.entered,
            ),
            StudentAssessmentEntryModel(
              studentId: 'stu_2',
              studentName: 'Bob Hopper',
              rollNumber: 'CS02',
              componentMarks: {'test1': null},
              totalMarks: 0.0,
              status: StudentMarkStatus.absent,
            ),
          ],
        ),
      );

      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(
            (ref) => _FakeAuthNotifier(AuthAuthenticated(user: testFacultyUser, token: 'jwt')),
          ),
          assessmentContextProvider(
            (sectionId: 'sec_1', subjectId: 'sub_1', academicYearId: null),
          ).overrideWith((ref) async => mockContext),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: InternalMarksScreen(
              sectionId: 'sec_1',
              subjectId: 'sub_1',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify header and subject render
      expect(find.text('Advanced Algorithms'), findsWidgets);
      expect(find.text('Open for Entry'), findsOneWidget);

      // Verify students render
      expect(find.text('Alice Turing'), findsOneWidget);
      expect(find.text('Bob Hopper'), findsOneWidget);

      // Verify no RenderFlex overflow
      final err = tester.takeException();
      expect(err, isNull);
    });

    testWidgets('4. Student Published Marks Screen renders scores & absent state', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockItems = [
        const StudentPublishedMarksItem(
          id: 'item_1',
          subject: {'name': 'Distributed Systems', 'code': 'CS601'},
          section: {'name': 'Section A'},
          components: [
            AssessmentComponentModel(key: 'exam', name: 'Internal Exam', maxMarks: 50.0),
          ],
          marks: {'exam': 42.5},
          totalMarks: 42.5,
          status: StudentMarkStatus.entered,
        ),
        const StudentPublishedMarksItem(
          id: 'item_2',
          subject: {'name': 'Machine Learning', 'code': 'CS602'},
          section: {'name': 'Section A'},
          components: [
            AssessmentComponentModel(key: 'exam', name: 'Internal Exam', maxMarks: 50.0),
          ],
          marks: {'exam': null},
          totalMarks: 0.0,
          status: StudentMarkStatus.absent,
          remarks: 'Medical Absence Approved',
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(
            (ref) => _FakeAuthNotifier(AuthAuthenticated(user: testStudentUser, token: 'jwt')),
          ),
          studentMarksProvider(null).overrideWith((ref) async => mockItems),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: StudentInternalMarksScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Distributed Systems'), findsOneWidget);
      expect(find.text('Machine Learning'), findsOneWidget);
      expect(find.textContaining('Medical Absence Approved'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
