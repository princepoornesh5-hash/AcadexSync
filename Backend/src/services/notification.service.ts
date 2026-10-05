import mongoose from 'mongoose';
import {
  Notification,
  INotification,
  DeviceToken,
  IDeviceToken,
  NotificationPreference,
  INotificationPreference,
} from '../models';
import {
  NotificationType,
  NotificationCategory,
  NotificationPriority,
  NotificationStatus,
  DevicePlatform,
} from '../constants/notification.constants';
import { AppRole } from '../constants/roles';
import { FcmService } from './fcm.service';
import { AuditService } from './audit.service';
import { ApiError } from '../utils/apiError';
import { logger } from '../utils/logger';
import { realtimeEventBus, AcadexEventType } from '../realtime';

export interface CreateNotificationInput {
  collegeId: string;
  departmentId?: string;
  recipientUserId: string;
  recipientRole?: AppRole;
  title: string;
  body: string;
  notificationType: NotificationType;
  category?: NotificationCategory;
  priority?: NotificationPriority;
  entityType?: string;
  entityId?: string;
  sourceType?: string;
  sourceId?: string;
  relatedEntityType?: string;
  relatedEntityId?: string;
  deepLink?: string;
  metadata?: Record<string, unknown>;
  idempotencyKey?: string;
  expiresAt?: Date | null;
}

export interface RegisterDeviceTokenInput {
  collegeId?: string;
  deviceToken: string;
  platform: DevicePlatform;
  appVersion?: string;
}

export class NotificationService {
  /**
   * Helper to map notification type to category if not explicitly supplied
   */
  static mapTypeToCategory(type: NotificationType): NotificationCategory {
    switch (type) {
      case NotificationType.REQUEST_RECEIVED:
      case NotificationType.REQUEST_UPDATED:
      case NotificationType.REQUEST_RESPONDED:
      case NotificationType.REQUEST_APPROVED:
      case NotificationType.REQUEST_REJECTED:
        return NotificationCategory.REQUEST;
      case NotificationType.NOTE_PUBLISHED:
      case NotificationType.NOTE_UPDATED:
        return NotificationCategory.NOTES;
      case NotificationType.ATTENDANCE_LOW:
      case NotificationType.ATTENDANCE_MARKED:
      case NotificationType.ATTENDANCE_ABSENT:
      case NotificationType.ATTENDANCE_LATE:
      case NotificationType.ATTENDANCE_ALERT:
        return NotificationCategory.ATTENDANCE;
      case NotificationType.TIMETABLE_PUBLISHED:
      case NotificationType.TIMETABLE_UPDATED:
      case NotificationType.TIMETABLE_CANCELLED:
      case NotificationType.TIMETABLE_CHANGE:
        return NotificationCategory.TIMETABLE;
      case NotificationType.ANNOUNCEMENT:
        return NotificationCategory.ANNOUNCEMENT;
      case NotificationType.CALENDAR_HOLIDAY_DECLARED:
      case NotificationType.CALENDAR_EVENT_CREATED:
      case NotificationType.CALENDAR_EVENT_CANCELLED:
      case NotificationType.CALENDAR_EVENT:
      case NotificationType.CALENDAR_OVERRIDE:
      case NotificationType.HOLIDAY:
        return NotificationCategory.CALENDAR;
      case NotificationType.ACADEMIC_RECORD_INITIALIZED:
      case NotificationType.ACADEMIC_PROGRESSION_UPDATED:
        return NotificationCategory.ACADEMIC;
      case NotificationType.ASSESSMENT_PUBLISHED:
      case NotificationType.ASSESSMENT_MARK_UPDATED:
        return NotificationCategory.ASSESSMENT;
      case NotificationType.ACADEMIC_RESULT_PUBLISHED:
      case NotificationType.ACADEMIC_RESULT_REOPENED:
        return NotificationCategory.RESULT;
      case NotificationType.ASSIGNMENT_PUBLISHED:
      case NotificationType.ASSIGNMENT_DUE_SOON:
      case NotificationType.ASSIGNMENT_OVERDUE:
      case NotificationType.ASSIGNMENT_GRADED:
      case NotificationType.GRADE_POSTED:
      case NotificationType.SUBMISSION_RECEIVED:
        return NotificationCategory.ASSIGNMENT;
      case NotificationType.PRACTICAL_SESSION_SCHEDULED:
      case NotificationType.PRACTICAL_SESSION_CANCELLED:
      case NotificationType.PRACTICAL_SESSION_COMPLETED:
        return NotificationCategory.PRACTICAL;
      case NotificationType.SYSTEM:
      default:
        return NotificationCategory.SYSTEM;
    }
  }

