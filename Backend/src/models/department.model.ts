import mongoose, { Document, Schema } from 'mongoose';
import { DepartmentStatus } from '../constants/status';

export interface IDepartment extends Document {
  collegeId: mongoose.Types.ObjectId;
  name: string;
  code: string;
  description?: string;
  status: DepartmentStatus;
  isActive: boolean;
  hodId?: mongoose.Types.ObjectId | string;
  createdBy?: string;
  updatedBy?: string;
  metadata?: Record<string, unknown>;
  createdAt: Date;
  updatedAt: Date;
}

const DepartmentSchema = new Schema<IDepartment>(
  {
    collegeId: { type: Schema.Types.ObjectId, ref: 'College', required: true, index: true },
    name: { type: String, required: true, trim: true },
    code: { type: String, required: true, uppercase: true, trim: true },
    description: { type: String, default: '' },
    status: {
      type: String,
      enum: Object.values(DepartmentStatus),
      default: DepartmentStatus.ACTIVE,
      index: true,
    },
    isActive: { type: Boolean, default: true, index: true },
    hodId: { type: String, default: null },
    createdBy: { type: String, default: null },
    updatedBy: { type: String, default: null },
    metadata: { type: Schema.Types.Mixed, default: null },
  },
  {
    timestamps: true,
    toJSON: {
      virtuals: true,
      transform: (_: unknown, ret: Record<string, any>) => {
        ret.id = ret._id?.toString();
        ret.collegeId = ret.collegeId?.toString();
        delete ret.__v;
        return ret;
      },
    },
  }
);

DepartmentSchema.pre('save', function (next) {
  if (this.isModified('status')) {
    this.isActive = this.status === DepartmentStatus.ACTIVE;
  } else if (this.isModified('isActive')) {
    this.status = this.isActive ? DepartmentStatus.ACTIVE : DepartmentStatus.INACTIVE;
  }
  next();
});

DepartmentSchema.index({ collegeId: 1, code: 1 }, { unique: true });
DepartmentSchema.index({ collegeId: 1, name: 1 });
DepartmentSchema.index({ collegeId: 1, status: 1 });

export const Department = mongoose.model<IDepartment>('Department', DepartmentSchema);
