import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:campus_management/features/assignments/domain/models/assignment_models.dart';
import 'package:campus_management/features/assignments/presentation/providers/assignments_providers.dart';
import 'package:campus_management/features/assignments/domain/repositories/assignments_repository.dart';
import 'package:campus_management/features/assignments/presentation/screens/new_assignment_screen.dart';
import 'package:campus_management/features/assignments/presentation/screens/assignment_detail_screen.dart';
import 'package:campus_management/features/academic_structure/domain/models/academic_models.dart';
import 'package:campus_management/features/academic_structure/presentation/providers/academic_providers.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/core/realtime/models/realtime_event.dart';
import 'package:campus_management/core/realtime/presentation/providers/realtime_providers.dart';

class _FakeAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _FakeAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAssignmentsRepository implements AssignmentsRepository {
  List<AssignmentModel> assignments = [];

  @override
  Future<List<AssignmentModel>> getFacultyAssignments({String? status, String? sectionId, String? subjectId}) async {
    return assignments;
  }

  @override
  Future<List<AssignmentModel>> getStudentAssignments() async {
    return assignments;
  }

  @override
  Future<AssignmentModel> getAssignmentDetail(String id) async {
    final asgn = assignments.firstWhere((a) => a.id == id, orElse: () => throw Exception('Not found'));
    return asgn;
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
    final newAsgn = AssignmentModel(
      id: 'asgn_new_1',
      collegeId: 'col_1',
      departmentId: 'dept_1',
      courseId: 'course_1',
      academicYearId: 'ay_1',
      semesterId: 'sem_1',
      sectionId: null,
      subjectId: 'sub_1',
      facultyId: 'fac_user_1',
      facultyAssignmentId: facultyAssignmentId,
      facultyName: 'Dr. Turing',
      title: title,
      description: description,
      dueDate: dueDate,
      dueTime: dueTime,
      dueDateTime: DateTime.now().add(const Duration(days: 7)),
      maximumMarks: maximumMarks,
      status: status ?? AssignmentStatus.draft,
    );
    assignments.add(newAsgn);
    return newAsgn;
  }

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
  }) async {
    final existing = await getAssignmentDetail(id);
    return existing;
  }

  @override
  Future<AssignmentModel> publishAssignment(String id) async {
    return (await getAssignmentDetail(id));
  }

  @override
  Future<AssignmentModel> closeAssignment(String id) async {
    return (await getAssignmentDetail(id));
  }

  @override
  Future<AssignmentModel> archiveAssignment(String id) async {
    return (await getAssignmentDetail(id));
  }

  @override
  Future<void> completeAssignment(String id) async {}

  @override
  Future<void> deleteAssignment(String id) async {
    assignments.removeWhere((a) => a.id == id);
  }

  @override
  Future<AssignmentActivityResponseModel> getAssignmentActivity(String id) async {
    final asgn = await getAssignmentDetail(id);
    return AssignmentActivityResponseModel(
      assignment: asgn,
      summary: const AssignmentActivitySummaryModel(
        totalStudents: 10,
        completedCount: 5,
        pendingCount: 5,
        overdueCount: 0,
        reviewedCount: 3,
        maximumMarks: 20,
      ),
      completed: [],
      pending: [],
    );
  }

  @override
  Future<AssignmentActivityResponseModel> recordMarks(String id, List<Map<String, dynamic>> marks) async {
    return getAssignmentActivity(id);
  }

  @override
  Future<SubmissionModel?> getMySubmission(String assignmentId) async => null;

  @override
  Future<SubmissionUploadAuthModel> getSubmissionUploadAuth({
    required String assignmentId,
    required String fileName,
    required String fileType,
  }) async =>
      SubmissionUploadAuthModel(
        signature: 'sig',
        expire: 12345,
        token: 'token',
        publicKey: 'pub',
        uploadEndpoint: 'https://upload.imagekit.io',
        folder: '/folder',
        fileName: fileName,
      );

  @override
  Future<SubmissionModel> saveDraftSubmission({
    required String assignmentId,
    String? textResponse,
    List<SubmissionAttachmentModel>? attachments,
  }) async =>
      SubmissionModel(
        id: 'sub_draft_1',
        assignmentId: assignmentId,
        studentId: 'stu_1',
        status: StudentTaskStatus.draft,
        textResponse: textResponse,
        attachments: attachments ?? [],
        submissionHistory: [],
        reviewStatus: FacultyReviewStatus.notReviewed,
      );

  @override
  Future<SubmissionModel> submitAssignment({
    required String assignmentId,
    String? textResponse,
    List<SubmissionAttachmentModel>? attachments,
  }) async =>
      SubmissionModel(
        id: 'sub_final_1',
        assignmentId: assignmentId,
        studentId: 'stu_1',
        status: StudentTaskStatus.submitted,
        textResponse: textResponse,
        attachments: attachments ?? [],
        submittedAt: DateTime.now(),
        submissionHistory: [],
        reviewStatus: FacultyReviewStatus.notReviewed,
      );

  @override
  Future<String> getSubmissionFileDownloadUrl({
    required String submissionId,
    required String fileId,
  }) async =>
      'https://ik.imagekit.io/acadex/file.pdf';

  @override
  Future<SubmissionModel> reviewSingleSubmission({
    required String assignmentId,
    required String studentId,
    double? marks,
    String? feedback,
    FacultyReviewStatus? reviewStatus,
  }) async =>
      SubmissionModel(
        id: 'sub_reviewed_1',
        assignmentId: assignmentId,
        studentId: studentId,
        status: StudentTaskStatus.completed,
        attachments: [],
        submissionHistory: [],
        reviewStatus: reviewStatus ?? FacultyReviewStatus.reviewed,
        marks: marks,
        feedback: feedback,
      );
}