  /**
   * Safe deep link validation and sanitization (Prompt 46 Section Y & Z)
   */
  static validateAndSanitizeDeepLink(
    deepLink?: string,
    _notificationType?: NotificationType,
    entityType?: string,
    entityId?: string
  ): string | undefined {
    if (!deepLink) {
      if (entityType && entityId) {
        const norm = entityType.toUpperCase();
        if (norm === 'ASSIGNMENT') return `/assignments/${entityId}`;
        if (norm === 'ASSESSMENT') return `/assessments/${entityId}`;
        if (norm === 'PRACTICAL' || norm === 'PRACTICALSESSION') return `/practicals/${entityId}`;
        if (norm === 'CALENDAR' || norm === 'CALENDAREVENT') return `/calendar/event/${entityId}`;
        if (norm === 'ACADEMICRESULT') return `/academic-results`;
        if (norm === 'REQUEST') return `/requests/${entityId}`;
        if (norm === 'ANNOUNCEMENT') return `/announcements/${entityId}`;
        if (norm === 'ATTENDANCE' || norm === 'ATTENDANCESESSION') return `/attendance/student`;
      }
      return undefined;
    }

    const trimmed = deepLink.trim();
    if (trimmed.includes('..') || /^[a-zA-Z]+:\/\//.test(trimmed) || trimmed.startsWith('javascript:')) {
      logger.warn(`Rejected potentially unsafe deepLink: ${trimmed}`);
      return undefined;
    }

    const allowedPrefixes = [
      '/assignments',
      '/assessments',
      '/practicals',
      '/calendar',
      '/academic-results',
      '/attendance',
      '/requests',
      '/announcements',
      '/notes',
      '/timetable',
      '/notifications',
      '/settings',
    ];

    const isAllowed = allowedPrefixes.some((prefix) => trimmed === prefix || trimmed.startsWith(`${prefix}/`));
    if (!isAllowed) {
      logger.warn(`Rejected untrusted deepLink prefix: ${trimmed}`);
      return undefined;
    }

    return trimmed;
  }

  /**
   * Determine whether notification is legally / institutionally mandatory (Prompt 46 Section V)
   */
  static isMandatoryNotification(type: NotificationType, category: NotificationCategory): boolean {
    if (category === NotificationCategory.SYSTEM || type === NotificationType.SYSTEM) {
      return true;
    }
    if (
      type === NotificationType.ACADEMIC_RESULT_PUBLISHED ||
      type === NotificationType.ACADEMIC_RESULT_REOPENED ||
      category === NotificationCategory.RESULT
    ) {
      return true;
    }
    return false;
  }

  /**
   * Evaluates user preferences for in-app delivery
   */
  static async shouldDeliverInApp(
    userId: string,
    collegeId: string,
    type: NotificationType,
    category: NotificationCategory
  ): Promise<boolean> {
    if (this.isMandatoryNotification(type, category)) {
      return true;
    }

    const pref = await this.getPreferences(userId, collegeId);
    if (!pref.inAppEnabled) return false;

    switch (category) {
      case NotificationCategory.ASSIGNMENT:
        return pref.assignments ?? true;
      case NotificationCategory.PRACTICAL:
        return pref.practicals ?? true;
      case NotificationCategory.ASSESSMENT:
        return pref.assessments ?? true;
      case NotificationCategory.CALENDAR:
        return pref.calendar ?? true;
      case NotificationCategory.ANNOUNCEMENT:
        return pref.announcements ?? true;
      case NotificationCategory.NOTES:
        return pref.notes ?? true;
      case NotificationCategory.ATTENDANCE:
        return pref.attendance ?? true;
      case NotificationCategory.TIMETABLE:
        return pref.timetable ?? true;
      case NotificationCategory.ACADEMIC:
        return pref.academic ?? true;
      default:
        return true;
    }
  }

