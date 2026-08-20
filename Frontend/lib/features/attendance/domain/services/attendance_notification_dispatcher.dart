import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../notifications/domain/models/notification_models.dart';
import '../../../notifications/data/repositories/notification_repository.dart';
import '../../../settings/domain/models/settings_models.dart';
import '../models/attendance_alert.dart';

/// Centralized domain service responsible for converting AttendanceAlert objects
/// into correctly scoped, deduplicated, user-facing notifications.
class AttendanceNotificationDispatcher {
  final NotificationRepository _notificationRepository;
  final String Function() _idGenerator;
  final Set<String> _dispatchedKeys = {};

  AttendanceNotificationDispatcher({
    required NotificationRepository notificationRepository,
    String Function()? idGenerator,
  })  : _notificationRepository = notificationRepository,
        _idGenerator = idGenerator ?? (() => const Uuid().v4());

  /// Builds a deterministic deduplication key for an alert and recipient.
  String buildNotificationKey(AttendanceAlert alert, {String? recipientId}) {
    final base = 'notif_${alert.id}_${alert.status.name}_${alert.severity.name}';
    return recipientId != null ? '${base}_$recipientId' : base;
  }

  /// Maps alert severity to standard notification priority.
  NotificationPriority mapSeverityToPriority(AttendanceAlertSeverity severity) {
    switch (severity) {
      case AttendanceAlertSeverity.critical:
        return NotificationPriority.critical;
      case AttendanceAlertSeverity.warning:
        return NotificationPriority.high;
      case AttendanceAlertSeverity.info:
        return NotificationPriority.normal;
    }
  }

  /// Converts an AttendanceAlert into relevant target notifications for authorized roles.
  List<NotificationModel> buildNotificationsForAlert({
    required AttendanceAlert alert,
    NotificationPreferences? prefs,
    bool recordKeys = false,
  }) {
    final notifications = <NotificationModel>[];
    final now = DateTime.now();
    final priority = mapSeverityToPriority(alert.severity);

    // 1. Personal Student Notification
    if (alert.studentId != null && alert.studentId!.isNotEmpty) {
      final studentKey = buildNotificationKey(alert, recipientId: alert.studentId);
      if (!_dispatchedKeys.contains(studentKey)) {
        final shouldSend = (alert.severity == AttendanceAlertSeverity.critical) ||
            (prefs == null || prefs.attendanceAlerts);

        if (shouldSend) {
          if (recordKeys) _dispatchedKeys.add(studentKey);
          notifications.add(NotificationModel(
            id: _idGenerator(),
            title: alert.title,
            message: alert.message,
            category: NotificationCategory.attendance,
            priority: priority,
            audienceType: NotificationAudienceType.personal,
            timestamp: now,
            recipientUserId: alert.studentId,
            recipientRole: AppRole.student,
            collegeId: alert.collegeId,
            departmentId: alert.departmentId,
            sectionId: alert.sectionId,
            relatedEntityId: alert.id,
            relatedEntityType: 'attendance_alert',
            navigationTarget: alert.studentId != null
                ? '/attendance/analytics/student/${alert.studentId}'
                : '/attendance/alerts/${alert.id}',
          ));
        }
      }
    }

    // 2. Assigned Faculty Notification
    if (alert.facultyId != null && alert.facultyId!.isNotEmpty) {
      final facultyKey = buildNotificationKey(alert, recipientId: alert.facultyId);
      if (!_dispatchedKeys.contains(facultyKey)) {
        if (recordKeys) _dispatchedKeys.add(facultyKey);
        notifications.add(NotificationModel(
          id: _idGenerator(),
          title: 'Faculty Notice: ${alert.title}',
          message: alert.message,
          category: NotificationCategory.attendance,
          priority: priority,
          audienceType: NotificationAudienceType.personal,
          timestamp: now,
          recipientUserId: alert.facultyId,
          recipientRole: AppRole.faculty,
          collegeId: alert.collegeId,
          departmentId: alert.departmentId,
          sectionId: alert.sectionId,
          relatedEntityId: alert.id,
          relatedEntityType: 'attendance_alert',
          navigationTarget: alert.subjectId != null
              ? '/attendance/analytics/subject/${alert.subjectId}'
              : '/attendance/alerts/${alert.id}',
        ));
      }
    }

    // 3. Department HOD Notification (Critical or Unmarked or Significant Drop)
    if (alert.departmentId.isNotEmpty &&
        (alert.severity == AttendanceAlertSeverity.critical ||
            alert.alertType == AttendanceAlertType.unmarkedAttendance)) {
      final hodKey = buildNotificationKey(alert, recipientId: alert.departmentId);
      if (!_dispatchedKeys.contains(hodKey)) {
        if (recordKeys) _dispatchedKeys.add(hodKey);
        notifications.add(NotificationModel(
          id: _idGenerator(),
          title: 'Dept Alert: ${alert.title}',
          message: alert.message,
          category: NotificationCategory.attendance,
          priority: priority,
          audienceType: NotificationAudienceType.department,
          timestamp: now,
          recipientRole: AppRole.hod,
          collegeId: alert.collegeId,
          departmentId: alert.departmentId,
          sectionId: alert.sectionId,
          relatedEntityId: alert.id,
          relatedEntityType: 'attendance_alert',
          navigationTarget: '/attendance/alerts/${alert.id}',
        ));
      }
    }

    // 4. College Admin Notification (Critical alerts only)
    if (alert.severity == AttendanceAlertSeverity.critical && alert.collegeId.isNotEmpty) {
      final adminKey = buildNotificationKey(alert, recipientId: alert.collegeId);
      if (!_dispatchedKeys.contains(adminKey)) {
        if (recordKeys) _dispatchedKeys.add(adminKey);
        notifications.add(NotificationModel(
          id: _idGenerator(),
          title: 'Institutional Compliance: ${alert.title}',
          message: alert.message,
          category: NotificationCategory.attendance,
          priority: NotificationPriority.critical,
          audienceType: NotificationAudienceType.college,
          timestamp: now,
          recipientRole: AppRole.collegeAdmin,
          collegeId: alert.collegeId,
          departmentId: alert.departmentId,
          relatedEntityId: alert.id,
          relatedEntityType: 'attendance_alert',
          navigationTarget: '/attendance/alerts/${alert.id}',
        ));
      }
    }

    return notifications;
  }

