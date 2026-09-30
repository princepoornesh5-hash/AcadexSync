import mongoose, { Document, Schema } from 'mongoose';
import { AcademicProgressionStatus } from '../constants/academicRecord.constants';

export interface IAcademicRecord extends Document {
  collegeId: mongoose.Types.ObjectId;
  studentId: mongoose.Types.ObjectId;
  studentEnrollmentId: mongoose.Types.ObjectId;
  departmentId: mongoose.Types.ObjectId;
  courseId: mongoose.Types.ObjectId;
  academicYearId: mongoose.Types.ObjectId;
  semesterId: mongoose.Types.ObjectId;
  sectionId?: mongoose.Types.ObjectId | null;
  academicStage?: string | null;
  cohort?: string | null;
  progressionStatus: AcademicProgressionStatus;
  remarks?: string | null;
  promotedAt?: Date | null;
  promotedBy?: mongoose.Types.ObjectId | null;
  completedAt?: Date | null;
  isFinalized: boolean;
  createdAt: Date;
  updatedAt: Date;
}

const AcademicRecordSchema = new Schema<IAcademicRecord>(
  {
    collegeId: { type: Schema.Types.ObjectId, ref: 'College', required: true, index: true },
    studentId: { type: Schema.Types.ObjectId, ref: 'Student', required: true, index: true },
    studentEnrollmentId: { type: Schema.Types.ObjectId, ref: 'StudentEnrollment', required: true, index: true },
    departmentId: { type: Schema.Types.ObjectId, ref: 'Department', required: true, index: true },
    courseId: { type: Schema.Types.ObjectId, ref: 'Course', required: true, index: true },
    academicYearId: { type: Schema.Types.ObjectId, ref: 'AcademicYear', required: true, index: true },
    semesterId: { type: Schema.Types.ObjectId, ref: 'Semester', required: true, index: true },
    sectionId: { type: Schema.Types.ObjectId, ref: 'Section', default: null, index: true },
    academicStage: { type: String, default: null, trim: true },
    cohort: { type: String, default: null, trim: true },
    progressionStatus: {
      type: String,
      enum: Object.values(AcademicProgressionStatus),
      default: AcademicProgressionStatus.ACTIVE,
      index: true,
    },
    remarks: { type: String, default: null, trim: true },
    promotedAt: { type: Date, default: null },
    promotedBy: { type: Schema.Types.ObjectId, ref: 'User', default: null },
    completedAt: { type: Date, default: null },
    isFinalized: { type: Boolean, default: false },
  },
  {
    timestamps: true,
    toJSON: {
      virtuals: true,
      transform: (_: unknown, ret: Record<string, any>) => {
        ret.id = ret._id?.toString();
        ret.collegeId = ret.collegeId?.toString();
        ret.studentId = ret.studentId?.toString();
        ret.studentEnrollmentId = ret.studentEnrollmentId?.toString();
        ret.departmentId = ret.departmentId?.toString();
        ret.courseId = ret.courseId?.toString();
        ret.academicYearId = ret.academicYearId?.toString();
        ret.semesterId = ret.semesterId?.toString();
        if (ret.sectionId) ret.sectionId = ret.sectionId.toString();
        if (ret.promotedBy) ret.promotedBy = ret.promotedBy.toString();
        delete ret.__v;
        return ret;
      },
    },
  }
);

// Enforce unique academic context per student
AcademicRecordSchema.index(
  { collegeId: 1, studentId: 1, academicYearId: 1, semesterId: 1 },
  { unique: true }
);

AcademicRecordSchema.index({ collegeId: 1, studentId: 1, createdAt: -1 });
AcademicRecordSchema.index({ collegeId: 1, departmentId: 1, academicYearId: 1, semesterId: 1 });
AcademicRecordSchema.index({ collegeId: 1, studentEnrollmentId: 1 });

export const AcademicRecord = mongoose.model<IAcademicRecord>(
  'AcademicRecord',
  AcademicRecordSchema
);