  /**
   * Evaluates user preferences for push delivery
   */
  static shouldDeliverPush(
    pref: INotificationPreference,
    type: NotificationType,
    category: NotificationCategory
  ): boolean {
    if (this.isMandatoryNotification(type, category)) {
      return true;
    }

    if (!pref.pushEnabled) return false;

    switch (category) {
      case NotificationCategory.ASSIGNMENT:
        return pref.assignments ?? true;
      case NotificationCategory.PRACTICAL:
        return pref.practicals ?? true;
      case NotificationCategory.ASSESSMENT:
        return pref.assessments ?? true;
      case NotificationCategory.CALENDAR:
        return pref.calendar ?? true;
      case NotificationCategory.ANNOUNCEMENT:
        return pref.announcements ?? true;
      case NotificationCategory.NOTES:
        return pref.notes ?? true;
      case NotificationCategory.ATTENDANCE:
        return pref.attendance ?? true;
      case NotificationCategory.TIMETABLE:
        return pref.timetable ?? true;
      case NotificationCategory.ACADEMIC:
        return pref.academic ?? true;
      default:
        return true;
    }
  }

  // =========================================================================
  // 1. DEVICE TOKEN MANAGEMENT
  // =========================================================================

  static async registerDeviceToken(
    userId: string,
    data: RegisterDeviceTokenInput
  ): Promise<IDeviceToken> {
    if (!data.deviceToken || data.deviceToken.trim().length === 0) {
      throw ApiError.badRequest('deviceToken is required');
    }

    const cleanToken = data.deviceToken.trim();

    const updated = await DeviceToken.findOneAndUpdate(
      { deviceToken: cleanToken },
      {
        userId: new mongoose.Types.ObjectId(userId),
        collegeId: data.collegeId ? new mongoose.Types.ObjectId(data.collegeId) : undefined,
        platform: data.platform,
        appVersion: data.appVersion,
        isActive: true,
        lastSeenAt: new Date(),
      },
      { upsert: true, new: true, setDefaultsOnInsert: true }
    );

    // Audit log without exposing the full token
    const maskedToken = cleanToken.length > 8 ? `${cleanToken.substring(0, 4)}...${cleanToken.substring(cleanToken.length - 4)}` : '***';
    await AuditService.log({
      collegeId: data.collegeId ? data.collegeId : undefined,
      actorUserId: userId,
      action: 'DEVICE_TOKEN_REGISTERED',
      entityType: 'DeviceToken',
      entityId: updated._id.toString(),
      newValue: { platform: data.platform, tokenPreview: maskedToken },
    }).catch((err: Error) => logger.warn(`Audit log failed for device token registration: ${err.message}`));

    return updated;
  }

  static async removeDeviceToken(userId: string, deviceToken: string): Promise<void> {
    if (!deviceToken) return;

    const tokenDoc = await DeviceToken.findOne({
      userId: new mongoose.Types.ObjectId(userId),
      deviceToken: deviceToken.trim(),
    });

    if (tokenDoc) {
      tokenDoc.isActive = false;
      await tokenDoc.save();

      const cleanToken = deviceToken.trim();
      const maskedToken = cleanToken.length > 8 ? `${cleanToken.substring(0, 4)}...${cleanToken.substring(cleanToken.length - 4)}` : '***';

      await AuditService.log({
        collegeId: tokenDoc.collegeId ? tokenDoc.collegeId.toString() : undefined,
        actorUserId: userId,
        action: 'DEVICE_TOKEN_REMOVED',
        entityType: 'DeviceToken',
        entityId: tokenDoc._id.toString(),
        newValue: { tokenPreview: maskedToken },
      }).catch((err: Error) => logger.warn(`Audit log failed for device token removal: ${err.message}`));
    }
  }

  static async deactivateInvalidTokens(tokens: string[]): Promise<void> {
    if (!tokens || tokens.length === 0) return;
    await DeviceToken.updateMany(
      { deviceToken: { $in: tokens } },
      { $set: { isActive: false, lastSeenAt: new Date() } }
    );
  }

  // =========================================================================
  // 2. USER PREFERENCES
  // =========================================================================

  static async getPreferences(userId: string, collegeId?: string): Promise<INotificationPreference> {
    const pref = await NotificationPreference.findOneAndUpdate(
      { userId: new mongoose.Types.ObjectId(userId) },
      {
        $setOnInsert: {
          userId: new mongoose.Types.ObjectId(userId),
          collegeId: collegeId && collegeId !== 'global' && mongoose.Types.ObjectId.isValid(collegeId)
            ? new mongoose.Types.ObjectId(collegeId)
            : undefined,
          inAppEnabled: true,
          pushEnabled: true,
          academic: true,
          assignments: true,
          practicals: true,
          assessments: true,
          calendar: true,
          announcements: true,
          notes: true,
          attendance: true,
          timetable: true,
          academicResults: true,
          system: true,
        },
      },
      { upsert: true, new: true, setDefaultsOnInsert: true }
    );

    return pref;
  }

