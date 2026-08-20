import { z } from 'zod';
import { AccountStatus } from '../constants/status';

export const provisionHodSchema = z.object({
  departmentId: z.string().min(1, 'departmentId is required'),
  name: z.string().trim().min(2, 'Name must be at least 2 characters').max(100),
  instituteId: z.string().trim().min(2, 'instituteId must be at least 2 characters').max(50).toUpperCase(),
  email: z.string().trim().email('Invalid email address').toLowerCase(),
  phone: z.string().trim().optional(),
});

export const updateHodProfileSchema = z.object({
  name: z.string().trim().min(2).max(100).optional(),
  email: z.string().trim().email().toLowerCase().optional(),
  phone: z.string().trim().optional(),
  profilePictureUrl: z.string().trim().url().optional(),
});

export const transferHodDepartmentSchema = z.object({
  departmentId: z.string().min(1, 'departmentId is required'),
});

export const hodQuerySchema = z.object({
  page: z
    .string()
    .optional()
    .transform((val) => (val ? parseInt(val, 10) : 1))
    .pipe(z.number().positive().default(1)),
  limit: z
    .string()
    .optional()
    .transform((val) => (val ? parseInt(val, 10) : 20))
    .pipe(z.number().positive().max(100).default(20)),
  search: z.string().optional(),
  collegeId: z.string().optional(),
  departmentId: z.string().optional(),
  status: z.nativeEnum(AccountStatus).optional(),
  sortBy: z.enum(['name', 'instituteId', 'createdAt']).optional().default('name'),
  sortOrder: z.enum(['asc', 'desc']).optional().default('asc'),
});
