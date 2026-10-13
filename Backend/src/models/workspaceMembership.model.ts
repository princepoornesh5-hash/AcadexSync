import mongoose, { Document, Schema } from 'mongoose';
import { MembershipStatus } from '../constants/status';

export interface IWorkspaceMembership extends Document {
  userId: mongoose.Types.ObjectId;
  collegeId: mongoose.Types.ObjectId;
  status: MembershipStatus;
  isDefault: boolean;
  title?: string | null;
  joinedAt: Date;
  suspendedAt?: Date | null;
  revokedAt?: Date | null;
  statusReason?: string | null;
  metadata?: Record<string, unknown> | null;
  createdBy?: string | null;
  updatedBy?: string | null;
  createdAt: Date;
  updatedAt: Date;
}

const WorkspaceMembershipSchema = new Schema<IWorkspaceMembership>(
  {
    userId: { type: Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    collegeId: { type: Schema.Types.ObjectId, ref: 'College', required: true, index: true },
    status: {
      type: String,
      enum: Object.values(MembershipStatus),
      default: MembershipStatus.PENDING,
      required: true,
      index: true,
    },
    isDefault: { type: Boolean, default: false },
    title: { type: String, default: null, trim: true },
    joinedAt: { type: Date, default: Date.now },
    suspendedAt: { type: Date, default: null },
    revokedAt: { type: Date, default: null },
    statusReason: { type: String, default: null, trim: true },
    metadata: { type: Schema.Types.Mixed, default: null },
    createdBy: { type: String, default: null },
    updatedBy: { type: String, default: null },
  },
  {
    timestamps: true,
    toJSON: {
      virtuals: true,
      transform: (_: unknown, ret: Record<string, any>) => {
        ret.id = ret._id?.toString();
        ret.userId = ret.userId?.toString();
        ret.collegeId = ret.collegeId?.toString();
        delete ret.__v;
        return ret;
      },
    },
    toObject: {
      virtuals: true,
      transform: (_: unknown, ret: Record<string, any>) => {
        ret.id = ret._id?.toString();
        ret.userId = ret.userId?.toString();
        ret.collegeId = ret.collegeId?.toString();
        delete ret.__v;
        return ret;
      },
    },
  }
);

// Virtual population for associated role assignments
WorkspaceMembershipSchema.virtual('roleAssignments', {
  ref: 'WorkspaceRoleAssignment',
  localField: '_id',
  foreignField: 'membershipId',
});

// Canonical compound uniqueness index: Exactly one membership per user per college
WorkspaceMembershipSchema.index({ userId: 1, collegeId: 1 }, { unique: true });
WorkspaceMembershipSchema.index({ collegeId: 1, status: 1 });
WorkspaceMembershipSchema.index({ userId: 1, status: 1 });

export const WorkspaceMembership = mongoose.model<IWorkspaceMembership>(
  'WorkspaceMembership',
  WorkspaceMembershipSchema
);
