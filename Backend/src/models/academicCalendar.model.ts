import mongoose, { Document, Schema } from 'mongoose';
import { AcademicCalendarStatus } from '../constants/calendar.constants';

export interface ICalendarHolidayItem {
  date: string; // YYYY-MM-DD
  name: string;
  description?: string;
  isFullDay?: boolean;
}

export interface IAcademicCalendar extends Document {
  collegeId: mongoose.Types.ObjectId;
  academicYearId: mongoose.Types.ObjectId;
  courseId?: mongoose.Types.ObjectId | null;
  departmentId?: mongoose.Types.ObjectId | null;
  semesterId?: mongoose.Types.ObjectId | null;
  title: string;
  description?: string;
  startDate: string; // YYYY-MM-DD
  endDate: string; // YYYY-MM-DD
  status: AcademicCalendarStatus;
  workingDays: number[]; // 1=Mon, 2=Tue, 3=Wed, 4=Thu, 5=Fri, 6=Sat, 7=Sun
  holidays: ICalendarHolidayItem[];
  createdBy: mongoose.Types.ObjectId;
  updatedBy?: mongoose.Types.ObjectId | null;
  createdAt: Date;
  updatedAt: Date;
}

const CalendarHolidayItemSchema = new Schema<ICalendarHolidayItem>(
  {
    date: {
      type: String,
      required: true,
      match: /^\d{4}-\d{2}-\d{2}$/,
    },
    name: {
      type: String,
      required: true,
      trim: true,
    },
    description: {
      type: String,
      default: '',
      trim: true,
    },
    isFullDay: {
      type: Boolean,
      default: true,
    },
  },
  { _id: false }
);

const AcademicCalendarSchema = new Schema<IAcademicCalendar>(
  {
    collegeId: {
      type: Schema.Types.ObjectId,
      ref: 'College',
      required: true,
      index: true,
    },
    academicYearId: {
      type: Schema.Types.ObjectId,
      ref: 'AcademicYear',
      required: true,
      index: true,
    },
    courseId: {
      type: Schema.Types.ObjectId,
      ref: 'Course',
      default: null,
      index: true,
    },
    departmentId: {
      type: Schema.Types.ObjectId,
      ref: 'Department',
      default: null,
      index: true,
    },
    semesterId: {
      type: Schema.Types.ObjectId,
      ref: 'Semester',
      default: null,
      index: true,
    },
    title: {
      type: String,
      required: true,
      trim: true,
    },
    description: {
      type: String,
      default: '',
      trim: true,
    },
    startDate: {
      type: String,
      required: true,
      match: /^\d{4}-\d{2}-\d{2}$/,
      index: true,
    },
    endDate: {
      type: String,
      required: true,
      match: /^\d{4}-\d{2}-\d{2}$/,
      index: true,
    },
    status: {
      type: String,
      enum: Object.values(AcademicCalendarStatus),
      default: AcademicCalendarStatus.DRAFT,
      index: true,
    },
    workingDays: {
      type: [Number],
      default: [1, 2, 3, 4, 5],
    },
    holidays: [CalendarHolidayItemSchema],
    createdBy: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    updatedBy: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },
  },
  {
    timestamps: true,
    toJSON: {
      virtuals: true,
      transform: (_: unknown, ret: Record<string, any>) => {
        ret.id = ret._id?.toString();
        ret.collegeId = ret.collegeId?.toString();
        if (ret.academicYearId) ret.academicYearId = ret.academicYearId.toString();
        if (ret.courseId) ret.courseId = ret.courseId.toString();
        if (ret.departmentId) ret.departmentId = ret.departmentId.toString();
        if (ret.semesterId) ret.semesterId = ret.semesterId.toString();
        if (ret.createdBy) ret.createdBy = ret.createdBy.toString();
        delete ret.__v;
        return ret;
      },
    },
  }
);

AcademicCalendarSchema.index({ collegeId: 1, academicYearId: 1, status: 1 });
AcademicCalendarSchema.index({ collegeId: 1, startDate: 1, endDate: 1 });

export const AcademicCalendar = mongoose.model<IAcademicCalendar>(
  'AcademicCalendar',
  AcademicCalendarSchema
);
