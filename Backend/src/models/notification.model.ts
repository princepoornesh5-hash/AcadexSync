import mongoose, { Document, Schema } from 'mongoose';
import { AppRole } from '../constants/roles';
import {
  NotificationType,
  NotificationCategory,
  NotificationPriority,
} from '../constants/notification.constants';

export interface INotification extends Document {
  collegeId: mongoose.Types.ObjectId;
  departmentId?: mongoose.Types.ObjectId;
  recipientUserId: mongoose.Types.ObjectId;
  recipientRole?: AppRole;
  title: string;
  body: string;
  message?: string;
  notificationType: NotificationType;
  category: NotificationCategory;
  priority: NotificationPriority;
  entityType?: string;
  entityId?: string;
  deepLink?: string;
  navigationTarget?: string;
  metadata?: Record<string, unknown>;
  isRead: boolean;
  readAt?: Date | null;
  expiresAt?: Date | null;
  idempotencyKey?: string | null;
  createdAt: Date;
  updatedAt: Date;
}

const NotificationSchema = new Schema<INotification>(
  {
    collegeId: { type: Schema.Types.ObjectId, ref: 'College', required: true, index: true },
    departmentId: { type: Schema.Types.ObjectId, ref: 'Department', default: null, index: true },
    recipientUserId: { type: Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    recipientRole: { type: String, enum: Object.values(AppRole), default: null },
    title: { type: String, required: true, trim: true },
    body: { type: String, required: true, trim: true },
    notificationType: {
      type: String,
      enum: Object.values(NotificationType),
      required: true,
      index: true,
    },
    category: {
      type: String,
      enum: Object.values(NotificationCategory),
      default: NotificationCategory.GENERAL,
      index: true,
    },
    priority: {
      type: String,
      enum: Object.values(NotificationPriority),
      default: NotificationPriority.NORMAL,
    },
    entityType: { type: String, default: null },
    entityId: { type: String, default: null },
    deepLink: { type: String, default: null },
    metadata: { type: Schema.Types.Mixed, default: {} },
    isRead: { type: Boolean, default: false, index: true },
    readAt: { type: Date, default: null },
    expiresAt: { type: Date, default: null },
    idempotencyKey: { type: String, default: null, sparse: true, index: true },
  },
  {
    timestamps: true,
    toJSON: {
      virtuals: true,
      transform: (_: unknown, ret: Record<string, any>) => {
        ret.id = ret._id?.toString();
        if (ret.recipientUserId) ret.recipientUserId = ret.recipientUserId.toString();
        if (ret.collegeId) ret.collegeId = ret.collegeId.toString();
        if (ret.departmentId) ret.departmentId = ret.departmentId.toString();
        ret.message = ret.body;
        ret.navigationTarget = ret.deepLink;
        delete ret.__v;
        return ret;
      },
    },
  }
);

// High performance compound indexes for fast inbox & unread counts
NotificationSchema.index({ recipientUserId: 1, isRead: 1, createdAt: -1 });
NotificationSchema.index({ collegeId: 1, recipientUserId: 1, createdAt: -1 });
NotificationSchema.index({ recipientUserId: 1, idempotencyKey: 1 }, { sparse: true });

export const Notification = mongoose.model<INotification>(
  'Notification',
  NotificationSchema
);
