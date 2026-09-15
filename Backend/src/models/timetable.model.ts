import mongoose, { Document, Schema } from 'mongoose';
import {
  TimetableDay,
  TimetableStatus,
  TimetableTimingMode,
  TimetableBreakType,
  TimetableSessionType,
} from '../constants/status';

export interface ITimetablePeriod {
  _id?: mongoose.Types.ObjectId;
  index: number;
  name: string;
  startTime: string;
  endTime: string;
  dayOfWeek?: TimetableDay;
}

export interface ITimetableBreak {
  _id?: mongoose.Types.ObjectId;
  name: string;
  startTime: string;
  endTime: string;
  appliesToDays: TimetableDay[];
  isVerticalSpan: boolean;
  breakType: TimetableBreakType;
}

export interface ITimetableGridEntry {
  _id?: mongoose.Types.ObjectId;
  dayOfWeek: TimetableDay;
  startPeriodIndex?: number;
  periodSpan?: number;
  startTime: string;
  endTime: string;
  subjectId: mongoose.Types.ObjectId;
  facultyId: mongoose.Types.ObjectId;
  facultyAssignmentId?: mongoose.Types.ObjectId;
  roomId?: mongoose.Types.ObjectId;
  roomNumber?: string;
  building?: string;
  sessionType: TimetableSessionType;
}

export interface ITimetable extends Document {
  collegeId: mongoose.Types.ObjectId;
  departmentId: mongoose.Types.ObjectId;
  courseId: mongoose.Types.ObjectId;
  academicYearId: mongoose.Types.ObjectId;
  semesterId: mongoose.Types.ObjectId;
  sectionId: mongoose.Types.ObjectId;
  name: string;
  status: TimetableStatus;
  version: number;
  activeDays: TimetableDay[];
  timingMode: TimetableTimingMode;
  periods: ITimetablePeriod[];
  breaks: ITimetableBreak[];
  entries: ITimetableGridEntry[];
  publishedAt?: Date;
  publishedBy?: string;
  createdBy?: string;
  updatedBy?: string;
  createdAt: Date;
  updatedAt: Date;
}

const TimetablePeriodSchema = new Schema<ITimetablePeriod>(
  {
    index: { type: Number, required: true },
    name: { type: String, required: true },
    startTime: { type: String, required: true },
    endTime: { type: String, required: true },
    dayOfWeek: { type: String, enum: Object.values(TimetableDay), default: null },
  },
  { _id: true }
);

const TimetableBreakSchema = new Schema<ITimetableBreak>(
  {
    name: { type: String, required: true },
    startTime: { type: String, required: true },
    endTime: { type: String, required: true },
    appliesToDays: [{ type: String, enum: Object.values(TimetableDay) }],
    isVerticalSpan: { type: Boolean, default: true },
    breakType: {
      type: String,
      enum: Object.values(TimetableBreakType),
      default: TimetableBreakType.LUNCH,
    },
  },
  { _id: true }
);

const TimetableGridEntrySchema = new Schema<ITimetableGridEntry>(
  {
    dayOfWeek: { type: String, enum: Object.values(TimetableDay), required: true },
    startPeriodIndex: { type: Number, default: 1 },
    periodSpan: { type: Number, default: 1 },
    startTime: { type: String, required: true },
    endTime: { type: String, required: true },
    subjectId: { type: Schema.Types.ObjectId, ref: 'Subject', required: true },
    facultyId: { type: Schema.Types.ObjectId, ref: 'Faculty', required: true },
    facultyAssignmentId: { type: Schema.Types.ObjectId, ref: 'FacultyAssignment', default: null },
    roomId: { type: Schema.Types.ObjectId, ref: 'Room', default: null },
    roomNumber: { type: String, default: null },
    building: { type: String, default: null },
    sessionType: {
      type: String,
      enum: Object.values(TimetableSessionType),
      default: TimetableSessionType.LECTURE,
    },
  },
  { _id: true }
);

const TimetableSchema = new Schema<ITimetable>(
  {
    collegeId: { type: Schema.Types.ObjectId, ref: 'College', required: true, index: true },
    departmentId: { type: Schema.Types.ObjectId, ref: 'Department', required: true, index: true },
    courseId: { type: Schema.Types.ObjectId, ref: 'Course', required: true },
    academicYearId: { type: Schema.Types.ObjectId, ref: 'AcademicYear', required: true },
    semesterId: { type: Schema.Types.ObjectId, ref: 'Semester', required: true },
    sectionId: { type: Schema.Types.ObjectId, ref: 'Section', required: true, index: true },
    name: { type: String, required: true, trim: true },
    status: {
      type: String,
      enum: Object.values(TimetableStatus),
      default: TimetableStatus.DRAFT,
    },
    version: { type: Number, default: 1 },
    activeDays: [
      {
        type: String,
        enum: Object.values(TimetableDay),
      },
    ],
    timingMode: {
      type: String,
      enum: Object.values(TimetableTimingMode),
      default: TimetableTimingMode.SAME_EVERY_DAY,
    },
    periods: [TimetablePeriodSchema],
    breaks: [TimetableBreakSchema],
    entries: [TimetableGridEntrySchema],
    publishedAt: { type: Date, default: null },
    publishedBy: { type: String, default: null },
    createdBy: { type: String, default: null },
    updatedBy: { type: String, default: null },
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
        delete ret.__v;
        return ret;
      },
    },
  }
);

TimetableSchema.index({ collegeId: 1, sectionId: 1, status: 1 });
TimetableSchema.index({ collegeId: 1, departmentId: 1 });
TimetableSchema.index({ 'entries.facultyId': 1 });
TimetableSchema.index({ 'entries.facultyAssignmentId': 1 });
TimetableSchema.index({ 'entries.roomId': 1 });

export const Timetable = mongoose.model<ITimetable>('Timetable', TimetableSchema);
