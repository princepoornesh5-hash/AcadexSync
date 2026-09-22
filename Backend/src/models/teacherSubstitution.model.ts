import mongoose, { Document, Schema } from 'mongoose';

export enum TeacherSubstitutionStatus {
  ACTIVE = 'ACTIVE',
  CANCELLED = 'CANCELLED',
}

export interface ITeacherSubstitution extends Document {
  collegeId: mongoose.Types.ObjectId;
  departmentId: mongoose.Types.ObjectId;
  sectionId: mongoose.Types.ObjectId;
  timetableId: mongoose.Types.ObjectId;
  timetableEntryId: mongoose.Types.ObjectId;
  date: string; // Format: YYYY-MM-DD (canonical local calendar date)
  originalFacultyId: mongoose.Types.ObjectId;
  substituteFacultyId: mongoose.Types.ObjectId;
  reason: string;
  status: TeacherSubstitutionStatus;
  createdBy: mongoose.Types.ObjectId;
  updatedBy?: mongoose.Types.ObjectId;
  createdAt: Date;
  updatedAt: Date;
}

const TeacherSubstitutionSchema = new Schema<ITeacherSubstitution>(
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
      required: true,
      index: true,
    },
    sectionId: {
      type: Schema.Types.ObjectId,
      ref: 'Section',
      required: true,
      index: true,
    },
    timetableId: {
      type: Schema.Types.ObjectId,
      ref: 'Timetable',
      required: true,
      index: true,
    },
    timetableEntryId: {
      type: Schema.Types.ObjectId,
      required: true,
      index: true,
    },
    date: {
      type: String,
      required: true,
      trim: true,
      match: /^\d{4}-\d{2}-\d{2}$/,
      index: true,
    },
    originalFacultyId: {
      type: Schema.Types.ObjectId,
      ref: 'Faculty',
      required: true,
      index: true,
    },
    substituteFacultyId: {
      type: Schema.Types.ObjectId,
      ref: 'Faculty',
      required: true,
      index: true,
    },
    reason: {
      type: String,
      required: true,
      trim: true,
      maxlength: 500,
    },
    status: {
      type: String,
      enum: Object.values(TeacherSubstitutionStatus),
      default: TeacherSubstitutionStatus.ACTIVE,
      index: true,
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

// Compound unique index ensuring only one active substitution per timetable entry on any date
TeacherSubstitutionSchema.index(
  { timetableId: 1, timetableEntryId: 1, date: 1, status: 1 },
  { unique: true }
);

// Fast lookup indices
TeacherSubstitutionSchema.index({ collegeId: 1, date: 1 });
TeacherSubstitutionSchema.index({ substituteFacultyId: 1, date: 1 });
TeacherSubstitutionSchema.index({ originalFacultyId: 1, date: 1 });

export const TeacherSubstitution = mongoose.model<ITeacherSubstitution>(
  'TeacherSubstitution',
  TeacherSubstitutionSchema
);