  static async updatePreferences(
    userId: string,
    update: Partial<{
      inAppEnabled: boolean;
      pushEnabled: boolean;
      academic: boolean;
      assignments: boolean;
      practicals: boolean;
      assessments: boolean;
      calendar: boolean;
      announcements: boolean;
      notes: boolean;
      attendance: boolean;
      timetable: boolean;
    }>,
    collegeId?: string
  ): Promise<INotificationPreference> {
    let pref = await NotificationPreference.findOne({
      userId: new mongoose.Types.ObjectId(userId),
    });

    if (!pref) {
      pref = new NotificationPreference({
        userId: new mongoose.Types.ObjectId(userId),
        collegeId: collegeId && collegeId !== 'global' && mongoose.Types.ObjectId.isValid(collegeId)
          ? new mongoose.Types.ObjectId(collegeId)
          : undefined,
      });
    }

    if (update.inAppEnabled !== undefined) pref.inAppEnabled = update.inAppEnabled;
    if (update.pushEnabled !== undefined) pref.pushEnabled = update.pushEnabled;
    if (update.academic !== undefined) pref.academic = update.academic;
    if (update.assignments !== undefined) pref.assignments = update.assignments;
    if (update.practicals !== undefined) pref.practicals = update.practicals;
    if (update.assessments !== undefined) pref.assessments = update.assessments;
    if (update.calendar !== undefined) pref.calendar = update.calendar;
    if (update.announcements !== undefined) pref.announcements = update.announcements;
    if (update.notes !== undefined) pref.notes = update.notes;
    if (update.attendance !== undefined) pref.attendance = update.attendance;
    if (update.timetable !== undefined) pref.timetable = update.timetable;

    // MANDATORY POLICIES: system and academicResults can NEVER be disabled
    pref.system = true;
    pref.academicResults = true;

    await pref.save();

    await AuditService.log({
      collegeId: pref.collegeId ? pref.collegeId.toString() : undefined,
      actorUserId: userId,
      action: 'NOTIFICATION_PREFERENCE_UPDATED',
      entityType: 'NotificationPreference',
      entityId: pref._id.toString(),
      newValue: { preferences: update },
    }).catch((err: Error) => logger.warn(`Audit log failed for preference update: ${err.message}`));

    return pref;
  }

  // =========================================================================
  // 3. NOTIFICATION CREATION & PUSH DISPATCH
  // =========================================================================

  private static inFlightIdempotencyKeys = new Map<string, Promise<INotification>>();

