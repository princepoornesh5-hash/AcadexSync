import 'dart:async';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import '../../../../core/firebase/firebase_services.dart';
import '../../../../features/auth/domain/models/user_model.dart';
import '../../domain/models/notification_models.dart';
import '../../../settings/domain/models/settings_models.dart';
import 'notification_repository.dart';

class FirebaseNotificationRepository implements NotificationRepository {
  final FirestoreService _firestoreService;

  FirebaseNotificationRepository(this._firestoreService);

  @override
  Stream<List<NotificationModel>> watchNotifications(UserModel user, NotificationPreferences prefs) {
    // We will listen to multiple scopes and merge them using a StreamController.
    final controller = StreamController<List<NotificationModel>>();
    
    // Maintain a local map of notification ID to NotificationModel
    final notificationMap = <String, NotificationModel>{};
    
    // Subscriptions
    final subs = <StreamSubscription>[];

    void emitUpdate() {
      if (controller.isClosed) return;
      
      final list = notificationMap.values.toList();
      
      // Apply preferences filtering locally since we can't easily do it in complex Firestore streams
      final filtered = list.where((n) {
        if (n.category == NotificationCategory.attendance && !prefs.attendanceAlerts) return false;
        if (n.category == NotificationCategory.academic && !prefs.academicUpdates) return false;
        if (n.category == NotificationCategory.notes && !prefs.notesUploaded) return false;
        if (n.category == NotificationCategory.certificates && !prefs.certificateUpdates) return false;
        if (n.category == NotificationCategory.system && !prefs.generalNotifications) return false;
        return true;
      }).toList();

      filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      controller.add(filtered);
    }

    void handleStreamUpdate(List<Map<String, dynamic>> rawDocs) {
      for (final raw in rawDocs) {
        final n = NotificationModel.fromJson(raw);
        notificationMap[n.id] = n;
      }
      emitUpdate();
    }

    // 1. Personal Scope
    subs.add(_firestoreService.watchQuery('notifications', {
      'recipientUserId': user.id,
      'audienceType': NotificationAudienceType.personal.name,
    }).listen(handleStreamUpdate));

    // 2. Platform Scope
    subs.add(_firestoreService.watchQuery('notifications', {
      'audienceType': NotificationAudienceType.platform.name,
    }).listen(handleStreamUpdate));

    // 3. College Scope (if user has collegeId)
    if (user.collegeId != null) {
      subs.add(_firestoreService.watchQuery('notifications', {
        'collegeId': user.collegeId,
        'audienceType': NotificationAudienceType.college.name,
      }).listen(handleStreamUpdate));
    }

    // 4. Department Scope (if user has departmentId)
    if (user.departmentId != null) {
      subs.add(_firestoreService.watchQuery('notifications', {
        'departmentId': user.departmentId,
        'audienceType': NotificationAudienceType.department.name,
      }).listen(handleStreamUpdate));
    }

    // 5. Role Scope
    subs.add(_firestoreService.watchQuery('notifications', {
      'recipientRole': user.role.value,
      'audienceType': NotificationAudienceType.role.name,
    }).listen(handleStreamUpdate));

    controller.onCancel = () {
      for (final sub in subs) {
        sub.cancel();
      }
    };

    return controller.stream;
  }

  @override
  Future<void> markAsRead(String id, String userId) async {
    final doc = await _firestoreService.getDocument('notifications', id);
    if (doc != null) {
      // In a real multi-tenant scenario for announcements (where many read the same document),
      // tracking read state per user requires a subcollection. 
      // For this simplified architecture, we will track the state if it's a personal notification,
      // or we maintain a local override list for announcements in the user's profile.
      // But per prompt rules: "A user may modify only their own notification read state."
      // Since changing an announcement's isRead field would affect everyone, we must ensure it's personal.
      // Wait, if it's an announcement, we should just ignore it or build read receipts.
      // Since prompt specifies "Users must not modify: recipientUserId ... through a normal read-state update",
      // we'll update it directly if it's a personal notification.
      
      final n = NotificationModel.fromJson(doc);
      if (n.audienceType == NotificationAudienceType.personal && n.recipientUserId == userId) {
         await _firestoreService.setDocument('notifications', id, {
           'isRead': true,
           'readAt': DateTime.now().toIso8601String(),
         });
      }
    }
  }

  @override
  Future<void> markAsUnread(String id, String userId) async {
    final doc = await _firestoreService.getDocument('notifications', id);
    if (doc != null) {
      final n = NotificationModel.fromJson(doc);
      if (n.audienceType == NotificationAudienceType.personal && n.recipientUserId == userId) {
         await _firestoreService.setDocument('notifications', id, {
           'isRead': false,
         });
      }
    }
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    // Note: Due to limitations of not having Cloud Functions in this prompt,
    // marking all as read is difficult without downloading all docs.
    // We will do a client-side batch for personal unread notifications.
    final docs = await _firestoreService.queryCollection('notifications', {
      'recipientUserId': userId,
      'isRead': false,
    });
    
    for (final raw in docs) {
      await _firestoreService.setDocument('notifications', raw['id'], {
        'isRead': true,
        'readAt': DateTime.now().toIso8601String(),
      });
    }
  }

  @override
  Future<void> deleteNotification(String id, String userId) async {
    final doc = await _firestoreService.getDocument('notifications', id);
    if (doc != null) {
      final n = NotificationModel.fromJson(doc);
      if (n.recipientUserId == userId) {
        await _firestoreService.deleteDocument('notifications', id);
      }
    }
  }

  @override
  Future<void> clearAll(String userId) async {
    final docs = await _firestoreService.queryCollection('notifications', {
      'recipientUserId': userId,
    });
    for (final raw in docs) {
      await _firestoreService.deleteDocument('notifications', raw['id']);
    }
  }

  @override
  Future<NotificationModel> createPersonalNotification(NotificationModel notification) async {
    final newId = 'notif_${DateTime.now().millisecondsSinceEpoch}';
    final n = notification.copyWith(id: newId, audienceType: NotificationAudienceType.personal);
    await _firestoreService.setDocument('notifications', newId, n.toJson());
    return n;
  }

  @override
  Future<NotificationModel> createAnnouncement(NotificationModel notification) async {
    final newId = 'announcement_${DateTime.now().millisecondsSinceEpoch}';
    final n = notification.copyWith(id: newId);
    await _firestoreService.setDocument('notifications', newId, n.toJson());
    return n;
  }
}
