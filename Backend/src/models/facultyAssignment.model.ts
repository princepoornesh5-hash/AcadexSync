import mongoose, { Document, Schema } from 'mongoose';

export interface IFacultyAssignment extends Document {
  collegeId: mongoose.Types.ObjectId;
  departmentId: mongoose.Types.ObjectId;
  facultyId: mongoose.Types.ObjectId;
  facultyName: string;
  courseId: mongoose.Types.ObjectId;
  semesterId: mongoose.Types.ObjectId;
  sectionId: mongoose.Types.ObjectId;
  subjectId: mongoose.Types.ObjectId;
  academicYearId: mongoose.Types.ObjectId;
  roomId?: string;
  maxStudents?: number;
  assignmentType?: string;
  assignedBy?: string;
  isActive: boolean;
  assignedAt: Date;
  createdAt: Date;
  updatedAt: Date;
}

const FacultyAssignmentSchema = new Schema<IFacultyAssignment>(
  {
    collegeId: { type: Schema.Types.ObjectId, ref: 'College', required: true, index: true },
    departmentId: { type: Schema.Types.ObjectId, ref: 'Department', required: true, index: true },
    facultyId: { type: Schema.Types.ObjectId, ref: 'Faculty', required: true, index: true },
    facultyName: { type: String, required: true, trim: true },
    courseId: { type: Schema.Types.ObjectId, ref: 'Course', required: true },
    semesterId: { type: Schema.Types.ObjectId, ref: 'Semester', required: true },
    sectionId: { type: Schema.Types.ObjectId, ref: 'Section', required: true, index: true },
    subjectId: { type: Schema.Types.ObjectId, ref: 'Subject', required: true, index: true },
    academicYearId: { type: Schema.Types.ObjectId, ref: 'AcademicYear', required: true },
    roomId: { type: String, default: null },
    maxStudents: { type: Number, default: null },
    assignmentType: { type: String, default: 'lecture' },
    assignedBy: { type: String, default: null },
    isActive: { type: Boolean, default: true },
    assignedAt: { type: Date, default: Date.now },
  },
  {
    timestamps: true,
    toJSON: {
      virtuals: true,
      transform: (_: unknown, ret: Record<string, any>) => {
        ret.id = ret._id?.toString();
        ret.collegeId = ret.collegeId?.toString();
        ret.departmentId = ret.departmentId?.toString();
        ret.facultyId = ret.facultyId?.toString();
        ret.courseId = ret.courseId?.toString();
        ret.semesterId = ret.semesterId?.toString();
        ret.sectionId = ret.sectionId?.toString();
        ret.subjectId = ret.subjectId?.toString();
        ret.academicYearId = ret.academicYearId?.toString();
        delete ret.__v;
        return ret;
      },
    },
  }
);

FacultyAssignmentSchema.index(
  { collegeId: 1, facultyId: 1, sectionId: 1, subjectId: 1 },
  { unique: true }
);
FacultyAssignmentSchema.index({ collegeId: 1, sectionId: 1 });
FacultyAssignmentSchema.index({ collegeId: 1, facultyId: 1 });

export const FacultyAssignment = mongoose.model<IFacultyAssignment>(
  'FacultyAssignment',
  FacultyAssignmentSchema
);
