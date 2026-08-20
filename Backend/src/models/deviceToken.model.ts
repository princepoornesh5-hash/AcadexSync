import mongoose, { Document, Schema } from 'mongoose';
import { DevicePlatform } from '../constants/notification.constants';

export interface IDeviceToken extends Document {
  userId: mongoose.Types.ObjectId;
  collegeId?: mongoose.Types.ObjectId;
  deviceToken: string;
  platform: DevicePlatform;
  appVersion?: string;
  isActive: boolean;
  lastSeenAt: Date;
  createdAt: Date;
  updatedAt: Date;
}

const DeviceTokenSchema = new Schema<IDeviceToken>(
  {
    userId: { type: Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    collegeId: { type: Schema.Types.ObjectId, ref: 'College', default: null, index: true },
    deviceToken: { type: String, required: true, trim: true, unique: true },
    platform: {
      type: String,
      enum: Object.values(DevicePlatform),
      required: true,
      default: DevicePlatform.ANDROID,
    },
    appVersion: { type: String, default: null },
    isActive: { type: Boolean, default: true, index: true },
    lastSeenAt: { type: Date, default: Date.now },
  },
  {
    timestamps: true,
    toJSON: {
      virtuals: true,
      transform: (_: unknown, ret: Record<string, any>) => {
        ret.id = ret._id?.toString();
        if (ret.userId) ret.userId = ret.userId.toString();
        if (ret.collegeId) ret.collegeId = ret.collegeId.toString();
        delete ret.__v;
        return ret;
      },
    },
  }
);

DeviceTokenSchema.index({ userId: 1, isActive: 1 });
DeviceTokenSchema.index({ userId: 1, deviceToken: 1 });

export const DeviceToken = mongoose.model<IDeviceToken>('DeviceToken', DeviceTokenSchema);
