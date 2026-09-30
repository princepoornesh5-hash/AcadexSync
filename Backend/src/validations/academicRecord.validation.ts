import { z } from 'zod';
import { AcademicProgressionStatus, SubjectAcademicStatus } from '../constants/academicRecord.constants';

export const initializeRecordSchema = z.object({
  studentEnrollmentId: z.string().min(1, 'studentEnrollmentId is required'),
});

export const updateProgressionSchema = z.object({
  progressionStatus: z.nativeEnum(AcademicProgressionStatus, {
    errorMap: () => ({ message: 'Invalid academic progression status' }),
  }),
  remarks: z.string().max(500).optional().nullable(),
});

export const updateSubjectStatusSchema = z.object({
  status: z.nativeEnum(SubjectAcademicStatus, {
    errorMap: () => ({ message: 'Invalid subject academic status' }),
  }),
  remarks: z.string().max(500).optional().nullable(),
});

export const queryHistorySchema = z.object({
  studentId: z.string().optional(),
  academicYearId: z.string().optional(),
  semesterId: z.string().optional(),
  courseId: z.string().optional(),
});

export const queryDepartmentRecordsSchema = z.object({
  departmentId: z.string().optional(),
  courseId: z.string().optional(),
  academicYearId: z.string().optional(),
  semesterId: z.string().optional(),
  sectionId: z.string().optional(),
  progressionStatus: z.nativeEnum(AcademicProgressionStatus).optional(),
  search: z.string().optional(),
  page: z.coerce.number().min(1).default(1),
  limit: z.coerce.number().min(1).max(100).default(20),
});
