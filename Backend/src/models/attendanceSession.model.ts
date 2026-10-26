import mongoose, { Document, Schema } from 'mongoose';
import { AttendanceStatus, AttendanceSessionStatus } from '../constants/status';
import { normalizeTimeSlot } from '../utils/dateTime';

export interface IAttendanceRecordItem {
  _id?: mongoose.Types.ObjectId;
  studentId: mongoose.Types.ObjectId;
  studentName: string;
  rollNumber: string;
  sectionId?: mongoose.Types.ObjectId | null;
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
  sectionId?: mongoose.Types.ObjectId | null;
  sectionName?: string | null;
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
  isSubstitution?: boolean;
  substituteFacultyId?: mongoose.Types.ObjectId | null;
  substitutionId?: mongoose.Types.ObjectId | null;
  originalFacultyId?: mongoose.Types.ObjectId | null;
  originalFacultyAssignmentId?: mongoose.Types.ObjectId | null;
  substitutionReason?: string | null;
  createdBy?: string;
  lastModifiedBy?: string;
  sourceType?: 'LIVE' | 'IMPORTED' | 'HISTORICAL_MANUAL';
  importBatchId?: string;
  version: number;
  createdAt: Date;
  updatedAt: Date;
}

const AttendanceRecordItemSchema = new Schema<IAttendanceRecordItem>(
  {
    studentId: { type: Schema.Types.ObjectId, ref: 'Student', required: true },
    studentName: { type: String, required: true },
    rollNumber: { type: String, required: true },
    sectionId: { type: Schema.Types.ObjectId, ref: 'Section', default: null },
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
    sectionId: { type: Schema.Types.ObjectId, ref: 'Section', default: null, index: true },
    sectionName: { type: String, default: null },
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
    isSubstitution: { type: Boolean, default: false, index: true },
    substituteFacultyId: { type: Schema.Types.ObjectId, ref: 'Faculty', default: null, index: true },
    substitutionId: { type: Schema.Types.ObjectId, ref: 'TeacherSubstitution', default: null, index: true },
    originalFacultyId: { type: Schema.Types.ObjectId, ref: 'Faculty', default: null, index: true },
    originalFacultyAssignmentId: { type: Schema.Types.ObjectId, ref: 'FacultyAssignment', default: null, index: true },
    substitutionReason: { type: String, default: null },
    createdBy: { type: String, default: null },
    lastModifiedBy: { type: String, default: null },
    sourceType: { type: String, enum: ['LIVE', 'IMPORTED', 'HISTORICAL_MANUAL'], default: 'LIVE' },
    importBatchId: { type: String, default: null, index: true },
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
        if (ret.sectionId) ret.sectionId = ret.sectionId.toString();
        if (ret.timetableId) ret.timetableId = ret.timetableId.toString();
        if (ret.facultyAssignmentId) ret.facultyAssignmentId = ret.facultyAssignmentId.toString();
        if (ret.substituteFacultyId) ret.substituteFacultyId = ret.substituteFacultyId.toString();
        if (ret.substitutionId) ret.substitutionId = ret.substitutionId.toString();
        if (ret.originalFacultyId) ret.originalFacultyId = ret.originalFacultyId.toString();
        if (ret.originalFacultyAssignmentId) ret.originalFacultyAssignmentId = ret.originalFacultyAssignmentId.toString();
        delete ret.__v;
        return ret;
      },
    },
  }
);

AttendanceSessionSchema.pre('validate', function (next) {
  if (this.timeSlot) {
    this.timeSlot = normalizeTimeSlot(this.timeSlot);
  }
  next();
});

AttendanceSessionSchema.index(
  { collegeId: 1, sectionId: 1, subjectId: 1, date: 1, timeSlot: 1 },
  { unique: true, partialFilterExpression: { sectionId: { $type: 'objectId' } } }
);
AttendanceSessionSchema.index(
  { collegeId: 1, semesterId: 1, subjectId: 1, date: 1, timeSlot: 1 },
  { unique: true, partialFilterExpression: { sectionId: null } }
);
AttendanceSessionSchema.index({ collegeId: 1, facultyId: 1, date: 1 });
AttendanceSessionSchema.index({ collegeId: 1, date: 1 });
AttendanceSessionSchema.index({ collegeId: 1, status: 1 });
AttendanceSessionSchema.index({ 'records.studentId': 1 });

export const AttendanceSession = mongoose.model<IAttendanceSession>(
  'AttendanceSession',
  AttendanceSessionSchema
);
