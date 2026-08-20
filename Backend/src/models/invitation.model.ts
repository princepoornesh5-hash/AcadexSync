import mongoose, { Document, Schema } from 'mongoose';
import { AppRole } from '../constants/roles';
import { InvitationStatus } from '../constants/status';

export interface IInvitation extends Document {
  userId: mongoose.Types.ObjectId;
  collegeId: mongoose.Types.ObjectId;
  departmentId?: mongoose.Types.ObjectId;
  role: AppRole;
  codeHash: string;
  status: InvitationStatus;
  expiresAt: Date;
  createdBy: string;
  usedAt?: Date;
  revokedAt?: Date;
  revokedBy?: string;
  lastSentAt: Date;
  attemptCount: number;
  metadata?: Record<string, unknown>;
  createdAt: Date;
  updatedAt: Date;
  isExpired(): boolean;
  isValid(): boolean;
}

const InvitationSchema = new Schema<IInvitation>(
  {
    userId: { type: Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    collegeId: { type: Schema.Types.ObjectId, ref: 'College', required: true, index: true },
    departmentId: { type: Schema.Types.ObjectId, ref: 'Department', default: null },
    role: {
      type: String,
      enum: Object.values(AppRole),
      required: true,
    },
    codeHash: { type: String, required: true },
    status: {
      type: String,
      enum: Object.values(InvitationStatus),
      default: InvitationStatus.PENDING,
      index: true,
    },
    expiresAt: { type: Date, required: true },
    createdBy: { type: String, required: true },
    usedAt: { type: Date, default: null },
    revokedAt: { type: Date, default: null },
    revokedBy: { type: String, default: null },
    lastSentAt: { type: Date, default: Date.now },
    attemptCount: { type: Number, default: 0 },
    metadata: { type: Schema.Types.Mixed, default: null },
  },
  {
    timestamps: true,
    toJSON: {
      virtuals: true,
      transform: (_: unknown, ret: Record<string, any>) => {
        ret.id = ret._id?.toString();
        ret.userId = ret.userId?.toString();
        ret.collegeId = ret.collegeId?.toString();
        if (ret.departmentId) ret.departmentId = ret.departmentId.toString();
        delete ret.codeHash;
        delete ret.__v;
        return ret;
      },
    },
  }
);

InvitationSchema.methods.isExpired = function (): boolean {
  return new Date() > this.expiresAt;
};

InvitationSchema.methods.isValid = function (): boolean {
  return this.status === InvitationStatus.PENDING && !this.isExpired();
};

InvitationSchema.index({ userId: 1, status: 1 });
InvitationSchema.index({ collegeId: 1, status: 1 });
InvitationSchema.index({ codeHash: 1 });
InvitationSchema.index({ expiresAt: 1 });

export const Invitation = mongoose.model<IInvitation>('Invitation', InvitationSchema);
