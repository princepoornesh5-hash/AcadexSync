import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_management/features/academic_structure/presentation/providers/academic_providers.dart';
import 'package:campus_management/features/academic_structure/domain/models/academic_models.dart';
import 'package:campus_management/features/assignments/domain/models/assignment_models.dart';
import 'package:campus_management/features/assignments/domain/repositories/assignments_repository.dart';
import 'package:campus_management/features/assignments/presentation/providers/assignments_providers.dart';
import 'package:campus_management/features/assignments/presentation/screens/new_assignment_screen.dart';
import 'package:campus_management/features/assignments/presentation/screens/student_assignments_screen.dart';
import 'package:campus_management/features/assignments/presentation/screens/assignment_detail_screen.dart';
import 'package:campus_management/features/assignments/presentation/screens/assignment_activity_screen.dart';
import 'package:campus_management/features/assignments/presentation/widgets/marks_slider_row.dart';

class _FakeAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _FakeAuthNotifier(super.initial);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestFacultyAssignmentNotifier extends FacultyAssignmentsNotifier {
  final List<FacultyAssignment> initialAssignments;
  _TestFacultyAssignmentNotifier(this.initialAssignments);
  @override
  Future<List<FacultyAssignment>> build() async => initialAssignments;
}

class FakeAssignmentsRepository implements AssignmentsRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  List<AssignmentModel> facultyAssignments = [];

  List<AssignmentModel> studentAssignments = [];
  AssignmentModel? assignmentDetail;
  AssignmentActivityResponseModel? activityData;

  List<Map<String, dynamic>> recordedMarksPayload = [];
  bool completeAssignmentCalled = false;
  String? completedAssignmentId;

  @override
  Future<List<AssignmentModel>> getFacultyAssignments({
    String? status,
    String? sectionId,
    String? subjectId,
  }) async {
    return facultyAssignments;
  }

  @override
  Future<List<AssignmentModel>> getStudentAssignments() async {
    return studentAssignments;
  }

  @override
  Future<AssignmentModel> getAssignmentDetail(String id) async {
    if (assignmentDetail != null) return assignmentDetail!;
    return AssignmentModel(
      id: id,
      collegeId: 'college_01',
      departmentId: 'dept_01',
      courseId: 'course_01',
      academicYearId: 'ay_01',
      semesterId: 'sem_01',
      sectionId: 'sec_01',
      subjectId: 'sub_01',
      facultyId: 'fac_01',
      facultyName: 'Prof. Donald Knuth',
      title: 'Linked List Problems',
      description: 'Complete singly and doubly linked list problems.',
      questions: const ['Explain singly linked lists.', 'Write an insertion algorithm.'],
      assignmentType: AssignmentType.homework,
      dueDate: '2026-09-30',
      dueTime: '11:59 PM',
      dueDateTime: DateTime.now().add(const Duration(days: 3)),
      maximumMarks: 10,
      status: AssignmentStatus.published,
      subjectName: 'Data Structures',
      sectionName: 'CSE-A',
      studentStatus: StudentTaskStatus.pending,
    );
  }

  @override
  Future<AssignmentModel> createAssignment({
    required String facultyAssignmentId,
    required String title,
    required String description,
    List<String>? questions,
    AssignmentType? assignmentType,
    required String dueDate,
    required String dueTime,
    required int maximumMarks,
    List<AssignmentAttachmentModel>? attachments,
    AssignmentStatus? status,
  }) async {
    final asgn = AssignmentModel(
      id: 'asgn_new_1',
      collegeId: 'college_01',
      departmentId: 'dept_01',
      courseId: 'course_01',
      academicYearId: 'ay_01',
      semesterId: 'sem_01',
      sectionId: 'sec_01',
      subjectId: 'sub_01',
      facultyId: 'fac_01',
      facultyAssignmentId: facultyAssignmentId,
      facultyName: 'Prof. Donald Knuth',
      title: title,
      description: description,
      questions: questions ?? [],
      assignmentType: assignmentType ?? AssignmentType.homework,
      dueDate: dueDate,
      dueTime: dueTime,
      dueDateTime: DateTime.now().add(const Duration(days: 7)),
      maximumMarks: maximumMarks,
      attachments: attachments ?? [],
      status: status ?? AssignmentStatus.draft,
      subjectName: 'Data Structures',
      sectionName: 'CSE-A',
    );
    facultyAssignments = [asgn, ...facultyAssignments];
    return asgn;
  }

  @override
  Future<AssignmentModel> publishAssignment(String id) async {
    final asgn = await getAssignmentDetail(id);
    return asgn;
  }

  @override
  Future<AssignmentModel> closeAssignment(String id) async {
    final asgn = await getAssignmentDetail(id);
    return asgn;
  }

  @override
  Future<void> completeAssignment(String id) async {
    completeAssignmentCalled = true;
    completedAssignmentId = id;
  }

  @override
  Future<AssignmentActivityResponseModel> getAssignmentActivity(String id) async {
    if (activityData != null) return activityData!;

    final asgn = await getAssignmentDetail(id);
    return AssignmentActivityResponseModel(
      assignment: asgn,
      summary: const AssignmentActivitySummaryModel(
        totalStudents: 42,
        completedCount: 31,
        pendingCount: 8,
        overdueCount: 3,
        reviewedCount: 20,
        averageMarks: 7.8,
        maximumMarks: 10,
      ),
      completed: [
        StudentAssignmentActivityModel(
          studentId: 'stu_01',
          studentName: 'Ravi Kumar',
          rollNumber: 'CS-01',
          status: StudentTaskStatus.completed,
          completedAt: DateTime.now().subtract(const Duration(hours: 2)),
          reviewStatus: FacultyReviewStatus.reviewed,
          marks: 8,
          maximumMarks: 10,
        ),
        StudentAssignmentActivityModel(
          studentId: 'stu_02',
          studentName: 'Priya Sharma',
          rollNumber: 'CS-02',
          status: StudentTaskStatus.completed,
          completedAt: DateTime.now().subtract(const Duration(hours: 1)),
          reviewStatus: FacultyReviewStatus.notReviewed,
          marks: null,
          maximumMarks: 10,
        ),
      ],
      pending: const [
        StudentAssignmentActivityModel(
          studentId: 'stu_03',
          studentName: 'Kiran Kumar',
          rollNumber: 'CS-03',
          status: StudentTaskStatus.pending,
          reviewStatus: FacultyReviewStatus.notReviewed,
          marks: null,
          maximumMarks: 10,
        ),
      ],
    );
  }

  @override
  Future<AssignmentActivityResponseModel> recordMarks(
    String id,
    List<Map<String, dynamic>> marks,
  ) async {
    recordedMarksPayload = marks;
    return getAssignmentActivity(id);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testFacultyUser = UserModel(
    id: 'fac_user_1',
    name: 'Prof. Donald Knuth',
    email: 'knuth@coea.edu',
    role: AppRole.faculty,
    collegeId: 'college_01',
    departmentId: 'dept_01',
  );

  final testStudentUser = UserModel(
    id: 'stu_user_1',
    name: 'Ravi Kumar',
    email: 'ravi@coea.edu',
    role: AppRole.student,
    collegeId: 'college_01',
    departmentId: 'dept_01',
  );

  final testTeachingAssignment = FacultyAssignment(
    id: 'fa_001',
    collegeId: 'college_01',
    departmentId: 'dept_01',
    facultyId: 'fac_user_1',
    facultyName: 'Prof. Donald Knuth',
    courseId: 'course_01',
    semesterId: 'sem_01',
    sectionId: 'sec_01',
    subjectId: 'sub_01',
    academicYearId: 'ay_01',
  );

  final testAssignmentModel = AssignmentModel(
    id: 'asgn_001',
    collegeId: 'college_01',
    departmentId: 'dept_01',
    courseId: 'course_01',
    academicYearId: 'ay_01',
    semesterId: 'sem_01',
    sectionId: 'sec_01',
    subjectId: 'sub_01',
    facultyId: 'fac_user_1',
    facultyName: 'Prof. Donald Knuth',
    title: 'Linked List Problems',
    description: 'Complete the following exercises.',
    questions: const ['Explain singly linked lists.', 'Write an insertion algorithm.'],
    assignmentType: AssignmentType.homework,
    dueDate: '30 Sep',
    dueTime: '11:59 PM',
    dueDateTime: DateTime.now().add(const Duration(days: 4)),
    maximumMarks: 10,
    status: AssignmentStatus.published,
    subjectName: 'Data Structures',
    sectionName: 'CSE-A',
    studentStatus: StudentTaskStatus.pending,
  );

  group('Assignment Domain & Screen Tests', () {
    // 20 & 21. Faculty assignment creation screen renders & authorized teaching context is used
    testWidgets('20 & 21. Faculty assignment creation screen renders with authorized teaching context', (tester) async {
      final fakeRepo = FakeAssignmentsRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(AuthAuthenticated(user: testFacultyUser, token: 'jwt'))),
            assignmentsRepositoryProvider.overrideWithValue(fakeRepo),
            facultyAssignmentsProvider.overrideWith(() => _TestFacultyAssignmentNotifier([testTeachingAssignment])),
            subjectMapProvider.overrideWithValue({
              'sub_01': Subject(id: 'sub_01', collegeId: 'college_01', departmentId: 'dept_01', name: 'Data Structures', code: 'CS201', credits: 4, type: 'Theory', semesterId: 'sem_01'),
            }),
            sectionMapProvider.overrideWithValue({
              'sec_01': Section(id: 'sec_01', collegeId: 'college_01', departmentId: 'dept_01', courseId: 'course_01', semesterId: 'sem_01', name: 'CSE-A', capacity: 60),
            }),
          ],
          child: const MaterialApp(
            home: NewAssignmentScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Create Assignment'), findsOneWidget);
      expect(find.text('TEACHING CONTEXT'), findsOneWidget);
      expect(find.text('Data Structures (CSE-A)'), findsOneWidget);
      expect(find.text('ASSIGNMENT TITLE'), findsOneWidget);
      expect(find.text('MAXIMUM MARKS'), findsOneWidget);
      expect(find.text('Publish Assignment'), findsOneWidget);
      expect(find.text('Save Draft'), findsOneWidget);
    });

    // 22. Student assignment view renders
    testWidgets('22. Student assignment view renders with upcoming assignments list', (tester) async {
      final fakeRepo = FakeAssignmentsRepository();
      fakeRepo.studentAssignments = [testAssignmentModel];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(AuthAuthenticated(user: testStudentUser, token: 'jwt'))),
            assignmentsRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: StudentAssignmentsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Assignments'), findsOneWidget);
      expect(find.text('Linked List Problems'), findsOneWidget);
      expect(find.text('Data Structures'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
    });

    // 23. Student Done action updates state
    testWidgets('23. Student Done action updates state when Mark as Done is tapped', (tester) async {
      final fakeRepo = FakeAssignmentsRepository();
      fakeRepo.assignmentDetail = testAssignmentModel;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(AuthAuthenticated(user: testStudentUser, token: 'jwt'))),
            assignmentsRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: AssignmentDetailScreen(assignmentId: 'asgn_001'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Mark as Done'), findsOneWidget);
      await tester.tap(find.text('Mark as Done'));
      await tester.pumpAndSettle();

      expect(fakeRepo.completeAssignmentCalled, isTrue);
      expect(fakeRepo.completedAssignmentId, 'asgn_001');
    });

    // 24. Faculty Activity Completed/Pending tabs render
    testWidgets('24. Faculty Activity Completed and Pending tabs render', (tester) async {
      final fakeRepo = FakeAssignmentsRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(AuthAuthenticated(user: testFacultyUser, token: 'jwt'))),
            assignmentsRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: AssignmentActivityScreen(assignmentId: 'asgn_001'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Assignment Activity'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Ravi Kumar'), findsOneWidget);
    });

    // 25 & 26. Single-row marks slider uses 0 -> maximumMarks and snaps to integer
    testWidgets('25 & 26. Single-row marks slider uses 0 to maximumMarks and snaps to integer values', (tester) async {
      final student = StudentAssignmentActivityModel(
        studentId: 'stu_01',
        studentName: 'Ravi Kumar',
        status: StudentTaskStatus.completed,
        reviewStatus: FacultyReviewStatus.reviewed,
        marks: 8,
        maximumMarks: 10,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarksSliderRow(
              student: student,
              maximumMarks: 10,
              currentMark: 8,
              onMarkChanged: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('8 / 10'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);

      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.min, 0.0);
      expect(slider.max, 10.0);
      expect(slider.divisions, 10);
    });

    // 27 & 28. Temporary mark bubble shows and mark value updates during slider interaction
    testWidgets('27 & 28. Mark value updates during slider interaction', (tester) async {
      double? updatedMark;
      final student = StudentAssignmentActivityModel(
        studentId: 'stu_01',
        studentName: 'Ravi Kumar',
        status: StudentTaskStatus.completed,
        reviewStatus: FacultyReviewStatus.notReviewed,
        marks: 5,
        maximumMarks: 10,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarksSliderRow(
              student: student,
              maximumMarks: 10,
              currentMark: 5,
              onMarkChanged: (m) => updatedMark = m,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('5 / 10'), findsOneWidget);

      // Simulate dragging slider
      final sliderFinder = find.byType(Slider);
      final center = tester.getCenter(sliderFinder);
      await tester.dragFrom(center, const Offset(60, 0));
      await tester.pump();

      expect(updatedMark, isNotNull);
    });

    // 29. Full Marks shortcut sets maximum
    testWidgets('29. Full Marks shortcut sets maximum marks immediately', (tester) async {
      double? updatedMark;
      final student = StudentAssignmentActivityModel(
        studentId: 'stu_01',
        studentName: 'Ravi Kumar',
        status: StudentTaskStatus.completed,
        reviewStatus: FacultyReviewStatus.notReviewed,
        marks: 4,
        maximumMarks: 10,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarksSliderRow(
              student: student,
              maximumMarks: 10,
              currentMark: 4,
              onMarkChanged: (m) => updatedMark = m,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Full Marks'), findsOneWidget);
      await tester.tap(find.text('Full Marks'));
      await tester.pumpAndSettle();

      expect(updatedMark, 10);
      expect(find.text('10 / 10'), findsOneWidget);
    });

    // 30. Save Marks persists pending changes
    testWidgets('30. Save Marks button persists pending mark changes', (tester) async {
      final fakeRepo = FakeAssignmentsRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(AuthAuthenticated(user: testFacultyUser, token: 'jwt'))),
            assignmentsRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: AssignmentActivityScreen(assignmentId: 'asgn_001'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Full Marks on first student to create a local pending change
      final fullMarksBtn = find.text('Full Marks').first;
      await tester.tap(fullMarksBtn);
      await tester.pumpAndSettle();

      expect(find.text('Save Marks'), findsOneWidget);
      await tester.tap(find.text('Save Marks'));
      await tester.pumpAndSettle();

      expect(fakeRepo.recordedMarksPayload.isNotEmpty, isTrue);
      expect(fakeRepo.recordedMarksPayload[0]['marks'], 10);
    });

    // 31. Assignment progress summary renders real values
    testWidgets('31. Assignment progress summary renders real values in header', (tester) async {
      final fakeRepo = FakeAssignmentsRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(AuthAuthenticated(user: testFacultyUser, token: 'jwt'))),
            assignmentsRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: AssignmentActivityScreen(assignmentId: 'asgn_001'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('31 / 42 Completed'), findsOneWidget);
      expect(find.text('8 Pending'), findsOneWidget);
      expect(find.text('3 Overdue'), findsOneWidget);
      expect(find.text('Avg: 7.8 / 10'), findsOneWidget);
    });
  });
}
