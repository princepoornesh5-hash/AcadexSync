import mongoose, { Document, Schema } from 'mongoose';
import { AppRole } from '../constants/roles';
import { RequestStatus, RequestType } from '../constants/request.constants';

export interface IAcademicContext {
  courseId?: mongoose.Types.ObjectId | string;
  academicYearId?: mongoose.Types.ObjectId | string;
  semesterId?: mongoose.Types.ObjectId | string;
  sectionId?: mongoose.Types.ObjectId | string;
  subjectId?: mongoose.Types.ObjectId | string;
  facultyAssignmentId?: mongoose.Types.ObjectId | string;
  courseName?: string;
  sectionName?: string;
  subjectName?: string;
}

export interface IRequestDetails {
  startDate?: Date;
  endDate?: Date;
  date?: Date;
  resourceName?: string;
  requestedChange?: string;
  documentType?: string;
  reason?: string;
  metadata?: Record<string, unknown>;
}

export interface IRequestAuditEntry {
  status: RequestStatus;
  changedBy?: mongoose.Types.ObjectId | string;
  changedByName?: string;
  note?: string;
  timestamp: Date;
}

export interface IRequest extends Document {
  requestId: string;
  collegeId: mongoose.Types.ObjectId;
  departmentId?: mongoose.Types.ObjectId;
  requesterUserId: mongoose.Types.ObjectId | string;
  requesterName: string;
  requesterRole: AppRole;
  targetRole: AppRole;
  targetUserId?: mongoose.Types.ObjectId | string;
  targetName?: string;
  requestType: RequestType;
  title: string;
  description: string;
  academicContext?: IAcademicContext;
  details?: IRequestDetails;
  status: RequestStatus;
  respondedAt?: Date;
  respondedBy?: mongoose.Types.ObjectId | string;
  respondedByName?: string;
  responseMessage?: string;
  history: IRequestAuditEntry[];
  createdAt: Date;
  updatedAt: Date;
}

const AcademicContextSchema = new Schema(
  {
    courseId: { type: Schema.Types.ObjectId, ref: 'Course', default: null },
    academicYearId: { type: Schema.Types.ObjectId, ref: 'AcademicYear', default: null },
    semesterId: { type: Schema.Types.ObjectId, ref: 'Semester', default: null },
    sectionId: { type: Schema.Types.ObjectId, ref: 'Section', default: null },
    subjectId: { type: Schema.Types.ObjectId, ref: 'Subject', default: null },
    facultyAssignmentId: { type: Schema.Types.ObjectId, ref: 'FacultyAssignment', default: null },
    courseName: { type: String, default: null },
    sectionName: { type: String, default: null },
    subjectName: { type: String, default: null },
  },
  { _id: false }
);

const RequestDetailsSchema = new Schema(
  {
    startDate: { type: Date, default: null },
    endDate: { type: Date, default: null },
    date: { type: Date, default: null },
    resourceName: { type: String, default: null },
    requestedChange: { type: String, default: null },
    documentType: { type: String, default: null },
    reason: { type: String, default: null },
    metadata: { type: Schema.Types.Mixed, default: null },
  },
  { _id: false }
);

const RequestAuditEntrySchema = new Schema(
  {
    status: { type: String, enum: Object.values(RequestStatus), required: true },
    changedBy: { type: Schema.Types.Mixed, default: null },
    changedByName: { type: String, default: null },
    note: { type: String, default: null },
    timestamp: { type: Date, default: Date.now },
  },
  { _id: false }
);

const RequestSchema = new Schema<IRequest>(
  {
    requestId: { type: String, required: true, unique: true, index: true },
    collegeId: { type: Schema.Types.ObjectId, ref: 'College', required: true, index: true },
    departmentId: { type: Schema.Types.ObjectId, ref: 'Department', default: null, index: true },
    requesterUserId: { type: Schema.Types.Mixed, required: true, index: true },
    requesterName: { type: String, required: true, trim: true },
    requesterRole: {
      type: String,
      enum: Object.values(AppRole),
      required: true,
      index: true,
    },
    targetRole: {
      type: String,
      enum: Object.values(AppRole),
      required: true,
      index: true,
    },
    targetUserId: { type: Schema.Types.Mixed, default: null, index: true },
    targetName: { type: String, default: null },
    requestType: { type: String, required: true, index: true },
    title: { type: String, required: true, trim: true },
    description: { type: String, required: true, trim: true },
    academicContext: { type: AcademicContextSchema, default: null },
    details: { type: RequestDetailsSchema, default: null },
    status: {
      type: String,
      enum: Object.values(RequestStatus),
      default: RequestStatus.SUBMITTED,
      index: true,
    },
    respondedAt: { type: Date, default: null },
    respondedBy: { type: Schema.Types.Mixed, default: null },
    respondedByName: { type: String, default: null },
    responseMessage: { type: String, default: null },
    history: { type: [RequestAuditEntrySchema], default: [] },
  },
  {
    timestamps: true,
    toJSON: {
      virtuals: true,
      transform: (_: unknown, ret: Record<string, any>) => {
        ret.id = ret._id?.toString();
        ret.collegeId = ret.collegeId?.toString();
        if (ret.departmentId) ret.departmentId = ret.departmentId.toString();
        if (ret.requesterUserId) ret.requesterUserId = ret.requesterUserId.toString();
        if (ret.targetUserId) ret.targetUserId = ret.targetUserId.toString();
        if (ret.respondedBy) ret.respondedBy = ret.respondedBy.toString();
        if (ret.academicContext) {
          if (ret.academicContext.courseId) ret.academicContext.courseId = ret.academicContext.courseId.toString();
          if (ret.academicContext.academicYearId) ret.academicContext.academicYearId = ret.academicContext.academicYearId.toString();
          if (ret.academicContext.semesterId) ret.academicContext.semesterId = ret.academicContext.semesterId.toString();
          if (ret.academicContext.sectionId) ret.academicContext.sectionId = ret.academicContext.sectionId.toString();
          if (ret.academicContext.subjectId) ret.academicContext.subjectId = ret.academicContext.subjectId.toString();
          if (ret.academicContext.facultyAssignmentId) ret.academicContext.facultyAssignmentId = ret.academicContext.facultyAssignmentId.toString();
        }
        if (Array.isArray(ret.history)) {
          ret.history = ret.history.map((h: any) => ({
            ...h,
            changedBy: h.changedBy?.toString(),
          }));
        }
        delete ret.__v;
        return ret;
      },
    },
  }
);

// Compound indexes for high-performance multi-tenant querying
RequestSchema.index({ collegeId: 1, requesterUserId: 1, status: 1 });
RequestSchema.index({ collegeId: 1, targetRole: 1, departmentId: 1, status: 1 });
RequestSchema.index({ collegeId: 1, targetUserId: 1, status: 1 });
RequestSchema.index({ collegeId: 1, createdAt: -1 });

export const RequestModel = mongoose.model<IRequest>('Request', RequestSchema);
