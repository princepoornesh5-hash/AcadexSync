import { z } from 'zod';
import { Types } from 'mongoose';
import { ImportDataType } from '../constants/import.constants';

const objectIdRegex = /^[0-9a-fA-F]{24}$/;
const isValidObjectId = (val: string) => objectIdRegex.test(val) && Types.ObjectId.isValid(val);

export const objectIdSchema = z
  .string()
  .refine(isValidObjectId, { message: 'Invalid ObjectId format' });

export const uploadImportSchema = z.object({
  dataType: z.nativeEnum(ImportDataType),
  fileName: z.string().optional(),
  fileBase64: z.string().optional(),
  selectedSheet: z.string().optional(),
  defaultMaxMarks: z.coerce.number().positive().optional(),
  academicYearId: objectIdSchema.optional(),
  semesterId: objectIdSchema.optional(),
  sectionId: objectIdSchema.optional(),
  departmentId: objectIdSchema.optional(),
  courseId: objectIdSchema.optional(),
  subjectId: objectIdSchema.optional(),
  facultyAssignmentId: objectIdSchema.optional(),
});

export const updateSheetAndMappingsSchema = z.object({
  selectedSheet: z.string().optional(),
  customMappings: z
    .array(
      z.object({
        sourceColumn: z.string().min(1),
        targetField: z.string().min(1),
      })
    )
    .optional(),
});

export const validateAndPreviewSchema = z.object({
  academicYearId: objectIdSchema.optional(),
  semesterId: objectIdSchema.optional(),
  sectionId: objectIdSchema.optional(),
  departmentId: objectIdSchema.optional(),
  courseId: objectIdSchema.optional(),
  subjectId: objectIdSchema.optional(),
  facultyAssignmentId: objectIdSchema.optional(),
  academicYearName: z.string().optional(),
  semesterName: z.string().optional(),
  sectionName: z.string().optional(),
  subjectCode: z.string().optional(),
});

export const resolveRowSchema = z.object({
  rowNumber: z.number().int().positive(),
  resolvedEnrollmentId: objectIdSchema.optional(),
  action: z.enum(['RESOLVE', 'EXCLUDE']),
  reason: z.string().optional(),
});

export const confirmImportSchema = z.object({
  allowPartial: z.boolean().optional().default(false),
});
