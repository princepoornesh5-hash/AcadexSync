import 'dart:async';
import '../../../auth/domain/models/role_enum.dart';
import '../../../../features/auth/domain/models/user_model.dart';
import '../../../settings/domain/models/settings_models.dart';
import '../../domain/models/notification_models.dart';
import 'notification_repository.dart';

class MockNotificationRepository implements NotificationRepository {
  final List<NotificationModel> _notifications = [];
  bool _initialized = false;
  final bool autoGenerateInitialData;
  
  final _changeController = StreamController<void>.broadcast();

  MockNotificationRepository({
    List<NotificationModel>? initialNotifications,
    this.autoGenerateInitialData = false,
  }) {
    if (initialNotifications != null) {
      _notifications.addAll(initialNotifications);
      _initialized = true;
    }
  }

  void _notifyListeners() {
    _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    if (!_changeController.isClosed) {
      _changeController.add(null);
    }
  }

  List<NotificationModel> _filterForUser(UserModel user, NotificationPreferences prefs) {
    final list = _notifications.where((n) {
      // 1. Tenant Scoping
      if (user.role != AppRole.superAdmin &&
          n.collegeId != null &&
          n.collegeId!.isNotEmpty &&
          user.collegeId != null &&
          user.collegeId!.isNotEmpty) {
        if (n.collegeId != user.collegeId) return false;
      }

      // 2. Audience Scoping
      switch (n.audienceType) {
        case NotificationAudienceType.personal:
          if (n.recipientUserId != user.id) return false;
          break;
        case NotificationAudienceType.department:
          if (user.departmentId == null || user.departmentId != n.departmentId) return false;
          break;
        case NotificationAudienceType.college:
          if (user.collegeId == null || user.collegeId != n.collegeId) return false;
          break;
        case NotificationAudienceType.role:
          if (n.recipientRole != user.role) return false;
          break;
        case NotificationAudienceType.section:
          if (n.sectionId != null && n.sectionId != user.departmentId) return false;
          break;
        case NotificationAudienceType.platform:
          break;
      }

      // 3. User Preferences Scoping (Critical priority always delivers)
      if (n.priority != NotificationPriority.critical) {
        if (n.category == NotificationCategory.attendance && !prefs.attendanceAlerts) return false;
        if (n.category == NotificationCategory.academic && !prefs.academicUpdates) return false;
        if (n.category == NotificationCategory.notes && !prefs.notesUploaded) return false;
        if (n.category == NotificationCategory.certificates && !prefs.certificateUpdates) return false;
        if (n.category == NotificationCategory.system && !prefs.generalNotifications) return false;
      }

      return true;
    }).toList();

    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  @override
  Stream<List<NotificationModel>> watchNotifications(UserModel user, NotificationPreferences prefs) {
    if (!_initialized && autoGenerateInitialData) {
      _generateInitialData(user, prefs);
      _initialized = true;
    }

    final controller = StreamController<List<NotificationModel>>.broadcast();

    void emit() {
      if (!controller.isClosed) {
        controller.add(_filterForUser(user, prefs));
      }
    }

    scheduleMicrotask(emit);
    final sub = _changeController.stream.listen((_) => emit());
    controller.onCancel = () => sub.cancel();

    return controller.stream;
  }

  @override
  Future<void> markAsRead(String id, String userId) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true, readAt: DateTime.now());
      _notifyListeners();
    }
  }
  
  @override
  Future<void> markAsUnread(String id, String userId) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: false);
      _notifyListeners();
    }
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    for (int i = 0; i < _notifications.length; i++) {
      if (_notifications[i].recipientUserId == userId ||
          _notifications[i].audienceType != NotificationAudienceType.personal) {
        _notifications[i] = _notifications[i].copyWith(isRead: true, readAt: DateTime.now());
      }
    }
    _notifyListeners();
  }

  @override
  Future<void> deleteNotification(String id, String userId) async {
    _notifications.removeWhere((n) => n.id == id);
    _notifyListeners();
  }

  @override
  Future<void> clearAll(String userId) async {
    _notifications.clear();
    _notifyListeners();
  }

  @override
  Future<NotificationModel> createPersonalNotification(NotificationModel notification) async {
    final n = notification.copyWith(
      id: notification.id.isNotEmpty
          ? notification.id
          : 'mock_${DateTime.now().millisecondsSinceEpoch}',
      audienceType: NotificationAudienceType.personal,
    );
    _notifications.add(n);
    _notifyListeners();
    return n;
  }

  @override
  Future<NotificationModel> createAnnouncement(NotificationModel notification) async {
    final n = notification.copyWith(
      id: notification.id.isNotEmpty
          ? notification.id
          : 'announcement_${DateTime.now().millisecondsSinceEpoch}',
    );
    _notifications.add(n);
    _notifyListeners();
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
          navigationTarget: '/attendance',
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
          navigationTarget: '/attendance',
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
          navigationTarget: '/attendance',
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
          navigationTarget: '/attendance',
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
          navigationTarget: '/attendance',
        ));
        break;
    }
  }
}

final mockNotificationRepo = MockNotificationRepository(autoGenerateInitialData: true);
