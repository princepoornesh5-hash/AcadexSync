import mongoose, { Document, Schema } from 'mongoose';
import { PracticalSessionStatus } from '../constants/practical.constants';

export interface IPracticalSession extends Document {
  collegeId: mongoose.Types.ObjectId;
  departmentId: mongoose.Types.ObjectId;
  courseId: mongoose.Types.ObjectId;
  academicYearId: mongoose.Types.ObjectId;
  semesterId: mongoose.Types.ObjectId;
  sectionId?: mongoose.Types.ObjectId | null;
  subjectId: mongoose.Types.ObjectId;
  practicalDefinitionId?: mongoose.Types.ObjectId | null;
  facultyAssignmentId: mongoose.Types.ObjectId;
  facultyId: mongoose.Types.ObjectId;
  timetableEntryId?: string | null;
  roomId?: mongoose.Types.ObjectId | null;
  roomNumber?: string | null;
  building?: string | null;
  sessionNumber: number;
  topic: string;
  instructions?: string | null;
  scheduledDate: Date;
  startTime?: string | null;
  endTime?: string | null;
  actualDate?: Date | null;
  status: PracticalSessionStatus;
  totalEnrolled: number;
  completedCount: number;
  inProgressCount: number;
  absentCount: number;
  attendanceSessionId?: mongoose.Types.ObjectId | null;
  createdBy?: mongoose.Types.ObjectId | null;
  updatedBy?: mongoose.Types.ObjectId | null;
  createdAt: Date;
  updatedAt: Date;
}

const PracticalSessionSchema = new Schema<IPracticalSession>(
  {
    collegeId: { type: Schema.Types.ObjectId, ref: 'College', required: true, index: true },
    departmentId: { type: Schema.Types.ObjectId, ref: 'Department', required: true, index: true },
    courseId: { type: Schema.Types.ObjectId, ref: 'Course', required: true },
    academicYearId: { type: Schema.Types.ObjectId, ref: 'AcademicYear', required: true },
    semesterId: { type: Schema.Types.ObjectId, ref: 'Semester', required: true },
    sectionId: { type: Schema.Types.ObjectId, ref: 'Section', default: null, index: true },
    subjectId: { type: Schema.Types.ObjectId, ref: 'Subject', required: true, index: true },
    practicalDefinitionId: { type: Schema.Types.ObjectId, ref: 'PracticalDefinition', default: null },
    facultyAssignmentId: { type: Schema.Types.ObjectId, ref: 'FacultyAssignment', required: true, index: true },
    facultyId: { type: Schema.Types.ObjectId, ref: 'Faculty', required: true, index: true },
    timetableEntryId: { type: String, default: null },
    roomId: { type: Schema.Types.ObjectId, ref: 'Room', default: null },
    roomNumber: { type: String, default: null },
    building: { type: String, default: null },
    sessionNumber: { type: Number, default: 1, min: 1 },
    topic: { type: String, required: true, trim: true },
    instructions: { type: String, default: null },
    scheduledDate: { type: Date, required: true, index: true },
    startTime: { type: String, default: null },
    endTime: { type: String, default: null },
    actualDate: { type: Date, default: null },
    status: {
      type: String,
      enum: Object.values(PracticalSessionStatus),
      default: PracticalSessionStatus.PLANNED,
      index: true,
    },
    totalEnrolled: { type: Number, default: 0, min: 0 },
    completedCount: { type: Number, default: 0, min: 0 },
    inProgressCount: { type: Number, default: 0, min: 0 },
    absentCount: { type: Number, default: 0, min: 0 },
    attendanceSessionId: { type: Schema.Types.ObjectId, ref: 'AttendanceSession', default: null },
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
        ret.departmentId = ret.departmentId?.toString();
        ret.courseId = ret.courseId?.toString();
        ret.academicYearId = ret.academicYearId?.toString();
        ret.semesterId = ret.semesterId?.toString();
        if (ret.sectionId) ret.sectionId = ret.sectionId.toString();
        ret.subjectId = ret.subjectId?.toString();
        if (ret.practicalDefinitionId) ret.practicalDefinitionId = ret.practicalDefinitionId.toString();
        ret.facultyAssignmentId = ret.facultyAssignmentId?.toString();
        ret.facultyId = ret.facultyId?.toString();
        if (ret.roomId) ret.roomId = ret.roomId.toString();
        if (ret.attendanceSessionId) ret.attendanceSessionId = ret.attendanceSessionId.toString();
        if (ret.createdBy) ret.createdBy = ret.createdBy.toString();
        if (ret.updatedBy) ret.updatedBy = ret.updatedBy.toString();
        delete ret.__v;
        return ret;
      },
    },
  }
);

PracticalSessionSchema.index({ collegeId: 1, facultyAssignmentId: 1, scheduledDate: 1 });
PracticalSessionSchema.index({ collegeId: 1, subjectId: 1, status: 1 });

export const PracticalSession = mongoose.model<IPracticalSession>(
  'PracticalSession',
  PracticalSessionSchema
);
