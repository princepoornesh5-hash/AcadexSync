import mongoose, { Document, Schema } from 'mongoose';
import {
  ImportDataType,
  ImportBatchStatus,
  ColumnMappingStatus,
  MappingConfidence,
} from '../constants/import.constants';

export interface IColumnMapping {
  sourceColumn: string;
  targetField: string;
  confidence: MappingConfidence;
  status: ColumnMappingStatus;
}

export interface IUserRowResolution {
  rowNumber: number;
  resolvedEnrollmentId?: string;
  resolvedStudentId?: string;
  action: 'RESOLVE' | 'EXCLUDE';
  reason?: string;
}

export interface IImportBatch extends Document {
  importBatchId: string;
  collegeId: mongoose.Types.ObjectId;
  uploadedBy: mongoose.Types.ObjectId;
  uploadedAt: Date;
  dataType: ImportDataType;
  academicYearId?: mongoose.Types.ObjectId | null;
  semesterId?: mongoose.Types.ObjectId | null;
  sectionId?: mongoose.Types.ObjectId | null;
  departmentId?: mongoose.Types.ObjectId | null;
  courseId?: mongoose.Types.ObjectId | null;
  subjectId?: mongoose.Types.ObjectId | null;
  facultyAssignmentId?: mongoose.Types.ObjectId | null;
  fileName: string;
  fileType: 'XLSX' | 'CSV';
  fileSize: number;
  status: ImportBatchStatus;
  selectedSheet?: string;
  sheetNames: string[];
  detectedHeaderRow?: number;
  headers: string[];
  columnMappings: IColumnMapping[];
  rowCount: number;
  validCount: number;
  warningCount: number;
  unresolvedCount: number;
  errorCount: number;
  importedCount: number;
  failedCount: number;
  stagedRows?: any[];
  previewSummary?: Record<string, any>;
  errorMessage?: string;
  userResolutions?: IUserRowResolution[];
  metadata?: Record<string, any>;
  createdAt: Date;
  updatedAt: Date;
}

const ColumnMappingSchema = new Schema<IColumnMapping>(
  {
    sourceColumn: { type: String, required: true },
    targetField: { type: String, required: true },
    confidence: { type: String, enum: Object.values(MappingConfidence), default: MappingConfidence.MEDIUM },
    status: { type: String, enum: Object.values(ColumnMappingStatus), default: ColumnMappingStatus.UNMAPPED },
  },
  { _id: false }
);

const UserRowResolutionSchema = new Schema<IUserRowResolution>(
  {
    rowNumber: { type: Number, required: true },
    resolvedEnrollmentId: { type: String },
    resolvedStudentId: { type: String },
    action: { type: String, enum: ['RESOLVE', 'EXCLUDE'], required: true },
    reason: { type: String },
  },
  { _id: false }
);

const ImportBatchSchema = new Schema<IImportBatch>(
  {
    importBatchId: { type: String, required: true, unique: true, index: true },
    collegeId: { type: Schema.Types.ObjectId, ref: 'College', required: true, index: true },
    uploadedBy: { type: Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    uploadedAt: { type: Date, default: Date.now },
    dataType: { type: String, enum: Object.values(ImportDataType), required: true, index: true },
    academicYearId: { type: Schema.Types.ObjectId, ref: 'AcademicYear', default: null },
    semesterId: { type: Schema.Types.ObjectId, ref: 'Semester', default: null },
    sectionId: { type: Schema.Types.ObjectId, ref: 'Section', default: null },
    departmentId: { type: Schema.Types.ObjectId, ref: 'Department', default: null },
    courseId: { type: Schema.Types.ObjectId, ref: 'Course', default: null },
    subjectId: { type: Schema.Types.ObjectId, ref: 'Subject', default: null },
    facultyAssignmentId: { type: Schema.Types.ObjectId, ref: 'FacultyAssignment', default: null },
    fileName: { type: String, required: true, trim: true },
    fileType: { type: String, enum: ['XLSX', 'CSV'], required: true },
    fileSize: { type: Number, required: true },
    status: {
      type: String,
      enum: Object.values(ImportBatchStatus),
      default: ImportBatchStatus.UPLOADED,
      index: true,
    },
    selectedSheet: { type: String, default: null },
    sheetNames: [{ type: String }],
    detectedHeaderRow: { type: Number, default: 0 },
    headers: [{ type: String }],
    columnMappings: [ColumnMappingSchema],
    rowCount: { type: Number, default: 0 },
    validCount: { type: Number, default: 0 },
    warningCount: { type: Number, default: 0 },
    unresolvedCount: { type: Number, default: 0 },
    errorCount: { type: Number, default: 0 },
    importedCount: { type: Number, default: 0 },
    failedCount: { type: Number, default: 0 },
    stagedRows: { type: [Schema.Types.Mixed], default: [] },
    previewSummary: { type: Schema.Types.Mixed, default: {} },
    errorMessage: { type: String, default: null },
    userResolutions: [UserRowResolutionSchema],
    metadata: { type: Schema.Types.Mixed, default: {} },
  },
  {
    timestamps: true,
    toJSON: {
      virtuals: true,
      transform: (_: unknown, ret: Record<string, any>) => {
        ret.id = ret._id?.toString();
        ret.collegeId = ret.collegeId?.toString();
        ret.uploadedBy = ret.uploadedBy?.toString();
        if (ret.academicYearId) ret.academicYearId = ret.academicYearId?.toString();
        if (ret.semesterId) ret.semesterId = ret.semesterId?.toString();
        if (ret.sectionId) ret.sectionId = ret.sectionId?.toString();
        if (ret.departmentId) ret.departmentId = ret.departmentId?.toString();
        if (ret.courseId) ret.courseId = ret.courseId?.toString();
        if (ret.subjectId) ret.subjectId = ret.subjectId?.toString();
        if (ret.facultyAssignmentId) ret.facultyAssignmentId = ret.facultyAssignmentId?.toString();
        delete ret.__v;
        return ret;
      },
    },
  }
);

ImportBatchSchema.index({ collegeId: 1, createdAt: -1 });
ImportBatchSchema.index({ collegeId: 1, status: 1 });

export const ImportBatch = mongoose.model<IImportBatch>('ImportBatch', ImportBatchSchema);
