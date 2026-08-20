import mongoose, { Document, Schema } from 'mongoose';
import { SectionStatus } from '../constants/status';

export interface ISection extends Document {
  collegeId: mongoose.Types.ObjectId;
  departmentId: mongoose.Types.ObjectId;
  courseId: mongoose.Types.ObjectId;
  academicYearId?: mongoose.Types.ObjectId;
  semesterId: mongoose.Types.ObjectId;
  name: string;
  capacity: number;
  status: SectionStatus;
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

const SectionSchema = new Schema<ISection>(
  {
    collegeId: { type: Schema.Types.ObjectId, ref: 'College', required: true, index: true },
    departmentId: { type: Schema.Types.ObjectId, ref: 'Department', required: true, index: true },
    courseId: { type: Schema.Types.ObjectId, ref: 'Course', required: true, index: true },
    academicYearId: { type: Schema.Types.ObjectId, ref: 'AcademicYear', default: null },
    semesterId: { type: Schema.Types.ObjectId, ref: 'Semester', required: true, index: true },
    name: { type: String, required: true, trim: true },
    capacity: { type: Number, default: 60, min: 1 },
    status: {
      type: String,
      enum: Object.values(SectionStatus),
      default: SectionStatus.ACTIVE,
    },
    isActive: { type: Boolean, default: true },
  },
  {
    timestamps: true,
    toJSON: {
      virtuals: true,
      transform: (_: unknown, ret: Record<string, any>) => {
        ret.id = ret._id?.toString();
        ret.collegeId = ret.collegeId?.toString();
        ret.departmentId = ret.departmentId?.toString();
        ret.courseId = ret.courseId?.toString();
        ret.semesterId = ret.semesterId?.toString();
        if (ret.academicYearId) ret.academicYearId = ret.academicYearId.toString();
        delete ret.__v;
        return ret;
      },
    },
  }
);

SectionSchema.index(
  { collegeId: 1, departmentId: 1, semesterId: 1, name: 1 },
  { unique: true }
);
SectionSchema.index({ collegeId: 1, semesterId: 1 });

export const Section = mongoose.model<ISection>('Section', SectionSchema);
