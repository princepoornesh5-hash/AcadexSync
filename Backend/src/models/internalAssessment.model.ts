import mongoose, { Document, Schema } from 'mongoose';

export enum AssessmentStatus {
  DRAFT = 'DRAFT',
  SCHEDULED = 'SCHEDULED',
  COMPLETED = 'COMPLETED',
  MARKS_ENTRY = 'MARKS_ENTRY',
  SUBMITTED = 'SUBMITTED',
  LOCKED = 'LOCKED',
  // Backward compatibility with legacy workflow
  OPEN = 'OPEN',
  CLOSED = 'CLOSED',
  REVIEWED = 'REVIEWED',
  PUBLISHED = 'PUBLISHED',
  ARCHIVED = 'ARCHIVED',
}

export enum AssessmentType {
  UNIT_TEST = 'UNIT_TEST',
  INTERNAL = 'INTERNAL',
  INTERNAL_EXAM = 'INTERNAL_EXAM',
  MID_TERM = 'MID_TERM',
  MODEL_EXAM = 'MODEL_EXAM',
  SLIP_TEST = 'SLIP_TEST',
  SEMESTER_EXAM = 'SEMESTER_EXAM',
  LAB_EXAM = 'LAB_EXAM',
  LAB_INTERNAL = 'LAB_INTERNAL',
  PRACTICAL = 'PRACTICAL',
  VIVA_VOCE = 'VIVA_VOCE',
  QUIZ = 'QUIZ',
  ASSIGNMENT = 'ASSIGNMENT',
  PROJECT = 'PROJECT',
  OTHER = 'OTHER',
}

export enum StudentMarkStatus {
  NOT_ENTERED = 'NOT_ENTERED',
  ENTERED = 'ENTERED',
  PRESENT = 'PRESENT',
  ABSENT = 'ABSENT',
  EXCUSED = 'EXCUSED',
  EXEMPTED = 'EXEMPTED',
  NOT_APPEARED = 'NOT_APPEARED',
}

export interface IAssessmentComponent {
  key: string;
  name: string;
  maxMarks: number;
  weightage?: number;
  isStudentVisible?: boolean;
}

export interface IStudentAssessmentEntry {
  studentId: mongoose.Types.ObjectId;
  studentName: string;
  rollNumber?: string;
  admissionNumber?: string;
  componentMarks: Record<string, number | null>;
  totalMarks?: number;
  status?: StudentMarkStatus;
  remarks?: string;
}

export interface IAssessmentAuditEntry {
  action: string;
  performedBy: mongoose.Types.ObjectId;
  performedByName?: string;
  performedByRole?: string;
  timestamp: Date;
  details?: string;
  previousValue?: Record<string, unknown> | null;
  newValue?: Record<string, unknown> | null;
}

export interface IAssessmentSchedule {
  date: Date | string;
  dateString?: string;
  startTime?: string | null;
  endTime?: string | null;
  roomId?: mongoose.Types.ObjectId | null;
  roomNumber?: string | null;
  building?: string | null;
  invigilatorFacultyId?: mongoose.Types.ObjectId | null;
  invigilatorName?: string | null;
  instructions?: string | null;
  status?: 'SCHEDULED' | 'RESCHEDULED' | 'CANCELLED' | 'COMPLETED';
}

export interface IAssessmentCorrectionScope {
  requestId: mongoose.Types.ObjectId;
  studentEnrollmentIds: mongoose.Types.ObjectId[];
  unlockedAt: Date;
  unlockedBy: mongoose.Types.ObjectId;
  reason?: string;
}

export interface IAcademicScopeTarget {
  departmentId: mongoose.Types.ObjectId;
  courseId: mongoose.Types.ObjectId;
  academicYearId: mongoose.Types.ObjectId;
  semesterId: mongoose.Types.ObjectId;
  sectionId?: mongoose.Types.ObjectId | null;
  facultyAssignmentId?: mongoose.Types.ObjectId | null;
  departmentName?: string | null;
  sectionName?: string | null;
  semesterNumber?: number | null;
  studentCount?: number;
}

