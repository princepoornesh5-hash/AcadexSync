import mongoose, { Document, Schema } from 'mongoose';
import { AppRole } from '../constants/roles';
import { RoleAssignmentStatus } from '../constants/status';

export interface IWorkspaceRoleAssignment extends Document {
  membershipId: mongoose.Types.ObjectId;
  userId: mongoose.Types.ObjectId;
  collegeId: mongoose.Types.ObjectId;
  role: AppRole;
  departmentId?: mongoose.Types.ObjectId | null;
  status: RoleAssignmentStatus;
  scope?: Record<string, unknown> | null;
  assignedAt: Date;
  revokedAt?: Date | null;
  effectiveStartDate: Date;
  effectiveEndDate?: Date | null;
  assignedBy?: string | null;
  revokedBy?: string | null;
  statusReason?: string | null;
  createdAt: Date;
  updatedAt: Date;
}

const WorkspaceRoleAssignmentSchema = new Schema<IWorkspaceRoleAssignment>(
  {
    membershipId: {
      type: Schema.Types.ObjectId,
      ref: 'WorkspaceMembership',
      required: true,
      index: true,
    },
    userId: { type: Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    collegeId: { type: Schema.Types.ObjectId, ref: 'College', required: true, index: true },
    role: {
      type: String,
      enum: Object.values(AppRole),
      required: true,
      index: true,
    },
    departmentId: {
      type: Schema.Types.ObjectId,
      ref: 'Department',
      default: null,
      index: true,
    },
    status: {
      type: String,
      enum: Object.values(RoleAssignmentStatus),
      default: RoleAssignmentStatus.ACTIVE,
      required: true,
      index: true,
    },
    scope: { type: Schema.Types.Mixed, default: null },
    assignedAt: { type: Date, default: Date.now },
    revokedAt: { type: Date, default: null },
    effectiveStartDate: { type: Date, default: Date.now },
    effectiveEndDate: { type: Date, default: null },
    assignedBy: { type: String, default: null },
    revokedBy: { type: String, default: null },
    statusReason: { type: String, default: null, trim: true },
  },
  {
    timestamps: true,
    toJSON: {
      virtuals: true,
      transform: (_: unknown, ret: Record<string, any>) => {
        ret.id = ret._id?.toString();
        ret.membershipId = ret.membershipId?.toString();
        ret.userId = ret.userId?.toString();
        ret.collegeId = ret.collegeId?.toString();
        if (ret.departmentId) ret.departmentId = ret.departmentId.toString();
        delete ret.__v;
        return ret;
      },
    },
    toObject: {
      virtuals: true,
      transform: (_: unknown, ret: Record<string, any>) => {
        ret.id = ret._id?.toString();
        ret.membershipId = ret.membershipId?.toString();
        ret.userId = ret.userId?.toString();
        ret.collegeId = ret.collegeId?.toString();
        if (ret.departmentId) ret.departmentId = ret.departmentId.toString();
        delete ret.__v;
        return ret;
      },
    },
  }
);

// Date range validation guard
WorkspaceRoleAssignmentSchema.pre('validate', function (next) {
  if (this.effectiveStartDate && this.effectiveEndDate) {
    if (new Date(this.effectiveEndDate).getTime() < new Date(this.effectiveStartDate).getTime()) {
      return next(new Error('effectiveEndDate cannot be earlier than effectiveStartDate'));
    }
  }
  if (!this.effectiveStartDate && this.assignedAt) {
    this.effectiveStartDate = this.assignedAt;
  }
  next();
});

// Prevent duplicate role assignments with identical scope on the same membership
WorkspaceRoleAssignmentSchema.index(
  { membershipId: 1, role: 1, departmentId: 1 },
  { unique: true }
);

// Query optimization indexes
WorkspaceRoleAssignmentSchema.index({ userId: 1, collegeId: 1, status: 1 });
WorkspaceRoleAssignmentSchema.index({ collegeId: 1, role: 1, status: 1 });
WorkspaceRoleAssignmentSchema.index({ collegeId: 1, departmentId: 1, role: 1, status: 1 });

export const WorkspaceRoleAssignment = mongoose.model<IWorkspaceRoleAssignment>(
  'WorkspaceRoleAssignment',
  WorkspaceRoleAssignmentSchema
);
