import { z } from 'zod';
import { NoteType, NoteVisibility, NoteStatus } from '../constants/status';
import { ALLOWED_MIME_TYPES } from '../storage/imagekit.types';
import { env } from '../config/env';

const maxNoteSizeBytes = env.NOTES_MAX_FILE_SIZE_MB * 1024 * 1024;

export const requestUploadUrlSchema = z.object({
  departmentId: z.string().optional(),
  courseId: z.string().optional(),
  academicYearId: z.string().optional(),
  semesterId: z.string().optional(),
  sectionId: z.string().optional(),
  subjectId: z.string().min(1, 'subjectId is required'),
  title: z.string().trim().min(2, 'Title must be at least 2 characters').max(200),
  description: z.string().trim().max(2000).optional().default(''),
  noteType: z.nativeEnum(NoteType).optional().default(NoteType.STUDY_MATERIAL),
  visibility: z.nativeEnum(NoteVisibility).optional().default(NoteVisibility.PUBLIC),
  fileName: z.string().trim().min(3, 'File name must be at least 3 characters').max(255),
  mimeType: z.enum(ALLOWED_MIME_TYPES as any, {
    errorMap: () => ({ message: 'Unsupported file type. Supported: PDF, DOC, DOCX, PPT, PPTX, JPG, PNG, WEBP' }),
  }),
  fileSize: z
    .number()
    .int()
    .positive('File size must be greater than 0')
    .max(maxNoteSizeBytes, `File size exceeds maximum limit of ${env.NOTES_MAX_FILE_SIZE_MB}MB`),
  chapter: z.string().trim().max(100).optional(),
});

export const requestReplaceUrlSchema = z.object({
  fileName: z.string().trim().min(3).max(255),
  mimeType: z.enum(ALLOWED_MIME_TYPES as any, {
    errorMap: () => ({ message: 'Unsupported file type' }),
  }),
  fileSize: z
    .number()
    .int()
    .positive()
    .max(maxNoteSizeBytes, `File size exceeds maximum limit of ${env.NOTES_MAX_FILE_SIZE_MB}MB`),
});

export const updateNoteSchema = z.object({
  title: z.string().trim().min(2).max(200).optional(),
  description: z.string().trim().max(2000).optional(),
  noteType: z.nativeEnum(NoteType).optional(),
  visibility: z.nativeEnum(NoteVisibility).optional(),
  chapter: z.string().trim().max(100).optional(),
});

export const noteQuerySchema = z.object({
  page: z.string().optional().transform((v) => (v ? parseInt(v, 10) : 1)).pipe(z.number().positive().default(1)),
  limit: z.string().optional().transform((v) => (v ? parseInt(v, 10) : 20)).pipe(z.number().positive().max(100).default(20)),
  collegeId: z.string().optional(),
  departmentId: z.string().optional(),
  courseId: z.string().optional(),
  semesterId: z.string().optional(),
  sectionId: z.string().optional(),
  subjectId: z.string().optional(),
  facultyId: z.string().optional(),
  noteType: z.nativeEnum(NoteType).optional(),
  search: z.string().optional(),
  status: z.nativeEnum(NoteStatus).optional(),
});
