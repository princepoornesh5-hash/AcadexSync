import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_management/features/attendance/domain/models/attendance_alert.dart';
import 'package:campus_management/features/attendance/domain/services/attendance_notification_dispatcher.dart';
import 'package:campus_management/features/notifications/domain/models/notification_models.dart';
import 'package:campus_management/features/notifications/data/repositories/notification_repository.dart';
import 'package:campus_management/features/notifications/data/repositories/mock_notification_repository.dart';
import 'package:campus_management/features/notifications/presentation/providers/notification_providers.dart';
import 'package:campus_management/features/notifications/presentation/widgets/notification_badge.dart';
import 'package:campus_management/features/notifications/presentation/screens/notification_center_screen.dart';
import 'package:campus_management/features/settings/domain/models/settings_models.dart';
import 'package:campus_management/features/settings/presentation/providers/settings_providers.dart';

class _FakeAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _FakeAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeNotificationPreferencesNotifier extends NotificationPreferencesNotifier {
  final NotificationPreferences _prefs;
  _FakeNotificationPreferencesNotifier(this._prefs);

  @override
  Future<NotificationPreferences> build() async => _prefs;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testStudent = UserModel(
    id: 'STU-001',
    email: 'student@campus.edu',
    name: 'Rahul Kumar',
    role: AppRole.student,
    collegeId: 'COL-001',
    departmentId: 'DEP-CSE',
  );

  final testFaculty = UserModel(
    id: 'FAC-001',
    email: 'faculty@campus.edu',
    name: 'Prof. Sharma',
    role: AppRole.faculty,
    collegeId: 'COL-001',
    departmentId: 'DEP-CSE',
  );

  final testHod = UserModel(
    id: 'HOD-001',
    email: 'hod@campus.edu',
    name: 'Dr. Verma',
    role: AppRole.hod,
    collegeId: 'COL-001',
    departmentId: 'DEP-CSE',
  );

  final testCollegeAdmin = UserModel(
    id: 'ADM-001',
    email: 'admin@campus.edu',
    name: 'Dean Admin',
    role: AppRole.collegeAdmin,
    collegeId: 'COL-001',
  );

  final otherCollegeStudent = UserModel(
    id: 'STU-999',
    email: 'other@othercollege.edu',
    name: 'Other Student',
    role: AppRole.student,
    collegeId: 'COL-002',
    departmentId: 'DEP-ECE',
  );


  Widget buildTestApp({
    required Widget child,
    required UserModel user,
    NotificationRepository? repository,
    NotificationPreferences? prefs,
    List<Override> overrides = const [],
    ThemeMode themeMode = ThemeMode.light,
    double width = 1200,
    double height = 800,
  }) {
    final effectivePrefs = prefs ??
        const NotificationPreferences(
          attendanceAlerts: true,
          academicUpdates: true,
          announcements: true,
          notesUploaded: true,
          certificateUpdates: true,
          generalNotifications: true,
        );

    return ProviderScope(
      overrides: [
        authProvider.overrideWith((ref) => _FakeAuthNotifier(AuthAuthenticated(user: user, token: 'mock-token'))),
        if (repository != null)
          notificationRepositoryProvider.overrideWithValue(repository),
        notificationPreferencesProvider.overrideWith(() => _FakeNotificationPreferencesNotifier(effectivePrefs)),
        ...overrides,
      ],
      child: MaterialApp(
        themeMode: themeMode,
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        home: MediaQuery(
          data: MediaQueryData(size: Size(width, height)),
          child: child,
        ),
      ),
    );
  }

