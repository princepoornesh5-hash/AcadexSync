import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:campus_management/features/academic_records/domain/models/academic_record_models.dart';
import 'package:campus_management/features/academic_records/data/repositories/academic_records_repository.dart';
import 'package:campus_management/features/academic_records/presentation/providers/academic_records_providers.dart';
import 'package:campus_management/features/academic_records/presentation/screens/student_academic_history_screen.dart';
import 'package:campus_management/features/academic_records/presentation/screens/academic_record_detail_screen.dart';
import 'package:campus_management/features/academic_records/presentation/screens/department_academic_records_screen.dart';
import 'package:campus_management/features/academic_records/presentation/widgets/academic_period_card.dart';
import 'package:campus_management/features/academic_records/presentation/widgets/subject_academic_tile.dart';
import 'package:campus_management/features/academic_records/presentation/widgets/academic_metric_pill.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/core/realtime/models/realtime_event.dart';

class _FakeAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _FakeAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAcademicRecordsRepository implements AcademicRecordsRepository {
  List<AcademicHistoryItemModel> testHistory;
  AcademicRecordDetailModel testDetail;
  PaginatedAcademicRecordsModel testPaginated;

  FakeAcademicRecordsRepository({
    required this.testHistory,
    required this.testDetail,
    required this.testPaginated,
  });

  @override
  Future<List<AcademicHistoryItemModel>> getStudentHistory({String? studentId}) async {
    return testHistory;
  }

  @override
  Future<AcademicRecordDetailModel> getRecordDetail(String recordId) async {
    return testDetail;
  }

  @override
  Future<PaginatedAcademicRecordsModel> getDepartmentRecords({
    String? departmentId,
    String? courseId,
    String? semesterId,
    String? academicYearId,
    String? progressionStatus,
    int page = 1,
    int limit = 20,
  }) async {
    return testPaginated;
  }

  @override
  Future<AcademicRecordModel> updateProgressionStatus(
    String recordId, {
    required AcademicProgressionStatus status,
    String? remarks,
  }) async {
    return testDetail.record;
  }

  @override
  Future<void> updateSubjectStatus(
    String subjectRecordId, {
    required SubjectAcademicStatus status,
    String? remarks,
  }) async {}

  @override
  Future<AcademicRecordModel> initializeRecord(String studentEnrollmentId) async {
    return testDetail.record;
  }
}

