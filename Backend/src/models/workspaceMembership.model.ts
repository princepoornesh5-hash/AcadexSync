import mongoose, { Document, Schema } from 'mongoose';
import { MembershipStatus, MembershipType } from '../constants/status';

export interface IWorkspaceMembership extends Document {
  userId: mongoose.Types.ObjectId;
  collegeId: mongoose.Types.ObjectId;
  instituteId?: string | null;
  memberType?: MembershipType | null;
  status: MembershipStatus;
  isDefault: boolean;
  title?: string | null;
  admissionNumber?: string | null;
  employeeId?: string | null;
  joinedAt: Date;
  effectiveStartDate: Date;
  effectiveEndDate?: Date | null;
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
    instituteId: { type: String, default: null, trim: true, uppercase: true },
    memberType: {
      type: String,
      enum: Object.values(MembershipType),
      default: null,
      index: true,
    },
    status: {
      type: String,
      enum: Object.values(MembershipStatus),
      default: MembershipStatus.PENDING,
      required: true,
      index: true,
    },
    isDefault: { type: Boolean, default: false },
    title: { type: String, default: null, trim: true },
    admissionNumber: { type: String, default: null, trim: true },
    employeeId: { type: String, default: null, trim: true },
    joinedAt: { type: Date, default: Date.now },
    effectiveStartDate: { type: Date, default: Date.now },
    effectiveEndDate: { type: Date, default: null },
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

// Date range and normalization guard
WorkspaceMembershipSchema.pre('validate', function (next) {
  if (this.effectiveStartDate && this.effectiveEndDate) {
    if (new Date(this.effectiveEndDate).getTime() < new Date(this.effectiveStartDate).getTime()) {
      return next(new Error('effectiveEndDate cannot be earlier than effectiveStartDate'));
    }
  }
  if (!this.effectiveStartDate && this.joinedAt) {
    this.effectiveStartDate = this.joinedAt;
  }
  if (this.instituteId && typeof this.instituteId === 'string') {
    this.instituteId = this.instituteId.trim().toUpperCase();
  }
  next();
});

// Virtual population for associated role assignments
WorkspaceMembershipSchema.virtual('roleAssignments', {
  ref: 'WorkspaceRoleAssignment',
  localField: '_id',
  foreignField: 'membershipId',
});

// Canonical compound uniqueness index: Exactly one membership per user per college
WorkspaceMembershipSchema.index({ userId: 1, collegeId: 1 }, { unique: true });

// Institutional PIN uniqueness index: PIN Number is unique WITHIN a college
WorkspaceMembershipSchema.index(
  { collegeId: 1, instituteId: 1 },
  {
    unique: true,
    partialFilterExpression: {
      instituteId: { $type: 'string' },
    },
  }
);

// Query optimization indexes
WorkspaceMembershipSchema.index({ collegeId: 1, status: 1 });
WorkspaceMembershipSchema.index({ userId: 1, status: 1 });
WorkspaceMembershipSchema.index({ collegeId: 1, instituteId: 1, status: 1 });
WorkspaceMembershipSchema.index({ instituteId: 1 });

export const WorkspaceMembership = mongoose.model<IWorkspaceMembership>(
  'WorkspaceMembership',
  WorkspaceMembershipSchema
);
