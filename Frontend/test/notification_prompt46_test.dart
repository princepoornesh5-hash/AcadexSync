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
import 'package:campus_management/features/notifications/presentation/screens/notification_preferences_screen.dart';
import 'package:campus_management/features/settings/domain/models/settings_models.dart';
import 'package:campus_management/features/settings/presentation/providers/settings_providers.dart';
import 'package:campus_management/features/settings/domain/repositories/settings_repository.dart';

class _FakeAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _FakeAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeNotificationRepository implements NotificationRepository {
  List<NotificationModel> notifications;
  final StreamController<List<NotificationModel>> _controller =
      StreamController<List<NotificationModel>>.broadcast();
  bool shouldThrowError;

  FakeNotificationRepository({
    this.notifications = const [],
    this.shouldThrowError = false,
  });

  @override
  Stream<List<NotificationModel>> watchNotifications(
      UserModel user, NotificationPreferences prefs) {
    if (shouldThrowError) {
      return Stream.error(Exception('Simulated network error'));
    }
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
        return n.copyWith(isRead: true, status: NotificationStatus.read, readAt: DateTime.now());
      }
      return n;
    }).toList();
    _controller.add(notifications);
  }

  @override
  Future<void> markAsUnread(String id, String userId) async {
    notifications = notifications.map((n) {
      if (n.id == id) {
        return n.copyWith(isRead: false, status: NotificationStatus.unread, readAt: null);
      }
      return n;
    }).toList();
    _controller.add(notifications);
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    notifications = notifications.map((n) {
      return n.copyWith(isRead: true, status: NotificationStatus.read, readAt: DateTime.now());
    }).toList();
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
    _controller.add(notifications);
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
}

class FakeSettingsRepository implements SettingsRepository {
  NotificationPreferences preferences = NotificationPreferences.defaults();

  @override
  Future<NotificationPreferences> getNotificationPreferences() async {
    return preferences;
  }

