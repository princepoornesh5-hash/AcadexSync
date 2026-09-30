import mongoose, { Document, Schema } from 'mongoose';
import {
  CalendarSourceType,
  CalendarEventType,
  CalendarEventScope,
  CalendarEventStatus,
  CalendarRecurrence,
} from '../constants/calendar.constants';

export interface ICalendarEvent extends Document {
  collegeId: mongoose.Types.ObjectId;
  title: string;
  description: string;
  sourceType: CalendarSourceType;
  sourceId?: string | null;
  eventType: CalendarEventType;
  scope: CalendarEventScope;
  startDate: string; // YYYY-MM-DD
  endDate: string; // YYYY-MM-DD
  startTime?: string | null; // HH:mm
  endTime?: string | null; // HH:mm
  allDay: boolean;
  academicCalendarId?: mongoose.Types.ObjectId | null;
  departmentId?: mongoose.Types.ObjectId | null;
  courseId?: mongoose.Types.ObjectId | null;
  academicYearId?: mongoose.Types.ObjectId | null;
  semesterId?: mongoose.Types.ObjectId | null;
  sectionId?: mongoose.Types.ObjectId | null;
  subjectId?: mongoose.Types.ObjectId | null;
  facultyAssignmentId?: mongoose.Types.ObjectId | null;
  location?: string | null;
  isRecurring: boolean;
  recurrence: CalendarRecurrence;
  status: CalendarEventStatus;
  createdBy: mongoose.Types.ObjectId;
  creatorRole: string;
  creatorName: string;
  academicContext?: string | null;
  navigationTarget?: string | null;
  metadata?: Record<string, any>;
  createdAt: Date;
  updatedAt: Date;
}

const CalendarEventSchema = new Schema<ICalendarEvent>(
  {
    collegeId: {
      type: Schema.Types.ObjectId,
      ref: 'College',
      required: true,
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
    sourceType: {
      type: String,
      enum: Object.values(CalendarSourceType),
      default: CalendarSourceType.MANUAL,
      required: true,
    },
    sourceId: {
      type: String,
      default: null,
    },
    eventType: {
      type: String,
      enum: Object.values(CalendarEventType),
      required: true,
      index: true,
    },
    scope: {
      type: String,
      enum: Object.values(CalendarEventScope),
      required: true,
      index: true,
    },
    startDate: {
      type: String,
      required: true,
      index: true,
    },
    endDate: {
      type: String,
      required: true,
    },
    startTime: {
      type: String,
      default: null,
    },
    endTime: {
      type: String,
      default: null,
    },
    allDay: {
      type: Boolean,
      default: false,
    },
    academicCalendarId: {
      type: Schema.Types.ObjectId,
      ref: 'AcademicCalendar',
      default: null,
      index: true,
    },
    departmentId: {
      type: Schema.Types.ObjectId,
      ref: 'Department',
      default: null,
      index: true,
    },
    courseId: {
      type: Schema.Types.ObjectId,
      ref: 'Course',
      default: null,
    },
    academicYearId: {
      type: Schema.Types.ObjectId,
      ref: 'AcademicYear',
      default: null,
    },
    semesterId: {
      type: Schema.Types.ObjectId,
      ref: 'Semester',
      default: null,
    },
    sectionId: {
      type: Schema.Types.ObjectId,
      ref: 'Section',
      default: null,
      index: true,
    },
    subjectId: {
      type: Schema.Types.ObjectId,
      ref: 'Subject',
      default: null,
      index: true,
    },
    facultyAssignmentId: {
      type: Schema.Types.ObjectId,
      ref: 'FacultyAssignment',
      default: null,
    },
    location: {
      type: String,
      default: null,
      trim: true,
    },
    isRecurring: {
      type: Boolean,
      default: false,
    },
    recurrence: {
      type: String,
      enum: Object.values(CalendarRecurrence),
      default: CalendarRecurrence.NONE,
    },
    status: {
      type: String,
      enum: Object.values(CalendarEventStatus),
      default: CalendarEventStatus.PUBLISHED,
      index: true,
    },
    createdBy: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    creatorRole: {
      type: String,
      required: true,
    },
    creatorName: {
      type: String,
      required: true,
    },
    academicContext: {
      type: String,
      default: null,
    },
    navigationTarget: {
      type: String,
      default: null,
    },
    metadata: {
      type: Schema.Types.Mixed,
      default: {},
    },
  },
  {
    timestamps: true,
    toJSON: {
      virtuals: true,
      transform: (_: unknown, ret: Record<string, any>) => {
        ret.id = ret._id?.toString();
        ret.collegeId = ret.collegeId?.toString();
        if (ret.departmentId) ret.departmentId = ret.departmentId.toString();
        if (ret.courseId) ret.courseId = ret.courseId.toString();
        if (ret.academicYearId) ret.academicYearId = ret.academicYearId.toString();
        if (ret.semesterId) ret.semesterId = ret.semesterId.toString();
        if (ret.sectionId) ret.sectionId = ret.sectionId.toString();
        if (ret.subjectId) ret.subjectId = ret.subjectId.toString();
        if (ret.facultyAssignmentId) ret.facultyAssignmentId = ret.facultyAssignmentId.toString();
        if (ret.createdBy) ret.createdBy = ret.createdBy.toString();
        delete ret.__v;
        return ret;
      },
    },
  }
);

CalendarEventSchema.index({ collegeId: 1, startDate: 1, status: 1 });
CalendarEventSchema.index({ collegeId: 1, scope: 1, departmentId: 1 });
CalendarEventSchema.index({ collegeId: 1, sourceType: 1, sourceId: 1 });

export const CalendarEvent = mongoose.model<ICalendarEvent>('CalendarEvent', CalendarEventSchema);
