import mongoose, { Document, Schema } from 'mongoose';
import {
  InstitutionType,
  IAcademicStructureConfig,
  ITerminologyConfig,
  IAttendanceAlertsConfig,
  DEFAULT_ACADEMIC_STRUCTURE,
  DEFAULT_TERMINOLOGY,
  DEFAULT_ATTENDANCE_ALERTS,
} from '../constants/institutionConfig.constants';

export interface IInstitutionConfiguration extends Document {
  collegeId: mongoose.Types.ObjectId;
  institutionType: InstitutionType;
  academicStructure: IAcademicStructureConfig;
  terminology: ITerminologyConfig;
  attendanceAlerts: IAttendanceAlertsConfig;
  isConfigured: boolean;
  updatedBy?: mongoose.Types.ObjectId;
  createdAt: Date;
  updatedAt: Date;
}

const ConceptTermSchema = new Schema(
  {
    singular: { type: String, required: true, trim: true },
    plural: { type: String, required: true, trim: true },
  },
  { _id: false }
);

const AcademicStructureSchema = new Schema<IAcademicStructureConfig>(
  {
    program: { type: Boolean, default: true },
    academicYear: { type: Boolean, default: true },
    semester: { type: Boolean, default: true },
    section: { type: Boolean, default: true },
    subject: { type: Boolean, default: true },
    building: { type: Boolean, default: true },
    room: { type: Boolean, default: true },
  },
  { _id: false }
);

const TerminologySchema = new Schema<ITerminologyConfig>(
  {
    department: { type: ConceptTermSchema, default: () => DEFAULT_TERMINOLOGY.department },
    program: { type: ConceptTermSchema, default: () => DEFAULT_TERMINOLOGY.program },
    academicYear: { type: ConceptTermSchema, default: () => DEFAULT_TERMINOLOGY.academicYear },
    semester: { type: ConceptTermSchema, default: () => DEFAULT_TERMINOLOGY.semester },
    section: { type: ConceptTermSchema, default: () => DEFAULT_TERMINOLOGY.section },
    subject: { type: ConceptTermSchema, default: () => DEFAULT_TERMINOLOGY.subject },
    building: { type: ConceptTermSchema, default: () => DEFAULT_TERMINOLOGY.building },
    room: { type: ConceptTermSchema, default: () => DEFAULT_TERMINOLOGY.room },
  },
  { _id: false }
);

const AttendanceAlertsSchema = new Schema<IAttendanceAlertsConfig>(
  {
    enabled: { type: Boolean, default: true },
    warningPercentage: { type: Number, default: 75, min: 0, max: 100 },
    criticalPercentage: { type: Number, default: 65, min: 0, max: 100 },
    absenceAlertsEnabled: { type: Boolean, default: true },
  },
  { _id: false }
);

const InstitutionConfigurationSchema = new Schema<IInstitutionConfiguration>(
  {
    collegeId: {
      type: Schema.Types.ObjectId,
      ref: 'College',
      required: true,
      unique: true,
      index: true,
    },
    institutionType: {
      type: String,
      enum: Object.values(InstitutionType),
      default: InstitutionType.ENGINEERING,
      required: true,
    },
    academicStructure: {
      type: AcademicStructureSchema,
      default: () => ({ ...DEFAULT_ACADEMIC_STRUCTURE }),
    },
    terminology: {
      type: TerminologySchema,
      default: () => ({ ...DEFAULT_TERMINOLOGY }),
    },
    attendanceAlerts: {
      type: AttendanceAlertsSchema,
      default: () => ({ ...DEFAULT_ATTENDANCE_ALERTS }),
    },
    isConfigured: {
      type: Boolean,
      default: true,
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
        if (ret.updatedBy) ret.updatedBy = ret.updatedBy.toString();
        delete ret.__v;
        return ret;
      },
    },
  }
);

export const InstitutionConfiguration = mongoose.model<IInstitutionConfiguration>(
  'InstitutionConfiguration',
  InstitutionConfigurationSchema
);
