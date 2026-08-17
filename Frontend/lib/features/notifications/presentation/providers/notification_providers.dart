import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/firebase/firebase_initializer.dart';
import '../../../../core/firebase/firebase_services.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../../domain/models/notification_models.dart';
import '../../data/repositories/notification_repository.dart';
import '../../data/repositories/firebase_notification_repository.dart';
import '../../data/repositories/mock_notification_repository.dart';

// --- Repository Provider ---
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  if (FirebaseInitializer.shouldUseMock) {
    return mockNotificationRepo;
  }
  
  final firestoreService = ref.watch(firestoreServiceProvider);
  return FirebaseNotificationRepository(firestoreService);
});


// --- Filter Providers ---
enum NotificationFilter { all, unread, read, attendance, academic, system, security }

final notificationFilterProvider = StateProvider<NotificationFilter>((ref) => NotificationFilter.all);

// --- Stream Notifier Provider ---
class NotificationsNotifier extends StreamNotifier<List<NotificationModel>> {
  @override
  Stream<List<NotificationModel>> build() {
    final authState = ref.watch(authProvider);
    final prefsAsync = ref.watch(notificationPreferencesProvider);

    if (authState is! AuthAuthenticated) {
      return Stream.value([]);
    }
    
    final prefs = prefsAsync.valueOrNull;
    if (prefs == null) return Stream.value([]);

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

final notificationsProvider = StreamNotifierProvider<NotificationsNotifier, List<NotificationModel>>(() {
  return NotificationsNotifier();
});

// --- Computed Providers ---

final unreadNotificationCountProvider = Provider<int>((ref) {
  final asyncNotifications = ref.watch(notificationsProvider);
  return asyncNotifications.maybeWhen(
    data: (notifications) => notifications.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});

final filteredNotificationsProvider = Provider<List<NotificationModel>>((ref) {
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
        case NotificationFilter.academic:
          return notifications.where((n) => n.category == NotificationCategory.academic).toList();
        case NotificationFilter.system:
          return notifications.where((n) => n.category == NotificationCategory.system).toList();
        case NotificationFilter.security:
          return notifications.where((n) => n.category == NotificationCategory.security).toList();
      }
    },
    orElse: () => [],
  );
});

// --- Announcement Creation State ---
class AnnouncementCreationNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  AnnouncementCreationNotifier(this._ref) : super(const AsyncData(null));

  Future<void> createAnnouncement(NotificationModel model) async {
    state = const AsyncLoading();
    try {
      await _ref.read(notificationRepositoryProvider).createAnnouncement(model);
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
