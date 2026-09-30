import mongoose, { Document, Schema } from 'mongoose';

export enum LabSubmissionStatus {
  PENDING = 'PENDING',
  SUBMITTED = 'SUBMITTED',
  VERIFIED = 'VERIFIED',
  GRADED = 'GRADED',
}

export interface ILabSubmission {
  studentId: mongoose.Types.ObjectId;
  studentName: string;
  rollNumber?: string;
  status: LabSubmissionStatus;
  submissionDate?: Date;
  verifiedAt?: Date;
  verifiedBy?: mongoose.Types.ObjectId;
  observationMarks?: number;
  recordMarks?: number;
  vivaMarks?: number;
  totalMarks?: number;
  remarks?: string;
}

export interface ILabExperiment extends Document {
  collegeId: mongoose.Types.ObjectId;
  departmentId: mongoose.Types.ObjectId;
  courseId: mongoose.Types.ObjectId;
  academicYearId: mongoose.Types.ObjectId;
  semesterId: mongoose.Types.ObjectId;
  sectionId: mongoose.Types.ObjectId;
  subjectId: mongoose.Types.ObjectId;
  facultyAssignmentId?: mongoose.Types.ObjectId;
  facultyId?: mongoose.Types.ObjectId;
  facultyName?: string;
  experimentNumber: number;
  title: string;
  description?: string;
  date: Date;
  maxMarks: {
    observation: number;
    record: number;
    viva: number;
  };
  submissions: ILabSubmission[];
  createdAt: Date;
  updatedAt: Date;
}

const LabSubmissionSchema = new Schema<ILabSubmission>(
  {
    studentId: { type: Schema.Types.ObjectId, ref: 'Student', required: true },
    studentName: { type: String, required: true, trim: true },
    rollNumber: { type: String, default: null, trim: true },
    status: {
      type: String,
      enum: Object.values(LabSubmissionStatus),
      default: LabSubmissionStatus.PENDING,
    },
    submissionDate: { type: Date, default: null },
    verifiedAt: { type: Date, default: null },
    verifiedBy: { type: Schema.Types.ObjectId, ref: 'User', default: null },
    observationMarks: { type: Number, default: 0 },
    recordMarks: { type: Number, default: 0 },
    vivaMarks: { type: Number, default: 0 },
    totalMarks: { type: Number, default: 0 },
    remarks: { type: String, default: null },
  },
  { _id: false }
);

const LabExperimentSchema = new Schema<ILabExperiment>(
  {
    collegeId: { type: Schema.Types.ObjectId, ref: 'College', required: true, index: true },
    departmentId: { type: Schema.Types.ObjectId, ref: 'Department', required: true, index: true },
    courseId: { type: Schema.Types.ObjectId, ref: 'Course', required: true },
    academicYearId: { type: Schema.Types.ObjectId, ref: 'AcademicYear', required: true },
    semesterId: { type: Schema.Types.ObjectId, ref: 'Semester', required: true },
    sectionId: { type: Schema.Types.ObjectId, ref: 'Section', required: true, index: true },
    subjectId: { type: Schema.Types.ObjectId, ref: 'Subject', required: true, index: true },
    facultyAssignmentId: { type: Schema.Types.ObjectId, ref: 'FacultyAssignment', default: null },
    facultyId: { type: Schema.Types.ObjectId, ref: 'Faculty', default: null },
    facultyName: { type: String, default: null },
    experimentNumber: { type: Number, required: true },
    title: { type: String, required: true, trim: true },
    description: { type: String, default: null },
    date: { type: Date, default: Date.now },
    maxMarks: {
      observation: { type: Number, default: 10, min: 0 },
      record: { type: Number, default: 10, min: 0 },
      viva: { type: Number, default: 5, min: 0 },
    },
    submissions: [LabSubmissionSchema],
  },
  {
    timestamps: true,
    toJSON: {
      virtuals: true,
      transform: (_: unknown, ret: Record<string, any>) => {
        ret.id = ret._id?.toString();
        ret.collegeId = ret.collegeId?.toString();
        ret.departmentId = ret.departmentId?.toString();
        ret.courseId = ret.courseId?.toString();
        ret.academicYearId = ret.academicYearId?.toString();
        ret.semesterId = ret.semesterId?.toString();
        ret.sectionId = ret.sectionId?.toString();
        ret.subjectId = ret.subjectId?.toString();
        if (ret.facultyAssignmentId) ret.facultyAssignmentId = ret.facultyAssignmentId.toString();
        if (ret.facultyId) ret.facultyId = ret.facultyId.toString();
        delete ret.__v;
        return ret;
      },
    },
  }
);

LabExperimentSchema.index(
  { collegeId: 1, sectionId: 1, subjectId: 1, experimentNumber: 1 },
  { unique: true }
);

export const LabExperiment = mongoose.model<ILabExperiment>(
  'LabExperiment',
  LabExperimentSchema
);
