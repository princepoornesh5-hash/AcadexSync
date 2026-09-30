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
import 'package:campus_management/features/requests/presentation/widgets/response_dialog.dart';
import 'package:campus_management/features/notifications/domain/models/announcement_model.dart';
import 'package:campus_management/features/notifications/domain/models/notification_models.dart';
import 'package:campus_management/features/notifications/presentation/screens/announcement_list_screen.dart';
import 'package:campus_management/features/notifications/presentation/providers/notification_providers.dart';
import 'package:campus_management/features/notifications/data/repositories/api_notification_repository.dart';

class _FakeAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _FakeAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakePrompt47RequestsRepo implements RequestsRepository {
  final List<RequestModel> requests;
  final RequestSummaryCounts counts;

  FakePrompt47RequestsRepo({
    this.requests = const [],
    this.counts = const RequestSummaryCounts(myPendingCount: 2, incomingCount: 1),
  });

  @override
  Future<List<RequestModel>> getMyRequests({
    RequestStatus? status,
    String? requestType,
    int page = 1,
    int limit = 50,
  }) async {
    if (status != null) {
      return requests.where((r) => r.status == status).toList();
    }
    return requests;
  }

  @override
  Future<List<RequestModel>> getIncomingRequests({
    RequestStatus? status,
    String? requestType,
    int page = 1,
    int limit = 50,
  }) async {
    return requests;
  }

  @override
  Future<RequestSummaryCounts> getSummaryCounts() async => counts;

  @override
  Future<RequestModel?> getRequestById(String id) async {
    return requests.where((r) => r.id == id).firstOrNull;
  }

