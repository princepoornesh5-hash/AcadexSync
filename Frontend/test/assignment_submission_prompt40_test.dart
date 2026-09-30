import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:campus_management/features/assignments/domain/models/assignment_models.dart';
import 'package:campus_management/features/assignments/presentation/providers/assignments_providers.dart';
import 'package:campus_management/features/assignments/domain/repositories/assignments_repository.dart';
import 'package:campus_management/features/assignments/presentation/screens/assignment_detail_screen.dart';
import 'package:campus_management/features/assignments/presentation/screens/assignment_activity_screen.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';

class _FakeAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _FakeAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakePrompt40AssignmentsRepository implements AssignmentsRepository {
  SubmissionModel? currentStudentSubmission;
  AssignmentModel testAssignment;
  AssignmentActivityResponseModel testActivity;

  FakePrompt40AssignmentsRepository({
    required this.testAssignment,
    required this.testActivity,
    this.currentStudentSubmission,
  });

  @override
  Future<List<AssignmentModel>> getFacultyAssignments({String? status, String? sectionId, String? subjectId}) async =>
      [testAssignment];

  @override
  Future<List<AssignmentModel>> getStudentAssignments() async => [testAssignment];

  @override
  Future<AssignmentModel> getAssignmentDetail(String id) async => testAssignment;

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
  }) async =>
      testAssignment;

  @override
  Future<AssignmentModel> updateAssignment({
    required String id,
    String? title,
    String? description,
    List<String>? questions,
    AssignmentType? assignmentType,
    String? dueDate,
    String? dueTime,
    int? maximumMarks,
    List<AssignmentAttachmentModel>? attachments,
  }) async =>
      testAssignment;

  @override
  Future<AssignmentModel> publishAssignment(String id) async => testAssignment;

  @override
  Future<AssignmentModel> closeAssignment(String id) async => testAssignment;

  @override
  Future<AssignmentModel> archiveAssignment(String id) async => testAssignment;

  @override
  Future<void> completeAssignment(String id) async {}

  @override
  Future<void> deleteAssignment(String id) async {}

  @override
  Future<AssignmentActivityResponseModel> getAssignmentActivity(String id) async => testActivity;

  @override
  Future<AssignmentActivityResponseModel> recordMarks(String id, List<Map<String, dynamic>> marks) async => testActivity;

  @override
  Future<SubmissionModel?> getMySubmission(String assignmentId) async => currentStudentSubmission;

  @override
  Future<SubmissionUploadAuthModel> getSubmissionUploadAuth({
    required String assignmentId,
    required String fileName,
    required String fileType,
  }) async =>
      SubmissionUploadAuthModel(
        signature: 'test_signature',
        expire: 1727600000,
        token: 'test_token',
        publicKey: 'test_public_key',
        uploadEndpoint: 'https://upload.imagekit.io/api/v1/files/upload',
        folder: '/acadex/colleges/col1/assignments/asgn1/submissions/stu1',
        fileName: fileName,
      );

  @override
  Future<SubmissionModel> saveDraftSubmission({
    required String assignmentId,
    String? textResponse,
    List<SubmissionAttachmentModel>? attachments,
  }) async {
    final draft = SubmissionModel(
      id: 'sub_draft_1',
      assignmentId: assignmentId,
      studentId: 'stu_1',
      status: StudentTaskStatus.draft,
      textResponse: textResponse,
      attachments: attachments ?? [],
      submissionHistory: [],
      reviewStatus: FacultyReviewStatus.notReviewed,
    );
    currentStudentSubmission = draft;
    return draft;
  }

  @override
  Future<SubmissionModel> submitAssignment({
    required String assignmentId,
    String? textResponse,
    List<SubmissionAttachmentModel>? attachments,
  }) async {
    final finalSub = SubmissionModel(
      id: 'sub_final_1',
      assignmentId: assignmentId,
      studentId: 'stu_1',
      status: StudentTaskStatus.submitted,
      textResponse: textResponse,
      attachments: attachments ?? [],
      submittedAt: DateTime.now(),
      version: 1,
      submissionHistory: [],
      reviewStatus: FacultyReviewStatus.notReviewed,
    );
    currentStudentSubmission = finalSub;
    return finalSub;
  }

  @override
  Future<String> getSubmissionFileDownloadUrl({
    required String submissionId,
    required String fileId,
  }) async =>
      'https://ik.imagekit.io/acadex/submissions/download_test.pdf';

  @override
  Future<SubmissionModel> reviewSingleSubmission({
    required String assignmentId,
    required String studentId,
    double? marks,
    String? feedback,
    FacultyReviewStatus? reviewStatus,
  }) async {
    final reviewed = SubmissionModel(
      id: 'sub_reviewed_1',
      assignmentId: assignmentId,
      studentId: studentId,
      status: StudentTaskStatus.completed,
      attachments: [],
      submissionHistory: [],
      reviewStatus: reviewStatus ?? FacultyReviewStatus.reviewed,
      marks: marks,
      feedback: feedback,
      reviewedAt: DateTime.now(),
      reviewedBy: 'fac_1',
    );
    currentStudentSubmission = reviewed;
    return reviewed;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testAssignment = AssignmentModel(
    id: 'asgn_p40_1',
    collegeId: 'col_1',
    departmentId: 'dept_1',
    courseId: 'course_1',
    academicYearId: 'ay_1',
    semesterId: 'sem_1',
    sectionId: 'sec_1',
    subjectId: 'sub_1',
    facultyId: 'fac_user_1',
    facultyAssignmentId: 'fa_1',
    facultyName: 'Prof. Turing',
    title: 'Operating Systems Virtual Memory Lab',
    description: 'Implement page replacement algorithms in C and benchmark.',
    questions: ['1. Compare LRU vs FIFO', '2. Measure page fault rates'],
    dueDate: '2026-10-15',
    dueTime: '23:59',
    dueDateTime: DateTime.now().add(const Duration(days: 10)),
    maximumMarks: 20,
    status: AssignmentStatus.published,
    subjectName: 'Operating Systems',
    sectionName: 'CSE-A',
  );

  final testActivity = AssignmentActivityResponseModel(
    assignment: testAssignment,
    summary: const AssignmentActivitySummaryModel(
      totalStudents: 2,
      completedCount: 1,
      pendingCount: 1,
      overdueCount: 0,
      reviewedCount: 0,
      maximumMarks: 20,
    ),
    completed: [
      const StudentAssignmentActivityModel(
        studentId: 'stu_1',
        studentName: 'Poornesh Kumar',
        rollNumber: 'CS2026_01',
        status: StudentTaskStatus.submitted,
        isLate: true,
        reviewStatus: FacultyReviewStatus.notReviewed,
        maximumMarks: 20,
        submissionId: 'sub_p40_1',
        textResponse: 'Here is my benchmarking report on LRU algorithm.',
        attachments: [
          SubmissionAttachmentModel(
            fileId: 'f_101',
            name: 'benchmark_report.pdf',
            url: 'https://ik.imagekit.io/acadex/report.pdf',
            fileSize: 1048576,
          ),
        ],
        version: 1,
      ),
    ],
    pending: [
      const StudentAssignmentActivityModel(
        studentId: 'stu_2',
        studentName: 'John Doe',
        rollNumber: 'CS2026_02',
        status: StudentTaskStatus.pending,
        reviewStatus: FacultyReviewStatus.notReviewed,
        maximumMarks: 20,
      ),
    ],
  );

  group('PROMPT 40 — Assignment Submission & Review Domain Models', () {
    test('SubmissionModel parses full json payload with attachments, marks, feedback, and history', () {
      final json = {
        '_id': 'sub_123',
        'assignmentId': 'asgn_123',
        'studentId': 'stu_123',
        'status': 'SUBMITTED',
        'textResponse': 'This is my final solution.',
        'attachments': [
          {
            'fileId': 'file_01',
            'name': 'solution.pdf',
            'url': 'https://ik.imagekit.io/solution.pdf',
            'fileSize': 524288,
          },
        ],
        'submittedAt': '2026-09-29T10:00:00.000Z',
        'isLate': true,
        'version': 2,
        'submissionHistory': [
          {
            'version': 1,
            'textResponse': 'Draft attempt',
            'attachments': [],
            'submittedAt': '2026-09-28T09:00:00.000Z',
            'isLate': false,
          },
        ],
        'reviewStatus': 'REVIEWED',
        'marks': 18.5,
        'feedback': 'Excellent analysis and benchmarks.',
        'reviewedAt': '2026-09-29T12:00:00.000Z',
        'reviewedBy': 'fac_123',
      };

      final sub = SubmissionModel.fromJson(json);

      expect(sub.id, 'sub_123');
      expect(sub.assignmentId, 'asgn_123');
      expect(sub.studentId, 'stu_123');
      expect(sub.status, StudentTaskStatus.submitted);
      expect(sub.status.label, 'Submitted');
      expect(sub.textResponse, 'This is my final solution.');
      expect(sub.attachments.length, 1);
      expect(sub.attachments.first.name, 'solution.pdf');
      expect(sub.isLate, true);
      expect(sub.version, 2);
      expect(sub.submissionHistory.length, 1);
      expect(sub.submissionHistory.first.version, 1);
      expect(sub.reviewStatus, FacultyReviewStatus.reviewed);
      expect(sub.marks, 18.5);
      expect(sub.feedback, 'Excellent analysis and benchmarks.');
    });

    test('StudentTaskStatus & FacultyReviewStatus handle all valid enum cases and fallbacks', () {
      expect(StudentTaskStatus.fromString('DRAFT'), StudentTaskStatus.draft);
      expect(StudentTaskStatus.fromString('SUBMITTED'), StudentTaskStatus.submitted);
      expect(StudentTaskStatus.fromString('RESUBMITTED'), StudentTaskStatus.resubmitted);
      expect(StudentTaskStatus.fromString('COMPLETED'), StudentTaskStatus.completed);
      expect(StudentTaskStatus.fromString('OVERDUE'), StudentTaskStatus.overdue);
      expect(StudentTaskStatus.fromString('UNKNOWN'), StudentTaskStatus.pending);

      expect(FacultyReviewStatus.fromString('UNDER_REVIEW'), FacultyReviewStatus.underReview);
      expect(FacultyReviewStatus.fromString('REVIEWED'), FacultyReviewStatus.reviewed);
      expect(FacultyReviewStatus.fromString('NOT_REVIEWED'), FacultyReviewStatus.notReviewed);
      expect(FacultyReviewStatus.fromString(null), FacultyReviewStatus.notReviewed);
    });

    test('SubmissionUploadAuthModel deserializes securely', () {
      final json = {
        'signature': 'test_sig',
        'expire': 1727600000,
        'token': 'test_token',
        'publicKey': 'pub_123',
        'uploadEndpoint': 'https://upload.imagekit.io/api/v1/files/upload',
        'folder': '/acadex/submissions',
        'fileName': 'assignment.pdf',
      };

      final auth = SubmissionUploadAuthModel.fromJson(json);
      expect(auth.signature, 'test_sig');
      expect(auth.expire, 1727600000);
      expect(auth.uploadEndpoint, 'https://upload.imagekit.io/api/v1/files/upload');
    });

    test('AssignmentModel.isPastDue correctly calculates deadline', () {
      final past = AssignmentModel(
        id: '1',
        collegeId: 'c1',
        departmentId: 'd1',
        courseId: 'cr1',
        academicYearId: 'a1',
        semesterId: 's1',
        subjectId: 'sb1',
        facultyId: 'f1',
        facultyName: 'Prof. Turing',
        title: 'Past Assignment',
        description: 'Desc',
        dueDate: '2020-01-01',
        dueTime: '10:00',
        dueDateTime: DateTime.now().subtract(const Duration(days: 1)),
        maximumMarks: 10,
      );

      final future = AssignmentModel(
        id: '2',
        collegeId: 'c1',
        departmentId: 'd1',
        courseId: 'cr1',
        academicYearId: 'a1',
        semesterId: 's1',
        subjectId: 'sb1',
        facultyId: 'f1',
        facultyName: 'Prof. Turing',
        title: 'Future Assignment',
        description: 'Desc',
        dueDate: '2030-01-01',
        dueTime: '10:00',
        dueDateTime: DateTime.now().add(const Duration(days: 1)),
        maximumMarks: 10,
      );

      expect(past.isPastDue, true);
      expect(future.isPastDue, false);
    });
  });

  group('PROMPT 40 — Student Submission & Faculty Review UI (360px Mobile UX)', () {
    testWidgets('Student sees submission form with written response and attach button on 360px screen',
        (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final fakeRepo = FakePrompt40AssignmentsRepository(
        testAssignment: testAssignment,
        testActivity: testActivity,
        currentStudentSubmission: null, // No submission yet
      );

      final studentUser = UserModel(
        id: 'u_stu_1',
        name: 'Poornesh Kumar',
        email: 'poornesh@college.edu',
        role: AppRole.student,
        collegeId: 'col_1',
        departmentId: 'dept_1',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            assignmentsRepositoryProvider.overrideWithValue(fakeRepo),
            authProvider.overrideWith((ref) => _FakeAuthNotifier(AuthAuthenticated(user: studentUser, token: 'mock'))),
          ],
          child: const MaterialApp(
            home: AssignmentDetailScreen(assignmentId: 'asgn_p40_1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check header and content
      expect(find.text('Operating Systems Virtual Memory Lab'), findsOneWidget);
      expect(find.text('YOUR SUBMISSION'), findsOneWidget);
      expect(find.text('WRITTEN RESPONSE'), findsOneWidget);
      expect(find.text('Attach File'), findsOneWidget);
      expect(find.text('Save Draft'), findsOneWidget);
      expect(find.text('Submit'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Student sees Submitted state with Late badge and Resubmit action',
        (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final submitted = SubmissionModel(
        id: 'sub_done_1',
        assignmentId: 'asgn_p40_1',
        studentId: 'stu_1',
        status: StudentTaskStatus.submitted,
        textResponse: 'Benchmarking report attached.',
        attachments: const [
          SubmissionAttachmentModel(
            fileId: 'f_99',
            name: 'benchmarks_final.pdf',
            url: 'https://ik.imagekit.io/report.pdf',
          ),
        ],
        submittedAt: DateTime.now(),
        isLate: true,
        version: 1,
        submissionHistory: [],
        reviewStatus: FacultyReviewStatus.notReviewed,
      );

      final fakeRepo = FakePrompt40AssignmentsRepository(
        testAssignment: testAssignment,
        testActivity: testActivity,
        currentStudentSubmission: submitted,
      );

      final studentUser = UserModel(
        id: 'u_stu_1',
        name: 'Poornesh Kumar',
        email: 'poornesh@college.edu',
        role: AppRole.student,
        collegeId: 'col_1',
        departmentId: 'dept_1',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            assignmentsRepositoryProvider.overrideWithValue(fakeRepo),
            authProvider.overrideWith((ref) => _FakeAuthNotifier(AuthAuthenticated(user: studentUser, token: 'mock'))),
          ],
          child: const MaterialApp(
            home: AssignmentDetailScreen(assignmentId: 'asgn_p40_1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Submitted'), findsOneWidget);
      expect(find.text('Version 1'), findsOneWidget);
      expect(find.text('LATE'), findsOneWidget);
      expect(find.text('benchmarks_final.pdf'), findsOneWidget);
      expect(find.text('Resubmit Assignment'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Faculty sees student submission with LATE badge and review button on 360px layout',
        (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final fakeRepo = FakePrompt40AssignmentsRepository(
        testAssignment: testAssignment,
        testActivity: testActivity,
      );

      final facultyUser = UserModel(
        id: 'fac_user_1',
        name: 'Prof. Turing',
        email: 'turing@college.edu',
        role: AppRole.faculty,
        collegeId: 'col_1',
        departmentId: 'dept_1',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            assignmentsRepositoryProvider.overrideWithValue(fakeRepo),
            authProvider.overrideWith((ref) => _FakeAuthNotifier(AuthAuthenticated(user: facultyUser, token: 'mock'))),
          ],
          child: const MaterialApp(
            home: AssignmentActivityScreen(assignmentId: 'asgn_p40_1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check student in completed tab
      expect(find.text('Poornesh Kumar'), findsOneWidget);
      expect(find.text('LATE'), findsOneWidget);
      expect(find.text('Review'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Tap "Review" to open bottom sheet
      await tester.tap(find.text('Review'));
      await tester.pumpAndSettle();

      expect(find.text('AWARDED MARKS (Max: 20)'), findsOneWidget);
      expect(find.text('FACULTY FEEDBACK'), findsOneWidget);
      expect(find.text('Save Review'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
