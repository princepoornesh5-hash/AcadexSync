import 'dart:async';
import '../../../auth/domain/models/role_enum.dart';
import '../../../../features/auth/domain/models/user_model.dart';
import '../../../settings/domain/models/settings_models.dart';
import '../../domain/models/notification_models.dart';
import 'notification_repository.dart';

class MockNotificationRepository implements NotificationRepository {
  final List<NotificationModel> _notifications = [];
  bool _initialized = false;
  
  final _controller = StreamController<List<NotificationModel>>.broadcast();

  Future<void> _delay() async => await Future.delayed(const Duration(milliseconds: 400));

  void _emit() {
    _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    if (!_controller.isClosed) {
      _controller.add(List.from(_notifications));
    }
  }

  @override
  Stream<List<NotificationModel>> watchNotifications(UserModel user, NotificationPreferences prefs) {
    if (!_initialized) {
      _generateInitialData(user, prefs);
      _initialized = true;
      Future.delayed(const Duration(milliseconds: 100), _emit);
    } else {
      Future.delayed(const Duration(milliseconds: 100), _emit);
    }
    return _controller.stream;
  }

  @override
  Future<void> markAsRead(String id, String userId) async {
    await _delay();
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true, readAt: DateTime.now());
      _emit();
    }
  }
  
  @override
  Future<void> markAsUnread(String id, String userId) async {
    await _delay();
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: false);
      _emit();
    }
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    await _delay();
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true, readAt: DateTime.now());
    }
    _emit();
  }

  @override
  Future<void> deleteNotification(String id, String userId) async {
    await _delay();
    _notifications.removeWhere((n) => n.id == id);
    _emit();
  }

  @override
  Future<void> clearAll(String userId) async {
    await _delay();
    _notifications.clear();
    _emit();
  }

  @override
  Future<NotificationModel> createPersonalNotification(NotificationModel notification) async {
    await _delay();
    final n = notification.copyWith(
      id: 'mock_${DateTime.now().millisecondsSinceEpoch}',
      audienceType: NotificationAudienceType.personal,
    );
    _notifications.add(n);
    _emit();
    return n;
  }

  @override
  Future<NotificationModel> createAnnouncement(NotificationModel notification) async {
    await _delay();
    final n = notification.copyWith(id: 'announcement_${DateTime.now().millisecondsSinceEpoch}');
    _notifications.add(n);
    _emit();
    return n;
  }

  void _generateInitialData(UserModel user, NotificationPreferences prefs) {
    final now = DateTime.now();

    void add(NotificationModel n) {
      if (n.category == NotificationCategory.attendance && !prefs.attendanceAlerts) return;
      if (n.category == NotificationCategory.academic && !prefs.academicUpdates) return;
      if (n.category == NotificationCategory.notes && !prefs.notesUploaded) return;
      if (n.category == NotificationCategory.certificates && !prefs.certificateUpdates) return;
      if (n.category == NotificationCategory.system && !prefs.generalNotifications) return;
      _notifications.add(n);
    }

    if (prefs.generalNotifications) {
      add(NotificationModel(
        id: 'n_sys_1',
        title: 'System Maintenance',
        message: 'Acadex will be down for maintenance on Saturday from 2 AM to 4 AM.',
        category: NotificationCategory.system,
        priority: NotificationPriority.high,
        audienceType: NotificationAudienceType.platform,
        timestamp: now.subtract(const Duration(days: 2)),
        isRead: true,
      ));
    }

    switch (user.role) {
      case AppRole.student:
        add(NotificationModel(
          id: 'n_stu_1',
          title: 'Attendance Alert',
          message: 'Your attendance in Database Management Systems is below 75%.',
          category: NotificationCategory.attendance,
          priority: NotificationPriority.critical,
          audienceType: NotificationAudienceType.personal,
          recipientUserId: user.id,
          timestamp: now.subtract(const Duration(hours: 2)),
          navigationTarget: '/module/Attendance',
        ));
        break;
      case AppRole.faculty:
        add(NotificationModel(
          id: 'n_fac_1',
          title: 'Pending Attendance',
          message: 'Attendance for DCME 3-A is pending submission.',
          category: NotificationCategory.attendance,
          priority: NotificationPriority.high,
          audienceType: NotificationAudienceType.personal,
          recipientUserId: user.id,
          timestamp: now.subtract(const Duration(minutes: 30)),
          navigationTarget: '/module/Attendance',
        ));
        break;
      case AppRole.hod:
        add(NotificationModel(
          id: 'n_hod_1',
          title: 'Faculty Pending Attendance',
          message: '3 faculty members have pending attendance submissions today.',
          category: NotificationCategory.attendance,
          priority: NotificationPriority.high,
          audienceType: NotificationAudienceType.personal,
          recipientUserId: user.id,
          timestamp: now.subtract(const Duration(hours: 1)),
          navigationTarget: '/module/Attendance',
        ));
        break;
      case AppRole.collegeAdmin:
        add(NotificationModel(
          id: 'n_ca_1',
          title: 'Department Target Missed',
          message: 'Computer Engineering attendance completion is below target.',
          category: NotificationCategory.attendance,
          priority: NotificationPriority.critical,
          audienceType: NotificationAudienceType.personal,
          recipientUserId: user.id,
          timestamp: now.subtract(const Duration(hours: 3)),
          navigationTarget: '/module/Attendance',
        ));
        break;
      case AppRole.superAdmin:
        add(NotificationModel(
          id: 'n_sa_1',
          title: 'College Requires Attention',
          message: 'Global Institute of Technology attendance monitoring requires attention.',
          category: NotificationCategory.attendance,
          priority: NotificationPriority.high,
          audienceType: NotificationAudienceType.personal,
          recipientUserId: user.id,
          timestamp: now.subtract(const Duration(minutes: 15)),
          navigationTarget: '/module/Attendance',
        ));
        break;
    }
  }
}

final mockNotificationRepo = MockNotificationRepository();