  @override
  Future<RequestModel> createRequest({
    required RequestType requestType,
    String? title,
    required String description,
    AcademicContextModel? academicContext,
    RequestDetailsModel? details,
    String? status,
    String? relatedEntityType,
    String? relatedEntityId,
  }) async {
    return RequestModel(
      id: 'req_created_p47',
      requestId: 'REQ-2026-0047',
      collegeId: 'college_01',
      requesterUserId: 'user_student_1',
      requesterName: 'Student Ravi',
      requesterRole: AppRole.student,
      targetRole: AppRole.hod,
      requestType: requestType,
      title: title ?? 'Attendance Correction Request',
      description: description,
      status: status != null ? RequestStatusExtension.fromString(status) : RequestStatus.submitted,
      relatedEntityType: relatedEntityType,
      relatedEntityId: relatedEntityId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<RequestModel> submitRequest(String id) async {
    final existing = await getRequestById(id);
    return existing ??
        RequestModel(
          id: id,
          requestId: 'REQ-2026-0047',
          collegeId: 'college_01',
          requesterUserId: 'user_student_1',
          requesterName: 'Student Ravi',
          requesterRole: AppRole.student,
          targetRole: AppRole.hod,
          requestType: RequestType.attendanceCorrection,
          title: 'Submitted Request',
          description: 'Submitted from draft',
          status: RequestStatus.submitted,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
  }

  @override
  Future<RequestModel> cancelRequest(String id, {String? reason}) async {
    final existing = await getRequestById(id);
    return existing ??
        RequestModel(
          id: id,
          requestId: 'REQ-2026-0047',
          collegeId: 'college_01',
          requesterUserId: 'user_student_1',
          requesterName: 'Student Ravi',
          requesterRole: AppRole.student,
          targetRole: AppRole.hod,
          requestType: RequestType.leave,
          title: 'Cancelled Request',
          description: reason ?? 'Cancelled',
          status: RequestStatus.cancelled,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
  }

  @override
  Future<RequestModel> startReview(String id) async {
    final existing = await getRequestById(id);
    return existing ??
        RequestModel(
          id: id,
          requestId: 'REQ-2026-0047',
          collegeId: 'college_01',
          requesterUserId: 'user_student_1',
          requesterName: 'Student Ravi',
          requesterRole: AppRole.student,
          targetRole: AppRole.hod,
          requestType: RequestType.leave,
          title: 'In Review Request',
          description: 'Under review',
          status: RequestStatus.inReview,
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
      requestId: 'REQ-2026-0047',
      collegeId: 'college_01',
      requesterUserId: 'user_student_1',
      requesterName: 'Student Ravi',
      requesterRole: AppRole.student,
      targetRole: AppRole.hod,
      requestType: RequestType.attendanceCorrection,
      title: 'Correction Request',
      description: 'Missed scan',
      status: status,
      responseMessage: message,
      respondedAt: DateTime.now(),
      respondedByName: 'Prof. Sharma',
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
      requestId: 'REQ-2026-0047',
      collegeId: 'college_01',
      requesterUserId: 'user_student_1',
      requesterName: 'Student Ravi',
      requesterRole: AppRole.student,
      targetRole: AppRole.hod,
      requestType: RequestType.leave,
      title: 'Leave',
      description: 'Medical',
      status: status,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}

class FakePrompt47NotifRepo implements ApiNotificationRepository {
  final List<AnnouncementModel> announcements;

  FakePrompt47NotifRepo({this.announcements = const []});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<AnnouncementModel>> fetchAnnouncements({
    bool manage = false,
    String? status,
    String? audienceScope,
    String? departmentId,
    int page = 1,
    int limit = 50,
  }) async {
    if (status != null) {
      return announcements.where((a) => a.status.apiValue == status).toList();
    }
    return announcements;
  }

  @override
  Future<AnnouncementModel?> getAnnouncementById(String id) async {
    return announcements.where((a) => a.id == id).firstOrNull;
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

  final testAttendanceRequest = RequestModel(
    id: 'req_att_01',
    requestId: 'REQ-2026-001',
    collegeId: 'college_01',
    departmentId: 'dept_01',
    requesterUserId: 'user_student_1',
    requesterName: 'Ravi Kumar',
    requesterRole: AppRole.student,
    targetRole: AppRole.faculty,
    targetUserId: 'user_faculty_1',
    targetName: 'Prof. Sharma',
    requestType: RequestType.attendanceCorrection,
    title: 'Attendance Correction for Session 3',
    description: 'Present in class but biometric device was offline during slot.',
    relatedEntityType: 'AttendanceSession',
    relatedEntityId: 'session_9988',
    status: RequestStatus.submitted,
    history: [
      RequestAuditEntryModel(
        status: RequestStatus.draft,
        changedByName: 'Ravi Kumar',
        note: 'Draft initialized',
        timestamp: DateTime(2026, 9, 28, 9, 0),
      ),
      RequestAuditEntryModel(
        status: RequestStatus.submitted,
        changedByName: 'Ravi Kumar',
        note: 'Submitted for faculty verification',
        timestamp: DateTime(2026, 9, 28, 9, 15),
      ),
    ],
    createdAt: DateTime(2026, 9, 28, 9, 0),
    updatedAt: DateTime(2026, 9, 28, 9, 15),
  );

  final testAnnouncement = AnnouncementModel(
    id: 'ann_01',
    collegeId: 'college_01',
    departmentId: 'dept_01',
    createdBy: 'user_faculty_1',
    title: 'Lab Schedule Update for CSE Section A',
    body: 'The DBMS Practical session has been rescheduled to Thursday at 2:00 PM in Lab 3.',
    audienceScope: AnnouncementAudienceScope.section,
    targetSectionId: 'sec_01',
    category: 'academic',
    priority: NotificationPriority.high,
    status: AnnouncementStatus.published,
    publishAt: DateTime(2026, 9, 28, 8, 0),
    publishedAt: DateTime(2026, 9, 28, 8, 0),
    recipientCount: 45,
    createdAt: DateTime(2026, 9, 28, 8, 0),
    updatedAt: DateTime(2026, 9, 28, 8, 0),
  );

  Widget createTestWidget({
    required Widget child,
    required UserModel currentUser,
    RequestsRepository? requestsRepo,
    ApiNotificationRepository? notifRepo,
    double width = 360.0,
    double height = 800.0,
  }) {
    return ProviderScope(
      key: ValueKey(currentUser.id),
      overrides: [
        authProvider.overrideWith(
          (ref) => _FakeAuthNotifier(AuthAuthenticated(user: currentUser, token: 'mock_jwt_token')),
        ),
        if (requestsRepo != null) requestsRepositoryProvider.overrideWithValue(requestsRepo),
        if (notifRepo != null) apiNotificationRepositoryProvider.overrideWithValue(notifRepo),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: Size(width, height)),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: SizedBox(
              width: width,
              height: height,
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  group('Prompt 47 - Request Domain & Lifecycle State Transitions', () {
    test('1. RequestStatus maps correctly across entire lifecycle', () {
      expect(RequestStatusExtension.fromString('DRAFT'), RequestStatus.draft);
      expect(RequestStatusExtension.fromString('SUBMITTED'), RequestStatus.submitted);
      expect(RequestStatusExtension.fromString('IN_REVIEW'), RequestStatus.inReview);
      expect(RequestStatusExtension.fromString('UNDER_REVIEW'), RequestStatus.inReview);
      expect(RequestStatusExtension.fromString('APPROVED'), RequestStatus.approved);
      expect(RequestStatusExtension.fromString('REJECTED'), RequestStatus.rejected);
      expect(RequestStatusExtension.fromString('RESOLVED'), RequestStatus.resolved);
      expect(RequestStatusExtension.fromString('CANCELLED'), RequestStatus.cancelled);
      expect(RequestStatusExtension.fromString('CLOSED'), RequestStatus.closed);

      expect(RequestStatus.draft.value, 'DRAFT');
      expect(RequestStatus.inReview.value, 'IN_REVIEW');
      expect(RequestStatus.cancelled.value, 'CANCELLED');
    });

    test('2. AnnouncementStatus maps correctly across entire lifecycle', () {
      expect(AnnouncementStatus.fromString('DRAFT'), AnnouncementStatus.draft);
      expect(AnnouncementStatus.fromString('SCHEDULED'), AnnouncementStatus.scheduled);
      expect(AnnouncementStatus.fromString('PUBLISHED'), AnnouncementStatus.published);
      expect(AnnouncementStatus.fromString('EXPIRED'), AnnouncementStatus.expired);
      expect(AnnouncementStatus.fromString('CANCELLED'), AnnouncementStatus.cancelled);
      expect(AnnouncementStatus.fromString('ARCHIVED'), AnnouncementStatus.archived);

      expect(AnnouncementStatus.scheduled.apiValue, 'SCHEDULED');
      expect(AnnouncementStatus.cancelled.apiValue, 'CANCELLED');
      expect(AnnouncementStatus.expired.apiValue, 'EXPIRED');
    });

    test('3. RequestModel serializes and deserializes relatedEntityType and relatedEntityId', () {
      final json = testAttendanceRequest.toJson();
      expect(json['relatedEntityType'], 'AttendanceSession');
      expect(json['relatedEntityId'], 'session_9988');

      final reconstructed = RequestModel.fromJson(json);
      expect(reconstructed.relatedEntityType, 'AttendanceSession');
      expect(reconstructed.relatedEntityId, 'session_9988');
      expect(reconstructed.status, RequestStatus.submitted);
      expect(reconstructed.history.length, 2);
    });

    test('4. Strict Domain Separation: Request vs Announcement', () {
      // Request is actionable review/requester workflow
      expect(testAttendanceRequest.requesterUserId, isNotEmpty);
      expect(testAttendanceRequest.targetRole, AppRole.faculty);
      expect(testAttendanceRequest.status, RequestStatus.submitted);

      // Announcement is broadcast communication
      expect(testAnnouncement.audienceScope, AnnouncementAudienceScope.section);
      expect(testAnnouncement.targetSectionId, 'sec_01');
      expect(testAnnouncement.recipientCount, 45);
    });
  });

  group('Prompt 47 - Mobile UI 360px Overflow & Widget Validation', () {
    testWidgets('5. RequestCenterScreen renders cleanly at 360px width without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final fakeRepo = FakePrompt47RequestsRepo(requests: [testAttendanceRequest]);

      await tester.pumpWidget(
        createTestWidget(
          child: const RequestCenterScreen(),
          currentUser: studentUser,
          requestsRepo: fakeRepo,
          width: 360,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Request Center'), findsOneWidget);
      expect(find.text('Attendance Correction for Session 3'), findsOneWidget);
      expect(find.text('Draft'), findsOneWidget);
      expect(find.text('Submitted'), findsWidgets);
      expect(find.text('Under Review'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('6. NewRequestScreen renders Save Draft and Submit Request buttons at 360px without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final fakeRepo = FakePrompt47RequestsRepo();

      await tester.pumpWidget(
        createTestWidget(
          child: const NewRequestScreen(initialType: RequestType.attendanceCorrection),
          currentUser: studentUser,
          requestsRepo: fakeRepo,
          width: 360,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('New Request'), findsOneWidget);
      expect(find.text('Save Draft'), findsOneWidget);
      expect(find.text('Submit Request'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('7. RequestDetailScreen displays timeline and responder actions at 360px without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final fakeRepo = FakePrompt47RequestsRepo(requests: [testAttendanceRequest]);

      await tester.pumpWidget(
        createTestWidget(
          child: const RequestDetailScreen(requestId: 'req_att_01'),
          currentUser: facultyUser,
          requestsRepo: fakeRepo,
          width: 360,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Request Details'), findsOneWidget);
      expect(find.text('Timeline & History'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('Approve / Resolve'), 300);
      await tester.pumpAndSettle();

      expect(find.text('Mark In Review'), findsOneWidget);
      expect(find.text('Approve / Resolve'), findsOneWidget);
      expect(find.text('Reject'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('8. ResponseDialog validates minimum 5-character rejection reason', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final fakeRepo = FakePrompt47RequestsRepo(requests: [testAttendanceRequest]);

      await tester.pumpWidget(
        createTestWidget(
          child: const Scaffold(
            body: ResponseDialog(
              requestId: 'req_att_01',
              initialAction: 'REJECTED',
            ),
          ),
          currentUser: facultyUser,
          requestsRepo: fakeRepo,
          width: 360,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Respond to Request'), findsOneWidget);
      expect(find.text('Reject'), findsOneWidget);

      // Clear text field to make reason too short (< 5 chars)
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);
      await tester.enterText(textField, 'No');
      await tester.pumpAndSettle();

      // Tap confirm decision
      final confirmBtn = find.text('Confirm Decision');
      expect(confirmBtn, findsOneWidget);
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // Should show validation error snackbar
      expect(find.text('Please provide a rejection reason (at least 5 characters).'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('9. Student cannot author announcements while Faculty can author', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final notifRepo = FakePrompt47NotifRepo(announcements: [testAnnouncement]);

      // 1. As Student: Create Announcement button is NOT visible
      await tester.pumpWidget(
        createTestWidget(
          child: const AnnouncementListScreen(),
          currentUser: studentUser,
          notifRepo: notifRepo,
          width: 360,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Announcements'), findsOneWidget);
      expect(find.text('Create Announcement'), findsNothing);

      // 2. As Faculty: Create Announcement button IS visible
      await tester.pumpWidget(
        createTestWidget(
          child: const AnnouncementListScreen(),
          currentUser: facultyUser,
          notifRepo: notifRepo,
          width: 360,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Create Announcement'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
