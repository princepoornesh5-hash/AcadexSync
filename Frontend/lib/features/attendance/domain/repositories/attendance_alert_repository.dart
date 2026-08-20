import '../../../../features/auth/domain/models/user_model.dart';
import '../models/attendance_alert.dart';

/// Repository contract for managing attendance alerts, notifications, and early-warning lifecycles.
abstract class AttendanceAlertRepository {
  /// Fetches alerts scoped to the authorized user's role and tenant boundary.
  Future<List<AttendanceAlert>> getAlerts({
    required UserModel user,
    AttendanceAlertFilter? filter,
    String? searchQuery,
  });

  /// Real-time stream of scoped alerts.
  Stream<List<AttendanceAlert>> streamAlerts({
    required UserModel user,
    AttendanceAlertFilter? filter,
    String? searchQuery,
  });

  /// Fetches a single alert by its unique ID.
  Future<AttendanceAlert?> getAlertById(String alertId);

  /// Persists a new or updated alert document.
  Future<void> saveAlert(AttendanceAlert alert);

  /// Batch persists alerts with deduplication support.
  Future<void> saveAlerts(List<AttendanceAlert> alerts);

  /// Marks a specific alert as read.
  Future<void> markAsRead(String alertId);

  /// Marks all visible alerts as read for the current user.
  Future<void> markAllAsRead({required UserModel user});

  /// Updates alert lifecycle status to acknowledged.
  Future<void> acknowledgeAlert(String alertId);

  /// Updates alert lifecycle status to resolved.
  Future<void> resolveAlert(String alertId);

  /// Computes summary metrics (critical, warning, unread, active) for dashboard widgets.
  Future<AttendanceAlertSummary> getAlertSummary({required UserModel user});
}
