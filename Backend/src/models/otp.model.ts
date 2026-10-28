import mongoose, { Document, Schema } from 'mongoose';
import { OtpPurpose, OtpDeliveryMethod } from '../constants/status';

export interface IOtp extends Document {
  userId?: mongoose.Types.ObjectId | null;
  invitationId?: mongoose.Types.ObjectId | null;
  purpose: OtpPurpose;
  deliveryMethod: OtpDeliveryMethod;
  destination: string;
  otpHash: string;
  expiresAt: Date;
  attempts: number;
  consumedAt?: Date | null;
  createdAt: Date;
  updatedAt: Date;
  isExpired(): boolean;
  isConsumed(): boolean;
}

const OtpSchema = new Schema<IOtp>(
  {
    userId: { type: Schema.Types.ObjectId, ref: 'User', required: false, default: null, index: true },
    invitationId: { type: Schema.Types.ObjectId, ref: 'Invitation', required: false, default: null, index: true },
    purpose: {
      type: String,
      enum: Object.values(OtpPurpose),
      required: true,
      default: OtpPurpose.PASSWORD_RESET,
    },
    deliveryMethod: {
      type: String,
      enum: Object.values(OtpDeliveryMethod),
      required: true,
      default: OtpDeliveryMethod.EMAIL,
    },
    destination: { type: String, required: true, trim: true, lowercase: true, index: true },
    otpHash: { type: String, required: true },
    expiresAt: { type: Date, required: true },
    attempts: { type: Number, default: 0 },
    consumedAt: { type: Date, default: null },
  },
  {
    timestamps: true,
    toJSON: {
      virtuals: true,
      transform: (_: unknown, ret: Record<string, any>) => {
        ret.id = ret._id?.toString();
        ret.userId = ret.userId ? ret.userId.toString() : null;
        ret.invitationId = ret.invitationId ? ret.invitationId.toString() : null;
        delete ret.otpHash;
        delete ret.__v;
        return ret;
      },
    },
  }
);

OtpSchema.methods.isExpired = function (): boolean {
  return new Date() > this.expiresAt;
};

OtpSchema.methods.isConsumed = function (): boolean {
  return this.consumedAt !== null && this.consumedAt !== undefined;
};

OtpSchema.index({ destination: 1, purpose: 1, createdAt: -1 });
OtpSchema.index({ userId: 1, purpose: 1, createdAt: -1 });
OtpSchema.index({ invitationId: 1, purpose: 1 });
OtpSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });

export const Otp = mongoose.model<IOtp>('Otp', OtpSchema);
