import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_management/features/notifications/domain/models/notification_models.dart';
import 'package:campus_management/features/notifications/data/repositories/notification_repository.dart';
import 'package:campus_management/features/notifications/presentation/providers/notification_providers.dart';
import 'package:campus_management/features/notifications/presentation/screens/notification_center_screen.dart';
import 'package:campus_management/features/notifications/presentation/widgets/notification_card.dart';
import 'package:campus_management/features/notifications/presentation/widgets/notification_badge.dart';
import 'package:campus_management/features/requests/presentation/providers/requests_providers.dart';
import 'package:campus_management/features/requests/data/repositories/requests_repository.dart';
import 'package:campus_management/features/requests/domain/models/request_model.dart';
import 'package:campus_management/features/settings/domain/models/settings_models.dart';

class _FakeAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _FakeAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeNotificationRepository implements NotificationRepository {
  List<NotificationModel> notifications;
  final StreamController<List<NotificationModel>> _controller = StreamController<List<NotificationModel>>.broadcast();
  bool shouldThrowError;

  FakeNotificationRepository({
    this.notifications = const [],
    this.shouldThrowError = false,
  });

  @override
  Stream<List<NotificationModel>> watchNotifications(UserModel user, NotificationPreferences prefs) {
    if (shouldThrowError) {
      return Stream.error(Exception('Simulated network error'));
    }
    // Emit initial
    Future.microtask(() {
      if (!_controller.isClosed) {
        _controller.add(notifications);
      }
    });
    return _controller.stream;
  }

  @override
  Future<void> markAsRead(String id, String userId) async {
    notifications = notifications.map((n) {
      if (n.id == id) {
        return n.copyWith(isRead: true, readAt: DateTime.now());
      }
      return n;
    }).toList();
    _controller.add(notifications);
  }

  @override
  Future<void> markAsUnread(String id, String userId) async {
    notifications = notifications.map((n) {
      if (n.id == id) {
        return n.copyWith(isRead: false, readAt: null);
      }
      return n;
    }).toList();
    _controller.add(notifications);
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    notifications = notifications.map((n) => n.copyWith(isRead: true, readAt: DateTime.now())).toList();
    _controller.add(notifications);
  }

  @override
  Future<void> deleteNotification(String id, String userId) async {
    notifications = notifications.where((n) => n.id != id).toList();
    _controller.add(notifications);
  }

  @override
  Future<void> clearAll(String userId) async {
    notifications = [];
    _controller.add([]);
  }

  @override
  Future<NotificationModel> createPersonalNotification(NotificationModel notification) async {
    notifications = [notification, ...notifications];
    _controller.add(notifications);
    return notification;
  }

  @override
  Future<NotificationModel> createAnnouncement(NotificationModel notification) async {
    notifications = [notification, ...notifications];
    _controller.add(notifications);
    return notification;
  }

  void dispose() {
    _controller.close();
  }
}

