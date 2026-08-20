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
  DevicePlatform,
} from '../constants/notification.constants';
import { AppRole } from '../constants/roles';
import { FcmService } from './fcm.service';
import { AuditService } from './audit.service';
import { ApiError } from '../utils/apiError';
import { logger } from '../utils/logger';

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
  deepLink?: string;
  metadata?: Record<string, unknown>;
  idempotencyKey?: string;
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
  private static mapTypeToCategory(type: NotificationType): NotificationCategory {
    switch (type) {
      case NotificationType.NOTE_PUBLISHED:
      case NotificationType.NOTE_UPDATED:
        return NotificationCategory.NOTES;
      case NotificationType.ATTENDANCE_LOW:
      case NotificationType.ATTENDANCE_MARKED:
        return NotificationCategory.ATTENDANCE;
      case NotificationType.TIMETABLE_PUBLISHED:
      case NotificationType.TIMETABLE_UPDATED:
      case NotificationType.TIMETABLE_CANCELLED:
        return NotificationCategory.TIMETABLE;
      case NotificationType.ANNOUNCEMENT:
        return NotificationCategory.ANNOUNCEMENT;
      case NotificationType.SYSTEM:
      default:
        return NotificationCategory.SYSTEM;
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
          notes: true,
          attendance: true,
          timetable: true,
          system: true,
          pushEnabled: true,
        },
      },
      { upsert: true, new: true, setDefaultsOnInsert: true }
    );

    return pref;
  }

  static async updatePreferences(
    userId: string,
    update: Partial<{
      notes: boolean;
      attendance: boolean;
      timetable: boolean;
      pushEnabled: boolean;
    }>,
    collegeId?: string
  ): Promise<INotificationPreference> {
    let pref = await NotificationPreference.findOne({
      userId: new mongoose.Types.ObjectId(userId),
    });

    if (!pref) {
      pref = new NotificationPreference({
        userId: new mongoose.Types.ObjectId(userId),
        collegeId: collegeId ? new mongoose.Types.ObjectId(collegeId) : undefined,
      });
    }

    if (update.notes !== undefined) pref.notes = update.notes;
    if (update.attendance !== undefined) pref.attendance = update.attendance;
    if (update.timetable !== undefined) pref.timetable = update.timetable;
    if (update.pushEnabled !== undefined) pref.pushEnabled = update.pushEnabled;
    pref.system = true; // System notices cannot be disabled

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

  static async createNotification(input: CreateNotificationInput): Promise<INotification> {
    // 1. Idempotency check
    if (input.idempotencyKey) {
      const existing = await Notification.findOne({
        recipientUserId: new mongoose.Types.ObjectId(input.recipientUserId),
        idempotencyKey: input.idempotencyKey,
      });
      if (existing) {
        return existing;
      }
    }

    const category = input.category ?? this.mapTypeToCategory(input.notificationType);
    const priority = input.priority ?? NotificationPriority.NORMAL;

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
      entityType: input.entityType,
      entityId: input.entityId,
      deepLink: input.deepLink,
      metadata: input.metadata ?? {},
      idempotencyKey: input.idempotencyKey,
    });

    // 3. Asynchronously attempt FCM push delivery without blocking or failing transaction
    this.dispatchPushForNotification(notification).catch((err) => {
      logger.error('Error dispatching push notification for user', err);
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
        createdNotifications.push(notif);
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

      // Check category preference
      if (!pref.pushEnabled) return;
      if (notification.category === NotificationCategory.NOTES && !pref.notes) return;
      if (notification.category === NotificationCategory.ATTENDANCE && !pref.attendance) return;
      if (notification.category === NotificationCategory.TIMETABLE && !pref.timetable) return;

      // Retrieve all active device tokens for the recipient user
      const activeTokensDocs = await DeviceToken.find({
        userId: notification.recipientUserId,
        isActive: true,
      });

      if (activeTokensDocs.length === 0) return;

      const tokens = activeTokensDocs.map((doc) => doc.deviceToken);

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
      category?: NotificationCategory;
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

    const filter: Record<string, unknown> = {
      recipientUserId: new mongoose.Types.ObjectId(userId),
    };

    if (collegeId && collegeId !== 'global') {
      if (!mongoose.Types.ObjectId.isValid(collegeId)) {
        return { items: [], total: 0, page: 1, limit: 20, totalPages: 1, unreadCount: 0 };
      }
      filter.collegeId = new mongoose.Types.ObjectId(collegeId);
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
      Notification.countDocuments({
        recipientUserId: new mongoose.Types.ObjectId(userId),
        ...(collegeId && collegeId !== 'global' && mongoose.Types.ObjectId.isValid(collegeId)
          ? { collegeId: new mongoose.Types.ObjectId(collegeId) }
          : {}),
        isRead: false,
      }),
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

    const filter: Record<string, unknown> = {
      recipientUserId: new mongoose.Types.ObjectId(userId),
      isRead: false,
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

    if (!notification.isRead) {
      notification.isRead = true;
      notification.readAt = new Date();
      await notification.save();
    }

    return notification;
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
      $set: { isRead: true, readAt: new Date() },
    });

    return { updatedCount: result.modifiedCount };
  }
}