export interface IInternalAssessment extends Document {
  collegeId: mongoose.Types.ObjectId;
  departmentId: mongoose.Types.ObjectId;
  courseId: mongoose.Types.ObjectId;
  academicYearId: mongoose.Types.ObjectId;
  semesterId: mongoose.Types.ObjectId;
  sectionId?: mongoose.Types.ObjectId | null;
  subjectId: mongoose.Types.ObjectId;
  facultyAssignmentId?: mongoose.Types.ObjectId | null;
  facultyId?: mongoose.Types.ObjectId | null;
  facultyName?: string;
  academicScopes?: IAcademicScopeTarget[];
  isCommonExam?: boolean;
  title: string;
  assessmentType: AssessmentType | string;
  maximumMarks: number;
  passMarks?: number;
  weightage?: number;
  description?: string | null;
  assessmentDate?: Date;
  schedule?: IAssessmentSchedule | null;
  components: IAssessmentComponent[];
  entries: IStudentAssessmentEntry[];
  status: AssessmentStatus;
  isPublishedToStudents?: boolean;
  submittedAt?: Date;
  submittedBy?: mongoose.Types.ObjectId;
  publishedAt?: Date;
  publishedBy?: mongoose.Types.ObjectId;
  reviewedAt?: Date;
  reviewedBy?: mongoose.Types.ObjectId;
  lockedAt?: Date;
  lockedBy?: mongoose.Types.ObjectId;
  correctionScope?: IAssessmentCorrectionScope | null;
  sourceType?: 'LIVE' | 'IMPORTED' | 'HISTORICAL_MANUAL';
  importBatchId?: string;
  createdBy?: mongoose.Types.ObjectId | null;
  updatedBy?: mongoose.Types.ObjectId | null;
  auditLog: IAssessmentAuditEntry[];
  createdAt: Date;
  updatedAt: Date;
}

const AssessmentComponentSchema = new Schema<IAssessmentComponent>(
  {
    key: { type: String, required: true, trim: true },
    name: { type: String, required: true, trim: true },
    maxMarks: { type: Number, required: true, min: 1 },
    weightage: { type: Number, default: 0 },
    isStudentVisible: { type: Boolean, default: true },
  },
  { _id: false }
);

const StudentAssessmentEntrySchema = new Schema<IStudentAssessmentEntry>(
  {
    studentId: { type: Schema.Types.ObjectId, ref: 'Student', required: true },
    studentName: { type: String, required: true, trim: true },
    rollNumber: { type: String, default: null, trim: true },
    admissionNumber: { type: String, default: null, trim: true },
    componentMarks: { type: Schema.Types.Mixed, default: {} },
    totalMarks: { type: Number, default: 0 },
    status: {
      type: String,
      enum: Object.values(StudentMarkStatus),
      default: StudentMarkStatus.NOT_ENTERED,
    },
    remarks: { type: String, default: null },
  },
  { _id: false }
);

const AssessmentAuditEntrySchema = new Schema<IAssessmentAuditEntry>(
  {
    action: { type: String, required: true },
    performedBy: { type: Schema.Types.ObjectId, ref: 'User', required: true },
    performedByName: { type: String, default: null },
    performedByRole: { type: String, default: null },
    timestamp: { type: Date, default: Date.now },
    details: { type: String, default: null },
    previousValue: { type: Schema.Types.Mixed, default: null },
    newValue: { type: Schema.Types.Mixed, default: null },
  },
  { _id: false }
);

const AcademicScopeTargetSchema = new Schema<IAcademicScopeTarget>(
  {
    departmentId: { type: Schema.Types.ObjectId, ref: 'Department', required: true },
    courseId: { type: Schema.Types.ObjectId, ref: 'Course', required: true },
    academicYearId: { type: Schema.Types.ObjectId, ref: 'AcademicYear', required: true },
    semesterId: { type: Schema.Types.ObjectId, ref: 'Semester', required: true },
    sectionId: { type: Schema.Types.ObjectId, ref: 'Section', default: null },
    facultyAssignmentId: { type: Schema.Types.ObjectId, ref: 'FacultyAssignment', default: null },
    departmentName: { type: String, default: null },
    sectionName: { type: String, default: null },
    semesterNumber: { type: Number, default: null },
    studentCount: { type: Number, default: 0 },
  },
  { _id: false }
);

