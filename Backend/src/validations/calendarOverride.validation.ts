import { z } from 'zod';
import { CalendarOverrideType, CalendarOverrideScope } from '../models/calendarOverride.model';

export const createCalendarOverrideSchema = z.object({
  collegeId: z.string().optional(),
  departmentId: z.string().optional().nullable(),
  sectionId: z.string().optional().nullable(),
  timetableId: z.string().optional().nullable(),
  timetableEntryId: z.string().optional().nullable(),
  date: z
    .string()
    .trim()
    .regex(/^\d{4}-\d{2}-\d{2}$/, 'Date must be in YYYY-MM-DD format'),
  type: z.nativeEnum(CalendarOverrideType),
  scope: z.nativeEnum(CalendarOverrideScope).optional(),
  reason: z.string().trim().min(2, 'Reason must be at least 2 characters').max(500),
});

export const calendarOverrideQuerySchema = z.object({
  page: z.string().optional().transform((v) => (v ? parseInt(v, 10) : 1)).pipe(z.number().positive().default(1)),
  limit: z.string().optional().transform((v) => (v ? parseInt(v, 10) : 20)).pipe(z.number().positive().max(100).default(20)),
  collegeId: z.string().optional(),
  departmentId: z.string().optional(),
  date: z.string().optional(),
  from: z.string().optional(),
  to: z.string().optional(),
  type: z.nativeEnum(CalendarOverrideType).optional(),
});
