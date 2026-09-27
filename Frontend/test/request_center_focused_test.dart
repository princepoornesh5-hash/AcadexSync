import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_management/features/requests/domain/models/request_model.dart';
import 'package:campus_management/features/requests/data/repositories/requests_repository.dart';
import 'package:campus_management/features/requests/presentation/providers/requests_providers.dart';
import 'package:campus_management/features/requests/presentation/screens/request_center_screen.dart';
import 'package:campus_management/features/requests/presentation/screens/new_request_screen.dart';
import 'package:campus_management/features/requests/presentation/screens/request_detail_screen.dart';
import 'package:campus_management/features/requests/presentation/widgets/dashboard_request_card.dart';

class _FakeAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _FakeAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeRequestsRepository implements RequestsRepository {
  final List<RequestModel> myRequests;
  final List<RequestModel> incomingRequests;
  final RequestSummaryCounts counts;

  FakeRequestsRepository({
    this.myRequests = const [],
    this.incomingRequests = const [],
    this.counts = const RequestSummaryCounts(),
  });

  @override
  Future<List<RequestModel>> getMyRequests({
    RequestStatus? status,
    String? requestType,
    int page = 1,
    int limit = 50,
  }) async {
    return myRequests;
  }

  @override
  Future<List<RequestModel>> getIncomingRequests({
    RequestStatus? status,
    String? requestType,
    int page = 1,
    int limit = 50,
  }) async {
    return incomingRequests;
  }

  @override
  Future<RequestSummaryCounts> getSummaryCounts() async {
    return counts;
  }

  @override
  Future<RequestModel?> getRequestById(String id) async {
    final all = [...myRequests, ...incomingRequests];
    return all.where((r) => r.id == id).firstOrNull;
  }

