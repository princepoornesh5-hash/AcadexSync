import { z } from 'zod';
import { AttendanceStatus, AttendanceSessionStatus } from '../constants/status';

export const attendanceRecordItemInputSchema = z.object({
  studentId: z.string().min(1, 'studentId is required'),
  status: z.nativeEnum(AttendanceStatus).default(AttendanceStatus.PRESENT),
  remarks: z.string().trim().max(255).optional(),
});

export const createAttendanceSessionSchema = z.object({
  timetableId: z.string().optional(),
  timetableEntryId: z.string().optional(),
  departmentId: z.string().optional(),
  courseId: z.string().optional(),
  academicYearId: z.string().optional(),
  semesterId: z.string().optional(),
  sectionId: z.string().optional(),
  sectionName: z.string().optional(),
  subjectId: z.string().optional(),
  subjectName: z.string().optional(),
  facultyId: z.string().optional(),
  timeSlot: z.string().min(1, 'timeSlot is required'),
  date: z.string().or(z.date()).transform((val) => new Date(val)),
  roomNumber: z.string().optional(),
  building: z.string().optional(),
  records: z.array(attendanceRecordItemInputSchema).optional().default([]),
});

export const submitAttendanceRecordsSchema = z.object({
  records: z.array(attendanceRecordItemInputSchema).min(1, 'At least one student record is required'),
});

export const correctAttendanceRecordSchema = z.object({
  newStatus: z.nativeEnum(AttendanceStatus),
  reason: z.string().trim().min(3, 'Reason must be at least 3 characters').max(500),
});

export const attendanceQuerySchema = z.object({
  page: z.string().optional().transform((v) => (v ? parseInt(v, 10) : 1)).pipe(z.number().positive().default(1)),
  limit: z.string().optional().transform((v) => (v ? parseInt(v, 10) : 20)).pipe(z.number().positive().max(100).default(20)),
  collegeId: z.string().optional(),
  departmentId: z.string().optional(),
  courseId: z.string().optional(),
  academicYearId: z.string().optional(),
  semesterId: z.string().optional(),
  sectionId: z.string().optional(),
  subjectId: z.string().optional(),
  facultyId: z.string().optional(),
  studentId: z.string().optional(),
  from: z.string().optional().transform((v) => (v ? new Date(v) : undefined)),
  to: z.string().optional().transform((v) => (v ? new Date(v) : undefined)),
  status: z.nativeEnum(AttendanceSessionStatus).optional(),
});

export const attendanceAnalyticsQuerySchema = z.object({
  collegeId: z.string().optional(),
  departmentId: z.string().optional(),
  courseId: z.string().optional(),
  academicYearId: z.string().optional(),
  semesterId: z.string().optional(),
  sectionId: z.string().optional(),
  subjectId: z.string().optional(),
  facultyId: z.string().optional(),
  from: z.string().optional().transform((v) => (v ? new Date(v) : undefined)),
  to: z.string().optional().transform((v) => (v ? new Date(v) : undefined)),
  threshold: z.string().optional().transform((v) => (v ? parseFloat(v) : 75)).pipe(z.number().min(0).max(100).default(75)),
});
