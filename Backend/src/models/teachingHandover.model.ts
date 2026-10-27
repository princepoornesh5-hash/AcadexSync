import mongoose, { Document, Schema } from 'mongoose';

export interface ITeachingHandover extends Document {
  collegeId: mongoose.Types.ObjectId;
  departmentId: mongoose.Types.ObjectId;
  subjectId: mongoose.Types.ObjectId;
  sectionId?: mongoose.Types.ObjectId | null;
  academicYearId: mongoose.Types.ObjectId;
  semesterId: mongoose.Types.ObjectId;
  courseId: mongoose.Types.ObjectId;
  sourceAssignmentId: mongoose.Types.ObjectId;
  targetAssignmentId: mongoose.Types.ObjectId;
  previousFacultyId: mongoose.Types.ObjectId;
  previousFacultyUserId?: mongoose.Types.ObjectId | null;
  successorFacultyId: mongoose.Types.ObjectId;
  successorFacultyUserId?: mongoose.Types.ObjectId | null;
  status: 'COMPLETED' | 'CANCELLED';
  reassignedPendingWork: boolean;
  reassignedCounts: {
    assignments: number;
    sessions: number;
  };
  handedOverBy: mongoose.Types.ObjectId;
  handedOverAt: Date;
  notes?: string | null;
  createdAt: Date;
  updatedAt: Date;
}

const TeachingHandoverSchema = new Schema<ITeachingHandover>(
  {
    collegeId: { type: Schema.Types.ObjectId, ref: 'College', required: true, index: true },
    departmentId: { type: Schema.Types.ObjectId, ref: 'Department', required: true, index: true },
    subjectId: { type: Schema.Types.ObjectId, ref: 'Subject', required: true, index: true },
    sectionId: { type: Schema.Types.ObjectId, ref: 'Section', default: null, index: true },
    academicYearId: { type: Schema.Types.ObjectId, ref: 'AcademicYear', required: true, index: true },
    semesterId: { type: Schema.Types.ObjectId, ref: 'Semester', required: true, index: true },
    courseId: { type: Schema.Types.ObjectId, ref: 'Course', required: true, index: true },
    sourceAssignmentId: { type: Schema.Types.ObjectId, ref: 'FacultyAssignment', required: true, index: true },
    targetAssignmentId: { type: Schema.Types.ObjectId, ref: 'FacultyAssignment', required: true, index: true },
    previousFacultyId: { type: Schema.Types.ObjectId, ref: 'Faculty', required: true, index: true },
    previousFacultyUserId: { type: Schema.Types.ObjectId, ref: 'User', default: null },
    successorFacultyId: { type: Schema.Types.ObjectId, ref: 'Faculty', required: true, index: true },
    successorFacultyUserId: { type: Schema.Types.ObjectId, ref: 'User', default: null },
    status: {
      type: String,
      enum: ['COMPLETED', 'CANCELLED'],
      default: 'COMPLETED',
      index: true,
    },
    reassignedPendingWork: { type: Boolean, default: false },
    reassignedCounts: {
      assignments: { type: Number, default: 0 },
      sessions: { type: Number, default: 0 },
    },
    handedOverBy: { type: Schema.Types.ObjectId, ref: 'User', required: true },
    handedOverAt: { type: Date, default: Date.now },
    notes: { type: String, default: null, trim: true },
  },
  {
    timestamps: true,
    toJSON: {
      virtuals: true,
      transform: (_: unknown, ret: Record<string, any>) => {
        ret.id = ret._id?.toString();
        ret.collegeId = ret.collegeId?.toString();
        ret.departmentId = ret.departmentId?.toString();
        ret.subjectId = ret.subjectId?.toString();
        ret.sectionId = ret.sectionId?.toString();
        ret.sourceAssignmentId = ret.sourceAssignmentId?.toString();
        ret.targetAssignmentId = ret.targetAssignmentId?.toString();
        ret.previousFacultyId = ret.previousFacultyId?.toString();
        ret.successorFacultyId = ret.successorFacultyId?.toString();
        ret.handedOverBy = ret.handedOverBy?.toString();
        delete ret.__v;
        return ret;
      },
    },
  }
);

TeachingHandoverSchema.index({ collegeId: 1, subjectId: 1, sectionId: 1, handedOverAt: -1 });
TeachingHandoverSchema.index({ collegeId: 1, previousFacultyId: 1 });
TeachingHandoverSchema.index({ collegeId: 1, successorFacultyId: 1 });

export const TeachingHandover = mongoose.model<ITeachingHandover>(
  'TeachingHandover',
  TeachingHandoverSchema
);
