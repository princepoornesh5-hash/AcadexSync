import mongoose, { Document, Schema } from 'mongoose';
import { AttendanceStatus, AttendanceSessionStatus } from '../constants/status';

export interface IAttendanceRecordItem {
  _id?: mongoose.Types.ObjectId;
  studentId: mongoose.Types.ObjectId;
  studentName: string;
  rollNumber: string;
  sectionId: mongoose.Types.ObjectId;
  status: AttendanceStatus;
  oldStatus?: AttendanceStatus;
  lastModified?: Date;
  modifiedBy?: string;
  remarks?: string;
}

export interface IAttendanceSession extends Document {
  collegeId: mongoose.Types.ObjectId;
  departmentId: mongoose.Types.ObjectId;
  courseId?: mongoose.Types.ObjectId;
  academicYearId?: mongoose.Types.ObjectId;
  semesterId?: mongoose.Types.ObjectId;
  facultyId: mongoose.Types.ObjectId;
  subjectId: mongoose.Types.ObjectId;
  subjectName: string;
  sectionId: mongoose.Types.ObjectId;
  sectionName: string;
  timeSlot: string;
  date: Date;
  records: IAttendanceRecordItem[];
  timetableId?: mongoose.Types.ObjectId;
  timetableEntryId?: string;
  facultyAssignmentId?: mongoose.Types.ObjectId;
  roomNumber?: string;
  building?: string;
  status: AttendanceSessionStatus;
  isSubmitted: boolean;
  isLocked: boolean;
  createdBy?: string;
  lastModifiedBy?: string;
  version: number;
  createdAt: Date;
  updatedAt: Date;
}

const AttendanceRecordItemSchema = new Schema<IAttendanceRecordItem>(
  {
    studentId: { type: Schema.Types.ObjectId, ref: 'Student', required: true },
    studentName: { type: String, required: true },
    rollNumber: { type: String, required: true },
    sectionId: { type: Schema.Types.ObjectId, ref: 'Section', required: true },
    status: {
      type: String,
      enum: Object.values(AttendanceStatus),
      default: AttendanceStatus.PRESENT,
    },
    oldStatus: {
      type: String,
      enum: Object.values(AttendanceStatus),
      default: null,
    },
    lastModified: { type: Date, default: null },
    modifiedBy: { type: String, default: null },
    remarks: { type: String, default: null },
  },
  { _id: true }
);

const AttendanceSessionSchema = new Schema<IAttendanceSession>(
  {
    collegeId: { type: Schema.Types.ObjectId, ref: 'College', required: true, index: true },
    departmentId: { type: Schema.Types.ObjectId, ref: 'Department', required: true, index: true },
    courseId: { type: Schema.Types.ObjectId, ref: 'Course', default: null, index: true },
    academicYearId: { type: Schema.Types.ObjectId, ref: 'AcademicYear', default: null, index: true },
    semesterId: { type: Schema.Types.ObjectId, ref: 'Semester', default: null, index: true },
    facultyId: { type: Schema.Types.ObjectId, ref: 'Faculty', required: true, index: true },
    subjectId: { type: Schema.Types.ObjectId, ref: 'Subject', required: true, index: true },
    subjectName: { type: String, required: true },
    sectionId: { type: Schema.Types.ObjectId, ref: 'Section', required: true, index: true },
    sectionName: { type: String, required: true },
    timeSlot: { type: String, required: true },
    date: { type: Date, required: true, index: true },
    records: [AttendanceRecordItemSchema],
    timetableId: { type: Schema.Types.ObjectId, ref: 'Timetable', default: null, index: true },
    timetableEntryId: { type: String, default: null },
    facultyAssignmentId: { type: Schema.Types.ObjectId, ref: 'FacultyAssignment', default: null, index: true },
    roomNumber: { type: String, default: null },
    building: { type: String, default: null },
    status: {
      type: String,
      enum: Object.values(AttendanceSessionStatus),
      default: AttendanceSessionStatus.OPEN,
      index: true,
    },
    isSubmitted: { type: Boolean, default: false },
    isLocked: { type: Boolean, default: false },
    createdBy: { type: String, default: null },
    lastModifiedBy: { type: String, default: null },
    version: { type: Number, default: 1 },
  },
  {
    timestamps: true,
    toJSON: {
      virtuals: true,
      transform: (_: unknown, ret: Record<string, any>) => {
        ret.id = ret._id?.toString();
        ret.collegeId = ret.collegeId?.toString();
        ret.departmentId = ret.departmentId?.toString();
        if (ret.courseId) ret.courseId = ret.courseId.toString();
        if (ret.academicYearId) ret.academicYearId = ret.academicYearId.toString();
        if (ret.semesterId) ret.semesterId = ret.semesterId.toString();
        ret.facultyId = ret.facultyId?.toString();
        ret.subjectId = ret.subjectId?.toString();
        ret.sectionId = ret.sectionId?.toString();
        if (ret.timetableId) ret.timetableId = ret.timetableId.toString();
        if (ret.facultyAssignmentId) ret.facultyAssignmentId = ret.facultyAssignmentId.toString();
        delete ret.__v;
        return ret;
      },
    },
  }
);

AttendanceSessionSchema.index(
  { collegeId: 1, sectionId: 1, subjectId: 1, date: 1, timeSlot: 1 },
  { unique: true }
);
AttendanceSessionSchema.index({ collegeId: 1, facultyId: 1, date: 1 });
AttendanceSessionSchema.index({ collegeId: 1, date: 1 });
AttendanceSessionSchema.index({ collegeId: 1, status: 1 });
AttendanceSessionSchema.index({ 'records.studentId': 1 });

export const AttendanceSession = mongoose.model<IAttendanceSession>(
  'AttendanceSession',
  AttendanceSessionSchema
);