const InternalAssessmentSchema = new Schema<IInternalAssessment>(
  {
    collegeId: { type: Schema.Types.ObjectId, ref: 'College', required: true, index: true },
    departmentId: { type: Schema.Types.ObjectId, ref: 'Department', required: true, index: true },
    courseId: { type: Schema.Types.ObjectId, ref: 'Course', required: true },
    academicYearId: { type: Schema.Types.ObjectId, ref: 'AcademicYear', required: true },
    semesterId: { type: Schema.Types.ObjectId, ref: 'Semester', required: true },
    sectionId: { type: Schema.Types.ObjectId, ref: 'Section', default: null, index: true },
    subjectId: { type: Schema.Types.ObjectId, ref: 'Subject', required: true, index: true },
    facultyAssignmentId: { type: Schema.Types.ObjectId, ref: 'FacultyAssignment', default: null },
    facultyId: { type: Schema.Types.ObjectId, ref: 'Faculty', default: null },
    facultyName: { type: String, default: null },
    academicScopes: [AcademicScopeTargetSchema],
    isCommonExam: { type: Boolean, default: false, index: true },
    title: { type: String, default: 'Internal Assessment', trim: true },
    assessmentType: {
      type: String,
      default: AssessmentType.INTERNAL,
      index: true,
    },
    maximumMarks: { type: Number, default: 0 },
    passMarks: { type: Number, default: 0 },
    weightage: { type: Number, default: 0 },
    description: { type: String, default: null, trim: true },
    assessmentDate: { type: Date, default: null },
    schedule: { type: Schema.Types.Mixed, default: null },
    components: [AssessmentComponentSchema],
    entries: [StudentAssessmentEntrySchema],
    status: {
      type: String,
      enum: Object.values(AssessmentStatus),
      default: AssessmentStatus.DRAFT,
      index: true,
    },
    isPublishedToStudents: { type: Boolean, default: false, index: true },
    submittedAt: { type: Date, default: null },
    submittedBy: { type: Schema.Types.ObjectId, ref: 'User', default: null },
    publishedAt: { type: Date, default: null },
    publishedBy: { type: Schema.Types.ObjectId, ref: 'User', default: null },
    reviewedAt: { type: Date, default: null },
    reviewedBy: { type: Schema.Types.ObjectId, ref: 'User', default: null },
    lockedAt: { type: Date, default: null },
    lockedBy: { type: Schema.Types.ObjectId, ref: 'User', default: null },
    correctionScope: { type: Schema.Types.Mixed, default: null },
    sourceType: {
      type: String,
      enum: ['LIVE', 'IMPORTED', 'HISTORICAL_MANUAL'],
      default: 'LIVE',
    },
    importBatchId: { type: String, default: null, index: true },
    createdBy: { type: Schema.Types.ObjectId, ref: 'User', default: null },
    updatedBy: { type: Schema.Types.ObjectId, ref: 'User', default: null },
    auditLog: [AssessmentAuditEntrySchema],
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
        ret.semesterId = ret.semesterId?.toString();
        if (ret.sectionId) ret.sectionId = ret.sectionId.toString();
        ret.subjectId = ret.subjectId?.toString();
        if (ret.facultyAssignmentId) ret.facultyAssignmentId = ret.facultyAssignmentId.toString();
        if (ret.facultyId) ret.facultyId = ret.facultyId.toString();
        if (ret.publishedBy) ret.publishedBy = ret.publishedBy.toString();
        if (ret.reviewedBy) ret.reviewedBy = ret.reviewedBy.toString();
        if (ret.lockedBy) ret.lockedBy = ret.lockedBy.toString();
        if (ret.createdBy) ret.createdBy = ret.createdBy.toString();
        if (ret.updatedBy) ret.updatedBy = ret.updatedBy.toString();
        delete ret.__v;
        return ret;
      },
    },
  }
);

// Decoupled: allow multiple assessments for the same section & subject, with compound query indexing
InternalAssessmentSchema.index(
  { collegeId: 1, academicYearId: 1, semesterId: 1, sectionId: 1, subjectId: 1 }
);

// Prevent accidental duplicate titles for the exact same teaching assignment
InternalAssessmentSchema.index(
  { collegeId: 1, facultyAssignmentId: 1, title: 1 },
  {
    unique: true,
    partialFilterExpression: {
      status: { $ne: 'ARCHIVED' },
      facultyAssignmentId: { $type: 'objectId' },
    },
  }
);

InternalAssessmentSchema.index({ collegeId: 1, sectionId: 1 });
InternalAssessmentSchema.index({ collegeId: 1, subjectId: 1 });
InternalAssessmentSchema.index({ collegeId: 1, facultyAssignmentId: 1, status: 1 });
InternalAssessmentSchema.index({ collegeId: 1, departmentId: 1, status: 1 });

export const InternalAssessment = mongoose.model<IInternalAssessment>(
  'InternalAssessment',
  InternalAssessmentSchema
);

// Canonical model and interface aliases
export const Assessment = InternalAssessment;
export type IAssessment = IInternalAssessment;