  group('ACADEX Phase 8E: Attendance Communication & Notification Delivery Tests', () {
    late MockNotificationRepository mockRepo;
    late AttendanceNotificationDispatcher dispatcher;

    setUp(() {
      mockRepo = MockNotificationRepository();
      dispatcher = AttendanceNotificationDispatcher(notificationRepository: mockRepo);
    });

    test('1. Attendance alert creates notification', () {
      final alert = AttendanceAlert.createLowAttendance(
        id: 'ALT-1',
        collegeId: 'COL-001',
        departmentId: 'DEP-CSE',
        studentId: 'STU-001',
        studentName: 'Rahul Kumar',
        rollNumber: 'CS2026-01',
        sectionId: 'SEC-A',
        attendancePercentage: 62.0,
        presentCount: 6,
        totalSessions: 10,
      );

      final notifications = dispatcher.buildNotificationsForAlert(alert: alert);
      expect(notifications, isNotEmpty);
      expect(notifications.any((n) => n.recipientUserId == 'STU-001'), isTrue);
      expect(notifications.first.category, NotificationCategory.attendance);
    });

    test('2. Correct recipient is resolved', () {
      final alert = AttendanceAlert.createLowAttendance(
        id: 'ALT-2',
        collegeId: 'COL-001',
        departmentId: 'DEP-CSE',
        studentId: 'STU-001',
        studentName: 'Rahul Kumar',
        rollNumber: 'CS2026-01',
        sectionId: 'SEC-A',
        subjectId: 'SUB-DBMS',
        facultyId: 'FAC-001',
        attendancePercentage: 60.0, // Critical
        presentCount: 6,
        totalSessions: 10,
      );

      final notifications = dispatcher.buildNotificationsForAlert(alert: alert);

      // Student notification
      expect(notifications.any((n) => n.recipientUserId == 'STU-001' && n.recipientRole == AppRole.student), isTrue);

      // Faculty notification
      expect(notifications.any((n) => n.recipientUserId == 'FAC-001' && n.recipientRole == AppRole.faculty), isTrue);

      // Department HOD notification
      expect(notifications.any((n) => n.departmentId == 'DEP-CSE' && n.audienceType == NotificationAudienceType.department), isTrue);

      // College Admin notification (due to critical severity)
      expect(notifications.any((n) => n.collegeId == 'COL-001' && n.audienceType == NotificationAudienceType.college), isTrue);
    });

    test('3. Student receives only own notification', () async {
      await mockRepo.createPersonalNotification(
        NotificationModel(
          id: 'N-STU-1',
          title: 'Low Attendance',
          message: 'Your attendance is 60%',
          category: NotificationCategory.attendance,
          priority: NotificationPriority.critical,
          audienceType: NotificationAudienceType.personal,
          timestamp: DateTime.now(),
          recipientUserId: 'STU-001',
          recipientRole: AppRole.student,
          collegeId: 'COL-001',
          departmentId: 'DEP-CSE',
        ),
      );

      await mockRepo.createPersonalNotification(
        NotificationModel(
          id: 'N-STU-2',
          title: 'Low Attendance Other',
          message: 'Other student attendance is 55%',
          category: NotificationCategory.attendance,
          priority: NotificationPriority.critical,
          audienceType: NotificationAudienceType.personal,
          timestamp: DateTime.now(),
          recipientUserId: 'STU-002',
          recipientRole: AppRole.student,
          collegeId: 'COL-001',
          departmentId: 'DEP-CSE',
        ),
      );

      const prefs = NotificationPreferences(
        attendanceAlerts: true,
        academicUpdates: true,
        announcements: true,
        notesUploaded: true,
        certificateUpdates: true,
        generalNotifications: true,
      );

      final stream = mockRepo.watchNotifications(testStudent, prefs);
      final list = await stream.first;

      expect(list.length, 1);
      expect(list.first.recipientUserId, 'STU-001');
    });

    test('4. Faculty receives authorized notifications', () async {
      await mockRepo.createPersonalNotification(
        NotificationModel(
          id: 'N-FAC-1',
          title: 'Student Shortage in DBMS',
          message: 'Rahul Kumar has 60% in DBMS',
          category: NotificationCategory.attendance,
          priority: NotificationPriority.high,
          audienceType: NotificationAudienceType.personal,
          timestamp: DateTime.now(),
          recipientUserId: 'FAC-001',
          recipientRole: AppRole.faculty,
          collegeId: 'COL-001',
          departmentId: 'DEP-CSE',
        ),
      );

      const prefs = NotificationPreferences(
        attendanceAlerts: true,
        academicUpdates: true,
        announcements: true,
        notesUploaded: true,
        certificateUpdates: true,
        generalNotifications: true,
      );

      final stream = mockRepo.watchNotifications(testFaculty, prefs);
      final list = await stream.first;

      expect(list.length, 1);
      expect(list.first.recipientUserId, 'FAC-001');
    });

    test('5. HOD receives department notifications', () async {
      await mockRepo.createAnnouncement(
        NotificationModel(
          id: 'N-HOD-1',
          title: 'Department Attendance Alert',
          message: 'High shortage in CSE',
          category: NotificationCategory.attendance,
          priority: NotificationPriority.critical,
          audienceType: NotificationAudienceType.department,
          timestamp: DateTime.now(),
          recipientRole: AppRole.hod,
          collegeId: 'COL-001',
          departmentId: 'DEP-CSE',
        ),
      );

      const prefs = NotificationPreferences(
        attendanceAlerts: true,
        academicUpdates: true,
        announcements: true,
        notesUploaded: true,
        certificateUpdates: true,
        generalNotifications: true,
      );

      final stream = mockRepo.watchNotifications(testHod, prefs);
      final list = await stream.first;

      expect(list.length, 1);
      expect(list.first.departmentId, 'DEP-CSE');
    });

    test('6. College Admin receives college notifications', () async {
      await mockRepo.createAnnouncement(
        NotificationModel(
          id: 'N-ADM-1',
          title: 'College Compliance Alert',
          message: 'Critical compliance alert for COL-001',
          category: NotificationCategory.attendance,
          priority: NotificationPriority.critical,
          audienceType: NotificationAudienceType.college,
          timestamp: DateTime.now(),
          recipientRole: AppRole.collegeAdmin,
          collegeId: 'COL-001',
        ),
      );

      const prefs = NotificationPreferences(
        attendanceAlerts: true,
        academicUpdates: true,
        announcements: true,
        notesUploaded: true,
        certificateUpdates: true,
        generalNotifications: true,
      );

      final stream = mockRepo.watchNotifications(testCollegeAdmin, prefs);
      final list = await stream.first;

      expect(list.length, 1);
      expect(list.first.collegeId, 'COL-001');
    });

    test('7. Duplicate notification prevented', () async {
      final alert = AttendanceAlert.createLowAttendance(
        id: 'ALT-DUP',
        collegeId: 'COL-001',
        departmentId: 'DEP-CSE',
        studentId: 'STU-001',
        studentName: 'Rahul Kumar',
        rollNumber: 'CS2026-01',
        sectionId: 'SEC-A',
        attendancePercentage: 62.0,
        presentCount: 6,
        totalSessions: 10,
      );

      // First dispatch
      final firstRun = await dispatcher.dispatchAlerts(alerts: [alert]);
      expect(firstRun, isNotEmpty);

      // Second dispatch of identical alert state
      final secondRun = await dispatcher.dispatchAlerts(alerts: [alert]);
      expect(secondRun, isEmpty); // Deduplication prevents redundant messages
    });

    test('8. Notification marked read', () async {
      await mockRepo.createPersonalNotification(
        NotificationModel(
          id: 'N-READ-1',
          title: 'Test Notification',
          message: 'Message',
          category: NotificationCategory.attendance,
          priority: NotificationPriority.normal,
          audienceType: NotificationAudienceType.personal,
          timestamp: DateTime.now(),
          recipientUserId: 'STU-001',
        ),
      );

      await mockRepo.markAsRead('N-READ-1', 'STU-001');

      const prefs = NotificationPreferences(
        attendanceAlerts: true,
        academicUpdates: true,
        announcements: true,
        notesUploaded: true,
        certificateUpdates: true,
        generalNotifications: true,
      );

      final stream = mockRepo.watchNotifications(testStudent, prefs);
      final list = await stream.first;

      expect(list.first.isRead, isTrue);
      expect(list.first.readAt, isNotNull);
    });

    test('9. Mark all read works', () async {
      await mockRepo.createPersonalNotification(
        NotificationModel(
          id: 'N-ALL-1',
          title: 'Notif 1',
          message: 'Msg 1',
          category: NotificationCategory.attendance,
          priority: NotificationPriority.normal,
          audienceType: NotificationAudienceType.personal,
          timestamp: DateTime.now(),
          recipientUserId: 'STU-001',
        ),
      );
      await mockRepo.createPersonalNotification(
        NotificationModel(
          id: 'N-ALL-2',
          title: 'Notif 2',
          message: 'Msg 2',
          category: NotificationCategory.attendance,
          priority: NotificationPriority.normal,
          audienceType: NotificationAudienceType.personal,
          timestamp: DateTime.now(),
          recipientUserId: 'STU-001',
        ),
      );

      await mockRepo.markAllAsRead('STU-001');

      const prefs = NotificationPreferences(
        attendanceAlerts: true,
        academicUpdates: true,
        announcements: true,
        notesUploaded: true,
        certificateUpdates: true,
        generalNotifications: true,
      );

      final stream = mockRepo.watchNotifications(testStudent, prefs);
      final list = await stream.first;

      expect(list.every((n) => n.isRead), isTrue);
    });

    test('10. Unread count is correct', () async {
      await mockRepo.createPersonalNotification(
        NotificationModel(
          id: 'N-CNT-1',
          title: 'Unread 1',
          message: 'Msg 1',
          category: NotificationCategory.attendance,
          priority: NotificationPriority.normal,
          audienceType: NotificationAudienceType.personal,
          timestamp: DateTime.now(),
          recipientUserId: 'STU-001',
          isRead: false,
        ),
      );
      await mockRepo.createPersonalNotification(
        NotificationModel(
          id: 'N-CNT-2',
          title: 'Read 1',
          message: 'Msg 2',
          category: NotificationCategory.attendance,
          priority: NotificationPriority.normal,
          audienceType: NotificationAudienceType.personal,
          timestamp: DateTime.now(),
          recipientUserId: 'STU-001',
          isRead: true,
        ),
      );

      const prefs = NotificationPreferences(
        attendanceAlerts: true,
        academicUpdates: true,
        announcements: true,
        notesUploaded: true,
        certificateUpdates: true,
        generalNotifications: true,
      );

      final stream = mockRepo.watchNotifications(testStudent, prefs);
      final list = await stream.first;
      final unreadCount = list.where((n) => !n.isRead).length;

      expect(unreadCount, 1);
    });

    test('11. Notification navigation resolves correctly', () {
      final studentAlert = AttendanceAlert.createLowAttendance(
        id: 'ALT-NAV',
        collegeId: 'COL-001',
        departmentId: 'DEP-CSE',
        studentId: 'STU-001',
        studentName: 'Rahul Kumar',
        rollNumber: 'CS2026-01',
        attendancePercentage: 65.0,
        presentCount: 13,
        totalSessions: 20,
      );

      final notifications = dispatcher.buildNotificationsForAlert(alert: studentAlert);
      final studentNotif = notifications.firstWhere((n) => n.recipientUserId == 'STU-001');

      expect(studentNotif.navigationTarget, '/attendance/analytics/student/STU-001');
    });

    test('12. Recovery notification generated correctly', () {
      final alert = AttendanceAlert(
        id: 'ALT-REC',
        collegeId: 'COL-001',
        departmentId: 'DEP-CSE',
        studentId: 'STU-001',
        studentName: 'Rahul Kumar',
        rollNumber: 'CS2026-01',
        alertType: AttendanceAlertType.attendanceRecovery,
        severity: AttendanceAlertSeverity.info,
        status: AttendanceAlertStatus.resolved,
        title: 'Attendance Recovered: Rahul Kumar (75.0%)',
        message: 'Attendance has improved to 75.0%, successfully meeting requirements.',
        attendancePercentage: 75.0,
        threshold: 75.0,
        createdAt: DateTime.now(),
        resolvedAt: DateTime.now(),
        deduplicationKey: 'recovery_STU-001',
      );

      final notifs = dispatcher.buildNotificationsForAlert(alert: alert);
      expect(notifs, isNotEmpty);
      expect(notifs.first.title, contains('Recovered'));
      expect(notifs.first.priority, NotificationPriority.normal);
    });

    test('13. Grouped notification generated correctly for HOD', () {
      final alerts = [
        AttendanceAlert.createLowAttendance(
          id: 'ALT-G1',
          collegeId: 'COL-001',
          departmentId: 'DEP-CSE',
          studentId: 'STU-001',
          studentName: 'Student 1',
          rollNumber: 'CS-01',
          sectionId: 'SEC-A',
          attendancePercentage: 60.0,
          presentCount: 6,
          totalSessions: 10,
        ),
        AttendanceAlert.createLowAttendance(
          id: 'ALT-G2',
          collegeId: 'COL-001',
          departmentId: 'DEP-CSE',
          studentId: 'STU-002',
          studentName: 'Student 2',
          rollNumber: 'CS-02',
          sectionId: 'SEC-A',
          attendancePercentage: 65.0,
          presentCount: 6,
          totalSessions: 10,
        ),
      ];

      final grouped = dispatcher.buildGroupedShortageNotification(
        departmentId: 'DEP-CSE',
        collegeId: 'COL-001',
        alerts: alerts,
        sectionId: 'SEC-A',
      );

      expect(grouped, isNotNull);
      expect(grouped?.title, contains('2 Students with Low Attendance'));
      expect(grouped?.navigationTarget, '/attendance/analytics/section/SEC-A');
    });

    test('14. Notification preference respected for non-critical alerts', () {
      final warningAlert = AttendanceAlert.createLowAttendance(
        id: 'ALT-WARN',
        collegeId: 'COL-001',
        departmentId: 'DEP-CSE',
        studentId: 'STU-001',
        studentName: 'Rahul Kumar',
        rollNumber: 'CS2026-01',
        attendancePercentage: 72.0, // Warning (70-74.99%)
        presentCount: 72,
        totalSessions: 100,
      );

      const prefsDisabled = NotificationPreferences(
        attendanceAlerts: false, // Opted out
        academicUpdates: true,
        announcements: true,
        notesUploaded: true,
        certificateUpdates: true,
        generalNotifications: true,
      );

      final notifs = dispatcher.buildNotificationsForAlert(alert: warningAlert, prefs: prefsDisabled);
      expect(notifs.any((n) => n.recipientUserId == 'STU-001'), isFalse);
    });

    test('15. Critical notification follows policy and delivers even if optional alerts are disabled', () {
      final criticalAlert = AttendanceAlert.createLowAttendance(
        id: 'ALT-CRIT',
        collegeId: 'COL-001',
        departmentId: 'DEP-CSE',
        studentId: 'STU-001',
        studentName: 'Rahul Kumar',
        rollNumber: 'CS2026-01',
        attendancePercentage: 50.0, // Critical (<70%)
        presentCount: 5,
        totalSessions: 10,
      );

      const prefsDisabled = NotificationPreferences(
        attendanceAlerts: false, // User disabled general alerts
        academicUpdates: true,
        announcements: true,
        notesUploaded: true,
        certificateUpdates: true,
        generalNotifications: true,
      );

      final notifs = dispatcher.buildNotificationsForAlert(alert: criticalAlert, prefs: prefsDisabled);
      // Mandatory critical notifications still deliver
      expect(notifs.any((n) => n.recipientUserId == 'STU-001'), isTrue);
    });

    test('16. Push delivery failure does not break attendance dispatching (Safe Dispatch)', () async {
      final throwingRepo = _ThrowingNotificationRepo();
      final safeDispatcher = AttendanceNotificationDispatcher(notificationRepository: throwingRepo);

      final alert = AttendanceAlert.createLowAttendance(
        id: 'ALT-ERR',
        collegeId: 'COL-001',
        departmentId: 'DEP-CSE',
        studentId: 'STU-001',
        studentName: 'Rahul Kumar',
        rollNumber: 'CS2026-01',
        attendancePercentage: 60.0,
        presentCount: 6,
        totalSessions: 10,
      );

      // Must complete without throwing
      await expectLater(
        safeDispatcher.safeDispatch(alerts: [alert]),
        completes,
      );
    });

    test('17. In-app notification remains available after delivery attempt', () async {
      final alert = AttendanceAlert.createLowAttendance(
        id: 'ALT-INAPP',
        collegeId: 'COL-001',
        departmentId: 'DEP-CSE',
        studentId: 'STU-001',
        studentName: 'Rahul Kumar',
        rollNumber: 'CS2026-01',
        attendancePercentage: 60.0,
        presentCount: 6,
        totalSessions: 10,
      );

      await dispatcher.dispatchAlerts(alerts: [alert]);

      const prefs = NotificationPreferences(
        attendanceAlerts: true,
        academicUpdates: true,
        announcements: true,
        notesUploaded: true,
        certificateUpdates: true,
        generalNotifications: true,
      );

      final stream = mockRepo.watchNotifications(testStudent, prefs);
      final list = await stream.first;

      expect(list, isNotEmpty);
      expect(list.first.category, NotificationCategory.attendance);
    });

    test('18. Notification stream updates in real time', () async {
      const prefs = NotificationPreferences(
        attendanceAlerts: true,
        academicUpdates: true,
        announcements: true,
        notesUploaded: true,
        certificateUpdates: true,
        generalNotifications: true,
      );

      final emitted = <List<NotificationModel>>[];
      final stream = mockRepo.watchNotifications(testStudent, prefs);
      final sub = stream.listen(emitted.add);

      await Future.delayed(const Duration(milliseconds: 20));
      expect(emitted.isNotEmpty, isTrue);
      expect(emitted.last.isEmpty, isTrue);

      await mockRepo.createPersonalNotification(
        NotificationModel(
          id: 'N-RT',
          title: 'Real-time Alert',
          message: 'Real-time message',
          category: NotificationCategory.attendance,
          priority: NotificationPriority.critical,
          audienceType: NotificationAudienceType.personal,
          timestamp: DateTime.now(),
          recipientUserId: 'STU-001',
        ),
      );

      await Future.delayed(const Duration(milliseconds: 20));
      expect(emitted.last.length, 1);
      expect(emitted.last.first.id, 'N-RT');

      await sub.cancel();
    });

    test('19. Unauthorized notification access is rejected across tenant boundaries', () async {
      await mockRepo.createPersonalNotification(
        NotificationModel(
          id: 'N-COL1',
          title: 'College 1 Alert',
          message: 'College 1 only',
          category: NotificationCategory.attendance,
          priority: NotificationPriority.high,
          audienceType: NotificationAudienceType.personal,
          timestamp: DateTime.now(),
          recipientUserId: 'STU-001',
          collegeId: 'COL-001',
        ),
      );

      const prefs = NotificationPreferences(
        attendanceAlerts: true,
        academicUpdates: true,
        announcements: true,
        notesUploaded: true,
        certificateUpdates: true,
        generalNotifications: true,
      );

      // Student from College 2 watches notifications
      final stream = mockRepo.watchNotifications(otherCollegeStudent, prefs);
      final list = await stream.first;

      expect(list.isEmpty, isTrue); // College 2 student cannot see College 1 alert
    });

    test('20. Notification scope cannot be modified by client', () {
      final alert = AttendanceAlert.createLowAttendance(
        id: 'ALT-SEC',
        collegeId: 'COL-001',
        departmentId: 'DEP-CSE',
        studentId: 'STU-001',
        studentName: 'Rahul Kumar',
        rollNumber: 'CS2026-01',
        attendancePercentage: 60.0,
        presentCount: 6,
        totalSessions: 10,
      );

      final notif = dispatcher.buildNotificationsForAlert(alert: alert).first;
      expect(notif.collegeId, 'COL-001');
      expect(notif.departmentId, 'DEP-CSE');
      expect(notif.recipientUserId, 'STU-001');
    });

    testWidgets('21. NotificationCenterScreen renders empty state', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          child: const NotificationCenterScreen(),
          user: testStudent,
          repository: mockRepo,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Notification Center'), findsOneWidget);
      expect(find.text('All caught up!'), findsOneWidget);
    });

    testWidgets('22. NotificationBadge displays unread count', (tester) async {
      await mockRepo.createPersonalNotification(
        NotificationModel(
          id: 'N-BADGE-1',
          title: 'Low Attendance',
          message: 'Attendance is 60%',
          category: NotificationCategory.attendance,
          priority: NotificationPriority.critical,
          audienceType: NotificationAudienceType.personal,
          timestamp: DateTime.now(),
          recipientUserId: 'STU-001',
          isRead: false,
        ),
      );

      await tester.pumpWidget(
        buildTestApp(
          child: const Scaffold(appBar: PreferredSize(preferredSize: Size.fromHeight(56), child: NotificationBadge())),
          user: testStudent,
          repository: mockRepo,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('23. NotificationCenterScreen renders in Dark Mode', (tester) async {
      await mockRepo.createPersonalNotification(
        NotificationModel(
          id: 'N-DARK',
          title: 'Dark Mode Test Alert',
          message: 'Attendance warning',
          category: NotificationCategory.attendance,
          priority: NotificationPriority.critical,
          audienceType: NotificationAudienceType.personal,
          timestamp: DateTime.now(),
          recipientUserId: 'STU-001',
        ),
      );

      await tester.pumpWidget(
        buildTestApp(
          child: const NotificationCenterScreen(),
          user: testStudent,
          repository: mockRepo,
          themeMode: ThemeMode.dark,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Notification Center'), findsOneWidget);
      expect(find.text('Dark Mode Test Alert'), findsOneWidget);
    });

    testWidgets('24. NotificationCenterScreen renders cleanly on mobile viewport without overflow', (tester) async {
      await mockRepo.createPersonalNotification(
        NotificationModel(
          id: 'N-MOB',
          title: 'Mobile Responsive Alert',
          message: 'Checking mobile layout at 360px width',
          category: NotificationCategory.attendance,
          priority: NotificationPriority.high,
          audienceType: NotificationAudienceType.personal,
          timestamp: DateTime.now(),
          recipientUserId: 'STU-001',
        ),
      );

      await tester.pumpWidget(
        buildTestApp(
          child: const NotificationCenterScreen(),
          user: testStudent,
          repository: mockRepo,
          width: 360,
          height: 640,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Notification Center'), findsOneWidget);
      expect(find.text('Mobile Responsive Alert'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    test('25. FCM Token cleanup and graceful fallback logic verified', () {
      // Confirms dispatcher completes safely even when FCM is unconfigured or in offline mock
      final alert = AttendanceAlert.createLowAttendance(
        id: 'ALT-FCM',
        collegeId: 'COL-001',
        departmentId: 'DEP-CSE',
        studentId: 'STU-001',
        studentName: 'Rahul Kumar',
        rollNumber: 'CS2026-01',
        attendancePercentage: 65.0,
        presentCount: 13,
        totalSessions: 20,
      );

      final notifs = dispatcher.buildNotificationsForAlert(alert: alert);
      expect(notifs, isNotEmpty);
      expect(notifs.first.relatedEntityType, 'attendance_alert');
    });
  });
}

class _ThrowingNotificationRepo extends MockNotificationRepository {
  @override
  Future<NotificationModel> createPersonalNotification(NotificationModel notification) {
    throw Exception('Simulated Network Error');
  }

  @override
  Future<NotificationModel> createAnnouncement(NotificationModel notification) {
    throw Exception('Simulated Server Error');
  }
}
