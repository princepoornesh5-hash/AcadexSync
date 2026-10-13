import mongoose, { Document, Schema } from 'mongoose';

export type HistoricalAttendancePrecision = 'PERIOD_SUMMARY' | 'PERCENTAGE_ONLY';

export interface IHistoricalAttendanceSummary extends Document {
  collegeId: mongoose.Types.ObjectId;
  departmentId: mongoose.Types.ObjectId;
  courseId?: mongoose.Types.ObjectId | null;
  academicYearId?: mongoose.Types.ObjectId | null;
  semesterId?: mongoose.Types.ObjectId | null;
  sectionId?: mongoose.Types.ObjectId | null;
  subjectId: mongoose.Types.ObjectId;
  studentEnrollmentId: mongoose.Types.ObjectId;
  studentId: mongoose.Types.ObjectId;
  periodStart?: Date | null;
  periodEnd?: Date | null;
  periodLabel: string;
  classesHeld: number | null;
  presentCount: number | null;
  absentCount: number | null;
  attendancePercentage: number;
  precisionLevel: HistoricalAttendancePrecision;
  sourceType: 'LIVE' | 'IMPORTED' | 'HISTORICAL_MANUAL';
  importBatchId?: string | null;
  importedBy?: mongoose.Types.ObjectId | null;
  importedAt: Date;
  remarks?: string | null;
  createdAt: Date;
  updatedAt: Date;
}

const HistoricalAttendanceSummarySchema = new Schema<IHistoricalAttendanceSummary>(
  {
    collegeId: { type: Schema.Types.ObjectId, ref: 'College', required: true, index: true },
    departmentId: { type: Schema.Types.ObjectId, ref: 'Department', required: true, index: true },
    courseId: { type: Schema.Types.ObjectId, ref: 'Course', default: null },
    academicYearId: { type: Schema.Types.ObjectId, ref: 'AcademicYear', default: null, index: true },
    semesterId: { type: Schema.Types.ObjectId, ref: 'Semester', default: null, index: true },
    sectionId: { type: Schema.Types.ObjectId, ref: 'Section', default: null, index: true },
    subjectId: { type: Schema.Types.ObjectId, ref: 'Subject', required: true, index: true },
    studentEnrollmentId: { type: Schema.Types.ObjectId, ref: 'StudentEnrollment', required: true, index: true },
    studentId: { type: Schema.Types.ObjectId, ref: 'Student', required: true, index: true },
    periodStart: { type: Date, default: null },
    periodEnd: { type: Date, default: null },
    periodLabel: { type: String, required: true, trim: true },
    classesHeld: { type: Number, default: null },
    presentCount: { type: Number, default: null },
    absentCount: { type: Number, default: null },
    attendancePercentage: {
      type: Number,
      required: true,
      min: 0,
      max: 100,
    },
    precisionLevel: {
      type: String,
      enum: ['PERIOD_SUMMARY', 'PERCENTAGE_ONLY'],
      required: true,
      default: 'PERIOD_SUMMARY',
    },
    sourceType: {
      type: String,
      enum: ['LIVE', 'IMPORTED', 'HISTORICAL_MANUAL'],
      default: 'IMPORTED',
    },
    importBatchId: { type: String, default: 'MANUAL_ENTRY', index: true },
    importedBy: { type: Schema.Types.ObjectId, ref: 'User', default: null },
    importedAt: { type: Date, default: Date.now },
    remarks: { type: String, default: null },
  },
  {
    timestamps: true,
    toJSON: {
      virtuals: true,
      transform: (_: unknown, ret: Record<string, any>) => {
        ret.id = ret._id?.toString();
        ret.collegeId = ret.collegeId?.toString();
        ret.departmentId = ret.departmentId?.toString();
        if (ret.courseId) ret.courseId = ret.courseId.toString();
        if (ret.academicYearId) ret.academicYearId = ret.academicYearId.toString();
        if (ret.semesterId) ret.semesterId = ret.semesterId.toString();
        if (ret.sectionId) ret.sectionId = ret.sectionId.toString();
        ret.subjectId = ret.subjectId?.toString();
        ret.studentEnrollmentId = ret.studentEnrollmentId?.toString();
        ret.studentId = ret.studentId?.toString();
        if (ret.importedBy) ret.importedBy = ret.importedBy.toString();
        delete ret.__v;
        return ret;
      },
    },
  }
);

// Prevent duplicate summary for same student, subject, period, and batch
HistoricalAttendanceSummarySchema.index(
  { collegeId: 1, studentEnrollmentId: 1, subjectId: 1, periodLabel: 1, importBatchId: 1 },
  { unique: true }
);

HistoricalAttendanceSummarySchema.index({ collegeId: 1, studentEnrollmentId: 1 });
HistoricalAttendanceSummarySchema.index({ collegeId: 1, studentId: 1 });
HistoricalAttendanceSummarySchema.index({ collegeId: 1, sectionId: 1, subjectId: 1 });

export const HistoricalAttendanceSummary = mongoose.model<IHistoricalAttendanceSummary>(
  'HistoricalAttendanceSummary',
  HistoricalAttendanceSummarySchema
);
