import { z } from 'zod';
import {
  AcademicCalendarStatus,
  CalendarEventType,
  CalendarEventScope,
  CalendarEventStatus,
  CalendarRecurrence,
} from '../constants/calendar.constants';

const dateRegex = /^\d{4}-\d{2}-\d{2}$/;
const timeRegex = /^([01]\d|2[0-3]):[0-5]\d$/;

export const createCalendarEventSchema = z.object({
  title: z.string().trim().min(2, 'Title must be at least 2 characters').max(150),
  description: z.string().trim().max(2000).optional().default(''),
  eventType: z.nativeEnum(CalendarEventType, {
    errorMap: () => ({ message: 'Please select a valid event type' }),
  }),
  scope: z.nativeEnum(CalendarEventScope).optional(),
  startDate: z.string().regex(dateRegex, 'startDate must be in YYYY-MM-DD format'),
  endDate: z.string().regex(dateRegex, 'endDate must be in YYYY-MM-DD format').optional(),
  startTime: z.string().regex(timeRegex, 'startTime must be in HH:mm format').nullable().optional(),
  endTime: z.string().regex(timeRegex, 'endTime must be in HH:mm format').nullable().optional(),
  allDay: z.boolean().optional().default(false),
  academicCalendarId: z.string().nullable().optional(),
  departmentId: z.string().nullable().optional(),
  courseId: z.string().nullable().optional(),
  academicYearId: z.string().nullable().optional(),
  semesterId: z.string().nullable().optional(),
  sectionId: z.string().nullable().optional(),
  subjectId: z.string().nullable().optional(),
  facultyAssignmentId: z.string().nullable().optional(),
  location: z.string().max(100).nullable().optional(),
  isRecurring: z.boolean().optional().default(false),
  recurrence: z.nativeEnum(CalendarRecurrence).optional().default(CalendarRecurrence.NONE),
  status: z.nativeEnum(CalendarEventStatus).optional().default(CalendarEventStatus.PUBLISHED),
});

export const updateCalendarEventSchema = z.object({
  title: z.string().trim().min(2).max(150).optional(),
  description: z.string().trim().max(2000).optional(),
  eventType: z.nativeEnum(CalendarEventType).optional(),
  scope: z.nativeEnum(CalendarEventScope).optional(),
  startDate: z.string().regex(dateRegex).optional(),
  endDate: z.string().regex(dateRegex).optional(),
  startTime: z.string().regex(timeRegex).nullable().optional(),
  endTime: z.string().regex(timeRegex).nullable().optional(),
  allDay: z.boolean().optional(),
  academicCalendarId: z.string().nullable().optional(),
  departmentId: z.string().nullable().optional(),
  courseId: z.string().nullable().optional(),
  academicYearId: z.string().nullable().optional(),
  semesterId: z.string().nullable().optional(),
  sectionId: z.string().nullable().optional(),
  subjectId: z.string().nullable().optional(),
  facultyAssignmentId: z.string().nullable().optional(),
  location: z.string().max(100).nullable().optional(),
  isRecurring: z.boolean().optional(),
  recurrence: z.nativeEnum(CalendarRecurrence).optional(),
  status: z.nativeEnum(CalendarEventStatus).optional(),
});

export const createAcademicCalendarSchema = z.object({
  academicYearId: z.string().min(1, 'academicYearId is required'),
  courseId: z.string().nullable().optional(),
  departmentId: z.string().nullable().optional(),
  semesterId: z.string().nullable().optional(),
  title: z.string().trim().min(2, 'Title must be at least 2 characters').max(150),
  description: z.string().trim().max(2000).optional().default(''),
  startDate: z.string().regex(dateRegex, 'startDate must be in YYYY-MM-DD format'),
  endDate: z.string().regex(dateRegex, 'endDate must be in YYYY-MM-DD format'),
  status: z.nativeEnum(AcademicCalendarStatus).optional().default(AcademicCalendarStatus.DRAFT),
  workingDays: z.array(z.number().min(1).max(7)).optional().default([1, 2, 3, 4, 5]),
  holidays: z
    .array(
      z.object({
        date: z.string().regex(dateRegex),
        name: z.string().trim().min(1),
        description: z.string().optional().default(''),
        isFullDay: z.boolean().optional().default(true),
      })
    )
    .optional()
    .default([]),
});

export const updateAcademicCalendarSchema = z.object({
  title: z.string().trim().min(2).max(150).optional(),
  description: z.string().trim().max(2000).optional(),
  startDate: z.string().regex(dateRegex).optional(),
  endDate: z.string().regex(dateRegex).optional(),
  status: z.nativeEnum(AcademicCalendarStatus).optional(),
  workingDays: z.array(z.number().min(1).max(7)).optional(),
  holidays: z
    .array(
      z.object({
        date: z.string().regex(dateRegex),
        name: z.string().trim().min(1),
        description: z.string().optional().default(''),
        isFullDay: z.boolean().optional().default(true),
      })
    )
    .optional(),
});

export const declareHolidaySchema = z.object({
  date: z.string().regex(dateRegex, 'date must be in YYYY-MM-DD format'),
  name: z.string().trim().min(2, 'Name must be at least 2 characters').max(150),
  description: z.string().trim().max(1000).optional().default(''),
  scope: z.nativeEnum(CalendarEventScope).optional().default(CalendarEventScope.COLLEGE),
  departmentId: z.string().nullable().optional(),
});

export const workingDayQuerySchema = z.object({
  date: z.string().regex(dateRegex, 'date must be in YYYY-MM-DD format'),
  departmentId: z.string().optional(),
  courseId: z.string().optional(),
});