  static async createNotification(input: CreateNotificationInput): Promise<INotification> {
    const category = input.category ?? this.mapTypeToCategory(input.notificationType);
    const priority = input.priority ?? NotificationPriority.NORMAL;
    const safeDeepLink = this.validateAndSanitizeDeepLink(
      input.deepLink,
      input.notificationType,
      input.entityType ?? input.relatedEntityType,
      input.entityId ?? input.relatedEntityId
    );

    // Guard against invalid ObjectId inputs
    if (!mongoose.Types.ObjectId.isValid(input.recipientUserId) || !mongoose.Types.ObjectId.isValid(input.collegeId)) {
      logger.warn(`createNotification aborted: invalid recipientUserId (${input.recipientUserId}) or collegeId (${input.collegeId})`);
      return {
        _id: new mongoose.Types.ObjectId(),
        id: 'invalid_id',
        collegeId: mongoose.Types.ObjectId.isValid(input.collegeId) ? new mongoose.Types.ObjectId(input.collegeId) : new mongoose.Types.ObjectId(),
        recipientUserId: mongoose.Types.ObjectId.isValid(input.recipientUserId) ? new mongoose.Types.ObjectId(input.recipientUserId) : new mongoose.Types.ObjectId(),
        title: input.title,
        body: input.body,
        notificationType: input.notificationType,
        category,
        priority,
        status: NotificationStatus.UNREAD,
        isRead: false,
        deepLink: safeDeepLink,
        createdAt: new Date(),
        updatedAt: new Date(),
      } as any;
    }

    // Check user in-app preference before persisting optional notifications
    const deliverInApp = await this.shouldDeliverInApp(
      input.recipientUserId,
      input.collegeId,
      input.notificationType,
      category
    );

    if (!deliverInApp) {
      // Return a transient notification object without persisting into database
      return {
        _id: new mongoose.Types.ObjectId(),
        id: 'suppressed',
        collegeId: new mongoose.Types.ObjectId(input.collegeId),
        recipientUserId: new mongoose.Types.ObjectId(input.recipientUserId),
        title: input.title,
        body: input.body,
        notificationType: input.notificationType,
        category,
        priority,
        status: NotificationStatus.UNREAD,
        isRead: false,
        deepLink: safeDeepLink,
        createdAt: new Date(),
        updatedAt: new Date(),
      } as any;
    }

    if (input.idempotencyKey) {
      const key = `${input.recipientUserId}_${input.idempotencyKey}`;
      if (this.inFlightIdempotencyKeys.has(key)) {
        return this.inFlightIdempotencyKeys.get(key)!;
      }

      const promise = (async () => {
        const existing = await Notification.findOne({
          recipientUserId: new mongoose.Types.ObjectId(input.recipientUserId),
          idempotencyKey: input.idempotencyKey,
        });
        if (existing) {
          return existing;
        }

        try {
          // 2. Persist notification in MongoDB (Authoritative Source of Truth)
          const notification = await Notification.create({
            collegeId: new mongoose.Types.ObjectId(input.collegeId),
            departmentId: input.departmentId ? new mongoose.Types.ObjectId(input.departmentId) : undefined,
            recipientUserId: new mongoose.Types.ObjectId(input.recipientUserId),
            recipientRole: input.recipientRole,
            title: input.title,
            body: input.body,
            notificationType: input.notificationType,
            category,
            priority,
            status: NotificationStatus.UNREAD,
            entityType: input.entityType ?? input.relatedEntityType ?? input.sourceType,
            entityId: input.entityId ?? input.relatedEntityId ?? input.sourceId,
            deepLink: safeDeepLink,
            metadata: input.metadata ?? {},
            idempotencyKey: input.idempotencyKey,
            expiresAt: input.expiresAt ?? null,
          });

          // 3. Asynchronously attempt FCM push delivery without blocking or failing transaction
          this.dispatchPushForNotification(notification).catch((err) => {
            logger.error('Error dispatching push notification for user', err);
          });

          // 4. Emit Realtime event to connected recipient client (Persistence-First)
          realtimeEventBus.publish({
            eventType: AcadexEventType.NOTIFICATION_CREATED,
            aggregateType: 'Notification',
            aggregateId: notification.id,
            action: 'CREATED',
            collegeId: notification.collegeId.toString(),
            scope: {
              type: 'user',
              collegeId: notification.collegeId.toString(),
              userId: notification.recipientUserId.toString(),
            },
            payload: {
              notificationId: notification.id,
              title: notification.title,
              body: notification.body,
              category: notification.category,
              priority: notification.priority,
              notificationType: notification.notificationType,
              deepLink: notification.deepLink,
              createdAt: notification.createdAt,
            },
          });

          return notification;
        } catch (err: any) {
          if (err?.code === 11000) {
            const dupe = await Notification.findOne({
              recipientUserId: new mongoose.Types.ObjectId(input.recipientUserId),
              idempotencyKey: input.idempotencyKey,
            });
            if (dupe) return dupe;
          }
          throw err;
        }
      })();

      this.inFlightIdempotencyKeys.set(key, promise);
      try {
        return await promise;
      } finally {
        const timer = setTimeout(() => {
          this.inFlightIdempotencyKeys.delete(key);
        }, 10000);
        if (timer.unref) timer.unref();
      }
    }

    const notification = await Notification.create({
      collegeId: new mongoose.Types.ObjectId(input.collegeId),
      departmentId: input.departmentId ? new mongoose.Types.ObjectId(input.departmentId) : undefined,
      recipientUserId: new mongoose.Types.ObjectId(input.recipientUserId),
      recipientRole: input.recipientRole,
      title: input.title,
      body: input.body,
      notificationType: input.notificationType,
      category,
      priority,
      status: NotificationStatus.UNREAD,
      entityType: input.entityType ?? input.relatedEntityType ?? input.sourceType,
      entityId: input.entityId ?? input.relatedEntityId ?? input.sourceId,
      deepLink: safeDeepLink,
      metadata: input.metadata ?? {},
      idempotencyKey: input.idempotencyKey,
      expiresAt: input.expiresAt ?? null,
    });

    this.dispatchPushForNotification(notification).catch((err) => {
      logger.error('Error dispatching push notification for user', err);
    });

    realtimeEventBus.publish({
      eventType: AcadexEventType.NOTIFICATION_CREATED,
      aggregateType: 'Notification',
      aggregateId: notification.id,
      action: 'CREATED',
      collegeId: notification.collegeId.toString(),
      scope: {
        type: 'user',
        collegeId: notification.collegeId.toString(),
        userId: notification.recipientUserId.toString(),
      },
      payload: {
        notificationId: notification.id,
        title: notification.title,
        body: notification.body,
        category: notification.category,
        priority: notification.priority,
        notificationType: notification.notificationType,
        deepLink: notification.deepLink,
        createdAt: notification.createdAt,
      },
    });

    return notification;
  }

