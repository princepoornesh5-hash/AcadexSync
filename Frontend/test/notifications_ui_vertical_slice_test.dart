import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';

import 'package:campus_management/features/notifications/domain/models/notification_models.dart';
import 'package:campus_management/features/notifications/presentation/providers/notification_providers.dart';
import 'package:campus_management/features/notifications/presentation/screens/notification_center_screen.dart';
import 'package:campus_management/features/notifications/presentation/widgets/notification_card.dart';
import 'package:campus_management/features/notifications/presentation/widgets/notification_badge.dart';
import 'package:campus_management/features/notifications/data/repositories/mock_notification_repository.dart';
import 'package:campus_management/features/notifications/data/repositories/api_notification_repository.dart';

class _FakeAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _FakeAuthNotifier(super.initial);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('ACADEX Phase 9Q.6 — Notifications UI Vertical Slice Tests', () {
    final sampleNotification1 = NotificationModel(
      id: 'notif_1',
      title: 'Low Attendance Warning',
      message: 'Your attendance in Algorithms (CS601) is currently 72%. Minimum required is 75%.',
      category: NotificationCategory.attendance,
      priority: NotificationPriority.critical,
      audienceType: NotificationAudienceType.personal,
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      isRead: false,
      navigationTarget: '/attendance',
    );

    final sampleNotification2 = NotificationModel(
      id: 'notif_2',
      title: 'New Study Note Uploaded',
      message: 'Dr. Sarah Connor published Dynamic Programming & Memoization for Section A.',
      category: NotificationCategory.notes,
      priority: NotificationPriority.normal,
      audienceType: NotificationAudienceType.section,
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      isRead: true,
      navigationTarget: '/notes/note_1',
    );

    testWidgets('1. NotificationCenterScreen renders with title, filter bar, and notification items', (tester) async {
      final studentUser = UserModel(
        id: 'student_1',
        name: 'Arjun Verma',
        email: 'arjun@acadex.edu',
        role: AppRole.student,
        collegeId: 'col_123',
        departmentId: 'dept_cse',
        sectionId: 'sec_a',
        accountStatus: AccountStatus.active,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(
              (ref) => _FakeAuthNotifier(AuthAuthenticated(user: studentUser, token: 'fake-token')),
            ),
            notificationsProvider.overrideWith(
              () => _FakeNotificationsNotifier([sampleNotification1, sampleNotification2]),
            ),
          ],
          child: const MaterialApp(
            home: NotificationCenterScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Notification Center'), findsOneWidget);
      expect(find.text('Mark all read'), findsOneWidget);
      expect(find.text('Low Attendance Warning'), findsOneWidget);
      expect(find.text('New Study Note Uploaded'), findsOneWidget);
      // Student shouldn't see New Announcement FAB
      expect(find.text('New Announcement'), findsNothing);
    });

    testWidgets('2. Admin sees NotificationCenterScreen with New Announcement FAB', (tester) async {
      final adminUser = UserModel(
        id: 'admin_1',
        name: 'Dean Sharma',
        email: 'admin@acadex.edu',
        role: AppRole.collegeAdmin,
        collegeId: 'col_123',
        accountStatus: AccountStatus.active,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(
              (ref) => _FakeAuthNotifier(AuthAuthenticated(user: adminUser, token: 'fake-token')),
            ),
            notificationsProvider.overrideWith(
              () => _FakeNotificationsNotifier([sampleNotification1]),
            ),
          ],
          child: const MaterialApp(
            home: NotificationCenterScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('New Announcement'), findsOneWidget);
    });

    testWidgets('3. NotificationBadge displays unread count correctly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationsProvider.overrideWith(
              () => _FakeNotificationsNotifier([sampleNotification1, sampleNotification2]),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: NotificationBadge(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // sampleNotification1 is unread, sampleNotification2 is read -> unread count = 1
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('4. NotificationCard renders title, message, and view details link', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationCard(
              notification: sampleNotification1,
              onReadToggle: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Low Attendance Warning'), findsOneWidget);
      expect(find.textContaining('Your attendance in Algorithms'), findsOneWidget);
      expect(find.text('View details'), findsOneWidget);
    });

    testWidgets('5. NotificationCenterScreen renders empty state when no notifications', (tester) async {
      final studentUser = UserModel(
        id: 'student_1',
        name: 'Arjun Verma',
        email: 'arjun@acadex.edu',
        role: AppRole.student,
        collegeId: 'col_123',
        departmentId: 'dept_cse',
        sectionId: 'sec_a',
        accountStatus: AccountStatus.active,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(
              (ref) => _FakeAuthNotifier(AuthAuthenticated(user: studentUser, token: 'fake-token')),
            ),
            notificationsProvider.overrideWith(
              () => _FakeNotificationsNotifier([]),
            ),
          ],
          child: const MaterialApp(
            home: NotificationCenterScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('All caught up!'), findsOneWidget);
      expect(find.text("You don't have any notifications right now."), findsOneWidget);
    });

    testWidgets('6. ApiNotificationRepository can instantiate and load mock notifications', (tester) async {
      final repo = ApiNotificationRepository();
      expect(repo, isA<ApiNotificationRepository>());

      final mockRepo = mockNotificationRepo;
      expect(mockRepo, isNotNull);
    });
  });
}

class _FakeNotificationsNotifier extends NotificationsNotifier {
  final List<NotificationModel> _notifications;
  _FakeNotificationsNotifier(this._notifications);

  @override
  Stream<List<NotificationModel>> build() {
    return Stream.value(_notifications);
  }

  @override
  Future<void> markAllAsRead() async {}

  @override
  Future<void> markAsRead(String id) async {}

  @override
  Future<void> markAsUnread(String id) async {}

  @override
  Future<void> deleteNotification(String id) async {}
}
