import mongoose, { Document, Schema } from 'mongoose';
import { TransferCreditStatus } from '../constants/status';

export interface ITransferredSubjectItem {
  subjectCode: string;
  subjectName: string;
  credits: number;
  grade?: string | null;
  gradePoints?: number | null;
  equivalentSubjectId?: mongoose.Types.ObjectId | null;
  remarks?: string | null;
}

export interface ITransferCreditAuditEntry {
  action: string;
  performedBy: mongoose.Types.ObjectId;
  performedByName?: string;
  performedByRole?: string;
  timestamp: Date;
  details?: string | null;
  previousStatus?: TransferCreditStatus | null;
  newStatus?: TransferCreditStatus | null;
}

export interface ITransferCredit extends Document {
  collegeId: mongoose.Types.ObjectId;
  studentId: mongoose.Types.ObjectId;
  studentEnrollmentId: mongoose.Types.ObjectId;
  userId: mongoose.Types.ObjectId;
  originCollegeId?: mongoose.Types.ObjectId | null;
  originInstitutionName: string;
  priorProgramOrDegree?: string | null;
  admissionType: 'LATERAL_ENTRY' | 'INTER_COLLEGE_TRANSFER' | 'CREDIT_EXCHANGE' | 'REGULAR_ADMISSION_CREDIT';
  entrySemesterNumber: number;
  recognizedCredits: number;
  recognizedGradePoints?: number | null;
  transferredSubjects: ITransferredSubjectItem[];
  verificationStatus: TransferCreditStatus;
  verificationDocumentUrl?: string | null;
  approvedBy?: mongoose.Types.ObjectId | null;
  verifiedAt?: Date | null;
  approvedAt?: Date | null;
  rejectedAt?: Date | null;
  rejectionReason?: string | null;
  remarks?: string | null;
  metadata?: Record<string, unknown> | null;
  auditHistory: ITransferCreditAuditEntry[];
  createdAt: Date;
  updatedAt: Date;
}

const TransferredSubjectItemSchema = new Schema<ITransferredSubjectItem>(
  {
    subjectCode: { type: String, required: true, uppercase: true, trim: true },
    subjectName: { type: String, required: true, trim: true },
    credits: { type: Number, required: true, min: 0 },
    grade: { type: String, default: null, trim: true },
    gradePoints: { type: Number, default: null, min: 0 },
    equivalentSubjectId: { type: Schema.Types.ObjectId, ref: 'Subject', default: null },
    remarks: { type: String, default: null, trim: true },
  },
  { _id: false }
);

const TransferCreditAuditEntrySchema = new Schema<ITransferCreditAuditEntry>(
  {
    action: { type: String, required: true },
    performedBy: { type: Schema.Types.ObjectId, ref: 'User', required: true },
    performedByName: { type: String, default: null },
    performedByRole: { type: String, default: null },
    timestamp: { type: Date, default: Date.now },
    details: { type: String, default: null },
    previousStatus: { type: String, enum: Object.values(TransferCreditStatus), default: null },
    newStatus: { type: String, enum: Object.values(TransferCreditStatus), default: null },
  },
  { _id: false }
);

const TransferCreditSchema = new Schema<ITransferCredit>(
  {
    collegeId: { type: Schema.Types.ObjectId, ref: 'College', required: true, index: true },
    studentId: { type: Schema.Types.ObjectId, ref: 'Student', required: true, index: true },
    studentEnrollmentId: { type: Schema.Types.ObjectId, ref: 'StudentEnrollment', required: true, index: true },
    userId: { type: Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    originCollegeId: { type: Schema.Types.ObjectId, ref: 'College', default: null },
    originInstitutionName: { type: String, required: true, trim: true },
    priorProgramOrDegree: { type: String, default: null, trim: true },
    admissionType: {
      type: String,
      enum: ['LATERAL_ENTRY', 'INTER_COLLEGE_TRANSFER', 'CREDIT_EXCHANGE', 'REGULAR_ADMISSION_CREDIT'],
      default: 'INTER_COLLEGE_TRANSFER',
      required: true,
      index: true,
    },
    entrySemesterNumber: { type: Number, default: 3, min: 1 },
    recognizedCredits: { type: Number, required: true, min: 0 },
    recognizedGradePoints: { type: Number, default: null, min: 0 },
    transferredSubjects: { type: [TransferredSubjectItemSchema], default: [] },
    verificationStatus: {
      type: String,
      enum: Object.values(TransferCreditStatus),
      default: TransferCreditStatus.PENDING,
      required: true,
      index: true,
    },
    verificationDocumentUrl: { type: String, default: null },
    approvedBy: { type: Schema.Types.ObjectId, ref: 'User', default: null },
    verifiedAt: { type: Date, default: null },
    approvedAt: { type: Date, default: null },
    rejectedAt: { type: Date, default: null },
    rejectionReason: { type: String, default: null, trim: true },
    remarks: { type: String, default: null, trim: true },
    metadata: { type: Schema.Types.Mixed, default: null },
    auditHistory: { type: [TransferCreditAuditEntrySchema], default: [] },
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
        ret.userId = ret.userId?.toString();
        if (ret.originCollegeId) ret.originCollegeId = ret.originCollegeId.toString();
        if (ret.approvedBy) ret.approvedBy = ret.approvedBy.toString();
        delete ret.__v;
        return ret;
      },
    },
    toObject: {
      virtuals: true,
      transform: (_: unknown, ret: Record<string, any>) => {
        ret.id = ret._id?.toString();
        ret.collegeId = ret.collegeId?.toString();
        ret.studentId = ret.studentId?.toString();
        ret.studentEnrollmentId = ret.studentEnrollmentId?.toString();
        ret.userId = ret.userId?.toString();
        if (ret.originCollegeId) ret.originCollegeId = ret.originCollegeId.toString();
        if (ret.approvedBy) ret.approvedBy = ret.approvedBy.toString();
        delete ret.__v;
        return ret;
      },
    },
  }
);

// Prevent cross-tenant destination collision: transfer credit record must uniquely associate student to qualification record
TransferCreditSchema.index({ collegeId: 1, studentId: 1, originInstitutionName: 1 });
TransferCreditSchema.index({ collegeId: 1, verificationStatus: 1 });
TransferCreditSchema.index({ userId: 1, collegeId: 1 });

export const TransferCredit = mongoose.model<ITransferCredit>(
  'TransferCredit',
  TransferCreditSchema
);
