import mongoose, { Document, Schema } from 'mongoose';
import { AttendanceStatus } from '../constants/status';

export interface IAttendanceRecord extends Document {
  collegeId: mongoose.Types.ObjectId;
  departmentId?: mongoose.Types.ObjectId;
  sessionId: mongoose.Types.ObjectId;
  studentId: mongoose.Types.ObjectId;
  studentName: string;
  rollNumber: string;
  sectionId: mongoose.Types.ObjectId;
  subjectId: mongoose.Types.ObjectId;
  courseId?: mongoose.Types.ObjectId;
  academicYearId?: mongoose.Types.ObjectId;
  semesterId?: mongoose.Types.ObjectId;
  facultyId: mongoose.Types.ObjectId;
  date: Date;
  timeSlot: string;
  status: AttendanceStatus;
  oldStatus?: AttendanceStatus;
  lastModified?: Date;
  modifiedBy?: string;
  remarks?: string;
  isCancelled: boolean;
  createdAt: Date;
  updatedAt: Date;
}

const AttendanceRecordSchema = new Schema<IAttendanceRecord>(
  {
    collegeId: { type: Schema.Types.ObjectId, ref: 'College', required: true, index: true },
    departmentId: { type: Schema.Types.ObjectId, ref: 'Department', default: null, index: true },
    sessionId: { type: Schema.Types.ObjectId, ref: 'AttendanceSession', required: true, index: true },
    studentId: { type: Schema.Types.ObjectId, ref: 'Student', required: true, index: true },
    studentName: { type: String, required: true },
    rollNumber: { type: String, required: true },
    sectionId: { type: Schema.Types.ObjectId, ref: 'Section', required: true, index: true },
    subjectId: { type: Schema.Types.ObjectId, ref: 'Subject', required: true, index: true },
    courseId: { type: Schema.Types.ObjectId, ref: 'Course', default: null, index: true },
    academicYearId: { type: Schema.Types.ObjectId, ref: 'AcademicYear', default: null, index: true },
    semesterId: { type: Schema.Types.ObjectId, ref: 'Semester', default: null, index: true },
    facultyId: { type: Schema.Types.ObjectId, ref: 'Faculty', required: true, index: true },
    date: { type: Date, required: true, index: true },
    timeSlot: { type: String, required: true },
    status: {
      type: String,
      enum: Object.values(AttendanceStatus),
      required: true,
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
    isCancelled: { type: Boolean, default: false },
  },
  {
    timestamps: true,
    toJSON: {
      virtuals: true,
      transform: (_: unknown, ret: Record<string, any>) => {
        ret.id = ret._id?.toString();
        ret.collegeId = ret.collegeId?.toString();
        if (ret.departmentId) ret.departmentId = ret.departmentId.toString();
        ret.sessionId = ret.sessionId?.toString();
        ret.studentId = ret.studentId?.toString();
        ret.sectionId = ret.sectionId?.toString();
        ret.subjectId = ret.subjectId?.toString();
        if (ret.courseId) ret.courseId = ret.courseId.toString();
        if (ret.academicYearId) ret.academicYearId = ret.academicYearId.toString();
        if (ret.semesterId) ret.semesterId = ret.semesterId.toString();
        ret.facultyId = ret.facultyId?.toString();
        delete ret.__v;
        return ret;
      },
    },
  }
);

AttendanceRecordSchema.index(
  { sessionId: 1, studentId: 1 },
  { unique: true }
);
AttendanceRecordSchema.index({ collegeId: 1, studentId: 1, date: 1 });
AttendanceRecordSchema.index({ collegeId: 1, sectionId: 1, subjectId: 1, date: 1 });
AttendanceRecordSchema.index({ collegeId: 1, studentId: 1, subjectId: 1 });
AttendanceRecordSchema.index({ collegeId: 1, departmentId: 1, date: 1 });
AttendanceRecordSchema.index({ collegeId: 1, departmentId: 1, studentId: 1 });
AttendanceRecordSchema.index({ collegeId: 1, departmentId: 1, sectionId: 1, subjectId: 1 });

export const AttendanceRecord = mongoose.model<IAttendanceRecord>(
  'AttendanceRecord',
  AttendanceRecordSchema
);
