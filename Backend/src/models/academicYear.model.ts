import mongoose, { Document, Schema } from 'mongoose';
import { AcademicYearStatus } from '../constants/status';

export interface IAcademicYear extends Document {
  collegeId: mongoose.Types.ObjectId;
  name: string;
  startDate: Date;
  endDate: Date;
  status: AcademicYearStatus;
  isCurrent: boolean;
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

const AcademicYearSchema = new Schema<IAcademicYear>(
  {
    collegeId: { type: Schema.Types.ObjectId, ref: 'College', required: true, index: true },
    name: { type: String, required: true, trim: true },
    startDate: { type: Date, required: true },
    endDate: { type: Date, required: true },
    status: {
      type: String,
      enum: Object.values(AcademicYearStatus),
      default: AcademicYearStatus.UPCOMING,
    },
    isCurrent: { type: Boolean, default: false },
    isActive: { type: Boolean, default: true },
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

AcademicYearSchema.index({ collegeId: 1, name: 1 }, { unique: true });
AcademicYearSchema.index({ collegeId: 1, isCurrent: 1 });
AcademicYearSchema.index({ collegeId: 1, status: 1 });

export const AcademicYear = mongoose.model<IAcademicYear>('AcademicYear', AcademicYearSchema);
