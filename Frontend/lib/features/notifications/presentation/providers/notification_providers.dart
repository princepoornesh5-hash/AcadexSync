import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/firebase/firebase_services.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../../settings/domain/models/settings_models.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../../domain/models/notification_models.dart';
import '../../domain/models/announcement_model.dart';
import '../../domain/services/notification_service.dart';
import '../../../attendance/domain/services/attendance_notification_dispatcher.dart';
import '../../data/repositories/notification_repository.dart';
import '../../data/repositories/api_notification_repository.dart';

// --- Repository Provider ---
final apiNotificationRepositoryProvider = Provider<ApiNotificationRepository>((ref) {
  return ApiNotificationRepository();
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return ref.watch(apiNotificationRepositoryProvider);
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final repo = ref.watch(notificationRepositoryProvider);
  final firestoreService = ref.watch(firestoreServiceProvider);
  return NotificationService(repo, firestoreService);
});

final attendanceNotificationDispatcherProvider = Provider<AttendanceNotificationDispatcher>((ref) {
  final repo = ref.watch(notificationRepositoryProvider);
  return AttendanceNotificationDispatcher(notificationRepository: repo);
});


// --- Filter Providers ---
enum NotificationFilter { all, unread, read, announcements, attendance, academic, notes, timetable, system, security }

final notificationFilterProvider = StateProvider<NotificationFilter>((ref) => NotificationFilter.all);

// --- Stream Notifier Provider ---
class NotificationsNotifier extends AutoDisposeStreamNotifier<List<NotificationModel>> {
  @override
  Stream<List<NotificationModel>> build() {
    final authState = ref.watch(authProvider);
    final prefsAsync = ref.watch(notificationPreferencesProvider);

    if (authState is! AuthAuthenticated) {
      return Stream.value([]);
    }
    
    final prefs = prefsAsync.value ??
        NotificationPreferences(
          attendanceAlerts: true,
          academicUpdates: true,
          announcements: true,
          notesUploaded: true,
          certificateUpdates: true,
          generalNotifications: true,
        );

    final repo = ref.watch(notificationRepositoryProvider);
    return repo.watchNotifications(authState.user, prefs);
  }

  Future<void> markAsRead(String id) async {
    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated) return;
    
    await ref.read(notificationRepositoryProvider).markAsRead(id, authState.user.id);
  }

  Future<void> markAsUnread(String id) async {
    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated) return;
    
    await ref.read(notificationRepositoryProvider).markAsUnread(id, authState.user.id);
  }

  Future<void> markAllAsRead() async {
    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated) return;
    
    await ref.read(notificationRepositoryProvider).markAllAsRead(authState.user.id);
  }

  Future<void> deleteNotification(String id) async {
    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated) return;
    
    await ref.read(notificationRepositoryProvider).deleteNotification(id, authState.user.id);
  }

  Future<void> clearAll() async {
    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated) return;
    
    await ref.read(notificationRepositoryProvider).clearAll(authState.user.id);
  }
}

final notificationsProvider = StreamNotifierProvider.autoDispose<NotificationsNotifier, List<NotificationModel>>(() {
  return NotificationsNotifier();
});

// --- Computed Providers ---

