import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:campus_management/core/network/api_client.dart';
import 'package:campus_management/features/notifications/data/repositories/api_notification_repository.dart';
import 'package:campus_management/features/notifications/domain/models/notification_models.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/settings/domain/models/settings_models.dart';

class MockDio extends Fake implements Dio {
  final Map<String, dynamic> responses = {};
  final List<String> recordedCalls = [];

  @override
  Future<Response<T>> get<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    recordedCalls.add('GET $path');
    final resData = responses['GET $path'] ?? {'success': true, 'data': {}};
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      data: resData as T,
      statusCode: 200,
    );
  }

  @override
  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    recordedCalls.add('POST $path');
    final resData = responses['POST $path'] ?? {'success': true, 'data': {}};
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      data: resData as T,
      statusCode: 201,
    );
  }

  @override
  Future<Response<T>> patch<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    recordedCalls.add('PATCH $path');
    final resData = responses['PATCH $path'] ?? {'success': true, 'data': {}};
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      data: resData as T,
      statusCode: 200,
    );
  }

  @override
  Future<Response<T>> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    recordedCalls.add('DELETE $path');
    final resData = responses['DELETE $path'] ?? {'success': true, 'data': {}};
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      data: resData as T,
      statusCode: 200,
    );
  }
}

void main() {
  late MockDio mockDio;
  late ApiClient apiClient;
  late ApiNotificationRepository repo;

  setUp(() {
    mockDio = MockDio();
    apiClient = ApiClient(customDio: mockDio);
    repo = ApiNotificationRepository(apiClient: apiClient);
  });

  test('1. fetchNotifications parses backend notifications payload correctly', () async {
    mockDio.responses['GET /notifications'] = {
      'success': true,
      'data': {
        'items': [
          {
            '_id': 'notif_123',
            'title': 'New Note Published',
            'body': 'Lecture 1 notes are uploaded',
            'category': 'notes',
            'priority': 'normal',
            'isRead': false,
            'createdAt': '2026-08-19T10:00:00.000Z',
          },
          {
            '_id': 'notif_124',
            'title': 'Timetable Changed',
            'body': 'Room 101 rescheduled',
            'category': 'timetable',
            'priority': 'high',
            'isRead': true,
            'createdAt': '2026-08-19T09:00:00.000Z',
          }
        ],
        'total': 2,
      }
    };

    final notifs = await repo.fetchNotifications();
    expect(notifs.length, 2);
    expect(notifs[0].id, 'notif_123');
    expect(notifs[0].title, 'New Note Published');
    expect(notifs[0].message, 'Lecture 1 notes are uploaded');
    expect(notifs[0].category, NotificationCategory.notes);
    expect(notifs[0].priority, NotificationPriority.normal);
    expect(notifs[0].isRead, false);

    expect(notifs[1].id, 'notif_124');
    expect(notifs[1].isRead, true);
    expect(notifs[1].category, NotificationCategory.timetable);
  });

  test('2. getUnreadCount retrieves unread count correctly', () async {
    mockDio.responses['GET /notifications/unread-count'] = {
      'success': true,
      'data': {
        'unreadCount': 5,
      }
    };

    final count = await repo.getUnreadCount();
    expect(count, 5);
    expect(mockDio.recordedCalls, contains('GET /notifications/unread-count'));
  });

  test('3. registerDeviceToken sends token and platform to backend', () async {
    mockDio.responses['POST /notifications/device-tokens'] = {
      'success': true,
      'data': {
        'deviceToken': 'fcm_flutter_token_123',
        'platform': 'android',
      }
    };

    await repo.registerDeviceToken(
      deviceToken: 'fcm_flutter_token_123',
      platform: 'android',
      appVersion: '1.0.0',
    );

    expect(mockDio.recordedCalls, contains('POST /notifications/device-tokens'));
  });

  test('4. removeDeviceToken sends DELETE request to backend', () async {
    await repo.removeDeviceToken('fcm_flutter_token_123');
    expect(mockDio.recordedCalls, contains('DELETE /notifications/device-tokens/fcm_flutter_token_123'));
  });

  test('5. markAsRead and markAllAsRead call PATCH endpoints', () async {
    await repo.markAsRead('notif_123', 'user_1');
    expect(mockDio.recordedCalls, contains('PATCH /notifications/notif_123/read'));

    await repo.markAllAsRead('user_1');
    expect(mockDio.recordedCalls, contains('PATCH /notifications/read-all'));
  });

  test('6. watchNotifications filters notifications according to user preferences', () async {
    mockDio.responses['GET /notifications'] = {
      'success': true,
      'data': {
        'items': [
          {
            '_id': 'notif_1',
            'title': 'Attendance marked',
            'body': 'Absent today',
            'category': 'attendance',
            'priority': 'normal',
          },
          {
            '_id': 'notif_2',
            'title': 'Note uploaded',
            'body': 'DSA notes',
            'category': 'notes',
            'priority': 'normal',
          }
        ],
      }
    };

    final user = UserModel(
      id: 'user_1',
      email: 'student@coea.edu',
      name: 'Alice Student',
      role: AppRole.student,
    );

    // Disable notes notifications in prefs
    final prefs = NotificationPreferences(
      attendanceAlerts: true,
      notesUploaded: false,
      academicUpdates: true,
      announcements: true,
      certificateUpdates: true,
      generalNotifications: true,
    );

    final stream = repo.watchNotifications(user, prefs);
    final emitted = await stream.first;

    expect(emitted.length, 1);
    expect(emitted[0].category, NotificationCategory.attendance);
  });
}
