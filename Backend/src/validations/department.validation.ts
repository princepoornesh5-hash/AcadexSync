import { z } from 'zod';
import { DepartmentStatus } from '../constants/status';

export const createDepartmentSchema = z.object({
  collegeId: z.string().optional(),
  name: z.string().trim().min(2, 'Department name must be at least 2 characters').max(100),
  code: z
    .string()
    .trim()
    .min(2, 'Department code must be at least 2 characters')
    .max(20)
    .regex(/^[A-Za-z0-9\-_]+$/, 'Department code may only contain alphanumeric characters, hyphens, and underscores')
    .transform((val) => val.toUpperCase()),
  description: z.string().trim().max(500).optional().default(''),
  status: z.nativeEnum(DepartmentStatus).optional().default(DepartmentStatus.ACTIVE),
  metadata: z.record(z.unknown()).optional(),
});

export const updateDepartmentSchema = z.object({
  name: z.string().trim().min(2).max(100).optional(),
  code: z
    .string()
    .trim()
    .min(2)
    .max(20)
    .regex(/^[A-Za-z0-9\-_]+$/, 'Department code may only contain alphanumeric characters, hyphens, and underscores')
    .transform((val) => val.toUpperCase())
    .optional(),
  description: z.string().trim().max(500).optional(),
  metadata: z.record(z.unknown()).optional(),
});

export const updateDepartmentStatusSchema = z.object({
  status: z.nativeEnum(DepartmentStatus),
});

export const departmentQuerySchema = z.object({
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
  status: z.nativeEnum(DepartmentStatus).optional(),
  sortBy: z.enum(['name', 'code', 'status', 'createdAt', 'updatedAt']).optional().default('name'),
  sortOrder: z.enum(['asc', 'desc']).optional().default('asc'),
});
