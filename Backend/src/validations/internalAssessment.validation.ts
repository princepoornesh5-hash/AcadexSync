import { z } from 'zod';
import { Types } from 'mongoose';
import { AssessmentStatus, AssessmentType, StudentMarkStatus } from '../models/internalAssessment.model';

const objectIdRegex = /^[0-9a-fA-F]{24}$/;
const isValidObjectId = (val: string) => objectIdRegex.test(val) && Types.ObjectId.isValid(val);

export const objectIdSchema = z
  .string()
  .refine(isValidObjectId, { message: 'Invalid ObjectId format' });

export const assessmentComponentSchema = z.object({
  key: z.string().min(1, 'Component key is required'),
  name: z.string().min(1, 'Component name is required'),
  maxMarks: z.number().positive('Max marks must be greater than 0'),
  weightage: z.number().min(0).max(100).optional().default(0),
  isStudentVisible: z.boolean().optional().default(true),
});

export const studentMarkEntrySchema = z.object({
  studentId: objectIdSchema,
  studentName: z.string().optional(),
  rollNumber: z.string().optional(),
  admissionNumber: z.string().optional(),
  componentMarks: z.record(z.union([z.number().min(0), z.null()])).optional().default({}),
  obtainedMarks: z.number().min(0).optional(),
  totalMarks: z.number().min(0).optional(),
  status: z.nativeEnum(StudentMarkStatus).optional().default(StudentMarkStatus.NOT_ENTERED),
  remarks: z.string().max(500).optional(),
});

export const getContextSchema = z.object({
  query: z.object({
    sectionId: objectIdSchema,
    subjectId: objectIdSchema,
    academicYearId: objectIdSchema.optional(),
  }),
});

export const createAssessmentSchema = z.object({
  body: z.object({
    departmentId: objectIdSchema,
    courseId: objectIdSchema,
    academicYearId: objectIdSchema,
    semesterId: objectIdSchema,
    sectionId: objectIdSchema.optional().nullable(),
    subjectId: objectIdSchema,
    facultyAssignmentId: objectIdSchema.optional().nullable(),
    title: z.string().min(2, 'Title must be at least 2 characters').max(150),
    assessmentType: z.nativeEnum(AssessmentType).optional().default(AssessmentType.INTERNAL_EXAM),
    maximumMarks: z.number().positive('Maximum marks must be greater than 0'),
    assessmentDate: z.string().or(z.date()).optional(),
    components: z.array(assessmentComponentSchema).optional(),
  }),
});

export const saveDraftMarksSchema = z.object({
  body: z.object({
    sectionId: objectIdSchema,
    subjectId: objectIdSchema,
    academicYearId: objectIdSchema.optional(),
    title: z.string().optional(),
    entries: z.array(studentMarkEntrySchema).min(1, 'At least one student mark entry is required'),
  }),
});

export const bulkSaveMarksSchema = z.object({
  body: z.object({
    assessmentId: objectIdSchema.optional(),
    sectionId: objectIdSchema.optional(),
    subjectId: objectIdSchema.optional(),
    academicYearId: objectIdSchema.optional(),
    title: z.string().optional(),
    entries: z.array(studentMarkEntrySchema).min(1, 'At least one student mark entry is required'),
  }).refine((data) => data.assessmentId || (data.sectionId && data.subjectId), {
    message: 'Either assessmentId or both sectionId and subjectId must be provided',
  }),
});

export const correctMarkSchema = z.object({
  body: z.object({
    assessmentId: objectIdSchema.optional(),
    sectionId: objectIdSchema.optional(),
    subjectId: objectIdSchema.optional(),
    studentId: objectIdSchema,
    componentKey: z.string().optional(),
    newMark: z.number().min(0, 'Marks cannot be negative'),
    status: z.nativeEnum(StudentMarkStatus).optional(),
    reason: z.string().min(5, 'Correction reason must be at least 5 characters long'),
  }).refine((data) => data.assessmentId || (data.sectionId && data.subjectId), {
    message: 'Either assessmentId or both sectionId and subjectId must be provided',
  }),
});

export const reviewSchema = z.object({
  body: z.object({
    sectionId: objectIdSchema,
    subjectId: objectIdSchema,
    comments: z.string().max(1000).optional(),
  }),
});

export const publishSchema = z.object({
  body: z.object({
    sectionId: objectIdSchema,
    subjectId: objectIdSchema,
  }),
});

export const unlockSchema = z.object({
  body: z.object({
    sectionId: objectIdSchema,
    subjectId: objectIdSchema,
    reason: z.string().min(5, 'Unlock reason must be at least 5 characters long'),
  }),
});

export const assessmentTransitionSchema = z.object({
  body: z.object({
    status: z.nativeEnum(AssessmentStatus),
    reason: z.string().min(3).optional(),
  }),
});

export const subjectSummarySchema = z.object({
  query: z.object({
    subjectId: objectIdSchema,
    semesterId: objectIdSchema,
    studentId: objectIdSchema.optional(),
  }),
});
