import { z } from 'zod';
import { TeacherSubstitutionStatus } from '../models/teacherSubstitution.model';

const objectIdRegex = /^[0-9a-fA-F]{24}$/;
const dateRegex = /^\d{4}-\d{2}-\d{2}$/;

export const createTeacherSubstitutionSchema = z.object({
  body: z.object({
    timetableId: z.string().regex(objectIdRegex, 'Invalid timetable ID'),
    timetableEntryId: z.string().regex(objectIdRegex, 'Invalid timetable entry ID'),
    date: z.string().regex(dateRegex, 'Date must be formatted as YYYY-MM-DD'),
    substituteFacultyId: z.string().regex(objectIdRegex, 'Invalid substitute faculty ID'),
    originalFacultyId: z.string().regex(objectIdRegex, 'Invalid original faculty ID').optional(),
    reason: z.string().min(1, 'Reason is required').max(500, 'Reason cannot exceed 500 characters'),
  }),
});

export const updateTeacherSubstitutionSchema = z.object({
  params: z.object({
    id: z.string().regex(objectIdRegex, 'Invalid substitution ID'),
  }),
  body: z.object({
    substituteFacultyId: z.string().regex(objectIdRegex, 'Invalid substitute faculty ID').optional(),
    reason: z.string().min(1).max(500).optional(),
    status: z.nativeEnum(TeacherSubstitutionStatus).optional(),
  }),
});

export const queryTeacherSubstitutionSchema = z.object({
  query: z.object({
    date: z.string().regex(dateRegex, 'Date must be formatted as YYYY-MM-DD').optional(),
    timetableId: z.string().regex(objectIdRegex, 'Invalid timetable ID').optional(),
    timetableEntryId: z.string().regex(objectIdRegex, 'Invalid timetable entry ID').optional(),
    departmentId: z.string().regex(objectIdRegex, 'Invalid department ID').optional(),
    facultyId: z.string().regex(objectIdRegex, 'Invalid faculty ID').optional(),
    substituteFacultyId: z.string().regex(objectIdRegex, 'Invalid substitute faculty ID').optional(),
    status: z.nativeEnum(TeacherSubstitutionStatus).optional(),
  }),
});