  /// Builds a grouped digest notification for HOD / Admin when multiple students have shortages.
  NotificationModel? buildGroupedShortageNotification({
    required String departmentId,
    required String collegeId,
    required List<AttendanceAlert> alerts,
    String? sectionId,
  }) {
    if (alerts.isEmpty) return null;

    final count = alerts.length;
    final title = sectionId != null
        ? '$count Students with Low Attendance in Section'
        : '$count Students with Low Attendance in Department';
    final message = sectionId != null
        ? '$count students in Section $sectionId have attendance below the required 75% threshold.'
        : '$count students across department $departmentId have attendance below 75%. Review department analytics.';

    return NotificationModel(
      id: _idGenerator(),
      title: title,
      message: message,
      category: NotificationCategory.attendance,
      priority: count >= 5 ? NotificationPriority.critical : NotificationPriority.high,
      audienceType: NotificationAudienceType.department,
      timestamp: DateTime.now(),
      recipientRole: AppRole.hod,
      collegeId: collegeId,
      departmentId: departmentId,
      sectionId: sectionId,
      relatedEntityType: 'attendance_summary',
      navigationTarget: sectionId != null
          ? '/attendance/analytics/section/$sectionId'
          : '/attendance/analytics',
    );
  }

  /// Dispatches notifications for a list of generated alerts in a safe, non-blocking manner.
  Future<List<NotificationModel>> dispatchAlerts({
    required List<AttendanceAlert> alerts,
    NotificationPreferences? prefs,
    bool groupForDepartment = true,
  }) async {
    final dispatched = <NotificationModel>[];

    for (final alert in alerts) {
      final notifications = buildNotificationsForAlert(alert: alert, prefs: prefs, recordKeys: true);
      for (final n in notifications) {
        try {
          if (n.audienceType == NotificationAudienceType.personal) {
            await _notificationRepository.createPersonalNotification(n);
          } else {
            await _notificationRepository.createAnnouncement(n);
          }
          dispatched.add(n);
        } catch (e) {
          // Log and continue without blocking attendance flow
          debugPrint('Error delivering attendance notification: $e');
        }
      }
    }

    // Optionally generate grouped notification for HOD if there are multiple low attendance alerts
    if (groupForDepartment && alerts.length >= 2) {
      final byDept = <String, List<AttendanceAlert>>{};
      for (final a in alerts.where((a) => a.alertType == AttendanceAlertType.lowAttendance)) {
        if (a.departmentId.isNotEmpty) {
          byDept.putIfAbsent(a.departmentId, () => []).add(a);
        }
      }

      for (final entry in byDept.entries) {
        final grouped = buildGroupedShortageNotification(
          departmentId: entry.key,
          collegeId: entry.value.first.collegeId,
          alerts: entry.value,
        );
        if (grouped != null) {
          try {
            await _notificationRepository.createAnnouncement(grouped);
            dispatched.add(grouped);
          } catch (e) {
            debugPrint('Error delivering grouped notification: $e');
          }
        }
      }
    }

    return dispatched;
  }

  /// Safely resolves and dispatches notifications asynchronously without throwing or interrupting callers.
  Future<void> safeDispatch({
    required List<AttendanceAlert> alerts,
    NotificationPreferences? prefs,
  }) async {
    try {
      await dispatchAlerts(alerts: alerts, prefs: prefs);
    } catch (e, st) {
      debugPrint('Non-blocking attendance notification error: $e\n$st');
    }
  }
}
