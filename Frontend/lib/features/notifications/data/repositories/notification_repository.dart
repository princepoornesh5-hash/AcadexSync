import '../../../../features/auth/domain/models/user_model.dart';
import '../../domain/models/notification_models.dart';
import '../../../settings/domain/models/settings_models.dart';

abstract class NotificationRepository {
  /// Watches all relevant notifications for a user based on their identity and preferences.
  Stream<List<NotificationModel>> watchNotifications(UserModel user, NotificationPreferences prefs);

  /// Marks a specific notification as read.
  Future<void> markAsRead(String id, String userId);

  /// Marks a specific notification as unread.
  Future<void> markAsUnread(String id, String userId);

  /// Marks all notifications for a user as read.
  Future<void> markAllAsRead(String userId);

  /// Deletes a specific notification.
  Future<void> deleteNotification(String id, String userId);

  /// Clears all notifications for a user.
  Future<void> clearAll(String userId);

  /// Creates a personal notification for a specific user.
  Future<NotificationModel> createPersonalNotification(NotificationModel notification);

  /// Creates an announcement for a specific audience (Role, Dept, College, Platform).
  Future<NotificationModel> createAnnouncement(NotificationModel notification);
}
