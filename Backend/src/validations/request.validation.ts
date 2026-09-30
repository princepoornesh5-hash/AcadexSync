import { z } from 'zod';
import { RequestStatus, ALL_REQUEST_TYPES } from '../constants/request.constants';

export const createRequestSchema = z.object({
  requestType: z.enum(ALL_REQUEST_TYPES as unknown as [string, ...string[]], {
    errorMap: () => ({ message: 'Please select a valid request type.' }),
  }),
  title: z
    .string()
    .min(2, 'Title must be at least 2 characters.')
    .max(200, 'Title cannot exceed 200 characters.')
    .optional(),
  description: z
    .string()
    .min(3, 'Please provide details or a reason for your request (minimum 3 characters).')
    .max(5000, 'Description cannot exceed 5000 characters.'),
  status: z.enum(['DRAFT', 'SUBMITTED']).optional(),
  relatedEntityType: z.string().optional().nullable(),
  relatedEntityId: z.string().optional().nullable(),
  academicContext: z
    .object({
      courseId: z.string().optional().nullable(),
      academicYearId: z.string().optional().nullable(),
      semesterId: z.string().optional().nullable(),
      sectionId: z.string().optional().nullable(),
      subjectId: z.string().optional().nullable(),
      facultyAssignmentId: z.string().optional().nullable(),
      courseName: z.string().optional().nullable(),
      sectionName: z.string().optional().nullable(),
      subjectName: z.string().optional().nullable(),
    })
    .optional()
    .nullable(),
  details: z
    .object({
      startDate: z.string().datetime().optional().nullable().or(z.date().optional()),
      endDate: z.string().datetime().optional().nullable().or(z.date().optional()),
      date: z.string().datetime().optional().nullable().or(z.date().optional()),
      resourceName: z.string().optional().nullable(),
      requestedChange: z.string().optional().nullable(),
      documentType: z.string().optional().nullable(),
      reason: z.string().optional().nullable(),
      metadata: z.record(z.any()).optional().nullable(),
    })
    .optional()
    .nullable(),
});

export const cancelRequestSchema = z.object({
  reason: z.string().max(1000, 'Reason cannot exceed 1000 characters.').optional().nullable(),
});

export const respondRequestSchema = z.object({
  action: z.enum(['APPROVED', 'REJECTED', 'RESOLVED'], {
    errorMap: () => ({ message: 'Action must be APPROVED, REJECTED, or RESOLVED.' }),
  }),
  message: z.string().max(1000, 'Response message cannot exceed 1000 characters.').optional().nullable(),
});

export const updateRequestStatusSchema = z.object({
  status: z.nativeEnum(RequestStatus, {
    errorMap: () => ({ message: 'Please provide a valid request status.' }),
  }),
  note: z.string().max(1000, 'Note cannot exceed 1000 characters.').optional().nullable(),
});

export const requestQuerySchema = z.object({
  status: z.nativeEnum(RequestStatus).optional(),
  requestType: z.string().optional(),
  page: z
    .string()
    .optional()
    .transform((val) => (val ? parseInt(val, 10) : 1)),
  limit: z
    .string()
    .optional()
    .transform((val) => (val ? Math.min(parseInt(val, 10), 100) : 20)),
});