final unreadNotificationCountProvider = Provider.autoDispose<int>((ref) {
  final asyncNotifications = ref.watch(notificationsProvider);
  return asyncNotifications.maybeWhen(
    data: (notifications) => notifications.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});

final filteredNotificationsProvider = Provider.autoDispose<List<NotificationModel>>((ref) {
  final asyncNotifications = ref.watch(notificationsProvider);
  final filter = ref.watch(notificationFilterProvider);

  return asyncNotifications.maybeWhen(
    data: (notifications) {
      switch (filter) {
        case NotificationFilter.all:
          return notifications;
        case NotificationFilter.unread:
          return notifications.where((n) => !n.isRead).toList();
        case NotificationFilter.read:
          return notifications.where((n) => n.isRead).toList();
        case NotificationFilter.attendance:
          return notifications.where((n) => n.category == NotificationCategory.attendance).toList();
        case NotificationFilter.announcements:
          return notifications.where((n) => n.category == NotificationCategory.announcement).toList();
        case NotificationFilter.academic:
          return notifications.where((n) => n.category == NotificationCategory.academic).toList();
        case NotificationFilter.notes:
          return notifications.where((n) => n.category == NotificationCategory.notes).toList();
        case NotificationFilter.timetable:
          return notifications.where((n) => n.category == NotificationCategory.timetable).toList();
        case NotificationFilter.system:
          return notifications.where((n) => n.category == NotificationCategory.system).toList();
        case NotificationFilter.security:
          return notifications.where((n) => n.category == NotificationCategory.security).toList();
      }
    },
    orElse: () => [],
  );
});

// --- Announcements Providers ---
final announcementsProvider = FutureProvider.autoDispose<List<AnnouncementModel>>((ref) async {
  final repo = ref.watch(apiNotificationRepositoryProvider);
  return repo.fetchAnnouncements(manage: false);
});

final announcementByIdProvider = FutureProvider.autoDispose.family<AnnouncementModel?, String>((ref, id) async {
  final repo = ref.watch(apiNotificationRepositoryProvider);
  return repo.getAnnouncementById(id);
});

class AdminAnnouncementFilter {
  final AnnouncementStatus? status;
  final AnnouncementAudienceScope? audienceScope;
  final String? departmentId;

  const AdminAnnouncementFilter({this.status, this.audienceScope, this.departmentId});
}

final adminAnnouncementFilterProvider = StateProvider<AdminAnnouncementFilter>((ref) => const AdminAnnouncementFilter());

final adminAnnouncementsProvider = FutureProvider.autoDispose<List<AnnouncementModel>>((ref) async {
  final repo = ref.watch(apiNotificationRepositoryProvider);
  final filter = ref.watch(adminAnnouncementFilterProvider);
  return repo.fetchAnnouncements(
    manage: true,
    status: filter.status?.apiValue,
    audienceScope: filter.audienceScope?.apiValue,
    departmentId: filter.departmentId,
  );
});

// --- Announcement Creation State ---
class AnnouncementCreationNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  AnnouncementCreationNotifier(this._ref) : super(const AsyncData(null));

  Future<AnnouncementModel> createAnnouncement(Map<String, dynamic> payload) async {
    state = const AsyncLoading();
    try {
      final repo = _ref.read(apiNotificationRepositoryProvider);
      final created = await repo.createAnnouncementApi(payload);
      _ref.invalidate(announcementsProvider);
      _ref.invalidate(adminAnnouncementsProvider);
      _ref.invalidate(notificationsProvider);
      _ref.invalidate(unreadNotificationCountProvider);
      _ref.invalidate(superAdminActivityProvider);
      _ref.invalidate(collegeAdminActivityProvider);
      _ref.invalidate(hodActivityProvider);
      _ref.invalidate(facultyActivityProvider);
      _ref.invalidate(studentActivityProvider);
      state = const AsyncData(null);
      return created;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> publishAnnouncement(String id) async {
    state = const AsyncLoading();
    try {
      final repo = _ref.read(apiNotificationRepositoryProvider);
      await repo.publishAnnouncement(id);
      _ref.invalidate(announcementsProvider);
      _ref.invalidate(adminAnnouncementsProvider);
      _ref.invalidate(notificationsProvider);
      _ref.invalidate(unreadNotificationCountProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> archiveAnnouncement(String id) async {
    state = const AsyncLoading();
    try {
      final repo = _ref.read(apiNotificationRepositoryProvider);
      await repo.archiveAnnouncement(id);
      _ref.invalidate(announcementsProvider);
      _ref.invalidate(adminAnnouncementsProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> deleteAnnouncement(String id) async {
    state = const AsyncLoading();
    try {
      final repo = _ref.read(apiNotificationRepositoryProvider);
      await repo.deleteAnnouncement(id);
      _ref.invalidate(announcementsProvider);
      _ref.invalidate(adminAnnouncementsProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final announcementCreationProvider = StateNotifierProvider<AnnouncementCreationNotifier, AsyncValue<void>>((ref) {
  return AnnouncementCreationNotifier(ref);
});
