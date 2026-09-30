import mongoose, { Document, Schema } from 'mongoose';
import {
  ResultLifecycleStatus,
  SubjectResultStatus,
  OverallResultStatus,
} from '../constants/academicResult.constants';

export interface IAssessmentItemSnapshot {
  assessmentId: mongoose.Types.ObjectId;
  title: string;
  assessmentType: string;
  maximumMarks: number;
  obtainedMarks: number;
  status: string;
}

export interface ISubjectResult {
  subjectId: mongoose.Types.ObjectId;
  subjectCode: string;
  subjectName: string;
  subjectType: string;
  credits: number;
  totalMaxMarks: number;
  totalObtainedMarks: number;
  percentage: number;
  grade?: string | null;
  gradePoint?: number | null;
  status: SubjectResultStatus;
  earnedCredits: number;
  attendancePercentage?: number | null;
  attendanceEligible?: boolean | null;
  practicalCompletionRate?: number | null;
  practicalEligible?: boolean | null;
  assessmentsIncluded: IAssessmentItemSnapshot[];
  remarks?: string | null;
}

export interface IResultSummary {
  totalSubjects: number;
  passedSubjects: number;
  failedSubjects: number;
  incompleteSubjects: number;
  totalCreditsAttempted: number;
  totalCreditsEarned: number;
  totalMaxMarks: number;
  totalObtainedMarks: number;
  percentage?: number | null;
  gpa?: number | null;
  cgpa?: number | null;
  overallResult: OverallResultStatus;
}

export interface IPublicationSnapshot {
  version: number;
  publishedAt: Date;
  publishedBy: mongoose.Types.ObjectId;
  publishedByName: string;
  summary: IResultSummary;
  subjectResults: ISubjectResult[];
  ruleSnapshot: Record<string, any>;
}

export interface IReopenRecord {
  reopenedAt: Date;
  reopenedBy: mongoose.Types.ObjectId;
  reopenedByName: string;
  reopenedByRole: string;
  reason: string;
  previousVersion: number;
  previousStatus: ResultLifecycleStatus;
}

export interface IResultAuditLog {
  action: string;
  performedBy: mongoose.Types.ObjectId;
  performedByName: string;
  performedByRole: string;
  timestamp: Date;
  details?: string | null;
}

export interface IAcademicResult extends Document {
  collegeId: mongoose.Types.ObjectId;
  studentId: mongoose.Types.ObjectId;
  academicRecordId: mongoose.Types.ObjectId;
  studentEnrollmentId: mongoose.Types.ObjectId;
  departmentId: mongoose.Types.ObjectId;
  courseId: mongoose.Types.ObjectId;
  academicYearId: mongoose.Types.ObjectId;
  semesterId: mongoose.Types.ObjectId;
  sectionId?: mongoose.Types.ObjectId | null;
  academicStage?: string | null;
  status: ResultLifecycleStatus;
  version: number;
  summary: IResultSummary;
  subjectResults: ISubjectResult[];
  ruleConfigurationId?: mongoose.Types.ObjectId | null;
  ruleSnapshot?: Record<string, any> | null;
  calculatedAt: Date;
  calculatedBy?: mongoose.Types.ObjectId | null;
  reviewedAt?: Date | null;
  reviewedBy?: mongoose.Types.ObjectId | null;
  reviewNotes?: string | null;
  finalizedAt?: Date | null;
  finalizedBy?: mongoose.Types.ObjectId | null;
  publishedAt?: Date | null;
  publishedBy?: mongoose.Types.ObjectId | null;
  currentPublishedSnapshot?: IPublicationSnapshot | null;
  publicationSnapshots: IPublicationSnapshot[];
  reopenHistory: IReopenRecord[];
  auditLog: IResultAuditLog[];
  createdAt: Date;
  updatedAt: Date;
}

const AssessmentItemSnapshotSchema = new Schema<IAssessmentItemSnapshot>(
  {
    assessmentId: { type: Schema.Types.ObjectId, ref: 'InternalAssessment', required: true },
    title: { type: String, required: true },
    assessmentType: { type: String, required: true },
    maximumMarks: { type: Number, required: true },
    obtainedMarks: { type: Number, required: true },
    status: { type: String, required: true },
  },
  { _id: false }
);