  /**
   * Batch creates notifications for multiple recipients (e.g. all enrolled students)
   */
  static async createBatchNotifications(
    inputs: CreateNotificationInput[]
  ): Promise<INotification[]> {
    if (!inputs || inputs.length === 0) return [];

    const createdNotifications: INotification[] = [];

    // Filter out duplicates if idempotency keys are provided
    for (const input of inputs) {
      try {
        const notif = await this.createNotification(input);
        if (notif.id !== 'suppressed') {
          createdNotifications.push(notif);
        }
      } catch (err) {
        logger.error(`Failed to create notification for user ${input.recipientUserId}:`, err as Error);
      }
    }

    return createdNotifications;
  }

  /**
   * Internal helper to dispatch FCM push notification respecting user preferences
   */
  private static async dispatchPushForNotification(notification: INotification): Promise<void> {
    try {
      const pref = await this.getPreferences(
        notification.recipientUserId.toString(),
        notification.collegeId.toString()
      );

      const canPush = this.shouldDeliverPush(pref, notification.notificationType, notification.category);
      if (!canPush) return;

      // Retrieve all active device tokens for the recipient user
      const activeTokensDocs = await DeviceToken.find({
        userId: notification.recipientUserId,
        isActive: true,
      });

      if (activeTokensDocs.length === 0) return;

      const tokens = activeTokensDocs.map((doc) => doc.deviceToken);

      // Section AV: NEVER put sensitive student marks or private comments in FCM payloads
      const fcmPayload = {
        title: notification.title,
        body: notification.body,
        data: {
          notificationId: notification.id,
          notificationType: notification.notificationType,
          category: notification.category,
          deepLink: notification.deepLink || '',
          entityType: notification.entityType || '',
          entityId: notification.entityId || '',
        },
      };

      const result = await FcmService.sendMulticast(tokens, fcmPayload);

      // Deactivate invalid tokens if reported by FCM
      if (result.invalidTokens.length > 0) {
        await this.deactivateInvalidTokens(result.invalidTokens);
      }
    } catch (error) {
      logger.warn(`Push delivery encountered error for notification ${notification.id}: ${(error as Error).message}`);
    }
  }

  // =========================================================================
  // 4. INBOX & QUERY OPERATIONS (STRICT RBAC & TENANT ISOLATION)
  // =========================================================================

  static async listNotifications(
    userId: string,
    collegeId: string,
    options: {
      isRead?: boolean;
      status?: NotificationStatus;
      category?: NotificationCategory;
      includeArchived?: boolean;
      page?: number;
      limit?: number;
    } = {}
  ): Promise<{
    items: INotification[];
    total: number;
    page: number;
    limit: number;
    totalPages: number;
    unreadCount: number;
  }> {
    if (!mongoose.Types.ObjectId.isValid(userId)) {
      return { items: [], total: 0, page: 1, limit: 20, totalPages: 1, unreadCount: 0 };
    }

    const page = Math.max(1, options.page || 1);
    const limit = Math.min(100, Math.max(1, options.limit || 20));
    const skip = (page - 1) * limit;
    const now = new Date();

    const filter: Record<string, unknown> = {
      recipientUserId: new mongoose.Types.ObjectId(userId),
      $or: [{ expiresAt: null }, { expiresAt: { $gt: now } }],
    };

    if (collegeId && collegeId !== 'global') {
      if (!mongoose.Types.ObjectId.isValid(collegeId)) {
        return { items: [], total: 0, page: 1, limit: 20, totalPages: 1, unreadCount: 0 };
      }
      filter.collegeId = new mongoose.Types.ObjectId(collegeId);
    }

    if (options.status) {
      filter.status = options.status;
    } else if (!options.includeArchived) {
      filter.status = { $ne: NotificationStatus.ARCHIVED };
    }

    if (options.isRead !== undefined) {
      filter.isRead = options.isRead;
    }

    if (options.category) {
      filter.category = options.category;
    }

    const [items, total, unreadCount] = await Promise.all([
      Notification.find(filter)
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit),
      Notification.countDocuments(filter),
      this.getUnreadCount(userId, collegeId),
    ]);

