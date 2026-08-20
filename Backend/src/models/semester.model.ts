import mongoose, { Document, Schema } from 'mongoose';
import { SemesterStatus } from '../constants/status';

export interface ISemester extends Document {
  collegeId: mongoose.Types.ObjectId;
  departmentId: mongoose.Types.ObjectId;
  courseId: mongoose.Types.ObjectId;
  academicYearId: mongoose.Types.ObjectId;
  name: string;
  number: number;
  startDate?: Date;
  endDate?: Date;
  status: SemesterStatus;
  isCurrent: boolean;
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

const SemesterSchema = new Schema<ISemester>(
  {
    collegeId: { type: Schema.Types.ObjectId, ref: 'College', required: true, index: true },
    departmentId: { type: Schema.Types.ObjectId, ref: 'Department', required: true, index: true },
    courseId: { type: Schema.Types.ObjectId, ref: 'Course', required: true, index: true },
    academicYearId: { type: Schema.Types.ObjectId, ref: 'AcademicYear', required: true, index: true },
    name: { type: String, required: true, trim: true },
    number: { type: Number, required: true, min: 1, max: 12 },
    startDate: { type: Date, default: null },
    endDate: { type: Date, default: null },
    status: {
      type: String,
      enum: Object.values(SemesterStatus),
      default: SemesterStatus.UPCOMING,
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
        ret.departmentId = ret.departmentId?.toString();
        ret.courseId = ret.courseId?.toString();
        ret.academicYearId = ret.academicYearId?.toString();
        delete ret.__v;
        return ret;
      },
    },
  }
);

SemesterSchema.index(
  { collegeId: 1, courseId: 1, academicYearId: 1, number: 1 },
  { unique: true }
);
SemesterSchema.index({ collegeId: 1, departmentId: 1 });
SemesterSchema.index({ collegeId: 1, isCurrent: 1 });

export const Semester = mongoose.model<ISemester>('Semester', SemesterSchema);
