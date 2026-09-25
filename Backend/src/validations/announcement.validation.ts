import { z } from 'zod';
import {
  AudienceScope,
  AnnouncementStatus,
  NotificationCategory,
  NotificationPriority,
} from '../constants/notification.constants';
import { AppRole } from '../constants/roles';

export const createAnnouncementSchema = z.object({
  title: z.string().min(2, 'Title must be at least 2 characters').max(200, 'Title cannot exceed 200 characters'),
  body: z.string().min(2, 'Body must be at least 2 characters').max(10000, 'Body cannot exceed 10000 characters'),
  category: z.nativeEnum(NotificationCategory).optional(),
  audienceScope: z.nativeEnum(AudienceScope, {
    errorMap: () => ({ message: 'Valid audienceScope is required (COLLEGE, DEPARTMENT, COURSE, SEMESTER, SECTION, ROLE, INDIVIDUAL)' }),
  }),
  departmentId: z.string().optional().nullable(),
  targetRole: z.nativeEnum(AppRole).optional().nullable(),
  targetCourseId: z.string().optional().nullable(),
  targetSemesterId: z.string().optional().nullable(),
  targetSectionId: z.string().optional().nullable(),
  targetUserId: z.string().optional().nullable(),
  targetUserIds: z.array(z.string()).optional().nullable(),
  status: z.string().optional(),
  publishAt: z.string().datetime().optional().nullable().or(z.date().optional()),
  expiresAt: z.string().datetime().optional().nullable().or(z.date().optional()),
  priority: z.nativeEnum(NotificationPriority).optional(),
  isPinned: z.boolean().optional(),
  publishNow: z.boolean().optional(),
});

export const updateAnnouncementSchema = z.object({
  title: z.string().min(2).max(200).optional(),
  body: z.string().min(2).max(10000).optional(),
  category: z.nativeEnum(NotificationCategory).optional(),
  audienceScope: z.nativeEnum(AudienceScope).optional(),
  departmentId: z.string().optional().nullable(),
  targetRole: z.nativeEnum(AppRole).optional().nullable(),
  targetCourseId: z.string().optional().nullable(),
  targetSemesterId: z.string().optional().nullable(),
  targetSectionId: z.string().optional().nullable(),
  targetUserId: z.string().optional().nullable(),
  targetUserIds: z.array(z.string()).optional().nullable(),
  status: z.string().optional(),
  publishAt: z.string().datetime().optional().nullable().or(z.date().optional()),
  expiresAt: z.string().datetime().optional().nullable().or(z.date().optional()),
  priority: z.nativeEnum(NotificationPriority).optional(),
  isPinned: z.boolean().optional(),
});

export const announcementQuerySchema = z.object({
  status: z.nativeEnum(AnnouncementStatus).optional(),
  audienceScope: z.nativeEnum(AudienceScope).optional(),
  departmentId: z.string().optional(),
  manage: z
    .string()
    .optional()
    .transform((val) => val === 'true'),
  page: z
    .string()
    .optional()
    .transform((val) => (val ? parseInt(val, 10) : 1)),
  limit: z
    .string()
    .optional()
    .transform((val) => (val ? parseInt(val, 10) : 20)),
});
