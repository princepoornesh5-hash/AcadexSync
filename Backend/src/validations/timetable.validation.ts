import { z } from 'zod';
import {
  TimetableDay,
  TimetableStatus,
  TimetableTimingMode,
  TimetableBreakType,
  TimetableSessionType,
} from '../constants/status';

const timeRegex = /^([01]\d|2[0-3]):([0-5]\d)$/;

// Room Schemas
export const createRoomSchema = z.object({
  departmentId: z.string().optional(),
  name: z.string().trim().min(2, 'Name must be at least 2 characters').max(100),
  code: z.string().trim().min(1, 'Code is required').max(30).toUpperCase(),
  capacity: z.number().int().min(1, 'Capacity must be at least 1').max(1000).default(60),
  type: z.enum(['lecture', 'lab', 'seminar', 'other']).optional().default('lecture'),
});

export const updateRoomSchema = z.object({
  name: z.string().trim().min(2).max(100).optional(),
  code: z.string().trim().min(1).max(30).toUpperCase().optional(),
  capacity: z.number().int().min(1).max(1000).optional(),
  type: z.enum(['lecture', 'lab', 'seminar', 'other']).optional(),
  isActive: z.boolean().optional(),
});

export const roomQuerySchema = z.object({
  page: z.string().optional().transform((v) => (v ? parseInt(v, 10) : 1)).pipe(z.number().positive().default(1)),
  limit: z.string().optional().transform((v) => (v ? parseInt(v, 10) : 20)).pipe(z.number().positive().max(100).default(20)),
  collegeId: z.string().optional(),
  departmentId: z.string().optional(),
  type: z.enum(['lecture', 'lab', 'seminar', 'other']).optional(),
  search: z.string().optional(),
});

// Timetable Sub-schemas
export const timetablePeriodSchema = z.object({
  index: z.number().int().min(1),
  name: z.string().trim().min(1),
  startTime: z.string().regex(timeRegex, 'startTime must be in HH:mm format'),
  endTime: z.string().regex(timeRegex, 'endTime must be in HH:mm format'),
  dayOfWeek: z.nativeEnum(TimetableDay).optional(),
}).refine((p) => p.startTime < p.endTime, {
  message: 'startTime must be before endTime',
  path: ['endTime'],
});

export const timetableBreakSchema = z.object({
  name: z.string().trim().min(1),
  startTime: z.string().regex(timeRegex, 'startTime must be in HH:mm format'),
  endTime: z.string().regex(timeRegex, 'endTime must be in HH:mm format'),
  appliesToDays: z.array(z.nativeEnum(TimetableDay)).default([]),
  isVerticalSpan: z.boolean().default(true),
  breakType: z.nativeEnum(TimetableBreakType).default(TimetableBreakType.LUNCH),
}).refine((b) => b.startTime < b.endTime, {
  message: 'startTime must be before endTime',
  path: ['endTime'],
});

export const timetableGridEntrySchema = z.object({
  dayOfWeek: z.nativeEnum(TimetableDay),
  startPeriodIndex: z.number().int().min(1).optional().default(1),
  periodSpan: z.number().int().min(1).default(1),
  startTime: z.string().regex(timeRegex, 'startTime must be in HH:mm format'),
  endTime: z.string().regex(timeRegex, 'endTime must be in HH:mm format'),
  subjectId: z.string().min(1, 'subjectId is required').optional(),
  facultyId: z.string().min(1, 'facultyId is required').optional(),
  facultyAssignmentId: z.string().optional(),
  roomId: z.string().optional(),
  roomNumber: z.string().optional(),
  building: z.string().optional(),
  sessionType: z.nativeEnum(TimetableSessionType).optional().default(TimetableSessionType.LECTURE),
}).refine((e) => e.startTime < e.endTime, {
  message: 'startTime must be before endTime',
  path: ['endTime'],
}).refine((e) => Boolean(e.facultyAssignmentId || (e.subjectId && e.facultyId)), {
  message: 'Either facultyAssignmentId or both subjectId and facultyId must be provided',
  path: ['facultyAssignmentId'],
});

// Timetable Mutation Schemas
export const createTimetableSchema = z.object({
  departmentId: z.string().min(1, 'departmentId is required'),
  courseId: z.string().min(1, 'courseId is required'),
  academicYearId: z.string().min(1, 'academicYearId is required'),
  semesterId: z.string().min(1, 'semesterId is required'),
  sectionId: z.string().min(1, 'sectionId is required'),
  name: z.string().trim().min(2, 'Name must be at least 2 characters').max(100),
  activeDays: z.array(z.nativeEnum(TimetableDay)).optional(),
  timingMode: z.nativeEnum(TimetableTimingMode).optional().default(TimetableTimingMode.SAME_EVERY_DAY),
  periods: z.array(timetablePeriodSchema).optional().default([]),
  breaks: z.array(timetableBreakSchema).optional().default([]),
  entries: z.array(timetableGridEntrySchema).optional().default([]),
});

export const updateTimetableSchema = z.object({
  name: z.string().trim().min(2).max(100).optional(),
  activeDays: z.array(z.nativeEnum(TimetableDay)).optional(),
  timingMode: z.nativeEnum(TimetableTimingMode).optional(),
  periods: z.array(timetablePeriodSchema).optional(),
  breaks: z.array(timetableBreakSchema).optional(),
  entries: z.array(timetableGridEntrySchema).optional(),
  status: z.nativeEnum(TimetableStatus).optional(),
});

export const timetableQuerySchema = z.object({
  page: z.string().optional().transform((v) => (v ? parseInt(v, 10) : 1)).pipe(z.number().positive().default(1)),
  limit: z.string().optional().transform((v) => (v ? parseInt(v, 10) : 20)).pipe(z.number().positive().max(100).default(20)),
  collegeId: z.string().optional(),
  departmentId: z.string().optional(),
  courseId: z.string().optional(),
  academicYearId: z.string().optional(),
  semesterId: z.string().optional(),
  sectionId: z.string().optional(),
  facultyId: z.string().optional(),
  day: z.nativeEnum(TimetableDay).optional(),
  status: z.nativeEnum(TimetableStatus).optional(),
});
