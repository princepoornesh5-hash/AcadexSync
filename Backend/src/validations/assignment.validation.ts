import { z } from 'zod';
import { AssignmentStatus, AssignmentType } from '../constants/assignment.constants';

export const createAssignmentSchema = z.object({
  facultyAssignmentId: z.string().min(1, 'Teaching context (Faculty Assignment) is required.'),
  title: z
    .string()
    .min(2, 'Assignment Title must be at least 2 characters.')
    .max(200, 'Assignment Title cannot exceed 200 characters.'),
  description: z
    .string()
    .min(2, 'Description must be at least 2 characters.')
    .max(5000, 'Description cannot exceed 5000 characters.'),
  questions: z.array(z.string().min(1)).optional().default([]),
  assignmentType: z
    .nativeEnum(AssignmentType, {
      errorMap: () => ({ message: 'Please select a valid assignment type.' }),
    })
    .optional()
    .default(AssignmentType.HOMEWORK),
  dueDate: z.string().min(1, 'Due date is required.'),
  dueTime: z.string().min(1, 'Due time is required.'),
  maximumMarks: z
    .number({ invalid_type_error: 'Maximum marks must be a number.' })
    .int('Maximum marks must be an integer.')
    .min(1, 'Maximum marks must be greater than 0.'),
  attachments: z
    .array(
      z.object({
        name: z.string().min(1),
        url: z.string().min(1),
        fileType: z.string().optional(),
        fileSize: z.number().optional(),
      })
    )
    .optional()
    .default([]),
  status: z
    .nativeEnum(AssignmentStatus, {
      errorMap: () => ({ message: 'Status must be DRAFT or PUBLISHED.' }),
    })
    .optional()
    .default(AssignmentStatus.DRAFT),
});

export const updateAssignmentStatusSchema = z.object({
  status: z.nativeEnum(AssignmentStatus, {
    errorMap: () => ({ message: 'Status must be DRAFT, PUBLISHED, or CLOSED.' }),
  }),
});

export const recordMarksSchema = z.object({
  marks: z
    .array(
      z.object({
        studentId: z.string().min(1, 'Student ID is required.'),
        marks: z
          .number({ invalid_type_error: 'Marks must be an integer number.' })
          .int('Marks must be an integer.')
          .min(0, 'Negative marks are not allowed.'),
        feedback: z.string().max(500).optional(),
      })
    )
    .min(1, 'At least one student mark must be provided.'),
});