    return {
      items,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit) || 1,
      unreadCount,
    };
  }

  static async getUnreadCount(userId: string, collegeId: string): Promise<number> {
    if (!mongoose.Types.ObjectId.isValid(userId)) return 0;

    const now = new Date();
    const filter: Record<string, unknown> = {
      recipientUserId: new mongoose.Types.ObjectId(userId),
      isRead: false,
      status: { $ne: NotificationStatus.ARCHIVED },
      $or: [{ expiresAt: null }, { expiresAt: { $gt: now } }],
    };
    if (collegeId && collegeId !== 'global') {
      if (!mongoose.Types.ObjectId.isValid(collegeId)) return 0;
      filter.collegeId = new mongoose.Types.ObjectId(collegeId);
    }
    return Notification.countDocuments(filter);
  }

  static async getNotificationById(
    id: string,
    userId: string,
    collegeId: string
  ): Promise<INotification> {
    if (!mongoose.Types.ObjectId.isValid(id) || !mongoose.Types.ObjectId.isValid(userId)) {
      throw ApiError.notFound('Notification not found or access denied');
    }

    const filter: Record<string, unknown> = {
      _id: new mongoose.Types.ObjectId(id),
      recipientUserId: new mongoose.Types.ObjectId(userId),
    };
    if (collegeId && collegeId !== 'global') {
      if (!mongoose.Types.ObjectId.isValid(collegeId)) {
        throw ApiError.notFound('Notification not found or access denied');
      }
      filter.collegeId = new mongoose.Types.ObjectId(collegeId);
    }

    const notification = await Notification.findOne(filter);
    if (!notification) {
      throw ApiError.notFound('Notification not found or access denied');
    }
    return notification;
  }

  static async markAsRead(
    id: string,
    userId: string,
    collegeId: string
  ): Promise<INotification> {
    if (!mongoose.Types.ObjectId.isValid(id) || !mongoose.Types.ObjectId.isValid(userId)) {
      throw ApiError.notFound('Notification not found or access denied');
    }

    const filter: Record<string, unknown> = {
      _id: new mongoose.Types.ObjectId(id),
      recipientUserId: new mongoose.Types.ObjectId(userId),
    };
    if (collegeId && collegeId !== 'global') {
      if (!mongoose.Types.ObjectId.isValid(collegeId)) {
        throw ApiError.notFound('Notification not found or access denied');
      }
      filter.collegeId = new mongoose.Types.ObjectId(collegeId);
    }

    const notification = await Notification.findOne(filter);
    if (!notification) {
      throw ApiError.notFound('Notification not found or access denied');
    }

    if (!notification.isRead || notification.status !== NotificationStatus.READ) {
      notification.isRead = true;
      notification.status = NotificationStatus.READ;
      notification.readAt = new Date();
      await notification.save();

      realtimeEventBus.publish({
        eventType: AcadexEventType.NOTIFICATION_READ,
        aggregateType: 'Notification',
        aggregateId: notification.id,
        action: 'READ',
        collegeId: notification.collegeId.toString(),
        scope: {
          type: 'user',
          collegeId: notification.collegeId.toString(),
          userId: notification.recipientUserId.toString(),
        },
        payload: {
          notificationId: notification.id,
          userId: notification.recipientUserId.toString(),
        },
      });
    }

    return notification;
  }

  static async markAsUnread(
    id: string,
    userId: string,
    collegeId: string
  ): Promise<INotification> {
    if (!mongoose.Types.ObjectId.isValid(id) || !mongoose.Types.ObjectId.isValid(userId)) {
      throw ApiError.notFound('Notification not found or access denied');
    }

    const filter: Record<string, unknown> = {
      _id: new mongoose.Types.ObjectId(id),
      recipientUserId: new mongoose.Types.ObjectId(userId),
    };
    if (collegeId && collegeId !== 'global') {
      if (!mongoose.Types.ObjectId.isValid(collegeId)) {
        throw ApiError.notFound('Notification not found or access denied');
      }
      filter.collegeId = new mongoose.Types.ObjectId(collegeId);
    }

    const notification = await Notification.findOne(filter);
    if (!notification) {
      throw ApiError.notFound('Notification not found or access denied');
    }

    if (notification.isRead || notification.status !== NotificationStatus.UNREAD) {
      notification.isRead = false;
      notification.status = NotificationStatus.UNREAD;
      notification.readAt = null;
      await notification.save();

      realtimeEventBus.publish({
        eventType: AcadexEventType.NOTIFICATION_UPDATED,
        aggregateType: 'Notification',
        aggregateId: notification.id,
        action: 'UPDATED',
        collegeId: notification.collegeId.toString(),
        scope: {
          type: 'user',
          collegeId: notification.collegeId.toString(),
          userId: notification.recipientUserId.toString(),
        },
        payload: {
          notificationId: notification.id,
          userId: notification.recipientUserId.toString(),
          isRead: false,
          status: NotificationStatus.UNREAD,
        },
      });
    }

    return notification;
  }

  static async archiveNotification(
    id: string,
    userId: string,
    collegeId: string
  ): Promise<INotification> {
    if (!mongoose.Types.ObjectId.isValid(id) || !mongoose.Types.ObjectId.isValid(userId)) {
      throw ApiError.notFound('Notification not found or access denied');
    }

    const filter: Record<string, unknown> = {
      _id: new mongoose.Types.ObjectId(id),
      recipientUserId: new mongoose.Types.ObjectId(userId),
    };
    if (collegeId && collegeId !== 'global') {
      if (!mongoose.Types.ObjectId.isValid(collegeId)) {
        throw ApiError.notFound('Notification not found or access denied');
      }
      filter.collegeId = new mongoose.Types.ObjectId(collegeId);
    }

    const notification = await Notification.findOne(filter);
    if (!notification) {
      throw ApiError.notFound('Notification not found or access denied');
    }

    notification.status = NotificationStatus.ARCHIVED;
    if (!notification.isRead) {
      notification.isRead = true;
      notification.readAt = new Date();
    }
    await notification.save();

    realtimeEventBus.publish({
      eventType: AcadexEventType.NOTIFICATION_UPDATED,
      aggregateType: 'Notification',
      aggregateId: notification.id,
      action: 'UPDATED',
      collegeId: notification.collegeId.toString(),
      scope: {
        type: 'user',
        collegeId: notification.collegeId.toString(),
        userId: notification.recipientUserId.toString(),
      },
      payload: {
        notificationId: notification.id,
        userId: notification.recipientUserId.toString(),
        status: NotificationStatus.ARCHIVED,
      },
    });

    return notification;
  }

  static async deleteNotification(
    id: string,
    userId: string,
    collegeId: string
  ): Promise<void> {
    if (!mongoose.Types.ObjectId.isValid(id) || !mongoose.Types.ObjectId.isValid(userId)) {
      throw ApiError.notFound('Notification not found or access denied');
    }

    const filter: Record<string, unknown> = {
      _id: new mongoose.Types.ObjectId(id),
      recipientUserId: new mongoose.Types.ObjectId(userId),
    };
    if (collegeId && collegeId !== 'global') {
      if (!mongoose.Types.ObjectId.isValid(collegeId)) {
        throw ApiError.notFound('Notification not found or access denied');
      }
      filter.collegeId = new mongoose.Types.ObjectId(collegeId);
    }

    const deleted = await Notification.findOneAndDelete(filter);
    if (!deleted) {
      throw ApiError.notFound('Notification not found or access denied');
    }
  }

  static async markAllAsRead(
    userId: string,
    collegeId: string
  ): Promise<{ updatedCount: number }> {
    if (!mongoose.Types.ObjectId.isValid(userId)) {
      return { updatedCount: 0 };
    }

    const filter: Record<string, unknown> = {
      recipientUserId: new mongoose.Types.ObjectId(userId),
      isRead: false,
    };
    if (collegeId && collegeId !== 'global') {
      if (!mongoose.Types.ObjectId.isValid(collegeId)) {
        return { updatedCount: 0 };
      }
      filter.collegeId = new mongoose.Types.ObjectId(collegeId);
    }

    const result = await Notification.updateMany(filter, {
      $set: { isRead: true, status: NotificationStatus.READ, readAt: new Date() },
    });

    if (result.modifiedCount > 0) {
      realtimeEventBus.publish({
        eventType: AcadexEventType.NOTIFICATION_READ,
        aggregateType: 'Notification',
        aggregateId: userId,
        action: 'READ',
        collegeId: collegeId || 'global',
        scope: {
          type: 'user',
          collegeId: collegeId || 'global',
          userId,
        },
        payload: {
          userId,
          all: true,
          updatedCount: result.modifiedCount,
        },
      });
    }

    return { updatedCount: result.modifiedCount };
  }
}
