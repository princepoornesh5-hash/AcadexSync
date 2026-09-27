import mongoose, { Document, Schema } from 'mongoose';
import { FacultyReviewStatus, StudentTaskStatus } from '../constants/assignment.constants';

export interface IAssignmentSubmission extends Document {
  collegeId: mongoose.Types.ObjectId;
  assignmentId: mongoose.Types.ObjectId;
  studentId: mongoose.Types.ObjectId;
  studentUserId: mongoose.Types.ObjectId;
  studentName: string;
  rollNumber?: string;
  status: StudentTaskStatus;
  completedAt?: Date | null;
  isLate: boolean;
  reviewStatus: FacultyReviewStatus;
  marks?: number | null;
  reviewedAt?: Date | null;
  reviewedBy?: mongoose.Types.ObjectId | null;
  feedback?: string;
  createdAt: Date;
  updatedAt: Date;
}

const AssignmentSubmissionSchema = new Schema<IAssignmentSubmission>(
  {
    collegeId: { type: Schema.Types.ObjectId, ref: 'College', required: true, index: true },
    assignmentId: { type: Schema.Types.ObjectId, ref: 'Assignment', required: true, index: true },
    studentId: { type: Schema.Types.ObjectId, ref: 'Student', required: true, index: true },
    studentUserId: { type: Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    studentName: { type: String, required: true, trim: true },
    rollNumber: { type: String, default: null, trim: true },
    status: {
      type: String,
      enum: Object.values(StudentTaskStatus),
      default: StudentTaskStatus.PENDING,
      index: true,
    },
    completedAt: { type: Date, default: null },
    isLate: { type: Boolean, default: false },
    reviewStatus: {
      type: String,
      enum: Object.values(FacultyReviewStatus),
      default: FacultyReviewStatus.NOT_REVIEWED,
      index: true,
    },
    marks: { type: Number, default: null, min: 0 },
    reviewedAt: { type: Date, default: null },
    reviewedBy: { type: Schema.Types.ObjectId, ref: 'User', default: null },
    feedback: { type: String, default: null },
  },
  {
    timestamps: true,
    toJSON: {
      virtuals: true,
      transform: (_: unknown, ret: Record<string, any>) => {
        ret.id = ret._id?.toString();
        ret.submissionId = ret._id?.toString();
        ret.collegeId = ret.collegeId?.toString();
        ret.assignmentId = ret.assignmentId?.toString();
        ret.studentId = ret.studentId?.toString();
        ret.studentUserId = ret.studentUserId?.toString();
        if (ret.reviewedBy) ret.reviewedBy = ret.reviewedBy.toString();
        delete ret.__v;
        return ret;
      },
    },
  }
);

AssignmentSubmissionSchema.index({ assignmentId: 1, studentId: 1 }, { unique: true });
AssignmentSubmissionSchema.index({ assignmentId: 1, status: 1 });
AssignmentSubmissionSchema.index({ collegeId: 1, studentUserId: 1, status: 1 });

export const AssignmentSubmission = mongoose.model<IAssignmentSubmission>(
  'AssignmentSubmission',
  AssignmentSubmissionSchema
);