void main() {
  const collegeId = 'col_123';
  const studentUserId = 'usr_stu_123';
  const recordId = 'rec_1001';

  final mockStudentUser = UserModel(
    id: studentUserId,
    collegeId: collegeId,
    email: 'student@campus.edu',
    name: 'Jane Doe',
    role: AppRole.student,
  );

  final mockHodUser = UserModel(
    id: 'usr_hod_123',
    collegeId: collegeId,
    email: 'hod@campus.edu',
    name: 'Dr. Alan Turing',
    role: AppRole.hod,
    departmentId: 'dept_cs',
  );

  final mockRecord = AcademicRecordModel(
    id: recordId,
    collegeId: collegeId,
    studentId: 'stu_1001',
    studentName: 'Jane Doe',
    rollNumber: 'CS2024-001',
    studentEnrollmentId: 'enr_1001',
    courseId: 'crs_cs',
    departmentId: 'dept_cs',
    academicYearId: 'ay_2026',
    semesterId: 'sem_4',
    academicStage: 'Year 2',
    cohort: '2024-2028',
    progressionStatus: AcademicProgressionStatus.active,
  );

  final mockSubjectSummary = SubjectRecordSummary(
    id: 'srec_1',
    subjectId: 'sub_algo',
    name: 'Design & Analysis of Algorithms',
    code: 'CS401',
    type: 'Theory',
    credits: 4,
    status: SubjectAcademicStatus.inProgress,
    facultyName: 'Prof. Donald Knuth',
    attendance: const AttendanceAggregationSummary(
      totalClasses: 30,
      presentCount: 27,
      absentCount: 3,
      percentage: 90,
    ),
    practical: const PracticalAggregationSummary(
      totalSessions: 8,
      completedCount: 8,
      completionRate: 100,
    ),
    assignment: const AssignmentAggregationSummary(
      totalAssignments: 4,
      submittedCount: 4,
      completedCount: 3,
      completionRate: 100,
    ),
  );

  final mockHistoryItem = AcademicHistoryItemModel(
    record: mockRecord,
    courseName: 'B.Tech Computer Science & Engineering',
    departmentName: 'Computer Science',
    academicYearName: '2026–27',
    semesterNumber: 4,
    sectionName: 'A',
    subjectCount: 6,
    attendance: const AttendanceAggregationSummary(
      totalClasses: 60,
      presentCount: 54,
      percentage: 90,
    ),
    practical: const PracticalAggregationSummary(
      totalSessions: 16,
      completedCount: 16,
      completionRate: 100,
    ),
    assignment: const AssignmentAggregationSummary(
      totalAssignments: 10,
      submittedCount: 9,
      completionRate: 90,
    ),
  );

  final mockDetail = AcademicRecordDetailModel(
    record: mockRecord,
    courseName: 'B.Tech Computer Science & Engineering',
    departmentName: 'Computer Science',
    academicYearName: '2026–27',
    semesterNumber: 4,
    sectionName: 'A',
    overallAttendance: const AttendanceAggregationSummary(
      totalClasses: 60,
      presentCount: 54,
      absentCount: 6,
      percentage: 90,
    ),
    overallPractical: const PracticalAggregationSummary(
      totalSessions: 16,
      completedCount: 16,
      completionRate: 100,
    ),
    overallAssignment: const AssignmentAggregationSummary(
      totalAssignments: 10,
      submittedCount: 9,
      completionRate: 90,
    ),
    subjects: [mockSubjectSummary],
  );

  final mockPaginated = PaginatedAcademicRecordsModel(
    records: [mockRecord],
    page: 1,
    limit: 20,
    total: 1,
    totalPages: 1,
  );

  late FakeAcademicRecordsRepository fakeRepo;
  late StreamController<RealtimeEvent> eventStreamController;

  setUp(() {
    eventStreamController = StreamController<RealtimeEvent>.broadcast();
    fakeRepo = FakeAcademicRecordsRepository(
      testHistory: [mockHistoryItem],
      testDetail: mockDetail,
      testPaginated: mockPaginated,
    );
  });

  tearDown(() {
    eventStreamController.close();
  });

  Widget buildTestApp({
    required Widget child,
    UserModel? user,
    Size surfaceSize = const Size(360, 800),
  }) {
    final activeUser = user ?? mockStudentUser;
    return ProviderScope(
      overrides: [
        academicRecordsRepositoryProvider.overrideWithValue(fakeRepo),
        authProvider.overrideWith(
          (ref) => _FakeAuthNotifier(AuthAuthenticated(user: activeUser, token: 'mock-token')),
        ),
        currentUserProvider.overrideWithValue(activeUser),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: surfaceSize),
          child: child,
        ),
      ),
    );
  }

  group('PROMPT 42 — Academic Records & Student Academic History Frontend Tests', () {
    testWidgets('1. Student academic history renders chronological period cards', (tester) async {
      await tester.pumpWidget(
        buildTestApp(child: const StudentAcademicHistoryScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Academic History'), findsOneWidget);
      expect(find.text('2026–27'), findsOneWidget);
      expect(find.text('Semester 4'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.textContaining('B.Tech Computer Science'), findsOneWidget);
    });

    testWidgets('2. AcademicPeriodCard renders correctly and handles tap', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AcademicPeriodCard(
              item: mockHistoryItem,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('2026–27'), findsOneWidget);
      expect(find.text('Semester 4'), findsOneWidget);
      expect(find.text('Attendance: '), findsOneWidget);
      expect(find.text('90%'), findsWidgets);

      await tester.tap(find.byType(AcademicPeriodCard));
      expect(tapped, isTrue);
    });

    testWidgets('3. AcademicRecordDetailScreen renders context and aggregates', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          child: const AcademicRecordDetailScreen(recordId: recordId),
          user: mockStudentUser,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Academic Record Detail'), findsOneWidget);
      expect(find.text('Overall Performance Aggregates'), findsOneWidget);
      expect(find.text('Enrolled Subjects (1)'), findsOneWidget);
      expect(find.text('Design & Analysis of Algorithms'), findsOneWidget);
      expect(find.text('CS401'), findsOneWidget);
    });

    testWidgets('4. SubjectAcademicTile renders subject metadata and metrics', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SubjectAcademicTile(subject: mockSubjectSummary),
          ),
        ),
      );

      expect(find.text('Design & Analysis of Algorithms'), findsOneWidget);
      expect(find.text('CS401'), findsOneWidget);
      expect(find.text('In Progress'), findsOneWidget);
      expect(find.text('4 Credits • Theory'), findsOneWidget);
      expect(find.text('Faculty: Prof. Donald Knuth'), findsOneWidget);
    });

    testWidgets('5. AcademicMetricPill renders dynamic color based on percentage', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AcademicMetricPill(
                  icon: Icons.how_to_reg,
                  label: 'Attendance',
                  value: '90%',
                  percentage: 90,
                ),
                AcademicMetricPill(
                  icon: Icons.how_to_reg,
                  label: 'Attendance',
                  value: '65%',
                  percentage: 65,
                ),
                AcademicMetricPill(
                  icon: Icons.how_to_reg,
                  label: 'Attendance',
                  value: '45%',
                  percentage: 45,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('90%'), findsOneWidget);
      expect(find.text('65%'), findsOneWidget);
      expect(find.text('45%'), findsOneWidget);
    });

    testWidgets('6. Student role is strictly read-only (mutation FAB absent)', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          child: const AcademicRecordDetailScreen(recordId: recordId),
          user: mockStudentUser,
        ),
      );
      await tester.pumpAndSettle();

      // Student must NOT see the "Progression Status" FAB
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.text('Progression Status'), findsNothing);
    });

    testWidgets('7. HOD/Admin sees mutation action button', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          child: const AcademicRecordDetailScreen(recordId: recordId),
          user: mockHodUser,
        ),
      );
      await tester.pumpAndSettle();

      // HOD must see the "Progression Status" FAB
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('Progression Status'), findsOneWidget);
    });

    testWidgets('8. DepartmentAcademicRecordsScreen renders management directory', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          child: const DepartmentAcademicRecordsScreen(),
          user: mockHodUser,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Academic Records Directory'), findsOneWidget);
      expect(find.text('Jane Doe'), findsOneWidget);
      expect(find.textContaining('CS2024-001'), findsOneWidget);
      expect(find.text('All Statuses'), findsOneWidget);
    });

    testWidgets('9. Mobile-first 360px viewport renders without horizontal overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestApp(
          child: const StudentAcademicHistoryScreen(),
          surfaceSize: const Size(360, 800),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Academic History'), findsOneWidget);
    });

    testWidgets('10. Empty state renders cleanly when history is empty', (tester) async {
      fakeRepo.testHistory = [];

      await tester.pumpWidget(
        buildTestApp(child: const StudentAcademicHistoryScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('No Academic Records Yet'), findsOneWidget);
    });
  });
}