const SubjectResultSchema = new Schema<ISubjectResult>(
  {
    subjectId: { type: Schema.Types.ObjectId, ref: 'Subject', required: true },
    subjectCode: { type: String, required: true, trim: true },
    subjectName: { type: String, required: true, trim: true },
    subjectType: { type: String, default: 'theory' },
    credits: { type: Number, default: 0 },
    totalMaxMarks: { type: Number, required: true },
    totalObtainedMarks: { type: Number, required: true },
    percentage: { type: Number, required: true },
    grade: { type: String, default: null },
    gradePoint: { type: Number, default: null },
    status: {
      type: String,
      enum: Object.values(SubjectResultStatus),
      required: true,
      default: SubjectResultStatus.INCOMPLETE,
    },
    earnedCredits: { type: Number, default: 0 },
    attendancePercentage: { type: Number, default: null },
    attendanceEligible: { type: Boolean, default: null },
    practicalCompletionRate: { type: Number, default: null },
    practicalEligible: { type: Boolean, default: null },
    assessmentsIncluded: { type: [AssessmentItemSnapshotSchema], default: [] },
    remarks: { type: String, default: null, trim: true },
  },
  { _id: false }
);

const ResultSummarySchema = new Schema<IResultSummary>(
  {
    totalSubjects: { type: Number, required: true, default: 0 },
    passedSubjects: { type: Number, required: true, default: 0 },
    failedSubjects: { type: Number, required: true, default: 0 },
    incompleteSubjects: { type: Number, required: true, default: 0 },
    totalCreditsAttempted: { type: Number, required: true, default: 0 },
    totalCreditsEarned: { type: Number, required: true, default: 0 },
    totalMaxMarks: { type: Number, required: true, default: 0 },
    totalObtainedMarks: { type: Number, required: true, default: 0 },
    percentage: { type: Number, default: null },
    gpa: { type: Number, default: null },
    cgpa: { type: Number, default: null },
    overallResult: {
      type: String,
      enum: Object.values(OverallResultStatus),
      required: true,
      default: OverallResultStatus.INCOMPLETE,
    },
  },
  { _id: false }
);

const PublicationSnapshotSchema = new Schema<IPublicationSnapshot>(
  {
    version: { type: Number, required: true },
    publishedAt: { type: Date, required: true },
    publishedBy: { type: Schema.Types.ObjectId, ref: 'User', required: true },
    publishedByName: { type: String, required: true },
    summary: { type: ResultSummarySchema, required: true },
    subjectResults: { type: [SubjectResultSchema], required: true },
    ruleSnapshot: { type: Schema.Types.Mixed, default: {} },
  },
  { _id: false }
);

const ReopenRecordSchema = new Schema<IReopenRecord>(
  {
    reopenedAt: { type: Date, required: true },
    reopenedBy: { type: Schema.Types.ObjectId, ref: 'User', required: true },
    reopenedByName: { type: String, required: true },
    reopenedByRole: { type: String, required: true },
    reason: { type: String, required: true },
    previousVersion: { type: Number, required: true },
    previousStatus: { type: String, required: true },
  },
  { _id: false }
);

const ResultAuditLogSchema = new Schema<IResultAuditLog>(
  {
    action: { type: String, required: true },
    performedBy: { type: Schema.Types.ObjectId, ref: 'User', required: true },
    performedByName: { type: String, required: true },
    performedByRole: { type: String, required: true },
    timestamp: { type: Date, default: Date.now },
    details: { type: String, default: null },
  },
  { _id: false }
);