  @override
  Future<void> updateNotificationPreferences(NotificationPreferences newPrefs) async {
    preferences = newPrefs;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final testUser = UserModel(
    id: 'user_prompt46',
    email: 'student@acadex.edu',
    name: 'Prompt46 Student',
    role: AppRole.student,
    collegeId: 'college_1',
    createdAt: DateTime.now(),
  );

  Widget createWidgetUnderTest({
    required Widget child,
    required FakeNotificationRepository fakeRepo,
    FakeSettingsRepository? fakeSettingsRepo,
    Size screenSize = const Size(360, 800),
  }) {
    return ProviderScope(
      overrides: [
        authProvider.overrideWith((ref) => _FakeAuthNotifier(AuthAuthenticated(user: testUser, token: 'mock_token'))),
        notificationRepositoryProvider.overrideWithValue(fakeRepo),
        if (fakeSettingsRepo != null)
          settingsRepoProvider.overrideWithValue(fakeSettingsRepo),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: screenSize),
          child: child,
        ),
      ),
    );
  }

  group('PROMPT 46 — Frontend Notification Center & Preferences Tests', () {
    testWidgets('1. Notification Center renders at 360px without overflow', (tester) async {
      final fakeRepo = FakeNotificationRepository(notifications: [
        NotificationModel(
          id: 'notif_1',
          title: 'Assignment Released',
          message: 'Math homework is due on Monday.',
          category: NotificationCategory.assignment,
          priority: NotificationPriority.normal,
          audienceType: NotificationAudienceType.personal,
          timestamp: DateTime.now(),
          isRead: false,
          navigationTarget: '/assignments/asg_1',
        ),
      ]);

      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidgetUnderTest(
        child: const NotificationCenterScreen(),
        fakeRepo: fakeRepo,
        screenSize: const Size(360, 800),
      ));

      await tester.pumpAndSettle();

      expect(find.text('Notification Center'), findsOneWidget);
      expect(find.text('Assignment Released'), findsOneWidget);
      expect(find.text('Math homework is due on Monday.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('2. Unread badge renders correct unread count', (tester) async {
      final fakeRepo = FakeNotificationRepository(notifications: [
        NotificationModel(
          id: 'n1',
          title: 'Unread 1',
          message: 'Body 1',
          category: NotificationCategory.system,
          priority: NotificationPriority.normal,
          audienceType: NotificationAudienceType.personal,
          timestamp: DateTime.now(),
          isRead: false,
        ),
        NotificationModel(
          id: 'n2',
          title: 'Unread 2',
          message: 'Body 2',
          category: NotificationCategory.academic,
          priority: NotificationPriority.high,
          audienceType: NotificationAudienceType.personal,
          timestamp: DateTime.now(),
          isRead: false,
        ),
        NotificationModel(
          id: 'n3',
          title: 'Read 3',
          message: 'Body 3',
          category: NotificationCategory.announcement,
          priority: NotificationPriority.low,
          audienceType: NotificationAudienceType.personal,
          timestamp: DateTime.now(),
          isRead: true,
        ),
      ]);

      await tester.pumpWidget(createWidgetUnderTest(
        child: const Scaffold(body: NotificationBadge()),
        fakeRepo: fakeRepo,
      ));

      await tester.pumpAndSettle();

      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('3. Unread notification has distinct visual indicator', (tester) async {
      final unreadNotif = NotificationModel(
        id: 'unread_card',
        title: 'New Exam Schedule',
        message: 'Exam timetable released.',
        category: NotificationCategory.academic,
        priority: NotificationPriority.high,
        status: NotificationStatus.unread,
        audienceType: NotificationAudienceType.personal,
        timestamp: DateTime.now(),
        isRead: false,
      );

      await tester.pumpWidget(createWidgetUnderTest(
        child: Scaffold(
          body: NotificationCard(
            notification: unreadNotif,
            onReadToggle: () {},
            onDelete: () {},
          ),
        ),
        fakeRepo: FakeNotificationRepository(),
      ));

      await tester.pumpAndSettle();

      // Find the unread dot (Container with BoxShape.circle)
      expect(find.text('New Exam Schedule'), findsOneWidget);
      final dotFinder = find.byWidgetPredicate((widget) =>
          widget is Container &&
          widget.decoration is BoxDecoration &&
          (widget.decoration as BoxDecoration).shape == BoxShape.circle &&
          (widget.constraints?.maxWidth == 10 || widget.constraints?.maxHeight == 10));
      expect(dotFinder, findsOneWidget);
    });

    testWidgets('4. Filter chips render and filter notifications', (tester) async {
      final fakeRepo = FakeNotificationRepository(notifications: [
        NotificationModel(
          id: 'asg_notif',
          title: 'Task Assignment',
          message: 'Assignment detail',
          category: NotificationCategory.assignment,
          priority: NotificationPriority.normal,
          audienceType: NotificationAudienceType.personal,
          timestamp: DateTime.now(),
          isRead: false,
        ),
        NotificationModel(
          id: 'cal_notif',
          title: 'Holiday Notice',
          message: 'Calendar holiday',
          category: NotificationCategory.calendar,
          priority: NotificationPriority.normal,
          audienceType: NotificationAudienceType.personal,
          timestamp: DateTime.now(),
          isRead: true,
        ),
      ]);

      await tester.pumpWidget(createWidgetUnderTest(
        child: const NotificationCenterScreen(),
        fakeRepo: fakeRepo,
      ));

      await tester.pumpAndSettle();

      expect(find.text('All'), findsOneWidget);
      expect(find.text('Tasks'), findsOneWidget);
      expect(find.text('Calendar'), findsOneWidget);

      // Tap 'Calendar' filter chip
      await tester.tap(find.text('Calendar'));
      await tester.pumpAndSettle();

      expect(find.text('Holiday Notice'), findsOneWidget);
      expect(find.text('Task Assignment'), findsNothing);
    });

    testWidgets('5. Mark all as read updates all items and clears unread counter', (tester) async {
      final fakeRepo = FakeNotificationRepository(notifications: [
        NotificationModel(
          id: 'm1',
          title: 'Unread Item 1',
          message: 'Body 1',
          category: NotificationCategory.general,
          priority: NotificationPriority.normal,
          audienceType: NotificationAudienceType.personal,
          timestamp: DateTime.now(),
          isRead: false,
        ),
        NotificationModel(
          id: 'm2',
          title: 'Unread Item 2',
          message: 'Body 2',
          category: NotificationCategory.general,
          priority: NotificationPriority.normal,
          audienceType: NotificationAudienceType.personal,
          timestamp: DateTime.now(),
          isRead: false,
        ),
      ]);

      await tester.pumpWidget(createWidgetUnderTest(
        child: const NotificationCenterScreen(),
        fakeRepo: fakeRepo,
      ));

      await tester.pumpAndSettle();

      expect(find.text('Mark all as read'), findsOneWidget);

      await tester.tap(find.text('Mark all as read'));
      await tester.pumpAndSettle();

      expect(fakeRepo.notifications.every((n) => n.isRead), isTrue);
    });

    testWidgets('6. Empty state displays gracefully when no notifications exist', (tester) async {
      final fakeRepo = FakeNotificationRepository(notifications: []);

      await tester.pumpWidget(createWidgetUnderTest(
        child: const NotificationCenterScreen(),
        fakeRepo: fakeRepo,
      ));

      await tester.pumpAndSettle();

      expect(find.text('No new notifications'), findsOneWidget);
      expect(find.text("You're all caught up with your updates and requests."), findsOneWidget);
    });

    testWidgets('7. Error state displays retry button on stream failure', (tester) async {
      final fakeRepo = FakeNotificationRepository(shouldThrowError: true);

      await tester.pumpWidget(createWidgetUnderTest(
        child: const NotificationCenterScreen(),
        fakeRepo: fakeRepo,
      ));

      await tester.pumpAndSettle();

      expect(find.text("Couldn't load notifications."), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('8. Deep link auto-resolution from json handles all canonical domains', (tester) async {
      // Assignment
      final notifAsg = NotificationModel.fromJson({
        'id': '1',
        'title': 'Asg',
        'body': 'Body',
        'entityType': 'Assignment',
        'entityId': 'asg_99',
      });
      expect(notifAsg.navigationTarget, '/assignments/asg_99');

      // Assessment
      final notifAssess = NotificationModel.fromJson({
        'id': '2',
        'title': 'IA',
        'body': 'Body',
        'entityType': 'Assessment',
        'entityId': 'ia_88',
      });
      expect(notifAssess.navigationTarget, '/assessments/ia_88');

      // Practical
      final notifPrac = NotificationModel.fromJson({
        'id': '3',
        'title': 'Practical',
        'body': 'Body',
        'entityType': 'Practical',
        'entityId': 'prac_77',
      });
      expect(notifPrac.navigationTarget, '/practicals/prac_77');

      // Calendar
      final notifCal = NotificationModel.fromJson({
        'id': '4',
        'title': 'Holiday',
        'body': 'Body',
        'entityType': 'CalendarEvent',
        'entityId': 'ev_66',
      });
      expect(notifCal.navigationTarget, '/calendar/event/ev_66');

      // Result
      final notifRes = NotificationModel.fromJson({
        'id': '5',
        'title': 'Result',
        'body': 'Body',
        'entityType': 'AcademicResult',
        'entityId': 'res_55',
      });
      expect(notifRes.navigationTarget, '/academic-results');
    });

    testWidgets('9. Notification preferences screen renders delivery channels and categories', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final fakeSettingsRepo = FakeSettingsRepository();

      await tester.pumpWidget(createWidgetUnderTest(
        child: const NotificationPreferencesScreen(),
        fakeRepo: FakeNotificationRepository(),
        fakeSettingsRepo: fakeSettingsRepo,
        screenSize: const Size(360, 2400),
      ));

      await tester.pumpAndSettle();

      expect(find.text('Notification Settings'), findsOneWidget);
      expect(find.text('Delivery Channels'), findsOneWidget);
      expect(find.text('In-App Notifications'), findsOneWidget);
      expect(find.text('Push Notifications (FCM)'), findsOneWidget);
      expect(find.text('Assignments & Tasks'), findsOneWidget);
      expect(find.text('Practical Lab Sessions'), findsOneWidget);
      expect(find.text('Assessments & Internal Tests'), findsOneWidget);
      expect(find.text('Academic Calendar & Holidays'), findsOneWidget);
      expect(find.text('System & Official Academic Results'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('Save Preferences'), 500);
      expect(find.text('Save Preferences'), findsOneWidget);
    });

    testWidgets('10. 360px layout on preferences screen has zero overflow', (tester) async {
      final fakeSettingsRepo = FakeSettingsRepository();

      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidgetUnderTest(
        child: const NotificationPreferencesScreen(),
        fakeRepo: FakeNotificationRepository(),
        fakeSettingsRepo: fakeSettingsRepo,
        screenSize: const Size(360, 800),
      ));

      await tester.pumpAndSettle();

      expect(find.text('Notification Settings'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
