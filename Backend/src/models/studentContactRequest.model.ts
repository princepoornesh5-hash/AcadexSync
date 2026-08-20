import mongoose, { Document, Schema } from 'mongoose';

export type ContactRequestStatus = 'PENDING' | 'APPROVED' | 'REJECTED' | 'CANCELLED';

export interface IStudentContactRequest extends Document {
  collegeId: mongoose.Types.ObjectId;
  departmentId: mongoose.Types.ObjectId;
  studentUserId: mongoose.Types.ObjectId;
  studentProfileId?: mongoose.Types.ObjectId;
  studentName: string;
  studentInstituteId: string;
  currentPhone?: string;
  requestedPhone: string;
  status: ContactRequestStatus;
  resolvedBy?: mongoose.Types.ObjectId;
  resolvedByName?: string;
  resolvedAt?: Date;
  rejectionReason?: string;
  notes?: string;
  createdAt: Date;
  updatedAt: Date;
}

const StudentContactRequestSchema = new Schema<IStudentContactRequest>(
  {
    collegeId: { type: Schema.Types.ObjectId, ref: 'College', required: true, index: true },
    departmentId: { type: Schema.Types.ObjectId, ref: 'Department', required: true, index: true },
    studentUserId: { type: Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    studentProfileId: { type: Schema.Types.ObjectId, ref: 'Student', default: null },
    studentName: { type: String, required: true, trim: true },
    studentInstituteId: { type: String, required: true, trim: true, uppercase: true },
    currentPhone: { type: String, default: null, trim: true },
    requestedPhone: { type: String, required: true, trim: true },
    status: {
      type: String,
      enum: ['PENDING', 'APPROVED', 'REJECTED', 'CANCELLED'],
      default: 'PENDING',
      index: true,
    },
    resolvedBy: { type: Schema.Types.ObjectId, ref: 'User', default: null },
    resolvedByName: { type: String, default: null },
    resolvedAt: { type: Date, default: null },
    rejectionReason: { type: String, default: null },
    notes: { type: String, default: null },
  },
  {
    timestamps: true,
    toJSON: {
      virtuals: true,
      transform: (_: unknown, ret: Record<string, any>) => {
        ret.id = ret._id?.toString();
        ret.collegeId = ret.collegeId?.toString();
        ret.departmentId = ret.departmentId?.toString();
        ret.studentUserId = ret.studentUserId?.toString();
        if (ret.studentProfileId) ret.studentProfileId = ret.studentProfileId.toString();
        if (ret.resolvedBy) ret.resolvedBy = ret.resolvedBy.toString();
        delete ret.__v;
        return ret;
      },
    },
  }
);

StudentContactRequestSchema.index({ collegeId: 1, departmentId: 1, status: 1 });
StudentContactRequestSchema.index({ studentUserId: 1, status: 1 });

export const StudentContactRequest = mongoose.model<IStudentContactRequest>(
  'StudentContactRequest',
  StudentContactRequestSchema
);
