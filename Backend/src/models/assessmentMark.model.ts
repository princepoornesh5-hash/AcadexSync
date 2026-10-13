import mongoose, { Document, Schema } from 'mongoose';
import { StudentMarkStatus } from './internalAssessment.model';

export interface IAssessmentMarkAudit {
  action: string;
  previousMarks?: number | null;
  newMarks?: number | null;
  previousStatus?: StudentMarkStatus;
  newStatus?: StudentMarkStatus;
  performedBy: mongoose.Types.ObjectId;
  performedByName?: string;
  performedByRole?: string;
  reason?: string;
  timestamp: Date;
}

export interface IAssessmentMark extends Document {
  collegeId: mongoose.Types.ObjectId;
  assessmentId: mongoose.Types.ObjectId;
  facultyAssignmentId?: mongoose.Types.ObjectId | null;
  subjectId: mongoose.Types.ObjectId;
  studentEnrollmentId: mongoose.Types.ObjectId;
  studentId: mongoose.Types.ObjectId;
  studentName: string;
  rollNumber?: string | null;
  admissionNumber?: string | null;
  marks: number | null;
  maximumMarks: number;
  passMarks?: number;
  status: StudentMarkStatus;
  remarks?: string | null;
  isLocked: boolean;
  lockedAt?: Date | null;
  lockedBy?: mongoose.Types.ObjectId | null;
  sourceType: 'LIVE' | 'IMPORTED' | 'HISTORICAL_MANUAL';
  importBatchId?: string;
  auditHistory: IAssessmentMarkAudit[];
  createdAt: Date;
  updatedAt: Date;
}

const AssessmentMarkAuditSchema = new Schema<IAssessmentMarkAudit>(
  {
    action: { type: String, required: true },
    previousMarks: { type: Number, default: null },
    newMarks: { type: Number, default: null },
    previousStatus: { type: String, default: null },
    newStatus: { type: String, default: null },
    performedBy: { type: Schema.Types.ObjectId, ref: 'User', required: true },
    performedByName: { type: String, default: null },
    performedByRole: { type: String, default: null },
    reason: { type: String, default: null },
    timestamp: { type: Date, default: Date.now },
  },
  { _id: false }
);

const AssessmentMarkSchema = new Schema<IAssessmentMark>(
  {
    collegeId: { type: Schema.Types.ObjectId, ref: 'College', required: true, index: true },
    assessmentId: { type: Schema.Types.ObjectId, ref: 'InternalAssessment', required: true, index: true },
    facultyAssignmentId: { type: Schema.Types.ObjectId, ref: 'FacultyAssignment', default: null, index: true },
    subjectId: { type: Schema.Types.ObjectId, ref: 'Subject', required: true, index: true },
    studentEnrollmentId: { type: Schema.Types.ObjectId, ref: 'StudentEnrollment', required: true, index: true },
    studentId: { type: Schema.Types.ObjectId, ref: 'Student', required: true, index: true },
    studentName: { type: String, required: true, trim: true },
    rollNumber: { type: String, default: null, trim: true },
    admissionNumber: { type: String, default: null, trim: true },
    marks: {
      type: Number,
      default: null,
      validate: {
        validator: function (this: IAssessmentMark, val: number | null) {
          if (val === null || val === undefined) return true;
          return val >= 0 && val <= this.maximumMarks;
        },
        message: 'Marks cannot be negative or exceed maximum marks',
      },
    },
    maximumMarks: { type: Number, required: true, min: 1 },
    passMarks: { type: Number, default: 0 },
    status: {
      type: String,
      enum: Object.values(StudentMarkStatus),
      default: StudentMarkStatus.NOT_ENTERED,
      index: true,
    },
    remarks: { type: String, default: null, trim: true },
    isLocked: { type: Boolean, default: false },
    lockedAt: { type: Date, default: null },
    lockedBy: { type: Schema.Types.ObjectId, ref: 'User', default: null },
    sourceType: { type: String, enum: ['LIVE', 'IMPORTED', 'HISTORICAL_MANUAL'], default: 'LIVE' },
    importBatchId: { type: String, default: null, index: true },
    auditHistory: [AssessmentMarkAuditSchema],
  },
  {
    timestamps: true,
    toJSON: {
      virtuals: true,
      transform: (_: unknown, ret: Record<string, any>) => {
        ret.id = ret._id?.toString();
        ret.collegeId = ret.collegeId?.toString();
        ret.assessmentId = ret.assessmentId?.toString();
        if (ret.facultyAssignmentId) ret.facultyAssignmentId = ret.facultyAssignmentId.toString();
        ret.subjectId = ret.subjectId?.toString();
        ret.studentEnrollmentId = ret.studentEnrollmentId?.toString();
        ret.studentId = ret.studentId?.toString();
        if (ret.lockedBy) ret.lockedBy = ret.lockedBy.toString();
        delete ret.__v;
        return ret;
      },
    },
  }
);

// Enforce one mark record per student enrollment per assessment
AssessmentMarkSchema.index(
  { collegeId: 1, assessmentId: 1, studentEnrollmentId: 1 },
  { unique: true }
);

// High-speed lookup indices
AssessmentMarkSchema.index({ collegeId: 1, assessmentId: 1, studentId: 1 });
AssessmentMarkSchema.index({ collegeId: 1, studentEnrollmentId: 1 });
AssessmentMarkSchema.index({ collegeId: 1, studentId: 1 });

export const AssessmentMark = mongoose.model<IAssessmentMark>('AssessmentMark', AssessmentMarkSchema);
