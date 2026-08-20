import mongoose, { Document, Schema } from 'mongoose';
import {
  NoteStatus,
  NoteType,
  NoteLifecycleState,
  NoteVisibility,
  ResourceType,
} from '../constants/status';

export interface INoteVersion {
  version: number;
  storageKey: string;
  fileId: string;
  fileName: string;
  fileSize: number;
  mimeType: string;
  fileUrl?: string;
  uploadedAt: Date;
}

export interface INote extends Document {
  collegeId: mongoose.Types.ObjectId;
  departmentId: mongoose.Types.ObjectId;
  courseId: mongoose.Types.ObjectId;
  academicYearId?: mongoose.Types.ObjectId;
  semesterId: mongoose.Types.ObjectId;
  sectionId?: mongoose.Types.ObjectId;
  subjectId: mongoose.Types.ObjectId;
  facultyId?: mongoose.Types.ObjectId;
  authorUserId: mongoose.Types.ObjectId;
  title: string;
  description: string;
  noteType: NoteType;
  visibility: NoteVisibility;
  lifecycleState: NoteLifecycleState;
  status: NoteStatus;
  resourceType: ResourceType;
  storageProvider: string;
  originalFileName: string;
  storageKey: string;
  fileId: string;
  fileUrl?: string;
  thumbnailUrl?: string;
  mimeType: string;
  fileExtension: string;
  fileSize: number;
  version: number;
  previousVersions: INoteVersion[];
  chapter?: string;
  publishedAt?: Date;
  createdAt: Date;
  updatedAt: Date;
}

const NoteVersionSchema = new Schema<INoteVersion>(
  {
    version: { type: Number, required: true },
    storageKey: { type: String, required: true },
    fileId: { type: String, required: true },
    fileName: { type: String, required: true },
    fileSize: { type: Number, required: true },
    mimeType: { type: String, required: true },
    fileUrl: { type: String, default: null },
    uploadedAt: { type: Date, default: Date.now },
  },
  { _id: false }
);

const NoteSchema = new Schema<INote>(
  {
    collegeId: { type: Schema.Types.ObjectId, ref: 'College', required: true, index: true },
    departmentId: { type: Schema.Types.ObjectId, ref: 'Department', required: true, index: true },
    courseId: { type: Schema.Types.ObjectId, ref: 'Course', required: true, index: true },
    academicYearId: { type: Schema.Types.ObjectId, ref: 'AcademicYear', default: null },
    semesterId: { type: Schema.Types.ObjectId, ref: 'Semester', required: true, index: true },
    sectionId: { type: Schema.Types.ObjectId, ref: 'Section', default: null, index: true },
    subjectId: { type: Schema.Types.ObjectId, ref: 'Subject', required: true, index: true },
    facultyId: { type: Schema.Types.ObjectId, ref: 'Faculty', default: null, index: true },
    authorUserId: { type: Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    title: { type: String, required: true, trim: true },
    description: { type: String, default: '', trim: true },
    noteType: {
      type: String,
      enum: Object.values(NoteType),
      default: NoteType.STUDY_MATERIAL,
    },
    visibility: {
      type: String,
      enum: Object.values(NoteVisibility),
      default: NoteVisibility.PUBLIC,
    },
    lifecycleState: {
      type: String,
      enum: Object.values(NoteLifecycleState),
      default: NoteLifecycleState.PENDING_UPLOAD,
      index: true,
    },
    status: {
      type: String,
      enum: Object.values(NoteStatus),
      default: NoteStatus.DRAFT,
      index: true,
    },
    resourceType: {
      type: String,
      enum: Object.values(ResourceType),
      default: ResourceType.FILE_ATTACHMENT,
    },
    storageProvider: {
      type: String,
      default: 'imagekit',
      required: true,
    },
    originalFileName: { type: String, required: true, trim: true },
    storageKey: { type: String, required: true, unique: true },
    fileId: { type: String, required: true },
    fileUrl: { type: String, default: null },
    thumbnailUrl: { type: String, default: null },
    mimeType: { type: String, required: true },
    fileExtension: { type: String, required: true },
    fileSize: { type: Number, required: true, min: 1 },
    version: { type: Number, default: 1 },
    previousVersions: [NoteVersionSchema],
    chapter: { type: String, default: null },
    publishedAt: { type: Date, default: null },
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
        if (ret.academicYearId) ret.academicYearId = ret.academicYearId.toString();
        ret.semesterId = ret.semesterId?.toString();
        if (ret.sectionId) ret.sectionId = ret.sectionId.toString();
        ret.subjectId = ret.subjectId?.toString();
        if (ret.facultyId) ret.facultyId = ret.facultyId.toString();
        ret.authorUserId = ret.authorUserId?.toString();
        delete ret.__v;
        return ret;
      },
    },
  }
);

NoteSchema.index({ collegeId: 1, subjectId: 1, lifecycleState: 1 });
NoteSchema.index({ collegeId: 1, semesterId: 1, subjectId: 1 });
NoteSchema.index({ collegeId: 1, authorUserId: 1 });
NoteSchema.index({ collegeId: 1, status: 1 });

export const Note = mongoose.model<INote>('Note', NoteSchema);
