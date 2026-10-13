import mongoose, { Document, Schema } from 'mongoose';

export type AssessmentScheduleStatus = 'SCHEDULED' | 'RESCHEDULED' | 'CANCELLED' | 'COMPLETED';

export interface IAssessmentScheduleDoc extends Document {
  collegeId: mongoose.Types.ObjectId;
  assessmentId: mongoose.Types.ObjectId;
  facultyAssignmentId: mongoose.Types.ObjectId;
  departmentId: mongoose.Types.ObjectId;
  courseId: mongoose.Types.ObjectId;
  academicYearId: mongoose.Types.ObjectId;
  semesterId: mongoose.Types.ObjectId;
  sectionId?: mongoose.Types.ObjectId | null;
  subjectId: mongoose.Types.ObjectId;
  date: Date;
  dateString: string; // YYYY-MM-DD
  startTime: string; // HH:mm
  endTime: string; // HH:mm
  roomId?: mongoose.Types.ObjectId | null;
  roomNumber?: string | null;
  building?: string | null;
  invigilatorFacultyId?: mongoose.Types.ObjectId | null;
  invigilatorName?: string | null;
  instructions?: string | null;
  status: AssessmentScheduleStatus;
  createdBy?: mongoose.Types.ObjectId | null;
  updatedBy?: mongoose.Types.ObjectId | null;
  createdAt: Date;
  updatedAt: Date;
}

const AssessmentScheduleSchema = new Schema<IAssessmentScheduleDoc>(
  {
    collegeId: { type: Schema.Types.ObjectId, ref: 'College', required: true, index: true },
    assessmentId: { type: Schema.Types.ObjectId, ref: 'InternalAssessment', required: true, index: true },
    facultyAssignmentId: { type: Schema.Types.ObjectId, ref: 'FacultyAssignment', required: true, index: true },
    departmentId: { type: Schema.Types.ObjectId, ref: 'Department', required: true, index: true },
    courseId: { type: Schema.Types.ObjectId, ref: 'Course', required: true },
    academicYearId: { type: Schema.Types.ObjectId, ref: 'AcademicYear', required: true },
    semesterId: { type: Schema.Types.ObjectId, ref: 'Semester', required: true },
    sectionId: { type: Schema.Types.ObjectId, ref: 'Section', default: null, index: true },
    subjectId: { type: Schema.Types.ObjectId, ref: 'Subject', required: true, index: true },
    date: { type: Date, required: true, index: true },
    dateString: { type: String, required: true, index: true, trim: true },
    startTime: { type: String, required: true, trim: true },
    endTime: { type: String, required: true, trim: true },
    roomId: { type: Schema.Types.ObjectId, ref: 'Room', default: null, index: true },
    roomNumber: { type: String, default: null, trim: true },
    building: { type: String, default: null, trim: true },
    invigilatorFacultyId: { type: Schema.Types.ObjectId, ref: 'Faculty', default: null, index: true },
    invigilatorName: { type: String, default: null, trim: true },
    instructions: { type: String, default: null, trim: true },
    status: {
      type: String,
      enum: ['SCHEDULED', 'RESCHEDULED', 'CANCELLED', 'COMPLETED'],
      default: 'SCHEDULED',
      index: true,
    },
    createdBy: { type: Schema.Types.ObjectId, ref: 'User', default: null },
    updatedBy: { type: Schema.Types.ObjectId, ref: 'User', default: null },
  },
  {
    timestamps: true,
    toJSON: {
      virtuals: true,
      transform: (_: unknown, ret: Record<string, any>) => {
        ret.id = ret._id?.toString();
        ret.collegeId = ret.collegeId?.toString();
        ret.assessmentId = ret.assessmentId?.toString();
        ret.facultyAssignmentId = ret.facultyAssignmentId?.toString();
        ret.departmentId = ret.departmentId?.toString();
        ret.courseId = ret.courseId?.toString();
        ret.academicYearId = ret.academicYearId?.toString();
        ret.semesterId = ret.semesterId?.toString();
        if (ret.sectionId) ret.sectionId = ret.sectionId.toString();
        ret.subjectId = ret.subjectId?.toString();
        if (ret.roomId) ret.roomId = ret.roomId.toString();
        if (ret.invigilatorFacultyId) ret.invigilatorFacultyId = ret.invigilatorFacultyId.toString();
        if (ret.createdBy) ret.createdBy = ret.createdBy.toString();
        if (ret.updatedBy) ret.updatedBy = ret.updatedBy.toString();
        delete ret.__v;
        return ret;
      },
    },
  }
);

// One active schedule per assessment
AssessmentScheduleSchema.index(
  { collegeId: 1, assessmentId: 1 },
  { unique: true }
);

// Conflict query indices
AssessmentScheduleSchema.index({ collegeId: 1, dateString: 1, roomId: 1, status: 1 });
AssessmentScheduleSchema.index({ collegeId: 1, dateString: 1, sectionId: 1, status: 1 });
AssessmentScheduleSchema.index({ collegeId: 1, dateString: 1, invigilatorFacultyId: 1, status: 1 });
AssessmentScheduleSchema.index({ collegeId: 1, dateString: 1, status: 1 });

export const AssessmentSchedule = mongoose.model<IAssessmentScheduleDoc>(
  'AssessmentSchedule',
  AssessmentScheduleSchema
);
