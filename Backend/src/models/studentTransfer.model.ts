import mongoose, { Document, Schema } from 'mongoose';

export interface IStudentTransfer extends Document {
  userId: mongoose.Types.ObjectId;
  sourceCollegeId: mongoose.Types.ObjectId;
  sourceStudentId: mongoose.Types.ObjectId;
  sourceMembershipId?: mongoose.Types.ObjectId | null;
  sourcePin: string;
  destinationCollegeId: mongoose.Types.ObjectId;
  destinationStudentId?: mongoose.Types.ObjectId | null;
  destinationMembershipId?: mongoose.Types.ObjectId | null;
  destinationPin: string;
  destinationDepartmentId: mongoose.Types.ObjectId;
  destinationCourseId?: mongoose.Types.ObjectId | null;
  destinationSemesterId?: mongoose.Types.ObjectId | null;
  destinationAcademicYearId?: mongoose.Types.ObjectId | null;
  status: 'REQUESTED' | 'APPROVED' | 'COMPLETED' | 'REJECTED' | 'FAILED';
  transferDate: Date;
  effectiveDate: Date;
  reason?: string | null;
  approvedBy?: mongoose.Types.ObjectId | null;
  approvedAt?: Date | null;
  rejectionReason?: string | null;
  evidenceDocuments?: Array<{ title: string; url: string }> | null;
  createdAt: Date;
  updatedAt: Date;
}

const StudentTransferSchema = new Schema<IStudentTransfer>(
  {
    userId: { type: Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    sourceCollegeId: { type: Schema.Types.ObjectId, ref: 'College', required: true, index: true },
    sourceStudentId: { type: Schema.Types.ObjectId, ref: 'Student', required: true, index: true },
    sourceMembershipId: { type: Schema.Types.ObjectId, ref: 'WorkspaceMembership', default: null, index: true },
    sourcePin: { type: String, required: true, trim: true },
    destinationCollegeId: { type: Schema.Types.ObjectId, ref: 'College', required: true, index: true },
    destinationStudentId: { type: Schema.Types.ObjectId, ref: 'Student', default: null, index: true },
    destinationMembershipId: { type: Schema.Types.ObjectId, ref: 'WorkspaceMembership', default: null, index: true },
    destinationPin: { type: String, required: true, trim: true },
    destinationDepartmentId: { type: Schema.Types.ObjectId, ref: 'Department', required: true, index: true },
    destinationCourseId: { type: Schema.Types.ObjectId, ref: 'Course', default: null },
    destinationSemesterId: { type: Schema.Types.ObjectId, ref: 'Semester', default: null },
    destinationAcademicYearId: { type: Schema.Types.ObjectId, ref: 'AcademicYear', default: null },
    status: {
      type: String,
      enum: ['REQUESTED', 'APPROVED', 'COMPLETED', 'REJECTED', 'FAILED'],
      default: 'COMPLETED',
      required: true,
      index: true,
    },
    transferDate: { type: Date, default: Date.now },
    effectiveDate: { type: Date, default: Date.now },
    reason: { type: String, default: null, trim: true },
    approvedBy: { type: Schema.Types.ObjectId, ref: 'User', default: null },
    approvedAt: { type: Date, default: null },
    rejectionReason: { type: String, default: null, trim: true },
    evidenceDocuments: {
      type: [
        {
          title: { type: String, required: true },
          url: { type: String, required: true },
        },
      ],
      default: [],
    },
  },
  {
    timestamps: true,
    toJSON: {
      virtuals: true,
      transform: (_: unknown, ret: Record<string, any>) => {
        ret.id = ret._id?.toString();
        ret.userId = ret.userId?.toString();
        ret.sourceCollegeId = ret.sourceCollegeId?.toString();
        ret.sourceStudentId = ret.sourceStudentId?.toString();
        ret.destinationCollegeId = ret.destinationCollegeId?.toString();
        ret.destinationStudentId = ret.destinationStudentId?.toString();
        delete ret.__v;
        return ret;
      },
    },
  }
);

StudentTransferSchema.index({ sourceCollegeId: 1, transferDate: -1 });
StudentTransferSchema.index({ destinationCollegeId: 1, transferDate: -1 });
StudentTransferSchema.index({ userId: 1, transferDate: -1 });

export const StudentTransfer = mongoose.model<IStudentTransfer>(
  'StudentTransfer',
  StudentTransferSchema
);
