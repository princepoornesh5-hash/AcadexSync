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
  group('Internal Assessment Models & Serialization', () {
    test('Correctly parses AssessmentContextModel and components from JSON', () {
      final json = {
        'assessment': {
          'id': 'assess_123',
          'collegeId': 'col_1',
          'departmentId': 'dept_1',
          'courseId': 'course_1',
          'semesterId': 'sem_1',
          'sectionId': 'sec_456',
          'subjectId': 'sub_789',
          'title': 'Internal Assessment - Data Structures',
          'status': 'DRAFT',
          'components': [
            {
              'key': 'test1',
              'name': 'Internal Test 1',
              'maxMarks': 30.0,
              'weightage': 15.0,
              'isStudentVisible': true,
            },
            {
              'key': 'assignment',
              'name': 'Assignment',
              'maxMarks': 20.0,
              'weightage': 10.0,
              'isStudentVisible': true,
            }
          ],
          'entries': [
            {
              'studentId': 'stud_1',
              'studentName': 'Alice Johnson',
              'rollNumber': 'CS001',
              'admissionNumber': 'ADM001',
              'componentMarks': {'test1': 28.0, 'assignment': 18.0},
              'totalMarks': 46.0,
            },
            {
              'studentId': 'stud_2',
              'studentName': 'Bob Smith',
              'rollNumber': 'CS002',
              'admissionNumber': 'ADM002',
              'componentMarks': {'test1': 22.0, 'assignment': 15.0},
              'totalMarks': 37.0,
            }
          ],
        },
        'subject': {
          '_id': 'sub_789',
          'name': 'Data Structures',
          'code': 'CS401',
        },
        'section': {
          '_id': 'sec_456',
          'name': 'Section A',
        },
        'components': [
          {
            'key': 'test1',
            'name': 'Internal Test 1',
            'maxMarks': 30.0,
            'weightage': 15.0,
            'isStudentVisible': true,
          },
          {
            'key': 'assignment',
            'name': 'Assignment',
            'maxMarks': 20.0,
            'weightage': 10.0,
            'isStudentVisible': true,
          }
        ],
        'isLocked': false,
      };

      final context = AssessmentContextModel.fromJson(json);

      expect(context.assessment?.id, 'assess_123');
      expect(context.subject['name'], 'Data Structures');
      expect(context.section['name'], 'Section A');
      expect(context.components.length, 2);
      expect(context.assessment?.entries.length, 2);
      expect(context.assessment?.entries.first.studentName, 'Alice Johnson');
      expect(context.assessment?.entries.first.componentMarks['test1'], 28.0);
      expect(context.assessment?.status, InternalAssessmentStatus.draft);
      expect(context.isLocked, false);
    });

    test('Correctly parses StudentPublishedMarksItem from JSON', () {
      final json = {
        'id': 'pub_123',
        'subject': {
          'id': 'sub_789',
          'name': 'Operating Systems',
          'code': 'CS501',
        },
        'section': {
          'id': 'sec_456',
          'name': 'Section B',
        },
        'semester': {
          'id': 'sem_5',
          'name': 'Semester 5',
        },
        'publishedAt': '2026-09-28T10:00:00.000Z',
        'components': [
          {'key': 'test1', 'name': 'Internal Test 1', 'maxMarks': 30.0, 'weightage': 15.0, 'isStudentVisible': true},
          {'key': 'assignment', 'name': 'Assignment', 'maxMarks': 20.0, 'weightage': 10.0, 'isStudentVisible': true},
        ],
        'marks': {'test1': 27.0, 'assignment': 18.0},
        'totalMarks': 45.0,
        'remarks': 'Good performance',
      };

      final item = StudentPublishedMarksItem.fromJson(json);

      expect(item.id, 'pub_123');
      expect(item.subject['name'], 'Operating Systems');
      expect(item.section?['name'], 'Section B');
      expect(item.totalMarks, 45.0);
      expect(item.marks['test1'], 27.0);
      expect(item.remarks, 'Good performance');
    });
  });

  group('InternalMarksScreen Widget Tests', () {
    final facultyUser = UserModel(
      id: 'fac_user_1',
      name: 'Dr. Linus',
      email: 'linus@acadex.edu',
      role: AppRole.faculty,
      collegeId: 'col_1',
      departmentId: 'dept_1',
    );

    testWidgets('Renders draft assessment with context info, student rows, and action buttons', (tester) async {
      final mockContext = AssessmentContextModel(
        assessment: const InternalAssessmentModel(
          id: 'assess_test_1',
          collegeId: 'col_1',
          departmentId: 'dept_1',
          courseId: 'course_1',
          semesterId: 'sem_1',
          sectionId: 'sec_test_1',
          subjectId: 'sub_test_1',
          title: 'Internal Assessment',
          status: InternalAssessmentStatus.draft,
          components: [
            AssessmentComponentModel(
              key: 'test1',
              name: 'IA Test 1',
              maxMarks: 25.0,
              weightage: 15.0,
            ),
          ],
          entries: [
            StudentAssessmentEntryModel(
              studentId: 'st_1',
              studentName: 'Charlie Brown',
              rollNumber: 'CS010',
              componentMarks: {'test1': 20.0},
              totalMarks: 20.0,
            ),
          ],
        ),
        subject: {'name': 'Operating Systems', 'code': 'CS501'},
        section: {'name': 'CSE-A'},
        components: const [
          AssessmentComponentModel(
            key: 'test1',
            name: 'IA Test 1',
            maxMarks: 25.0,
            weightage: 15.0,
          ),
        ],
        isLocked: false,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(
              (ref) => _FakeAuthNotifier(AuthAuthenticated(user: facultyUser, token: 'jwt')),
            ),
            assessmentContextProvider(
              (sectionId: 'sec_test_1', subjectId: 'sub_test_1', academicYearId: null),
            ).overrideWith((ref) async => mockContext),
          ],
          child: const MaterialApp(
            home: InternalMarksScreen(
              sectionId: 'sec_test_1',
              subjectId: 'sub_test_1',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify header and subject information
      expect(find.text('Operating Systems'), findsWidgets);
      expect(find.text('CS501'), findsWidgets);
      expect(find.textContaining('CSE-A'), findsWidgets);
      expect(find.text('Charlie Brown'), findsOneWidget);
      expect(find.text('CS010'), findsOneWidget);
      expect(find.text('Draft'), findsWidgets);

      // Verify faculty actions
      expect(find.text('Save Draft'), findsOneWidget);
      expect(find.text('Mark as Reviewed'), findsOneWidget);
    });

    testWidgets('Renders locked banner and view-only state when published', (tester) async {
      final mockLockedContext = AssessmentContextModel(
        assessment: const InternalAssessmentModel(
          id: 'assess_test_2',
          collegeId: 'col_1',
          departmentId: 'dept_1',
          courseId: 'course_1',
          semesterId: 'sem_1',
          sectionId: 'sec_test_1',
          subjectId: 'sub_test_1',
          title: 'Internal Assessment',
          status: InternalAssessmentStatus.published,
          components: [
            AssessmentComponentModel(
              key: 'test1',
              name: 'IA Test 1',
              maxMarks: 25.0,
              weightage: 15.0,
            ),
          ],
          entries: [
            StudentAssessmentEntryModel(
              studentId: 'st_1',
              studentName: 'Charlie Brown',
              rollNumber: 'CS010',
              componentMarks: {'test1': 24.0},
              totalMarks: 24.0,
            ),
          ],
        ),
        subject: {'name': 'Operating Systems', 'code': 'CS501'},
        section: {'name': 'CSE-A'},
        components: const [
          AssessmentComponentModel(
            key: 'test1',
            name: 'IA Test 1',
            maxMarks: 25.0,
            weightage: 15.0,
          ),
        ],
        isLocked: true,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(
              (ref) => _FakeAuthNotifier(AuthAuthenticated(user: facultyUser, token: 'jwt')),
            ),
            assessmentContextProvider(
              (sectionId: 'sec_test_1', subjectId: 'sub_test_1', academicYearId: null),
            ).overrideWith((ref) async => mockLockedContext),
          ],
          child: const MaterialApp(
            home: InternalMarksScreen(
              sectionId: 'sec_test_1',
              subjectId: 'sub_test_1',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Published & Locked'), findsWidgets);
      expect(find.textContaining('Assessment marks finalized and locked'), findsOneWidget);
    });
  });

  group('StudentInternalMarksScreen Widget Tests', () {
    testWidgets('Displays published marks with breakdown cards', (tester) async {
      final mockStudentMarks = [
        const StudentPublishedMarksItem(
          id: 'pub_item_1',
          subject: {
            'id': 'sub_1',
            'name': 'Computer Networks',
            'code': 'CS502',
          },
          section: {
            'id': 'sec_1',
            'name': '5th Sem B',
          },
          semester: {
            'id': 'sem_5',
            'name': 'Semester 5',
          },
          components: [
            AssessmentComponentModel(
              key: 'test1',
              name: 'Test 1',
              maxMarks: 30.0,
              weightage: 15.0,
              isStudentVisible: true,
            ),
            AssessmentComponentModel(
              key: 'assignment',
              name: 'Assignment',
              maxMarks: 20.0,
              weightage: 10.0,
              isStudentVisible: true,
            ),
          ],
          marks: {'test1': 27.0, 'assignment': 18.0},
          totalMarks: 45.0,
          remarks: 'Consistent excellence',
        )
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            studentMarksProvider(null).overrideWith((ref) async => mockStudentMarks),
          ],
          child: const MaterialApp(
            home: StudentInternalMarksScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('My Internal Marks'), findsOneWidget);
      expect(find.text('Computer Networks'), findsOneWidget);
      expect(find.textContaining('CS502'), findsWidgets);
      expect(find.text('45 / 50'), findsOneWidget);
      expect(find.text('Test 1'), findsOneWidget);
      expect(find.text('Assignment'), findsOneWidget);
      expect(find.textContaining('Consistent excellence'), findsOneWidget);
    });
  });
}
