import mongoose, { Document, Schema } from 'mongoose';
import { OtpPurpose, OtpDeliveryMethod } from '../constants/status';

export interface IOtp extends Document {
  userId: mongoose.Types.ObjectId;
  purpose: OtpPurpose;
  deliveryMethod: OtpDeliveryMethod;
  destination: string;
  otpHash: string;
  expiresAt: Date;
  attempts: number;
  consumedAt?: Date;
  createdAt: Date;
  updatedAt: Date;
  isExpired(): boolean;
  isConsumed(): boolean;
}

const OtpSchema = new Schema<IOtp>(
  {
    userId: { type: Schema.Types.ObjectId, ref: 'User', required: true, index: true },
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
    },
    destination: { type: String, required: true, trim: true },
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
        ret.userId = ret.userId?.toString();
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

OtpSchema.index({ userId: 1, purpose: 1, createdAt: -1 });
OtpSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });

export const Otp = mongoose.model<IOtp>('Otp', OtpSchema);
