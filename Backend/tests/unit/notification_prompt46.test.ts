import mongoose, { Types } from 'mongoose';
import { MongoMemoryServer } from 'mongodb-memory-server';
import {
  Notification,
  DeviceToken,
  NotificationPreference,
  College,
  User,
} from '../../src/models';
import {
  NotificationType,
  NotificationCategory,
  NotificationPriority,
  NotificationStatus,
  DevicePlatform,
} from '../../src/constants/notification.constants';
import { AppRole } from '../../src/constants/roles';
import { NotificationService } from '../../src/services/notification.service';
import { FcmService } from '../../src/services/fcm.service';
import { realtimeEventBus, AcadexEventType } from '../../src/realtime';

describe('PROMPT 46 — Notifications, Notification Center & Preferences Hardening Tests', () => {
  let mongoServer: MongoMemoryServer;
  let collegeAId: Types.ObjectId;
  let collegeBId: Types.ObjectId;
  let userA1Id: Types.ObjectId;
  let userA2Id: Types.ObjectId;
  let userB1Id: Types.ObjectId;

  const publishedEvents: any[] = [];
  let eventSub: any;

  beforeAll(async () => {
    mongoServer = await MongoMemoryServer.create();
    await mongoose.connect(mongoServer.getUri());

    collegeAId = new Types.ObjectId();
    collegeBId = new Types.ObjectId();
    userA1Id = new Types.ObjectId();
    userA2Id = new Types.ObjectId();
    userB1Id = new Types.ObjectId();

    await College.create([
      {
        _id: collegeAId,
        name: 'College Alpha',
        code: 'CALPHA',
        principal: 'Dr. Alpha',
        phone: '1111111111',
        email: 'alpha@acadex.edu',
        address: '1 Alpha Road',
      },
      {
        _id: collegeBId,
        name: 'College Beta',
        code: 'CBETA',
        principal: 'Dr. Beta',
        phone: '2222222222',
        email: 'beta@acadex.edu',
        address: '2 Beta Road',
      },
    ]);

    await User.create([
      {
        _id: userA1Id,
        instituteId: 'INST_USER_A1',
        collegeId: collegeAId,
        email: 'usera1@acadex.edu',
        name: 'Student A1',
        role: AppRole.STUDENT,
      },
      {
        _id: userA2Id,
        instituteId: 'INST_USER_A2',
        collegeId: collegeAId,
        email: 'usera2@acadex.edu',
        name: 'Faculty A2',
        role: AppRole.FACULTY,
      },
      {
        _id: userB1Id,
        instituteId: 'INST_USER_B1',
        collegeId: collegeBId,
        email: 'userb1@acadex.edu',
        name: 'Student B1',
        role: AppRole.STUDENT,
      },
    ]);

    // Capture realtime events
    eventSub = (event: any) => {
      publishedEvents.push(event);
    };
    realtimeEventBus.on('*', eventSub);
  });

  afterAll(async () => {
    if (eventSub) realtimeEventBus.off('*', eventSub);
    await mongoose.disconnect();
    await mongoServer.stop();
  });

  beforeEach(async () => {
    await Notification.deleteMany({});
    await DeviceToken.deleteMany({});
    await NotificationPreference.deleteMany({});
    publishedEvents.length = 0;
    FcmService.setMockMessagingForTesting(null);
  });

  // =========================================================================
  // 1. PERSISTENCE-FIRST GUARANTEE
  // =========================================================================
  describe('1. Persistence-First Guarantee', () => {
    it('creates persistent notification and emits realtime event after persistence', async () => {
      const notif = await NotificationService.createNotification({
        collegeId: collegeAId.toString(),
        recipientUserId: userA1Id.toString(),
        recipientRole: AppRole.STUDENT,
        title: 'Assignment Published',
        body: 'Chapter 3 exercises have been assigned.',
        notificationType: NotificationType.ASSIGNMENT_PUBLISHED,
        category: NotificationCategory.ASSIGNMENT,
        priority: NotificationPriority.NORMAL,
        entityType: 'Assignment',
        entityId: 'asg_123',
        deepLink: '/assignments/asg_123',
      });

      expect(notif).toBeDefined();
      expect(notif._id).toBeDefined();
      expect(notif.isRead).toBe(false);
      expect(notif.status).toBe(NotificationStatus.UNREAD);

      // Verify DB persistence
      const persisted = await Notification.findById(notif._id);
      expect(persisted).not.toBeNull();
      expect(persisted!.title).toBe('Assignment Published');
      expect(persisted!.deepLink).toBe('/assignments/asg_123');

      // Verify realtime event was emitted with user room scope
      const createdEvents = publishedEvents.filter(
        (e) => e.eventType === AcadexEventType.NOTIFICATION_CREATED
      );
      expect(createdEvents.length).toBe(1);
      expect(createdEvents[0].scope.type).toBe('user');
      expect(createdEvents[0].scope.userId).toBe(userA1Id.toString());
      expect(createdEvents[0].payload.notificationId).toBe(notif.id);
    });

    it('does not create visible notification if recipient is invalid', async () => {
      await expect(
        NotificationService.createNotification({
          collegeId: collegeAId.toString(),
          recipientUserId: 'invalid_id',
          title: 'Failed',
          body: 'Should fail',
          notificationType: NotificationType.SYSTEM,
        })
      ).rejects.toThrow();

      const count = await Notification.countDocuments({});
      expect(count).toBe(0);
    });
  });

  // =========================================================================
  // 2. AUTHORIZATION & TENANT ISOLATION
  // =========================================================================
  describe('2. Authorization & Tenant Isolation', () => {
    it('prevents User A2 from reading User A1 notification', async () => {
      const notif = await Notification.create({
        collegeId: collegeAId,
        recipientUserId: userA1Id,
        title: 'Private Alert',
        body: 'For A1 only',
        notificationType: NotificationType.SYSTEM,
      });

      await expect(
        NotificationService.getNotificationById(
          notif._id.toString(),
          userA2Id.toString(),
          collegeAId.toString()
        )
      ).rejects.toThrow('Notification not found or access denied');
    });

    it('prevents User A2 from marking User A1 notification as read', async () => {
      const notif = await Notification.create({
        collegeId: collegeAId,
        recipientUserId: userA1Id,
        title: 'Private Alert',
        body: 'For A1 only',
        notificationType: NotificationType.SYSTEM,
      });

      await expect(
        NotificationService.markAsRead(
          notif._id.toString(),
          userA2Id.toString(),
          collegeAId.toString()
        )
      ).rejects.toThrow('Notification not found or access denied');
    });

    it('rejects cross-tenant notification access (College B cannot read College A notification)', async () => {
      const notif = await Notification.create({
        collegeId: collegeAId,
        recipientUserId: userA1Id,
        title: 'College A Alert',
        body: 'Belongs to College A',
        notificationType: NotificationType.SYSTEM,
      });

      await expect(
        NotificationService.getNotificationById(
          notif._id.toString(),
          userA1Id.toString(),
          collegeBId.toString() // Wrong college
        )
      ).rejects.toThrow('Notification not found or access denied');
    });
  });

  // =========================================================================
  // 3. DEDUPLICATION & IDEMPOTENCY
  // =========================================================================
  describe('3. Deduplication & Idempotency', () => {
    it('returns existing notification when identical idempotencyKey is used repeatedly', async () => {
      const idemKey = 'asg_pub_unique_001';

      const first = await NotificationService.createNotification({
        collegeId: collegeAId.toString(),
        recipientUserId: userA1Id.toString(),
        title: 'Assignment #1',
        body: 'Due Friday',
        notificationType: NotificationType.ASSIGNMENT_PUBLISHED,
        idempotencyKey: idemKey,
      });

      const second = await NotificationService.createNotification({
        collegeId: collegeAId.toString(),
        recipientUserId: userA1Id.toString(),
        title: 'Assignment #1',
        body: 'Due Friday (retried call)',
        notificationType: NotificationType.ASSIGNMENT_PUBLISHED,
        idempotencyKey: idemKey,
      });

      expect(second.id).toBe(first.id);

      const count = await Notification.countDocuments({
        recipientUserId: userA1Id,
        idempotencyKey: idemKey,
      });
      expect(count).toBe(1);
    });

    it('database unique constraint enforces idempotency against concurrent inserts', async () => {
      const idemKey = 'concurrent_key_002';

      const results = await Promise.all([
        NotificationService.createNotification({
          collegeId: collegeAId.toString(),
          recipientUserId: userA1Id.toString(),
          title: 'Concurrent 1',
          body: 'Body',
          notificationType: NotificationType.ASSIGNMENT_PUBLISHED,
          idempotencyKey: idemKey,
        }),
        NotificationService.createNotification({
          collegeId: collegeAId.toString(),
          recipientUserId: userA1Id.toString(),
          title: 'Concurrent 2',
          body: 'Body',
          notificationType: NotificationType.ASSIGNMENT_PUBLISHED,
          idempotencyKey: idemKey,
        }),
      ]);

      expect(results[0].id).toBe(results[1].id);
      const totalDocs = await Notification.countDocuments({
        recipientUserId: userA1Id,
        idempotencyKey: idemKey,
      });
      expect(totalDocs).toBe(1);
    });
  });

  // =========================================================================
  // 4. READ / UNREAD / ARCHIVE / DELETE & UNREAD COUNT
  // =========================================================================
  describe('4. Notification Read/Unread/Archive/Delete Lifecycle', () => {
    it('marks one notification as read and emits NOTIFICATION_READ', async () => {
      const notif = await Notification.create({
        collegeId: collegeAId,
        recipientUserId: userA1Id,
        title: 'Exam Schedule',
        body: 'Published today',
        notificationType: NotificationType.ACADEMIC_RECORD_INITIALIZED,
        isRead: false,
      });

      const updated = await NotificationService.markAsRead(
        notif._id.toString(),
        userA1Id.toString(),
        collegeAId.toString()
      );

      expect(updated.isRead).toBe(true);
      expect(updated.status).toBe(NotificationStatus.READ);
      expect(updated.readAt).toBeInstanceOf(Date);

      const readEvents = publishedEvents.filter(
        (e) => e.eventType === AcadexEventType.NOTIFICATION_READ
      );
      expect(readEvents.length).toBe(1);
      expect(readEvents[0].payload.notificationId).toBe(notif.id);
    });

    it('marks one notification back to unread and updates status', async () => {
      const notif = await Notification.create({
        collegeId: collegeAId,
        recipientUserId: userA1Id,
        title: 'To Be Re-read',
        body: 'Important detail',
        notificationType: NotificationType.SYSTEM,
        isRead: true,
        status: NotificationStatus.READ,
        readAt: new Date(),
      });

      const unreadNotif = await NotificationService.markAsUnread(
        notif._id.toString(),
        userA1Id.toString(),
        collegeAId.toString()
      );

      expect(unreadNotif.isRead).toBe(false);
      expect(unreadNotif.status).toBe(NotificationStatus.UNREAD);
      expect(unreadNotif.readAt).toBeNull();
    });

    it('marks all notifications read in batch and updates unread count', async () => {
      await Notification.create([
        {
          collegeId: collegeAId,
          recipientUserId: userA1Id,
          title: 'N1',
          body: 'B1',
          notificationType: NotificationType.SYSTEM,
          isRead: false,
        },
        {
          collegeId: collegeAId,
          recipientUserId: userA1Id,
          title: 'N2',
          body: 'B2',
          notificationType: NotificationType.SYSTEM,
          isRead: false,
        },
      ]);

      const initialUnread = await NotificationService.getUnreadCount(
        userA1Id.toString(),
        collegeAId.toString()
      );
      expect(initialUnread).toBe(2);

      const result = await NotificationService.markAllAsRead(
        userA1Id.toString(),
        collegeAId.toString()
      );
      expect(result.updatedCount).toBe(2);

      const finalUnread = await NotificationService.getUnreadCount(
        userA1Id.toString(),
        collegeAId.toString()
      );
      expect(finalUnread).toBe(0);
    });

    it('archives notification and excludes it from standard list', async () => {
      const notif = await Notification.create({
        collegeId: collegeAId,
        recipientUserId: userA1Id,
        title: 'To Archive',
        body: 'Archived content',
        notificationType: NotificationType.SYSTEM,
        isRead: false,
      });

      const archived = await NotificationService.archiveNotification(
        notif._id.toString(),
        userA1Id.toString(),
        collegeAId.toString()
      );

      expect(archived.status).toBe(NotificationStatus.ARCHIVED);

      // Standard list excludes archived
      const list = await NotificationService.listNotifications(
        userA1Id.toString(),
        collegeAId.toString()
      );
      expect(list.items.find((item) => item.id === notif.id)).toBeUndefined();

      // Explicit includeArchived returns it
      const listWithArchived = await NotificationService.listNotifications(
        userA1Id.toString(),
        collegeAId.toString(),
        { includeArchived: true }
      );
      expect(listWithArchived.items.find((item) => item.id === notif.id)).toBeDefined();
    });

    it('deletes notification safely', async () => {
      const notif = await Notification.create({
        collegeId: collegeAId,
        recipientUserId: userA1Id,
        title: 'To Delete',
        body: 'Temporary notification',
        notificationType: NotificationType.SYSTEM,
      });

      await NotificationService.deleteNotification(
        notif._id.toString(),
        userA1Id.toString(),
        collegeAId.toString()
      );

      const found = await Notification.findById(notif._id);
      expect(found).toBeNull();
    });
  });

  // =========================================================================
  // 5. NOTIFICATION PREFERENCES & MANDATORY POLICIES
  // =========================================================================
  describe('5. Notification Preferences & Mandatory Policies', () => {
    it('respects user disabling optional category in-app notifications', async () => {
      // User disables assignment notifications
      await NotificationService.updatePreferences(
        userA1Id.toString(),
        { assignments: false },
        collegeAId.toString()
      );

      const notif = await NotificationService.createNotification({
        collegeId: collegeAId.toString(),
        recipientUserId: userA1Id.toString(),
        title: 'New Assignment',
        body: 'Math homework',
        notificationType: NotificationType.ASSIGNMENT_PUBLISHED,
        category: NotificationCategory.ASSIGNMENT,
      });

      // Notification is suppressed, not inserted into Mongo
      expect(notif.id).toBe('suppressed');
      const inDb = await Notification.findOne({
        recipientUserId: userA1Id,
        title: 'New Assignment',
      });
      expect(inDb).toBeNull();
    });

    it('delivers mandatory notifications regardless of user preferences', async () => {
      // User disables inAppEnabled and all categories
      await NotificationService.updatePreferences(
        userA1Id.toString(),
        {
          inAppEnabled: false,
          assignments: false,
          academic: false,
        },
        collegeAId.toString()
      );

      // Official academic result published is MANDATORY
      const notif = await NotificationService.createNotification({
        collegeId: collegeAId.toString(),
        recipientUserId: userA1Id.toString(),
        title: 'Official Academic Results Published',
        body: 'Semester 4 final results have been published.',
        notificationType: NotificationType.ACADEMIC_RESULT_PUBLISHED,
        category: NotificationCategory.RESULT,
      });

      expect(notif.id).not.toBe('suppressed');
      const persisted = await Notification.findById(notif._id);
      expect(persisted).not.toBeNull();
      expect(persisted!.title).toBe('Official Academic Results Published');
    });

    it('enforces mandatory system and academicResults flags in updatePreferences', async () => {
      const updated = await NotificationService.updatePreferences(
        userA1Id.toString(),
        {
          assignments: false,
          calendar: false,
        },
        collegeAId.toString()
      );

      expect(updated.system).toBe(true);
      expect(updated.academicResults).toBe(true);
      expect(updated.assignments).toBe(false);
      expect(updated.calendar).toBe(false);
    });

    it('isolates user preferences per user and tenant', async () => {
      await NotificationService.updatePreferences(
        userA1Id.toString(),
        { calendar: false },
        collegeAId.toString()
      );

      const prefA1 = await NotificationService.getPreferences(userA1Id.toString(), collegeAId.toString());
      const prefA2 = await NotificationService.getPreferences(userA2Id.toString(), collegeAId.toString());

      expect(prefA1.calendar).toBe(false);
      expect(prefA2.calendar).toBe(true); // User A2 defaults to true
    });
  });

  // =========================================================================
  // 6. FCM / DEVICE TOKEN LIFECYCLE
  // =========================================================================
  describe('6. FCM & Device Token Management', () => {
    it('registers and refreshes active device token', async () => {
      const token = 'fcm_token_abc_123';
      const reg = await NotificationService.registerDeviceToken(userA1Id.toString(), {
        collegeId: collegeAId.toString(),
        deviceToken: token,
        platform: DevicePlatform.ANDROID,
        appVersion: '1.2.0',
      });

      expect(reg).toBeDefined();
      expect(reg.deviceToken).toBe(token);
      expect(reg.isActive).toBe(true);

      const found = await DeviceToken.findOne({ userId: userA1Id, isActive: true });
      expect(found).not.toBeNull();
      expect(found!.deviceToken).toBe(token);
    });

    it('removes device token on logout', async () => {
      const token = 'fcm_token_to_remove';
      await NotificationService.registerDeviceToken(userA1Id.toString(), {
        collegeId: collegeAId.toString(),
        deviceToken: token,
        platform: DevicePlatform.IOS,
      });

      await NotificationService.removeDeviceToken(userA1Id.toString(), token);

      const found = await DeviceToken.findOne({ deviceToken: token });
      expect(found!.isActive).toBe(false);
    });

    it('deactivates invalid tokens reported by FCM multicast delivery', async () => {
      const invalidToken = 'invalid_fcm_token_999';
      await DeviceToken.create({
        userId: userA1Id,
        collegeId: collegeAId,
        deviceToken: invalidToken,
        platform: DevicePlatform.ANDROID,
        isActive: true,
      });

      await NotificationService.deactivateInvalidTokens([invalidToken]);

      const doc = await DeviceToken.findOne({ deviceToken: invalidToken });
      expect(doc!.isActive).toBe(false);
    });
  });

  // =========================================================================
  // 7. DEEP LINK SANITIZATION & SECURITY
  // =========================================================================
  describe('7. Deep Link Sanitization & Destination Security', () => {
    it('accepts supported safe deep links', () => {
      const safe1 = NotificationService.validateAndSanitizeDeepLink('/assignments/asg_123');
      expect(safe1).toBe('/assignments/asg_123');

      const safe2 = NotificationService.validateAndSanitizeDeepLink('/assessments/ia_456');
      expect(safe2).toBe('/assessments/ia_456');

      const safe3 = NotificationService.validateAndSanitizeDeepLink('/calendar/event/ev_789');
      expect(safe3).toBe('/calendar/event/ev_789');

      const safe4 = NotificationService.validateAndSanitizeDeepLink('/academic-results');
      expect(safe4).toBe('/academic-results');
    });

    it('rejects malicious routes, path traversal, and external schemes', () => {
      const malicious1 = NotificationService.validateAndSanitizeDeepLink('javascript:alert(1)');
      expect(malicious1).toBeUndefined();

      const malicious2 = NotificationService.validateAndSanitizeDeepLink('https://phishing.site/login');
      expect(malicious2).toBeUndefined();

      const malicious3 = NotificationService.validateAndSanitizeDeepLink('/admin/../../root/delete-all');
      expect(malicious3).toBeUndefined();

      const unmapped = NotificationService.validateAndSanitizeDeepLink('/unauthorized/secret/route');
      expect(unmapped).toBeUndefined();
    });

    it('auto-generates canonical deep link from entityType and entityId when deepLink is omitted', () => {
      const generated = NotificationService.validateAndSanitizeDeepLink(
        undefined,
        NotificationType.PRACTICAL_SESSION_SCHEDULED,
        'PRACTICAL',
        'prac_777'
      );
      expect(generated).toBe('/practicals/prac_777');
    });
  });

  // =========================================================================
  // 8. CATEGORY TAXONOMY & REGISTRY MAPPING
  // =========================================================================
  describe('8. Category Taxonomy & Registry Mapping', () => {
    it('maps all Prompts 37–45 notification types to canonical categories', () => {
      expect(NotificationService.mapTypeToCategory(NotificationType.ASSIGNMENT_PUBLISHED)).toBe(
        NotificationCategory.ASSIGNMENT
      );
      expect(NotificationService.mapTypeToCategory(NotificationType.PRACTICAL_SESSION_SCHEDULED)).toBe(
        NotificationCategory.PRACTICAL
      );
      expect(NotificationService.mapTypeToCategory(NotificationType.ASSESSMENT_PUBLISHED)).toBe(
        NotificationCategory.ASSESSMENT
      );
      expect(NotificationService.mapTypeToCategory(NotificationType.ACADEMIC_RESULT_PUBLISHED)).toBe(
        NotificationCategory.RESULT
      );
      expect(NotificationService.mapTypeToCategory(NotificationType.CALENDAR_HOLIDAY_DECLARED)).toBe(
        NotificationCategory.CALENDAR
      );
      expect(NotificationService.mapTypeToCategory(NotificationType.CALENDAR_EVENT_CREATED)).toBe(
        NotificationCategory.CALENDAR
      );
      expect(NotificationService.mapTypeToCategory(NotificationType.REQUEST_RECEIVED)).toBe(
        NotificationCategory.REQUEST
      );
      expect(NotificationService.mapTypeToCategory(NotificationType.ATTENDANCE_LOW)).toBe(
        NotificationCategory.ATTENDANCE
      );
    });
  });
});