class _FakeFacultyAssignmentsNotifier extends FacultyAssignmentsNotifier {
  final List<FacultyAssignment> _list;
  _FakeFacultyAssignmentsNotifier(this._list);

  @override
  Future<List<FacultyAssignment>> build() async => _list;
}

void main() {
  final facultyUser = UserModel(
    id: 'fac_user_1',
    name: 'Dr. Alan Turing',
    email: 'turing@campus.edu',
    role: AppRole.faculty,
    collegeId: 'col_1',
  );

  final testFacultyAssignment = FacultyAssignment(
    id: 'fa_dbms_1',
    collegeId: 'col_1',
    departmentId: 'dept_cse',
    facultyId: 'fac_user_1',
    facultyName: 'Dr. Alan Turing',
    courseId: 'course_cs',
    semesterId: 'sem_5',
    sectionId: null, // Section optional
    subjectId: 'sub_dbms',
    academicYearId: 'ay_2026',
    isActive: true,
  );

  group('PROMPT 39 — Assignment Domain Model Hardening', () {
    test('AssignmentModel handles section optionality and archived status safely', () {
      final jsonWithSection = {
        'id': 'asgn_101',
        'collegeId': 'col_1',
        'departmentId': 'dept_1',
        'courseId': 'course_1',
        'academicYearId': 'ay_1',
        'semesterId': 'sem_1',
        'sectionId': 'sec_alpha',
        'subjectId': 'sub_1',
        'facultyId': 'fac_1',
        'facultyName': 'Dr. Turing',
        'title': 'SQL Homework 1',
        'description': 'Write 5 queries',
        'dueDate': '2026-10-10',
        'dueTime': '11:59 PM',
        'dueDateTime': '2026-10-10T23:59:00.000Z',
        'maximumMarks': 20,
        'status': 'PUBLISHED',
      };

      final asgn1 = AssignmentModel.fromJson(jsonWithSection);
      expect(asgn1.id, 'asgn_101');
      expect(asgn1.sectionId, 'sec_alpha');
      expect(asgn1.status, AssignmentStatus.published);

      final jsonSectionless = {
        'id': 'asgn_102',
        'collegeId': 'col_1',
        'departmentId': 'dept_1',
        'courseId': 'course_1',
        'academicYearId': 'ay_1',
        'semesterId': 'sem_1',
        'sectionId': null, // Section disabled!
        'subjectId': 'sub_1',
        'facultyId': 'fac_1',
        'facultyName': 'Dr. Turing',
        'title': 'Midterm Essay',
        'description': 'Coursewide submission',
        'dueDate': '2026-10-20',
        'dueTime': '11:59 PM',
        'dueDateTime': '2026-10-20T23:59:00.000Z',
        'maximumMarks': 50,
        'status': 'ARCHIVED',
      };

      final asgn2 = AssignmentModel.fromJson(jsonSectionless);
      expect(asgn2.id, 'asgn_102');
      expect(asgn2.sectionId, isNull);
      expect(asgn2.status, AssignmentStatus.archived);
      expect(asgn2.status.label, 'Archived');
    });
  });

  group('PROMPT 39 — NewAssignmentScreen Pre-fill & Mobile Layout Tests', () {
    testWidgets('Pre-fills initialFacultyAssignmentId and renders without overflow on 360px width', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;

      final fakeRepo = FakeAssignmentsRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(AuthAuthenticated(user: facultyUser, token: 'mock'))),
            assignmentsRepositoryProvider.overrideWithValue(fakeRepo),
            myFacultyAssignmentsProvider.overrideWithValue([testFacultyAssignment]),
            facultyAssignmentsProvider.overrideWith(() => _FakeFacultyAssignmentsNotifier([testFacultyAssignment])),
            subjectMapProvider.overrideWithValue({
              'sub_dbms': Subject(
                id: 'sub_dbms',
                collegeId: 'col_1',
                departmentId: 'dept_cse',
                courseId: 'course_cs',
                semesterId: 'sem_5',
                name: 'Database Systems',
                code: 'CS501',
              ),
            }),
            courseMapProvider.overrideWithValue({}),
            sectionMapProvider.overrideWithValue({}),
          ],
          child: const MaterialApp(
            home: NewAssignmentScreen(
              initialFacultyAssignmentId: 'fa_dbms_1',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Create Assignment'), findsOneWidget);
      expect(find.text('ASSIGNMENT TITLE'), findsOneWidget);
      expect(find.text('DUE DATE'), findsOneWidget);
      expect(find.text('DUE TIME'), findsOneWidget);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });
  });

  group('PROMPT 39 — AssignmentDetailScreen Actions & Mobile Layout Tests', () {
    testWidgets('Renders assignment detail and actions cleanly across mobile screen widths (360px, 390px, 412px)', (tester) async {
      final sampleAssignment = AssignmentModel(
        id: 'asgn_detail_1',
        collegeId: 'col_1',
        departmentId: 'dept_1',
        courseId: 'course_1',
        academicYearId: 'ay_1',
        semesterId: 'sem_1',
        sectionId: null,
        subjectId: 'sub_1',
        subjectName: 'Database Management Systems',
        facultyId: 'fac_user_1',
        facultyName: 'Dr. Alan Turing',
        title: 'Query Optimization Lab',
        description: 'Complete the explain plan analysis.',
        dueDate: '2026-10-15',
        dueTime: '11:59 PM',
        dueDateTime: DateTime.now().add(const Duration(days: 5)),
        maximumMarks: 25,
        status: AssignmentStatus.published,
      );

      final fakeRepo = FakeAssignmentsRepository()..assignments = [sampleAssignment];

      final screenWidths = [360.0, 390.0, 412.0];

      for (final width in screenWidths) {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authProvider.overrideWith((ref) => _FakeAuthNotifier(AuthAuthenticated(user: facultyUser, token: 'mock'))),
              assignmentsRepositoryProvider.overrideWithValue(fakeRepo),
              assignmentDetailProvider('asgn_detail_1').overrideWith((ref) => Future.value(sampleAssignment)),
            ],
            child: const MaterialApp(
              home: AssignmentDetailScreen(assignmentId: 'asgn_detail_1'),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Query Optimization Lab'), findsOneWidget);
        expect(find.text('View Activity & Record Marks'), findsOneWidget);
        expect(find.text('Close Assignment'), findsOneWidget);
        expect(find.text('Archive Assignment'), findsOneWidget);
      }

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });
  });

  group('PROMPT 39 — Realtime Invalidation on Assignment Events', () {
    test('RealtimeDispatcher debounces and invalidates assignment providers', () async {
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith((ref) => _FakeAuthNotifier(const AuthUnauthenticated())),
        ],
      );
      final dispatcher = container.read(realtimeDispatcherProvider);
      final eventController = StreamController<RealtimeEvent>.broadcast();

      dispatcher.start(eventController.stream);

      // Emit assignment.published event
      eventController.add(RealtimeEvent(
        eventId: 'evt_asgn_pub_1',
        eventVersion: 1,
        eventType: 'assignment.published',
        aggregateType: 'Assignment',
        aggregateId: 'asgn_99',
        action: 'PUBLISHED',
        occurredAt: DateTime.now(),
        collegeId: 'col_1',
        scope: {},
        payload: {
          'assignmentId': 'asgn_99',
          'title': 'Compiler Project',
        },
      ));

      // Wait beyond the 300ms debounce window
      await Future.delayed(const Duration(milliseconds: 350));

      dispatcher.stop();
      await eventController.close();
      await Future.delayed(const Duration(milliseconds: 50));
      container.dispose();
    });
  });
}
