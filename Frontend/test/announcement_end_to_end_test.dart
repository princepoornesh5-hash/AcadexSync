import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_management/features/notifications/domain/models/announcement_model.dart';
import 'package:campus_management/features/notifications/domain/models/notification_models.dart';
import 'package:campus_management/features/notifications/presentation/providers/notification_providers.dart';
import 'package:campus_management/features/notifications/presentation/screens/announcement_list_screen.dart';
import 'package:campus_management/features/notifications/presentation/screens/announcement_detail_screen.dart';
import 'package:campus_management/features/notifications/presentation/screens/create_announcement_screen.dart';
import 'package:campus_management/features/notifications/presentation/widgets/notification_badge.dart';

class _FakeAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _FakeAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeNotificationsNotifier extends NotificationsNotifier {
  final List<NotificationModel> _data;
  FakeNotificationsNotifier(this._data);

  @override
  Stream<List<NotificationModel>> build() => Stream.value(_data);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testUser = UserModel(
    id: 'user_admin_01',
    name: 'Admin Alice',
    email: 'alice@college.edu',
    role: AppRole.collegeAdmin,
    collegeId: 'college_01',
  );

  final testStudent = UserModel(
    id: 'user_student_01',
    name: 'Student Bob',
    email: 'bob@college.edu',
    role: AppRole.student,
    collegeId: 'college_01',
  );

  final mockAnnouncement = AnnouncementModel(
    id: 'ann_test_01',
    collegeId: 'college_01',
    title: 'Midterm Examination Schedule Released',
    body: 'The schedule for midterm examinations has been officially published.',
    category: 'EXAM',
    audienceScope: AnnouncementAudienceScope.college,
    priority: NotificationPriority.high,
    isPinned: true,
    status: AnnouncementStatus.published,
    createdBy: 'user_admin_01',
    publishAt: DateTime.now().subtract(const Duration(hours: 2)),
    publishedAt: DateTime.now().subtract(const Duration(hours: 2)),
    recipientCount: 150,
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
  );

  final mockNotification = NotificationModel(
    id: 'notif_01',
    title: 'Midterm Examination Schedule Released',
    message: 'The schedule for midterm examinations has been officially published.',
    category: NotificationCategory.announcement,
    priority: NotificationPriority.high,
    audienceType: NotificationAudienceType.college,
    timestamp: DateTime.now(),
    isRead: false,
    navigationTarget: '/announcements/ann_test_01',
  );

  group('Announcement Model & Domain Tests', () {
    test('AnnouncementModel serialization and deserialization', () {
      final json = mockAnnouncement.toJson();
      expect(json['title'], 'Midterm Examination Schedule Released');
      expect(json['category'], 'EXAM');
      expect(json['isPinned'], true);
      expect(json['status'], 'PUBLISHED');

      final deserialized = AnnouncementModel.fromJson(json);
      expect(deserialized.id, 'ann_test_01');
      expect(deserialized.title, 'Midterm Examination Schedule Released');
      expect(deserialized.audienceScope, AnnouncementAudienceScope.college);
      expect(deserialized.status, AnnouncementStatus.published);
      expect(deserialized.recipientCount, 150);
    });

    test('NotificationModel deepLink parsing maps to navigationTarget', () {
      final rawBackendData = {
        'id': 'notif_100',
        'title': 'Class Cancelled',
        'message': 'Your Math class is cancelled today.',
        'category': 'timetable',
        'priority': 'high',
        'audienceType': 'college',
        'isRead': false,
        'createdAt': DateTime.now().toIso8601String(),
        'deepLink': '/timetable',
      };

      final notif = NotificationModel.fromJson(rawBackendData);
      expect(notif.navigationTarget, '/timetable');
      expect(notif.category, NotificationCategory.timetable);
      expect(notif.isRead, false);
    });
  });

  group('Notification Badge & Filter Tests', () {
    testWidgets('NotificationBadge displays unread count when > 0', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));

      final container = ProviderContainer(
        overrides: [
          notificationsProvider.overrideWith(() => FakeNotificationsNotifier([
            mockNotification,
            mockNotification.copyWith(id: 'notif_02', isRead: true),
          ])),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: Center(
                child: NotificationBadge(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(NotificationBadge), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });
  });

  group('Announcement Screens UI Tests', () {
    testWidgets('AnnouncementListScreen renders announcements and tabs for Admin', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));

      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith((ref) => _FakeAuthNotifier(AuthAuthenticated(user: testUser, token: 'jwt_alice'))),
          adminAnnouncementsProvider.overrideWith((ref) => Future.value([mockAnnouncement])),
          announcementsProvider.overrideWith((ref) => Future.value([mockAnnouncement])),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: AnnouncementListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Announcements'), findsOneWidget);
      expect(find.text('Create Announcement'), findsOneWidget);
      expect(find.text('All (Admin)'), findsOneWidget);
      expect(find.text('Published'), findsOneWidget);
      expect(find.text('Drafts'), findsOneWidget);
      expect(find.text('My Feed'), findsOneWidget);
      expect(find.text('Midterm Examination Schedule Released'), findsOneWidget);
      expect(find.text('150 recipients'), findsOneWidget);
    });

    testWidgets('AnnouncementListScreen renders clean user feed for Student without admin tabs', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));

      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith((ref) => _FakeAuthNotifier(AuthAuthenticated(user: testStudent, token: 'jwt_bob'))),
          announcementsProvider.overrideWith((ref) => Future.value([mockAnnouncement])),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: AnnouncementListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Announcements'), findsOneWidget);
      // Student should not see Create Announcement button
      expect(find.text('Create Announcement'), findsNothing);
      expect(find.text('All (Admin)'), findsNothing);
      expect(find.text('Midterm Examination Schedule Released'), findsOneWidget);
      expect(find.text('Read more'), findsOneWidget);
    });

    testWidgets('AnnouncementDetailScreen renders details, badges, and body', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 800));

      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith((ref) => _FakeAuthNotifier(AuthAuthenticated(user: testUser, token: 'jwt_alice'))),
          announcementByIdProvider('ann_test_01').overrideWith((ref) => Future.value(mockAnnouncement)),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: AnnouncementDetailScreen(announcementId: 'ann_test_01'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Announcement Details'), findsOneWidget);
      expect(find.text('Midterm Examination Schedule Released'), findsOneWidget);
      expect(find.text('The schedule for midterm examinations has been officially published.'), findsOneWidget);
      expect(find.text('PUBLISHED'), findsOneWidget);
      expect(find.text('EXAM'), findsOneWidget);
      expect(find.text('Pinned'), findsOneWidget);
      expect(find.text('Archive Announcement'), findsOneWidget);
    });

    testWidgets('CreateAnnouncementScreen prevents non-admins from creating announcements', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 800));

      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith((ref) => _FakeAuthNotifier(AuthAuthenticated(user: testStudent, token: 'jwt_bob'))),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: CreateAnnouncementScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('You do not have permission to create announcements.'), findsOneWidget);
      expect(find.text('Broadcast Announcement'), findsNothing);
    });

    testWidgets('CreateAnnouncementScreen displays form for authorized admin', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 1000));

      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith((ref) => _FakeAuthNotifier(AuthAuthenticated(user: testUser, token: 'jwt_alice'))),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: CreateAnnouncementScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Announcement Details'), findsOneWidget);
      expect(find.text('Announcement Title *'), findsOneWidget);
      expect(find.text('Announcement Body *'), findsOneWidget);
      expect(find.text('Save Draft'), findsOneWidget);
      expect(find.text('Publish Now'), findsOneWidget);
    });
  });
}
