import 'dart:async';
import '../../../../core/network/api_client.dart';
import '../../../../features/auth/domain/models/user_model.dart';
import '../../domain/models/notification_models.dart';
import '../../../settings/domain/models/settings_models.dart';
import 'notification_repository.dart';

class ApiNotificationRepository implements NotificationRepository {
  final ApiClient _apiClient;
  final _updateStreamController = StreamController<void>.broadcast();

  ApiNotificationRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Fetches a page of notifications from the backend API.
  Future<List<NotificationModel>> fetchNotifications({
    int page = 1,
    int limit = 50,
    bool? isRead,
    String? category,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (isRead != null) queryParams['isRead'] = isRead;
      if (category != null && category.isNotEmpty) queryParams['category'] = category;

      final response = await _apiClient.dio.get(
        '/notifications',
        queryParameters: queryParams,
      );

      final data = response.data;
      if (data != null && data['success'] == true && data['data'] != null) {
        final items = data['data']['items'] as List<dynamic>? ?? [];
        return items
            .map((item) => NotificationModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Fetches the authoritative unread notification count.
  Future<int> getUnreadCount() async {
    try {
      final response = await _apiClient.dio.get('/notifications/unread-count');
      final data = response.data;
      if (data != null && data['success'] == true && data['data'] != null) {
        return (data['data']['unreadCount'] as num?)?.toInt() ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Registers an FCM device token on the backend.
  Future<void> registerDeviceToken({
    required String deviceToken,
    required String platform,
    String? appVersion,
    String? deviceModel,
  }) async {
    try {
      await _apiClient.dio.post(
        '/notifications/device-tokens',
        data: {
          'deviceToken': deviceToken,
          'platform': platform,
          if (appVersion != null) 'appVersion': appVersion,
          if (deviceModel != null) 'deviceModel': deviceModel,
        },
      );
    } catch (e) {
      // Non-blocking device token registration
    }
  }

  /// Removes an FCM device token from the backend.
  Future<void> removeDeviceToken(String deviceToken) async {
    try {
      await _apiClient.dio.delete('/notifications/device-tokens/$deviceToken');
    } catch (e) {
      // Non-blocking token removal
    }
  }

  /// Fetches the user's notification preferences from the backend.
  Future<NotificationPreferences?> getPreferences() async {
    try {
      final response = await _apiClient.dio.get('/notifications/preferences');
      final data = response.data;
      if (data != null && data['success'] == true && data['data'] != null) {
        final map = data['data'] as Map<String, dynamic>;
        return NotificationPreferences(
          attendanceAlerts: map['attendance'] ?? true,
          academicUpdates: map['academic'] ?? true,
          announcements: map['announcements'] ?? true,
          notesUploaded: map['notes'] ?? true,
          certificateUpdates: map['certificates'] ?? true,
          generalNotifications: map['system'] ?? true,
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Updates notification preferences on the backend.
  Future<void> updatePreferences(NotificationPreferences prefs) async {
    try {
      await _apiClient.dio.put(
        '/notifications/preferences',
        data: {
          'notes': prefs.notesUploaded,
          'attendance': prefs.attendanceAlerts,
          'timetable': true,
          'pushEnabled': true,
        },
      );
    } catch (e) {
      // Non-blocking update error handling
    }
  }

  @override
  Stream<List<NotificationModel>> watchNotifications(
    UserModel user,
    NotificationPreferences prefs,
  ) {
    late StreamController<List<NotificationModel>> controller;
    StreamSubscription? updateSub;

    Future<void> loadAndEmit() async {
      try {
        final notifications = await fetchNotifications(page: 1, limit: 50);
        
        // Filter by user preferences locally as secondary check
        final filtered = notifications.where((n) {
          if (n.category == NotificationCategory.attendance && !prefs.attendanceAlerts) return false;
          if (n.category == NotificationCategory.academic && !prefs.academicUpdates) return false;
          if (n.category == NotificationCategory.notes && !prefs.notesUploaded) return false;
          if (n.category == NotificationCategory.certificates && !prefs.certificateUpdates) return false;
          if (n.category == NotificationCategory.system && !prefs.generalNotifications) return false;
          return true;
        }).toList();

        if (!controller.isClosed) {
          controller.add(filtered);
        }
      } catch (e) {
        if (!controller.isClosed) {
          controller.add([]);
        }
      }
    }

    controller = StreamController<List<NotificationModel>>(
      onListen: () {
        loadAndEmit();
        updateSub = _updateStreamController.stream.listen((_) => loadAndEmit());
      },
      onCancel: () {
        updateSub?.cancel();
        if (!controller.isClosed) {
          controller.close();
        }
      },
    );

    return controller.stream;
  }

  @override
  Future<void> markAsRead(String id, String userId) async {
    try {
      await _apiClient.dio.patch('/notifications/$id/read');
      _updateStreamController.add(null);
    } catch (e) {
      // Handle or log error
    }
  }

  @override
  Future<void> markAsUnread(String id, String userId) async {
    // Backend notifications are authoritative; markAsUnread is not supported on backend
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    try {
      await _apiClient.dio.patch('/notifications/read-all');
      _updateStreamController.add(null);
    } catch (e) {
      // Handle or log error
    }
  }

  @override
  Future<void> deleteNotification(String id, String userId) async {
    // Soft/local delete if needed
    _updateStreamController.add(null);
  }

  @override
  Future<void> clearAll(String userId) async {
    // Mark all as read on backend
    await markAllAsRead(userId);
  }

  @override
  Future<NotificationModel> createPersonalNotification(NotificationModel notification) async {
    // Creation is handled server-side upon events
    return notification;
  }

  @override
  Future<NotificationModel> createAnnouncement(NotificationModel notification) async {
    // Creation is handled server-side upon events
    return notification;
  }
}