const AcademicResultSchema = new Schema<IAcademicResult>(
  {
    collegeId: { type: Schema.Types.ObjectId, ref: 'College', required: true, index: true },
    studentId: { type: Schema.Types.ObjectId, ref: 'Student', required: true, index: true },
    academicRecordId: { type: Schema.Types.ObjectId, ref: 'AcademicRecord', required: true, index: true },
    studentEnrollmentId: { type: Schema.Types.ObjectId, ref: 'StudentEnrollment', required: true, index: true },
    departmentId: { type: Schema.Types.ObjectId, ref: 'Department', required: true, index: true },
    courseId: { type: Schema.Types.ObjectId, ref: 'Course', required: true, index: true },
    academicYearId: { type: Schema.Types.ObjectId, ref: 'AcademicYear', required: true, index: true },
    semesterId: { type: Schema.Types.ObjectId, ref: 'Semester', required: true, index: true },
    sectionId: { type: Schema.Types.ObjectId, ref: 'Section', default: null, index: true },
    academicStage: { type: String, default: null, trim: true },
    status: {
      type: String,
      enum: Object.values(ResultLifecycleStatus),
      default: ResultLifecycleStatus.DRAFT,
      index: true,
    },
    version: { type: Number, default: 1 },
    summary: { type: ResultSummarySchema, required: true },
    subjectResults: { type: [SubjectResultSchema], default: [] },
    ruleConfigurationId: { type: Schema.Types.ObjectId, ref: 'AcademicRuleConfiguration', default: null },
    ruleSnapshot: { type: Schema.Types.Mixed, default: null },
    calculatedAt: { type: Date, default: Date.now },
    calculatedBy: { type: Schema.Types.ObjectId, ref: 'User', default: null },
    reviewedAt: { type: Date, default: null },
    reviewedBy: { type: Schema.Types.ObjectId, ref: 'User', default: null },
    reviewNotes: { type: String, default: null, trim: true },
    finalizedAt: { type: Date, default: null },
    finalizedBy: { type: Schema.Types.ObjectId, ref: 'User', default: null },
    publishedAt: { type: Date, default: null },
    publishedBy: { type: Schema.Types.ObjectId, ref: 'User', default: null },
    currentPublishedSnapshot: { type: PublicationSnapshotSchema, default: null },
    publicationSnapshots: { type: [PublicationSnapshotSchema], default: [] },
    reopenHistory: { type: [ReopenRecordSchema], default: [] },
    auditLog: { type: [ResultAuditLogSchema], default: [] },
  },
  {
    timestamps: true,
    toJSON: {
      virtuals: true,
      transform: (_: unknown, ret: Record<string, any>) => {
        ret.id = ret._id?.toString();
        ret.collegeId = ret.collegeId?.toString();
        ret.studentId = ret.studentId?.toString();
        ret.academicRecordId = ret.academicRecordId?.toString();
        ret.studentEnrollmentId = ret.studentEnrollmentId?.toString();
        ret.departmentId = ret.departmentId?.toString();
        ret.courseId = ret.courseId?.toString();
        ret.academicYearId = ret.academicYearId?.toString();
        ret.semesterId = ret.semesterId?.toString();
        if (ret.sectionId) ret.sectionId = ret.sectionId.toString();
        if (ret.ruleConfigurationId) ret.ruleConfigurationId = ret.ruleConfigurationId.toString();
        if (ret.calculatedBy) ret.calculatedBy = ret.calculatedBy.toString();
        if (ret.reviewedBy) ret.reviewedBy = ret.reviewedBy.toString();
        if (ret.finalizedBy) ret.finalizedBy = ret.finalizedBy.toString();
        if (ret.publishedBy) ret.publishedBy = ret.publishedBy.toString();
        delete ret.__v;
        return ret;
      },
    },
  }
);

// One academic result per student per semester per academic year
AcademicResultSchema.index(
  { collegeId: 1, studentId: 1, academicYearId: 1, semesterId: 1 },
  { unique: true }
);

AcademicResultSchema.index({ collegeId: 1, courseId: 1, semesterId: 1, status: 1 });
AcademicResultSchema.index({ collegeId: 1, departmentId: 1, semesterId: 1 });
AcademicResultSchema.index({ collegeId: 1, status: 1 });

export const AcademicResult = mongoose.model<IAcademicResult>(
  'AcademicResult',
  AcademicResultSchema
);
