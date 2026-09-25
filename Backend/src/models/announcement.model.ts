import mongoose, { Document, Schema } from 'mongoose';
import { AppRole } from '../constants/roles';
import {
  AudienceScope,
  AnnouncementStatus,
  NotificationCategory,
  NotificationPriority,
} from '../constants/notification.constants';

export interface IAnnouncement extends Document {
  collegeId: mongoose.Types.ObjectId;
  departmentId?: mongoose.Types.ObjectId | null;
  title: string;
  body: string;
  category: NotificationCategory;
  audienceScope: AudienceScope;
  targetRole?: AppRole | null;
  targetCourseId?: mongoose.Types.ObjectId | null;
  targetSemesterId?: mongoose.Types.ObjectId | null;
  targetSectionId?: mongoose.Types.ObjectId | null;
  targetUserId?: mongoose.Types.ObjectId | null;
  publishAt: Date;
  expiresAt?: Date | null;
  priority: NotificationPriority;
  isPinned: boolean;
  status: AnnouncementStatus;
  createdBy: mongoose.Types.ObjectId;
  publishedAt?: Date | null;
  recipientCount: number;
  createdAt: Date;
  updatedAt: Date;
}

const AnnouncementSchema = new Schema<IAnnouncement>(
  {
    collegeId: { type: Schema.Types.ObjectId, ref: 'College', required: true, index: true },
    departmentId: { type: Schema.Types.ObjectId, ref: 'Department', default: null, index: true },
    title: { type: String, required: true, trim: true },
    body: { type: String, required: true, trim: true },
    category: {
      type: String,
      enum: Object.values(NotificationCategory),
      default: NotificationCategory.ANNOUNCEMENT,
      index: true,
    },
    audienceScope: {
      type: String,
      enum: Object.values(AudienceScope),
      required: true,
      index: true,
    },
    targetRole: {
      type: String,
      enum: Object.values(AppRole),
      default: null,
    },
    targetCourseId: { type: Schema.Types.ObjectId, ref: 'Course', default: null },
    targetSemesterId: { type: Schema.Types.ObjectId, ref: 'Semester', default: null },
    targetSectionId: { type: Schema.Types.ObjectId, ref: 'Section', default: null },
    targetUserId: { type: Schema.Types.ObjectId, ref: 'User', default: null },
    publishAt: { type: Date, default: Date.now },
    expiresAt: { type: Date, default: null },
    priority: {
      type: String,
      enum: Object.values(NotificationPriority),
      default: NotificationPriority.NORMAL,
    },
    isPinned: { type: Boolean, default: false },
    status: {
      type: String,
      enum: Object.values(AnnouncementStatus),
      default: AnnouncementStatus.DRAFT,
      index: true,
    },
    createdBy: { type: Schema.Types.ObjectId, ref: 'User', required: true },
    publishedAt: { type: Date, default: null },
    recipientCount: { type: Number, default: 0 },
  },
  {
    timestamps: true,
    toJSON: {
      virtuals: true,
      transform: (_: unknown, ret: Record<string, any>) => {
        ret.id = ret._id?.toString();
        if (ret.collegeId) ret.collegeId = ret.collegeId.toString();
        if (ret.departmentId) ret.departmentId = ret.departmentId.toString();
        if (ret.targetCourseId) ret.targetCourseId = ret.targetCourseId.toString();
        if (ret.targetSemesterId) ret.targetSemesterId = ret.targetSemesterId.toString();
        if (ret.targetSectionId) ret.targetSectionId = ret.targetSectionId.toString();
        if (ret.targetUserId) ret.targetUserId = ret.targetUserId.toString();
        if (ret.createdBy) ret.createdBy = ret.createdBy.toString();
        delete ret.__v;
        return ret;
      },
    },
  }
);

// Compound indexes for fast filtered feed retrieval and tenant security
AnnouncementSchema.index({ collegeId: 1, status: 1, publishAt: -1 });
AnnouncementSchema.index({ collegeId: 1, audienceScope: 1, status: 1 });
AnnouncementSchema.index({ departmentId: 1, status: 1, publishAt: -1 });

export const Announcement = mongoose.model<IAnnouncement>('Announcement', AnnouncementSchema);