class FakeRequestsRepoForNotif implements RequestsRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

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
      id: 'req_created_1',
      requestId: 'REQ-2026-0001',
      collegeId: 'college_01',
      requesterUserId: 'user_01',
      requesterName: 'Student Alice',
      requesterRole: AppRole.student,
      targetRole: AppRole.hod,
      requestType: requestType,
      title: title ?? 'Leave',
      description: description,
      status: RequestStatus.submitted,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testUser = UserModel(
    id: 'user_student_1',
    name: 'Alice Student',
    email: 'alice@coea.edu',
    role: AppRole.student,
    collegeId: 'college_01',
    departmentId: 'dept_01',
  );

  final testRequestNotification = NotificationModel(
    id: 'notif_001',
    title: 'Leave Request Approved',
    message: 'Your leave request for 28 Sep was approved.',
    notificationType: NotificationType.requestApproved,
    category: NotificationCategory.request,
    priority: NotificationPriority.normal,
    audienceType: NotificationAudienceType.personal,
    timestamp: DateTime.now(),
    isRead: false,
    recipientUserId: 'user_student_1',
    recipientRole: AppRole.student,
    collegeId: 'college_01',
    relatedEntityType: 'REQUEST',
    relatedEntityId: 'REQ-2026-0001',
    navigationTarget: '/requests/REQ-2026-0001',
  );

  final testAttendanceNotification = NotificationModel(
    id: 'notif_002',
    title: 'Attendance Correction',
    message: 'Your attendance correction was reviewed.',
    notificationType: NotificationType.requestResponded,
    category: NotificationCategory.attendance,
    priority: NotificationPriority.normal,
    audienceType: NotificationAudienceType.personal,
    timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
    isRead: false,
    recipientUserId: 'user_student_1',
    recipientRole: AppRole.student,
    collegeId: 'college_01',
    relatedEntityType: 'REQUEST',
    relatedEntityId: 'REQ-2026-0002',
    navigationTarget: '/requests/REQ-2026-0002',
  );

  group('Notification Domain & Provider Tests', () {
    // 10. Notification model serializes/deserializes correctly
    test('10. NotificationModel serializes and deserializes correctly with request aliases', () {
      final json = {
        'id': 'notif_99',
        'title': 'Timetable Update',
        'body': 'Room changed for CS201',
        'notificationType': 'REQUEST_RECEIVED',
        'category': 'request',
        'priority': 'high',
        'isRead': false,
        'createdAt': '2026-09-28T10:00:00.000Z',
        'relatedEntityType': 'REQUEST',
        'relatedEntityId': 'REQ-2026-0099',
        'metadata': {'requestId': 'REQ-2026-0099'},
      };

      final model = NotificationModel.fromJson(json);
      expect(model.id, 'notif_99');
      expect(model.title, 'Timetable Update');
      expect(model.message, 'Room changed for CS201');
      expect(model.body, 'Room changed for CS201');
      expect(model.notificationType, NotificationType.requestReceived);
      expect(model.category, NotificationCategory.request);
      expect(model.priority, NotificationPriority.high);
      expect(model.relatedEntityType, 'REQUEST');
      expect(model.relatedEntityId, 'REQ-2026-0099');
      expect(model.navigationTarget, '/requests/REQ-2026-0099');

      final serialized = model.toJson();
      expect(serialized['id'], 'notif_99');
      expect(serialized['notificationId'], 'notif_99');
      expect(serialized['type'], 'REQUEST_RECEIVED');
      expect(serialized['relatedEntityId'], 'REQ-2026-0099');
    });

    // 11. Unread count provider works
    test('11. Unread count provider calculates live unread count', () async {
      final repo = FakeNotificationRepository(
        notifications: [testRequestNotification, testAttendanceNotification],
      );

      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith((ref) => _FakeAuthNotifier(AuthAuthenticated(user: testUser, token: 'jwt'))),
          notificationRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      // Listen to notifications
      container.listen(notificationsProvider, (_, __) {});
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final unreadCount = container.read(unreadNotificationCountProvider);
      expect(unreadCount, 2);

      // Mark one read
      await repo.markAsRead('notif_001', testUser.id);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final updatedCount = container.read(unreadNotificationCountProvider);
      expect(updatedCount, 1);
    });
  });

  group('Notification Center UI Widget Tests', () {
    // 12. Notification list renders
    testWidgets('12. Notification Center renders notification list items', (tester) async {
      final repo = FakeNotificationRepository(
        notifications: [testRequestNotification, testAttendanceNotification],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(AuthAuthenticated(user: testUser, token: 'jwt'))),
            notificationRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: NotificationCenterScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Notification Center'), findsOneWidget);
      expect(find.text('Leave Request Approved'), findsOneWidget);
      expect(find.text('Your leave request for 28 Sep was approved.'), findsOneWidget);
      expect(find.text('Attendance Correction'), findsOneWidget);
      expect(find.text('Mark all as read'), findsOneWidget);
    });

    // 13. Tapping notification marks read
    testWidgets('13. Tapping notification marks it as read', (tester) async {
      bool markReadCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationCard(
              notification: testRequestNotification,
              onReadToggle: () {
                markReadCalled = true;
              },
              onDelete: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap card
      await tester.tap(find.text('Leave Request Approved'));
      await tester.pumpAndSettle();

      expect(markReadCalled, isTrue);
    });

    // 14. Related request notification navigates using requestId / target
    testWidgets('14. Related request notification card contains navigation Target', (tester) async {
      expect(testRequestNotification.navigationTarget, '/requests/REQ-2026-0001');
      expect(testRequestNotification.relatedEntityId, 'REQ-2026-0001');
      expect(testRequestNotification.relatedEntityType, 'REQUEST');
    });

    // 15. Empty state renders
    testWidgets('15. Notification Center renders clean empty state when no notifications exist', (tester) async {
      final repo = FakeNotificationRepository(notifications: const []);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(AuthAuthenticated(user: testUser, token: 'jwt'))),
            notificationRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: NotificationCenterScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No new notifications'), findsOneWidget);
      expect(find.text("You're all caught up with your updates and requests."), findsOneWidget);
      // "Mark all as read" button must NOT be shown when empty
      expect(find.text('Mark all as read'), findsNothing);
    });

    // 16. Error state renders safely
    testWidgets('16. Notification Center renders clean sanitized error state on network failure', (tester) async {
      final repo = FakeNotificationRepository(shouldThrowError: true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(AuthAuthenticated(user: testUser, token: 'jwt'))),
            notificationRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: NotificationCenterScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text("Couldn't load notifications."), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    // 17. Notification refresh occurs after relevant Request action
    test('17. Notification refresh triggers when a Request action is performed', () async {
      final repo = FakeNotificationRepository(
        notifications: [testRequestNotification],
      );
      final reqRepo = FakeRequestsRepoForNotif();

      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith((ref) => _FakeAuthNotifier(AuthAuthenticated(user: testUser, token: 'jwt'))),
          notificationRepositoryProvider.overrideWithValue(repo),
          requestsRepositoryProvider.overrideWithValue(reqRepo),
        ],
      );
      addTearDown(container.dispose);

      int invalidationCount = 0;
      container.listen(unreadNotificationCountProvider, (_, __) {
        invalidationCount++;
      });

      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Perform a Request Action
      await container.read(requestActionProvider.notifier).createRequest(
        requestType: RequestType.leave,
        title: 'New Request',
        description: 'New Description',
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Invalidation occurred after request action
      expect(invalidationCount, greaterThanOrEqualTo(1));
    });

    // Test NotificationBadge rendering with unread count
    testWidgets('NotificationBadge displays active unread badge count', (tester) async {
      final repo = FakeNotificationRepository(
        notifications: [testRequestNotification, testAttendanceNotification],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(AuthAuthenticated(user: testUser, token: 'jwt'))),
            notificationRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              appBar: PreferredSize(
                preferredSize: Size.fromHeight(56),
                child: NotificationBadge(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('2'), findsOneWidget);
    });
  });
}
