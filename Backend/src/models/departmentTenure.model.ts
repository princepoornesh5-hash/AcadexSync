import mongoose, { Document, Schema } from 'mongoose';

export interface IDepartmentTenure extends Document {
  collegeId: mongoose.Types.ObjectId;
  departmentId: mongoose.Types.ObjectId;
  userId: mongoose.Types.ObjectId;
  facultyId?: mongoose.Types.ObjectId | null;
  membershipId?: mongoose.Types.ObjectId | null;
  startDate: Date;
  endDate?: Date | null;
  status: 'ACTIVE' | 'COMPLETED' | 'REVOKED';
  appointedBy: mongoose.Types.ObjectId;
  revokedBy?: mongoose.Types.ObjectId | null;
  revokedAt?: Date | null;
  notes?: string | null;
  createdAt: Date;
  updatedAt: Date;
}

const DepartmentTenureSchema = new Schema<IDepartmentTenure>(
  {
    collegeId: { type: Schema.Types.ObjectId, ref: 'College', required: true, index: true },
    departmentId: { type: Schema.Types.ObjectId, ref: 'Department', required: true },
    userId: { type: Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    facultyId: { type: Schema.Types.ObjectId, ref: 'Faculty', default: null, index: true },
    membershipId: { type: Schema.Types.ObjectId, ref: 'WorkspaceMembership', default: null, index: true },
    startDate: { type: Date, default: Date.now, required: true },
    endDate: { type: Date, default: null },
    status: {
      type: String,
      enum: ['ACTIVE', 'COMPLETED', 'REVOKED'],
      default: 'ACTIVE',
      required: true,
      index: true,
    },
    appointedBy: { type: Schema.Types.ObjectId, ref: 'User', required: true },
    revokedBy: { type: Schema.Types.ObjectId, ref: 'User', default: null },
    revokedAt: { type: Date, default: null },
    notes: { type: String, default: null, trim: true },
  },
  {
    timestamps: true,
    toJSON: {
      virtuals: true,
      transform: (_: unknown, ret: Record<string, any>) => {
        ret.id = ret._id?.toString();
        ret.collegeId = ret.collegeId?.toString();
        ret.departmentId = ret.departmentId?.toString();
        ret.userId = ret.userId?.toString();
        ret.facultyId = ret.facultyId?.toString();
        ret.membershipId = ret.membershipId?.toString();
        ret.appointedBy = ret.appointedBy?.toString();
        ret.revokedBy = ret.revokedBy?.toString();
        delete ret.__v;
        return ret;
      },
    },
  }
);

// Guarantee: at most one active HOD tenure per department at any given moment
DepartmentTenureSchema.index(
  { departmentId: 1 },
  { unique: true, partialFilterExpression: { status: 'ACTIVE' } }
);

DepartmentTenureSchema.index({ collegeId: 1, departmentId: 1, startDate: -1 });
DepartmentTenureSchema.index({ userId: 1, collegeId: 1, status: 1 });

export const DepartmentTenure = mongoose.model<IDepartmentTenure>(
  'DepartmentTenure',
  DepartmentTenureSchema
);
