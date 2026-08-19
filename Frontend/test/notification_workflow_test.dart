import 'package:flutter_test/flutter_test.dart';
import 'package:campus_management/features/notifications/domain/models/notification_models.dart';
import 'package:campus_management/features/notifications/data/repositories/firebase_notification_repository.dart';
import 'package:campus_management/features/notifications/domain/services/notification_service.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/settings/domain/models/settings_models.dart';
import 'package:campus_management/core/firebase/firebase_services.dart';

class FakeFirestoreService implements FirestoreService {
  final Map<String, Map<String, dynamic>> _db = {};

  @override
  Future<void> setDocument(String collection, String id, Map<String, dynamic> data) async {
    final path = '$collection/$id';
    if (_db.containsKey(path)) {
      _db[path]!.addAll(data);
    } else {
      _db[path] = data;
    }
  }

  @override
  Future<Map<String, dynamic>?> getDocument(String collection, String id) async {
    return _db['$collection/$id'];
  }

  @override
  Future<void> deleteDocument(String collection, String id) async {
    _db.remove('$collection/$id');
  }

  @override
  Future<List<Map<String, dynamic>>> queryCollection(String collection, Map<String, dynamic> filters) async {
    final docs = _db.entries
        .where((e) => e.key.startsWith('$collection/'))
        .map((e) => e.value)
        .toList();
        
    if (filters.isEmpty) return docs;
    
    return docs.where((doc) {
      for (final entry in filters.entries) {
        if (doc[entry.key] != entry.value) return false;
      }
      return true;
    }).toList();
  }

  @override
  Stream<List<Map<String, dynamic>>> watchQuery(String collection, Map<String, dynamic> filters, {bool descending = false, int? limit, String? orderBy}) async* {
    // Basic mock stream that just emits the current snapshot once for testing
    yield await queryCollection(collection, filters);
  }
  
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Prompt 62: Notification Workflow Integration', () {
    late FakeFirestoreService firestoreService;
    late FirebaseNotificationRepository repo;
    late NotificationService service;

    setUp(() {
      firestoreService = FakeFirestoreService();
      repo = FirebaseNotificationRepository(firestoreService);
      service = NotificationService(repo, firestoreService);
    });

    test('1. Fan-out Notifications (Note Published)', () async {
      // 1. Seed students in sec1
      await firestoreService.setDocument('user_profiles', 'profile1', {
        'userId': 'student1',
        'sectionId': 'sec1',
      });
      await firestoreService.setDocument('user_profiles', 'profile2', {
        'userId': 'student2',
        'sectionId': 'sec1',
      });
      await firestoreService.setDocument('user_profiles', 'profile3', {
        'userId': 'student3',
        'sectionId': 'sec2', // different section
      });

      // 2. Trigger NotificationService
      await service.notifyNotePublished(
        noteId: 'note123',
        noteTitle: 'Chapter 1',
        sectionId: 'sec1',
      );

      // 3. Verify exactly 2 notifications were generated for sec1 students
      final allNotifs = await firestoreService.queryCollection('notifications', {});
      expect(allNotifs.length, 2);
      expect(allNotifs.any((n) => n['recipientUserId'] == 'student1'), isTrue);
      expect(allNotifs.any((n) => n['recipientUserId'] == 'student2'), isTrue);
      expect(allNotifs.any((n) => n['recipientUserId'] == 'student3'), isFalse);
    });

    test('2. Watch Notifications & Tenant Scope', () async {
      // Seed notifications
      await repo.createPersonalNotification(
        NotificationModel(
          id: 'n1',
          title: 'Personal',
          message: 'msg',
          category: NotificationCategory.general,
          priority: NotificationPriority.normal,
          audienceType: NotificationAudienceType.personal,
          timestamp: DateTime.now(),
          recipientUserId: 'userA',
        ),
      );

      await repo.createAnnouncement(
        NotificationModel(
          id: 'n2',
          title: 'College Announcement',
          message: 'msg',
          category: NotificationCategory.system,
          priority: NotificationPriority.high,
          audienceType: NotificationAudienceType.college,
          timestamp: DateTime.now(),
          collegeId: 'colA',
        ),
      );

      // Setup UserModel for userA in colA
      final userA = UserModel(
        id: 'userA',
        name: 'User A',
        email: 'userA@test.com',
        role: AppRole.student,
        collegeId: 'colA',
      );

      final prefs = const NotificationPreferences(
        attendanceAlerts: true,
        academicUpdates: true,
        notesUploaded: true,
        certificateUpdates: true,
        generalNotifications: true,
        announcements: true,
      );

      // Watch notifications
      final stream = repo.watchNotifications(userA, prefs);
      List<NotificationModel> latestA = [];
      final subA = stream.listen((l) => latestA = l);
      await Future.delayed(const Duration(milliseconds: 50));

      // userA should see both personal and their college announcement
      expect(latestA.length, 2);
      await subA.cancel();

      // Setup UserModel for userB in colB
      final userB = UserModel(
        id: 'userB',
        name: 'User B',
        email: 'userB@test.com',
        role: AppRole.student,
        collegeId: 'colB',
      );

      final streamB = repo.watchNotifications(userB, prefs);
      List<NotificationModel> latestB = [];
      final subB = streamB.listen((l) => latestB = l);
      await Future.delayed(const Duration(milliseconds: 50));

      // userB should see 0 notifications (not userA, not colA)
      expect(latestB.length, 0);
      await subB.cancel();
    });

    test('3. Mark As Read / Unread / Mark All Read', () async {
      final n1 = await repo.createPersonalNotification(
        NotificationModel(
          id: '',
          title: 'Notif 1',
          message: 'msg',
          category: NotificationCategory.general,
          priority: NotificationPriority.normal,
          audienceType: NotificationAudienceType.personal,
          timestamp: DateTime.now(),
          recipientUserId: 'userX',
          isRead: false,
        ),
      );

      final n2 = await repo.createPersonalNotification(
        NotificationModel(
          id: '',
          title: 'Notif 2',
          message: 'msg',
          category: NotificationCategory.general,
          priority: NotificationPriority.normal,
          audienceType: NotificationAudienceType.personal,
          timestamp: DateTime.now(),
          recipientUserId: 'userX',
          isRead: false,
        ),
      );

      // Test individual Mark as Read
      await repo.markAsRead(n1.id, 'userX');
      var doc = await firestoreService.getDocument('notifications', n1.id);
      expect(doc!['isRead'], true);

      // Test individual Mark as Unread
      await repo.markAsUnread(n1.id, 'userX');
      doc = await firestoreService.getDocument('notifications', n1.id);
      expect(doc!['isRead'], false);

      // Test Mark All as Read
      await repo.markAllAsRead('userX');
      
      final d1 = await firestoreService.getDocument('notifications', n1.id);
      final d2 = await firestoreService.getDocument('notifications', n2.id);
      
      expect(d1!['isRead'], true);
      expect(d2!['isRead'], true);
    });

    test('4. Security: User cannot modify another users notification', () async {
      final nPrivate = await repo.createPersonalNotification(
        NotificationModel(
          id: '',
          title: 'Private',
          message: 'msg',
          category: NotificationCategory.general,
          priority: NotificationPriority.normal,
          audienceType: NotificationAudienceType.personal,
          timestamp: DateTime.now(),
          recipientUserId: 'userPrivate',
          isRead: false,
        ),
      );

      // Attempt to mark as read by a different user
      await repo.markAsRead(nPrivate.id, 'maliciousUser');

      // Assert it remains unread
      var doc = await firestoreService.getDocument('notifications', nPrivate.id);
      expect(doc!['isRead'], false);
    });
  });
}
