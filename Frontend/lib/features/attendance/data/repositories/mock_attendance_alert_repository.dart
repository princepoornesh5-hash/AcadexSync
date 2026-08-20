import '../../../../features/auth/domain/models/role_enum.dart';
import '../../../../features/auth/domain/models/user_model.dart';
import '../../domain/models/attendance_alert.dart';
import '../../domain/repositories/attendance_alert_repository.dart';

/// In-memory Mock implementation of AttendanceAlertRepository for testing.
class MockAttendanceAlertRepository implements AttendanceAlertRepository {
  final Map<String, AttendanceAlert> _store = {};

  MockAttendanceAlertRepository([List<AttendanceAlert>? initialAlerts]) {
    if (initialAlerts != null) {
      for (final a in initialAlerts) {
        _store[a.id] = a;
      }
    }
  }

  @override
  Future<List<AttendanceAlert>> getAlerts({
    required UserModel user,
    AttendanceAlertFilter? filter,
    String? searchQuery,
  }) async {
    var alerts = _store.values.toList();

    // 1. Tenant Scoping
    if (user.role != AppRole.superAdmin && user.collegeId != null && user.collegeId!.isNotEmpty) {
      alerts = alerts.where((a) => a.collegeId == user.collegeId).toList();
    }

    // 2. Role Scoping
    switch (user.role) {
      case AppRole.student:
        alerts = alerts.where((a) => a.studentId == user.id).toList();
        break;
      case AppRole.faculty:
        alerts = alerts.where((a) => a.facultyId == user.id).toList();
        break;
      case AppRole.hod:
        if (user.departmentId != null && user.departmentId!.isNotEmpty) {
          alerts = alerts.where((a) => a.departmentId == user.departmentId).toList();
        }
        break;
      case AppRole.collegeAdmin:
      case AppRole.superAdmin:
        break;
    }

    // 3. Filters
    if (filter != null) {
      if (filter.severity != null) {
        alerts = alerts.where((a) => a.severity == filter.severity).toList();
      }
      if (filter.status != null) {
        alerts = alerts.where((a) => a.status == filter.status).toList();
      }
      if (filter.unreadOnly == true) {
        alerts = alerts.where((a) => a.isRead == false).toList();
      }
      if (filter.alertType != null) {
        alerts = alerts.where((a) => a.alertType == filter.alertType).toList();
      }
      if (filter.sectionId != null && filter.sectionId!.isNotEmpty) {
        alerts = alerts.where((a) => a.sectionId == filter.sectionId).toList();
      }
      if (filter.subjectId != null && filter.subjectId!.isNotEmpty) {
        alerts = alerts.where((a) => a.subjectId == filter.subjectId).toList();
      }
    }

    // 4. Search
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      alerts = alerts.where((a) {
        final studentMatch = a.studentName?.toLowerCase().contains(q) ?? false;
        final rollMatch = a.rollNumber?.toLowerCase().contains(q) ?? false;
        final subjectMatch = a.subjectName?.toLowerCase().contains(q) ?? false;
        final sectionMatch = a.sectionId?.toLowerCase().contains(q) ?? false;
        final titleMatch = a.title.toLowerCase().contains(q);
        final messageMatch = a.message.toLowerCase().contains(q);
        return studentMatch || rollMatch || subjectMatch || sectionMatch || titleMatch || messageMatch;
      }).toList();
    }

    // 5. Sort: Critical first, then newest
    alerts.sort((a, b) {
      final severityWeightA = a.severity == AttendanceAlertSeverity.critical
          ? 2
          : (a.severity == AttendanceAlertSeverity.warning ? 1 : 0);
      final severityWeightB = b.severity == AttendanceAlertSeverity.critical
          ? 2
          : (b.severity == AttendanceAlertSeverity.warning ? 1 : 0);

      if (severityWeightA != severityWeightB) {
        return severityWeightB.compareTo(severityWeightA);
      }
      return b.createdAt.compareTo(a.createdAt);
    });

    return alerts;
  }

  @override
  Stream<List<AttendanceAlert>> streamAlerts({
    required UserModel user,
    AttendanceAlertFilter? filter,
    String? searchQuery,
  }) async* {
    yield await getAlerts(user: user, filter: filter, searchQuery: searchQuery);
  }

  @override
  Future<AttendanceAlert?> getAlertById(String alertId) async {
    return _store[alertId];
  }

  @override
  Future<void> saveAlert(AttendanceAlert alert) async {
    _store[alert.id] = alert;
  }

  @override
  Future<void> saveAlerts(List<AttendanceAlert> alerts) async {
    for (final a in alerts) {
      _store[a.id] = a;
    }
  }

  @override
  Future<void> markAsRead(String alertId) async {
    final existing = _store[alertId];
    if (existing != null) {
      _store[alertId] = existing.copyWith(
        isRead: true,
        readAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<void> markAllAsRead({required UserModel user}) async {
    final alerts = await getAlerts(user: user, filter: const AttendanceAlertFilter(unreadOnly: true));
    final now = DateTime.now();
    for (final a in alerts) {
      _store[a.id] = a.copyWith(
        isRead: true,
        readAt: now,
        updatedAt: now,
      );
    }
  }

  @override
  Future<void> acknowledgeAlert(String alertId) async {
    final existing = _store[alertId];
    if (existing != null) {
      _store[alertId] = existing.copyWith(
        status: AttendanceAlertStatus.acknowledged,
        acknowledgedAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isRead: true,
      );
    }
  }

  @override
  Future<void> resolveAlert(String alertId) async {
    final existing = _store[alertId];
    if (existing != null) {
      _store[alertId] = existing.copyWith(
        status: AttendanceAlertStatus.resolved,
        resolvedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<AttendanceAlertSummary> getAlertSummary({required UserModel user}) async {
    final alerts = await getAlerts(user: user);
    return AttendanceAlertSummary.fromAlerts(alerts);
  }
}
