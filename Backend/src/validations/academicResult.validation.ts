import { z } from 'zod';
import { ResultLifecycleStatus } from '../constants/academicResult.constants';

const objectIdRegex = /^[0-9a-fA-F]{24}$/;
const objectIdSchema = z.string().regex(objectIdRegex, 'Invalid ObjectId');

export const gradeDefinitionSchema = z.object({
  grade: z.string().min(1, 'Grade symbol is required').trim(),
  minPercentage: z.number().min(0).max(100),
  maxPercentage: z.number().min(0).max(100),
  gradePoint: z.number().min(0),
  isPassing: z.boolean().default(true),
  description: z.string().optional(),
});

export const passCriteriaSchema = z.object({
  minSubjectPercentage: z.number().min(0).max(100).default(40),
  minAttendancePercentage: z.number().min(0).max(100).nullable().optional(),
  minPracticalCompletionRate: z.number().min(0).max(100).nullable().optional(),
  requireAllComponentsPassed: z.boolean().default(false),
});

export const gpaPolicySchema = z.object({
  enabled: z.boolean().default(false),
  scale: z.number().min(1).default(10.0),
  formula: z.enum(['CREDIT_WEIGHTED', 'SIMPLE_AVERAGE']).default('CREDIT_WEIGHTED'),
  passingGradePointMin: z.number().min(0).default(4.0),
});

export const cgpaPolicySchema = z.object({
  enabled: z.boolean().default(false),
  calculationPeriod: z.enum(['CUMULATIVE_ACROSS_SEMESTERS']).default('CUMULATIVE_ACROSS_SEMESTERS'),
});

export const createAcademicRuleConfigSchema = z.object({
  name: z.string().min(3, 'Rule configuration name must be at least 3 characters').trim(),
  description: z.string().optional().nullable(),
  courseId: objectIdSchema.optional().nullable(),
  isDefault: z.boolean().default(false),
  gradingScale: z.array(gradeDefinitionSchema).min(1, 'At least one grade level must be defined'),
  passCriteria: passCriteriaSchema.default({ minSubjectPercentage: 40 }),
  gpaPolicy: gpaPolicySchema.default({ enabled: false, scale: 10.0, formula: 'CREDIT_WEIGHTED', passingGradePointMin: 4.0 }),
  cgpaPolicy: cgpaPolicySchema.default({ enabled: false, calculationPeriod: 'CUMULATIVE_ACROSS_SEMESTERS' }),
});

export const updateAcademicRuleConfigSchema = createAcademicRuleConfigSchema.partial();

export const calculateSemesterResultSchema = z.object({
  studentId: objectIdSchema,
  semesterId: objectIdSchema,
  academicYearId: objectIdSchema,
  academicRecordId: objectIdSchema.optional(),
});

export const calculateClassResultsSchema = z.object({
  courseId: objectIdSchema,
  semesterId: objectIdSchema,
  academicYearId: objectIdSchema,
  sectionId: objectIdSchema.optional().nullable(),
});

export const reviewResultSchema = z.object({
  reviewNotes: z.string().max(500, 'Review notes cannot exceed 500 characters').optional().nullable(),
});

export const finalizeResultSchema = z.object({
  reviewNotes: z.string().max(500, 'Finalization notes cannot exceed 500 characters').optional().nullable(),
});

export const publishResultSchema = z.object({
  publicationNotes: z.string().max(500, 'Publication notes cannot exceed 500 characters').optional().nullable(),
});

export const reopenResultSchema = z.object({
  reason: z.string().min(5, 'Reopening reason must be at least 5 characters long').trim(),
});

export const queryResultsSchema = z.object({
  courseId: objectIdSchema.optional(),
  semesterId: objectIdSchema.optional(),
  academicYearId: objectIdSchema.optional(),
  departmentId: objectIdSchema.optional(),
  sectionId: objectIdSchema.optional(),
  status: z.nativeEnum(ResultLifecycleStatus).optional(),
  studentId: objectIdSchema.optional(),
  page: z.coerce.number().min(1).default(1),
  limit: z.coerce.number().min(1).max(100).default(50),
});
