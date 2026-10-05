import { z } from 'zod';
import { RequestStatus, ALL_REQUEST_TYPES } from '../constants/request.constants';

/**
 * Strict validator for canonical ISO dates and timestamps.
 * Accepts:
 *  - Pure calendar date: YYYY-MM-DD
 *  - Full ISO 8601 with UTC suffix: YYYY-MM-DDTHH:mm:ss.sssZ
 *  - Full ISO 8601 with timezone offset: YYYY-MM-DDTHH:mm:ss.sss+05:30
 *  - Local ISO 8601 without offset: YYYY-MM-DDTHH:mm:ss.sss
 * Rejects:
 *  - Impossible calendar dates (e.g. Feb 30, April 31, Feb 29 on non-leap years)
 *  - Arbitrary strings / malformed formats
 */
export function isValidIsoDateString(val: string): boolean {
  if (typeof val !== 'string') return false;
  const isoPattern = /^(\d{4})-(\d{2})-(\d{2})(?:T(\d{2}):(\d{2}):(\d{2})(?:\.(\d{1,9}))?(Z|[+-]\d{2}:?\d{2})?)?$/;
  const match = val.match(isoPattern);
  if (!match) return false;

  const year = parseInt(match[1], 10);
  const month = parseInt(match[2], 10);
  const day = parseInt(match[3], 10);
  if (month < 1 || month > 12 || day < 1 || day > 31) return false;

  const d = new Date(val.includes('T') ? val : `${val}T00:00:00.000Z`);
  if (isNaN(d.getTime())) return false;

  // Verify impossible dates (like February 30th or leap year validity)
  if (!val.includes('T') || val.endsWith('Z')) {
    if (d.getUTCFullYear() !== year || d.getUTCMonth() + 1 !== month || d.getUTCDate() !== day) {
      return false;
    }
  }
  return true;
}

export const isoDateSchema = z
  .string()
  .refine(isValidIsoDateString, {
    message: 'Please provide a valid ISO date or date-time string (e.g. YYYY-MM-DD or YYYY-MM-DDTHH:mm:ssZ).',
  })
  .or(z.date())
  .optional()
  .nullable();

export const createRequestSchema = z
  .object({
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
        startDate: isoDateSchema,
        endDate: isoDateSchema,
        date: isoDateSchema,
        resourceName: z.string().optional().nullable(),
        requestedChange: z.string().optional().nullable(),
        documentType: z.string().optional().nullable(),
        reason: z.string().optional().nullable(),
        metadata: z.record(z.any()).optional().nullable(),
      })
      .optional()
      .nullable(),
  })
  .superRefine((data, ctx) => {
    if (data.details?.startDate && data.details?.endDate) {
      const start = new Date(data.details.startDate);
      const end = new Date(data.details.endDate);
      if (!isNaN(start.getTime()) && !isNaN(end.getTime()) && end < start) {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          message: 'End date cannot be earlier than start date.',
          path: ['details', 'endDate'],
        });
      }
    }
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
