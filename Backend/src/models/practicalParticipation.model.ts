import mongoose, { Document, Schema } from 'mongoose';
import { PracticalParticipationStatus } from '../constants/practical.constants';

export interface IPracticalParticipation extends Document {
  collegeId: mongoose.Types.ObjectId;
  practicalSessionId: mongoose.Types.ObjectId;
  studentId: mongoose.Types.ObjectId;
  studentEnrollmentId: mongoose.Types.ObjectId;
  status: PracticalParticipationStatus;
  notes?: string | null;
  startedAt?: Date | null;
  completedAt?: Date | null;
  updatedBy?: mongoose.Types.ObjectId | null;
  createdAt: Date;
  updatedAt: Date;
}

const PracticalParticipationSchema = new Schema<IPracticalParticipation>(
  {
    collegeId: { type: Schema.Types.ObjectId, ref: 'College', required: true, index: true },
    practicalSessionId: { type: Schema.Types.ObjectId, ref: 'PracticalSession', required: true, index: true },
    studentId: { type: Schema.Types.ObjectId, ref: 'Student', required: true, index: true },
    studentEnrollmentId: { type: Schema.Types.ObjectId, ref: 'StudentEnrollment', required: true, index: true },
    status: {
      type: String,
      enum: Object.values(PracticalParticipationStatus),
      default: PracticalParticipationStatus.NOT_STARTED,
      index: true,
    },
    notes: { type: String, default: null, trim: true },
    startedAt: { type: Date, default: null },
    completedAt: { type: Date, default: null },
    updatedBy: { type: Schema.Types.ObjectId, ref: 'User', default: null },
  },
  {
    timestamps: true,
    toJSON: {
      virtuals: true,
      transform: (_: unknown, ret: Record<string, any>) => {
        ret.id = ret._id?.toString();
        ret.collegeId = ret.collegeId?.toString();
        ret.practicalSessionId = ret.practicalSessionId?.toString();
        ret.studentId = ret.studentId?.toString();
        ret.studentEnrollmentId = ret.studentEnrollmentId?.toString();
        if (ret.updatedBy) ret.updatedBy = ret.updatedBy.toString();
        delete ret.__v;
        return ret;
      },
    },
  }
);

PracticalParticipationSchema.index(
  { collegeId: 1, practicalSessionId: 1, studentId: 1 },
  { unique: true }
);
PracticalParticipationSchema.index({ collegeId: 1, studentId: 1, status: 1 });

export const PracticalParticipation = mongoose.model<IPracticalParticipation>(
  'PracticalParticipation',
  PracticalParticipationSchema
);
