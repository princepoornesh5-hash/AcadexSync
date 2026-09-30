import mongoose, { Document, Schema } from 'mongoose';
import {
  IGradeDefinition,
  IPassCriteriaConfig,
  IGPAPolicyConfig,
  ICGPAPolicyConfig,
  PRESET_UGC_10_POINT_SCALE,
} from '../constants/academicResult.constants';

export interface IAcademicRuleConfiguration extends Document {
  collegeId: mongoose.Types.ObjectId;
  courseId?: mongoose.Types.ObjectId | null;
  name: string;
  description?: string | null;
  isDefault: boolean;
  gradingScale: IGradeDefinition[];
  passCriteria: IPassCriteriaConfig;
  gpaPolicy: IGPAPolicyConfig;
  cgpaPolicy: ICGPAPolicyConfig;
  isConfigured: boolean;
  createdBy?: mongoose.Types.ObjectId | null;
  updatedBy?: mongoose.Types.ObjectId | null;
  createdAt: Date;
  updatedAt: Date;
}

const GradeDefinitionSchema = new Schema<IGradeDefinition>(
  {
    grade: { type: String, required: true, trim: true },
    minPercentage: { type: Number, required: true, min: 0, max: 100 },
    maxPercentage: { type: Number, required: true, min: 0, max: 100 },
    gradePoint: { type: Number, required: true, min: 0 },
    isPassing: { type: Boolean, default: true },
    description: { type: String, trim: true },
  },
  { _id: false }
);

const PassCriteriaSchema = new Schema<IPassCriteriaConfig>(
  {
    minSubjectPercentage: { type: Number, default: 40, min: 0, max: 100 },
    minAttendancePercentage: { type: Number, default: null, min: 0, max: 100 },
    minPracticalCompletionRate: { type: Number, default: null, min: 0, max: 100 },
    requireAllComponentsPassed: { type: Boolean, default: false },
  },
  { _id: false }
);

const GPAPolicySchema = new Schema<IGPAPolicyConfig>(
  {
    enabled: { type: Boolean, default: false },
    scale: { type: Number, default: 10.0, min: 1 },
    formula: {
      type: String,
      enum: ['CREDIT_WEIGHTED', 'SIMPLE_AVERAGE'],
      default: 'CREDIT_WEIGHTED',
    },
    passingGradePointMin: { type: Number, default: 4.0 },
  },
  { _id: false }
);

const CGPAPolicySchema = new Schema<ICGPAPolicyConfig>(
  {
    enabled: { type: Boolean, default: false },
    calculationPeriod: {
      type: String,
      enum: ['CUMULATIVE_ACROSS_SEMESTERS'],
      default: 'CUMULATIVE_ACROSS_SEMESTERS',
    },
  },
  { _id: false }
);

const AcademicRuleConfigurationSchema = new Schema<IAcademicRuleConfiguration>(
  {
    collegeId: {
      type: Schema.Types.ObjectId,
      ref: 'College',
      required: true,
      index: true,
    },
    courseId: {
      type: Schema.Types.ObjectId,
      ref: 'Course',
      default: null,
      index: true,
    },
    name: {
      type: String,
      required: true,
      trim: true,
    },
    description: {
      type: String,
      default: null,
      trim: true,
    },
    isDefault: {
      type: Boolean,
      default: false,
    },
    gradingScale: {
      type: [GradeDefinitionSchema],
      default: () => [...PRESET_UGC_10_POINT_SCALE],
    },
    passCriteria: {
      type: PassCriteriaSchema,
      default: () => ({
        minSubjectPercentage: 40,
        minAttendancePercentage: null,
        minPracticalCompletionRate: null,
        requireAllComponentsPassed: false,
      }),
    },
    gpaPolicy: {
      type: GPAPolicySchema,
      default: () => ({
        enabled: false,
        scale: 10.0,
        formula: 'CREDIT_WEIGHTED',
        passingGradePointMin: 4.0,
      }),
    },
    cgpaPolicy: {
      type: CGPAPolicySchema,
      default: () => ({
        enabled: false,
        calculationPeriod: 'CUMULATIVE_ACROSS_SEMESTERS',
      }),
    },
    isConfigured: {
      type: Boolean,
      default: true,
    },
    createdBy: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      default: null,
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
        if (ret.courseId) ret.courseId = ret.courseId.toString();
        if (ret.createdBy) ret.createdBy = ret.createdBy.toString();
        if (ret.updatedBy) ret.updatedBy = ret.updatedBy.toString();
        delete ret.__v;
        return ret;
      },
    },
  }
);

// One default rule per college, or one rule per course in a college
AcademicRuleConfigurationSchema.index(
  { collegeId: 1, courseId: 1 },
  { unique: true }
);

export const AcademicRuleConfiguration = mongoose.model<IAcademicRuleConfiguration>(
  'AcademicRuleConfiguration',
  AcademicRuleConfigurationSchema
);
