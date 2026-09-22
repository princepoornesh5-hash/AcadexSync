import mongoose, { Document, Schema } from 'mongoose';
import { CollegeStatus } from '../constants/status';

export interface ICollege extends Document {
  name: string;
  code: string;
  address: string;
  email: string;
  phone: string;
  principal: string;
  status: CollegeStatus;
  isActive: boolean;
  timezone?: string;
  logoUrl?: string;
  createdBy?: string;
  updatedBy?: string;
  metadata?: Record<string, unknown>;
  createdAt: Date;
  updatedAt: Date;
}

const CollegeSchema = new Schema<ICollege>(
  {
    name: { type: String, required: true, trim: true },
    code: { type: String, required: true, unique: true, uppercase: true, trim: true },
    address: { type: String, required: true, trim: true },
    email: { type: String, required: true, lowercase: true, trim: true },
    phone: { type: String, required: true, trim: true },
    principal: { type: String, required: true, trim: true },
    timezone: { type: String, default: 'Asia/Kolkata', trim: true },
    status: {
      type: String,
      enum: Object.values(CollegeStatus),
      default: CollegeStatus.ACTIVE,
      index: true,
    },
    isActive: { type: Boolean, default: true, index: true },
    logoUrl: { type: String, default: null },
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
        delete ret.__v;
        return ret;
      },
    },
  }
);

CollegeSchema.pre('save', function (next) {
  if (this.isModified('status')) {
    this.isActive = this.status === CollegeStatus.ACTIVE;
  } else if (this.isModified('isActive')) {
    this.status = this.isActive ? CollegeStatus.ACTIVE : CollegeStatus.INACTIVE;
  }
  next();
});

CollegeSchema.index({ name: 1 });

export const College = mongoose.model<ICollege>('College', CollegeSchema);
