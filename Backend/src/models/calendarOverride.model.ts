import mongoose, { Document, Schema } from 'mongoose';

export enum CalendarOverrideType {
  HOLIDAY = 'HOLIDAY',
  CANCELLED = 'CANCELLED',
}

export enum CalendarOverrideScope {
  COLLEGE = 'COLLEGE',
  DEPARTMENT = 'DEPARTMENT',
  SECTION = 'SECTION',
  ENTRY = 'ENTRY',
}

export interface ICalendarOverride extends Document {
  collegeId: mongoose.Types.ObjectId;
  departmentId?: mongoose.Types.ObjectId;
  sectionId?: mongoose.Types.ObjectId;
  timetableId?: mongoose.Types.ObjectId;
  timetableEntryId?: mongoose.Types.ObjectId;
  date: string; // Format: YYYY-MM-DD (canonical local calendar date)
  type: CalendarOverrideType;
  scope: CalendarOverrideScope;
  reason: string;
  createdBy: mongoose.Types.ObjectId;
  updatedBy?: mongoose.Types.ObjectId;
  createdAt: Date;
  updatedAt: Date;
}

const CalendarOverrideSchema = new Schema<ICalendarOverride>(
  {
    collegeId: {
      type: Schema.Types.ObjectId,
      ref: 'College',
      required: true,
      index: true,
    },
    departmentId: {
      type: Schema.Types.ObjectId,
      ref: 'Department',
      default: null,
      index: true,
    },
    sectionId: {
      type: Schema.Types.ObjectId,
      ref: 'Section',
      default: null,
      index: true,
    },
    timetableId: {
      type: Schema.Types.ObjectId,
      ref: 'Timetable',
      default: null,
      index: true,
    },
    timetableEntryId: {
      type: Schema.Types.ObjectId,
      default: null,
      index: true,
    },
    date: {
      type: String,
      required: true,
      trim: true,
      match: /^\d{4}-\d{2}-\d{2}$/,
      index: true,
    },
    type: {
      type: String,
      enum: Object.values(CalendarOverrideType),
      required: true,
    },
    scope: {
      type: String,
      enum: Object.values(CalendarOverrideScope),
      required: true,
    },
    reason: {
      type: String,
      required: true,
      trim: true,
      maxlength: 500,
    },
    createdBy: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
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
        delete ret.__v;
        return ret;
      },
    },
  }
);

// Compound unique index ensuring no duplicate overrides for the same target scope and date
CalendarOverrideSchema.index(
  { collegeId: 1, departmentId: 1, sectionId: 1, timetableEntryId: 1, date: 1 },
  { unique: true }
);

// Fast lookup index for active date lookups
CalendarOverrideSchema.index({ collegeId: 1, date: 1 });

export const CalendarOverride = mongoose.model<ICalendarOverride>(
  'CalendarOverride',
  CalendarOverrideSchema
);