  @override
  Future<RequestModel> createRequest({
    required RequestType requestType,
    String? title,
    required String description,
    AcademicContextModel? academicContext,
    RequestDetailsModel? details,
  }) async {
    return RequestModel(
      id: 'req_created_1',
      requestId: 'REQ-2026-0001',
      collegeId: 'college_01',
      requesterUserId: 'user_student_1',
      requesterName: 'Student Ravi',
      requesterRole: AppRole.student,
      targetRole: AppRole.hod,
      requestType: requestType,
      title: title ?? 'Leave Request',
      description: description,
      status: RequestStatus.submitted,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<RequestModel> respondToRequest({
    required String id,
    required String action,
    String? message,
  }) async {
    final status = RequestStatusExtension.fromString(action);
    return RequestModel(
      id: id,
      requestId: 'REQ-2026-0001',
      collegeId: 'college_01',
      requesterUserId: 'user_student_1',
      requesterName: 'Student Ravi',
      requesterRole: AppRole.student,
      targetRole: AppRole.hod,
      requestType: RequestType.leave,
      title: 'Leave Request',
      description: 'Medical leave',
      status: status,
      responseMessage: message,
      respondedAt: DateTime.now(),
      respondedByName: 'Dr. HOD',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<RequestModel> updateStatus({
    required String id,
    required RequestStatus status,
    String? note,
  }) async {
    return RequestModel(
      id: id,
      requestId: 'REQ-2026-0001',
      collegeId: 'college_01',
      requesterUserId: 'user_student_1',
      requesterName: 'Student Ravi',
      requesterRole: AppRole.student,
      targetRole: AppRole.hod,
      requestType: RequestType.leave,
      title: 'Leave Request',
      description: 'Medical leave',
      status: status,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final studentUser = UserModel(
    id: 'user_student_1',
    name: 'Ravi Kumar',
    email: 'ravi@college.edu',
    role: AppRole.student,
    collegeId: 'college_01',
    departmentId: 'dept_01',
  );

  final facultyUser = UserModel(
    id: 'user_faculty_1',
    name: 'Prof. Sharma',
    email: 'sharma@college.edu',
    role: AppRole.faculty,
    collegeId: 'college_01',
    departmentId: 'dept_01',
  );

  final testLeaveRequest = RequestModel(
    id: 'req_001',
    requestId: 'REQ-2026-001',
    collegeId: 'college_01',
    requesterUserId: 'user_student_1',
    requesterName: 'Ravi Kumar',
    requesterRole: AppRole.student,
    targetRole: AppRole.hod,
    targetName: 'HOD Computer Science',
    requestType: RequestType.leave,
    title: 'Medical Leave Request',
    description: 'Need leave for 2 days due to viral fever.',
    academicContext: const AcademicContextModel(
      courseName: 'B.Tech CSE',
      sectionName: 'CSE-A',
    ),
    details: RequestDetailsModel(
      startDate: DateTime(2026, 10, 1),
      endDate: DateTime(2026, 10, 2),
      reason: 'Viral fever',
    ),
    status: RequestStatus.submitted,
    createdAt: DateTime(2026, 9, 28, 10, 0),
    updatedAt: DateTime(2026, 9, 28, 10, 0),
  );

  group('Request Domain & Role Permission Tests', () {
    test('Allowed request types per role are correct', () {
      final studentTypes = RequestTypeExtension.allowedTypesForRole(AppRole.student);
      expect(studentTypes, contains(RequestType.leave));
      expect(studentTypes, contains(RequestType.attendanceCorrection));
      expect(studentTypes, contains(RequestType.academicIssue));
      expect(studentTypes, isNot(contains(RequestType.facultyRequirement)));
      expect(studentTypes, isNot(contains(RequestType.workloadConcern)));

      final facultyTypes = RequestTypeExtension.allowedTypesForRole(AppRole.faculty);
      expect(facultyTypes, contains(RequestType.leave));
      expect(facultyTypes, contains(RequestType.onDuty));
      expect(facultyTypes, contains(RequestType.timetableChange));
      expect(facultyTypes, contains(RequestType.resourceRequest));
      expect(facultyTypes, contains(RequestType.workloadConcern));
      expect(facultyTypes, isNot(contains(RequestType.facultyRequirement)));

      final hodTypes = RequestTypeExtension.allowedTypesForRole(AppRole.hod);
      expect(hodTypes, contains(RequestType.leave));
      expect(hodTypes, contains(RequestType.facultyRequirement));
      expect(hodTypes, contains(RequestType.infrastructureIssue));
      expect(hodTypes, contains(RequestType.academicApproval));
      expect(hodTypes, contains(RequestType.eventWorkshopApproval));
    });

    test('RequestModel serialization to and from JSON', () {
      final json = testLeaveRequest.toJson();
      final parsed = RequestModel.fromJson(json);

      expect(parsed.id, testLeaveRequest.id);
      expect(parsed.requestId, testLeaveRequest.requestId);
      expect(parsed.requestType, RequestType.leave);
      expect(parsed.status, RequestStatus.submitted);
      expect(parsed.requesterName, 'Ravi Kumar');
      expect(parsed.academicContext?.courseName, 'B.Tech CSE');
      expect(parsed.details?.reason, 'Viral fever');
    });

    test('RequestStatus extensions define distinct styling and labels', () {
      expect(RequestStatus.submitted.displayName, 'Submitted');
      expect(RequestStatus.inReview.displayName, 'Under Review');
      expect(RequestStatus.approved.displayName, 'Approved');
      expect(RequestStatus.rejected.displayName, 'Rejected');
      expect(RequestStatus.resolved.displayName, 'Resolved');
      expect(RequestStatus.closed.displayName, 'Closed');
    });
  });

  group('Request Center UI Widget Tests', () {
    testWidgets('Student views Request Center with My Requests list', (tester) async {
      final repo = FakeRequestsRepository(
        myRequests: [testLeaveRequest],
        counts: const RequestSummaryCounts(myPendingCount: 1),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(AuthAuthenticated(user: studentUser, token: 'fake_jwt'))),
            requestsRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: RequestCenterScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Request Center'), findsOneWidget);
      expect(find.text('New Request'), findsOneWidget);
      expect(find.text('Medical Leave Request'), findsOneWidget);
      expect(find.text('Submitted'), findsWidgets);
      // Student should NOT have the "Needs Attention" tab
      expect(find.text('Needs Attention'), findsNothing);
    });

    testWidgets('Faculty views Request Center with both My Requests and Needs Attention tabs', (tester) async {
      final repo = FakeRequestsRepository(
        myRequests: [],
        incomingRequests: [testLeaveRequest],
        counts: const RequestSummaryCounts(incomingCount: 1),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(AuthAuthenticated(user: facultyUser, token: 'fake_jwt'))),
            requestsRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: RequestCenterScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('My Requests'), findsOneWidget);
      expect(find.text('Needs Attention'), findsOneWidget);
    });

    testWidgets('NewRequestScreen renders fields and auto-fills academic context', (tester) async {
      final repo = FakeRequestsRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(AuthAuthenticated(user: studentUser, token: 'fake_jwt'))),
            requestsRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: NewRequestScreen(
              initialType: RequestType.attendanceCorrection,
              initialSubjectName: 'Data Structures',
              initialSectionName: 'CSE-A',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('New Request'), findsOneWidget);
      expect(find.textContaining('Context: Data Structures • CSE-A'), findsOneWidget);
      expect(find.text('Date of Class'), findsOneWidget);
      expect(find.text('Submit Request'), findsOneWidget);
    });

    testWidgets('RequestDetailScreen displays complete metadata and requester close action', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = FakeRequestsRepository(
        myRequests: [testLeaveRequest],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(AuthAuthenticated(user: studentUser, token: 'fake_jwt'))),
            requestsRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: RequestDetailScreen(requestId: 'req_001'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Request Details'), findsOneWidget);
      expect(find.text('Medical Leave Request'), findsNothing); // Title is in description or header
      expect(find.text('Need leave for 2 days due to viral fever.'), findsOneWidget);
      expect(find.text('Cancel Request'), findsOneWidget);
    });

    testWidgets('DashboardRequestCard renders real pending counts', (tester) async {
      final repo = FakeRequestsRepository(
        counts: const RequestSummaryCounts(myPendingCount: 2),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(AuthAuthenticated(user: studentUser, token: 'fake_jwt'))),
            requestsRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: DashboardRequestCard(role: AppRole.student),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('2 requests in progress'), findsOneWidget);
      expect(find.text('Tap to track status and review responses'), findsOneWidget);
    });
  });
}
