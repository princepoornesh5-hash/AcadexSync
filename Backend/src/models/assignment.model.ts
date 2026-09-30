import mongoose, { Document, Schema } from 'mongoose';
import { AssignmentStatus, AssignmentType } from '../constants/assignment.constants';

export interface IAssignmentAttachment {
  name: string;
  url: string;
  fileType?: string;
  fileSize?: number;
}

export interface IAssignment extends Document {
  collegeId: mongoose.Types.ObjectId;
  departmentId: mongoose.Types.ObjectId;
  courseId: mongoose.Types.ObjectId;
  academicYearId: mongoose.Types.ObjectId;
  semesterId: mongoose.Types.ObjectId;
  sectionId?: mongoose.Types.ObjectId | null;
  subjectId: mongoose.Types.ObjectId;
  facultyId: mongoose.Types.ObjectId;
  facultyAssignmentId?: mongoose.Types.ObjectId;
  facultyName: string;
  title: string;
  description: string;
  questions: string[];
  assignmentType: AssignmentType;
  dueDate: string;
  dueTime: string;
  dueDateTime: Date;
  maximumMarks: number;
  attachments: IAssignmentAttachment[];
  status: AssignmentStatus;
  publishedAt?: Date | null;
  closedAt?: Date | null;
  createdAt: Date;
  updatedAt: Date;
}

const AssignmentAttachmentSchema = new Schema(
  {
    name: { type: String, required: true, trim: true },
    url: { type: String, required: true, trim: true },
    fileType: { type: String, default: null },
    fileSize: { type: Number, default: null },
  },
  { _id: false }
);

const AssignmentSchema = new Schema<IAssignment>(
  {
    collegeId: { type: Schema.Types.ObjectId, ref: 'College', required: true, index: true },
    departmentId: { type: Schema.Types.ObjectId, ref: 'Department', required: true, index: true },
    courseId: { type: Schema.Types.ObjectId, ref: 'Course', required: true },
    academicYearId: { type: Schema.Types.ObjectId, ref: 'AcademicYear', required: true },
    semesterId: { type: Schema.Types.ObjectId, ref: 'Semester', required: true, index: true },
    sectionId: { type: Schema.Types.ObjectId, ref: 'Section', required: false, default: null, index: true },
    subjectId: { type: Schema.Types.ObjectId, ref: 'Subject', required: true, index: true },
    facultyId: { type: Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    facultyAssignmentId: { type: Schema.Types.ObjectId, ref: 'FacultyAssignment', default: null, index: true },
    facultyName: { type: String, required: true, trim: true },
    title: { type: String, required: true, trim: true },
    description: { type: String, required: true, trim: true },
    questions: { type: [String], default: [] },
    assignmentType: {
      type: String,
      enum: Object.values(AssignmentType),
      default: AssignmentType.HOMEWORK,
    },
    dueDate: { type: String, required: true },
    dueTime: { type: String, required: true },
    dueDateTime: { type: Date, required: true, index: true },
    maximumMarks: { type: Number, required: true, min: 1 },
    attachments: { type: [AssignmentAttachmentSchema], default: [] },
    status: {
      type: String,
      enum: Object.values(AssignmentStatus),
      default: AssignmentStatus.DRAFT,
      index: true,
    },
    publishedAt: { type: Date, default: null },
    closedAt: { type: Date, default: null },
  },
  {
    timestamps: true,
    toJSON: {
      virtuals: true,
      transform: (_: unknown, ret: Record<string, any>) => {
        ret.id = ret._id?.toString();
        ret.assignmentId = ret._id?.toString();
        ret.collegeId = ret.collegeId?.toString();
        ret.departmentId = ret.departmentId?.toString();
        ret.courseId = ret.courseId?.toString();
        ret.academicYearId = ret.academicYearId?.toString();
        ret.semesterId = ret.semesterId?.toString();
        ret.sectionId = ret.sectionId ? ret.sectionId.toString() : null;
        ret.subjectId = ret.subjectId?.toString();
        ret.facultyId = ret.facultyId?.toString();
        if (ret.facultyAssignmentId) {
          ret.facultyAssignmentId = ret.facultyAssignmentId.toString();
        }
        delete ret.__v;
        return ret;
      },
    },
  }
);

// Indexes for tenant and student/faculty queries
AssignmentSchema.index({ collegeId: 1, semesterId: 1, status: 1, dueDateTime: 1 });
AssignmentSchema.index({ collegeId: 1, sectionId: 1, status: 1, dueDateTime: 1 });
AssignmentSchema.index({ collegeId: 1, facultyId: 1, status: 1 });
AssignmentSchema.index({ collegeId: 1, facultyAssignmentId: 1, status: 1 });

export const Assignment = mongoose.model<IAssignment>('Assignment', AssignmentSchema);
