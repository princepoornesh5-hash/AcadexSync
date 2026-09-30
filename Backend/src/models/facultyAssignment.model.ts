import mongoose, { Document, Schema } from 'mongoose';

export interface IFacultyAssignment extends Document {
  collegeId: mongoose.Types.ObjectId;
  departmentId: mongoose.Types.ObjectId;
  facultyId: mongoose.Types.ObjectId;
  facultyName: string;
  courseId: mongoose.Types.ObjectId;
  semesterId: mongoose.Types.ObjectId;
  sectionId?: mongoose.Types.ObjectId | null;
  subjectId: mongoose.Types.ObjectId;
  academicYearId: mongoose.Types.ObjectId;
  cohort?: string;
  academicStage?: string;
  roomId?: string;
  maxStudents?: number;
  assignmentType?: string;
  assignedBy?: string;
  status: 'active' | 'inactive' | 'ended' | 'archived';
  isActive: boolean;
  assignedAt: Date;
  endedAt?: Date | null;
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
    sectionId: { type: Schema.Types.ObjectId, ref: 'Section', required: false, default: null, index: true },
    subjectId: { type: Schema.Types.ObjectId, ref: 'Subject', required: true, index: true },
    academicYearId: { type: Schema.Types.ObjectId, ref: 'AcademicYear', required: true },
    cohort: { type: String, default: null, trim: true },
    academicStage: { type: String, default: null, trim: true },
    roomId: { type: String, default: null },
    maxStudents: { type: Number, default: null },
    assignmentType: { type: String, default: 'lecture' },
    assignedBy: { type: String, default: null },
    status: {
      type: String,
      enum: ['active', 'inactive', 'ended', 'archived'],
      default: 'active',
      index: true,
    },
    isActive: { type: Boolean, default: true, index: true },
    assignedAt: { type: Date, default: Date.now },
    endedAt: { type: Date, default: null },
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

// Bidirectional synchronization between status and isActive
FacultyAssignmentSchema.pre('save', function (next) {
  if (this.isModified('status')) {
    this.isActive = this.status === 'active';
  } else if (this.isModified('isActive')) {
    this.status = this.isActive ? 'active' : 'inactive';
  }
  next();
});

// Authoritative uniqueness index: prevents duplicate active assignments while preserving historical records
FacultyAssignmentSchema.index(
  { collegeId: 1, facultyId: 1, subjectId: 1, academicYearId: 1, semesterId: 1, sectionId: 1 },
  { unique: true, partialFilterExpression: { status: 'active' } }
);

FacultyAssignmentSchema.index({ collegeId: 1, facultyId: 1, status: 1 });
FacultyAssignmentSchema.index({ collegeId: 1, sectionId: 1, status: 1 });
FacultyAssignmentSchema.index({ collegeId: 1, departmentId: 1, status: 1 });
FacultyAssignmentSchema.index({ collegeId: 1, subjectId: 1, status: 1 });
FacultyAssignmentSchema.index({ collegeId: 1, semesterId: 1 });
FacultyAssignmentSchema.index({ collegeId: 1, academicYearId: 1 });

export const FacultyAssignment = mongoose.model<IFacultyAssignment>(
  'FacultyAssignment',
  FacultyAssignmentSchema
);
