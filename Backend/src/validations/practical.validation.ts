import { z } from 'zod';
import { PracticalParticipationStatus } from '../constants/practical.constants';

const objectIdRegex = /^[0-9a-fA-F]{24}$/;
const objectIdSchema = z.string().regex(objectIdRegex, 'Invalid ObjectId format');

export const practicalValidation = {
  createDefinition: z.object({
    body: z.object({
      subjectId: objectIdSchema,
      courseId: objectIdSchema,
      academicYearId: objectIdSchema,
      semesterId: objectIdSchema,
      sectionId: objectIdSchema.nullable().optional(),
      departmentId: objectIdSchema,
      title: z.string().trim().min(2, 'Title must be at least 2 characters').max(200),
      code: z.string().trim().max(50).nullable().optional(),
      description: z.string().trim().max(1000).nullable().optional(),
      plannedSessions: z.number().int().min(1).max(100).optional(),
    }),
  }),

  createSession: z.object({
    body: z.object({
      facultyAssignmentId: objectIdSchema,
      topic: z.string().trim().min(2, 'Topic must be at least 2 characters').max(250),
      instructions: z.string().trim().max(2000).nullable().optional(),
      scheduledDate: z.string().refine((val) => !isNaN(Date.parse(val)), {
        message: 'Invalid scheduledDate format',
      }),
      startTime: z.string().trim().max(20).nullable().optional(),
      endTime: z.string().trim().max(20).nullable().optional(),
      roomId: objectIdSchema.nullable().optional(),
      timetableEntryId: z.string().trim().nullable().optional(),
      sessionNumber: z.number().int().min(1).optional(),
      practicalDefinitionId: objectIdSchema.nullable().optional(),
    }),
  }),

  updateParticipation: z.object({
    body: z.object({
      status: z.nativeEnum(PracticalParticipationStatus),
      notes: z.string().trim().max(500).nullable().optional(),
    }),
  }),

  bulkUpdateParticipation: z.object({
    body: z.object({
      updates: z
        .array(
          z.object({
            studentId: objectIdSchema,
            status: z.nativeEnum(PracticalParticipationStatus),
            notes: z.string().trim().max(500).nullable().optional(),
          })
        )
        .min(1, 'At least one student update must be provided'),
    }),
  }),

  cancelSession: z.object({
    body: z.object({
      reason: z.string().trim().max(500).optional(),
    }),
  }),
};
