import { z } from 'zod';
import { CollegeStatus } from '../constants/status';

export const createCollegeSchema = z.object({
  name: z.string().trim().min(2, 'College name must be at least 2 characters').max(200),
  code: z
    .string()
    .trim()
    .min(2, 'College code must be at least 2 characters')
    .max(20)
    .regex(/^[A-Za-z0-9\-_]+$/, 'College code may only contain alphanumeric characters, hyphens, and underscores')
    .transform((val) => val.toUpperCase()),
  address: z.string().trim().min(5, 'Address must be at least 5 characters'),
  email: z.string().trim().toLowerCase().email('Invalid email address format'),
  phone: z.string().trim().min(7, 'Phone number must be at least 7 digits').max(20),
  principal: z.string().trim().min(2, 'Principal name must be at least 2 characters'),
  status: z.nativeEnum(CollegeStatus).optional().default(CollegeStatus.ACTIVE),
  logoUrl: z.string().url().optional().nullable(),
  metadata: z.record(z.unknown()).optional(),
});

export const updateCollegeSchema = z.object({
  name: z.string().trim().min(2).max(200).optional(),
  code: z
    .string()
    .trim()
    .min(2)
    .max(20)
    .regex(/^[A-Za-z0-9\-_]+$/, 'College code may only contain alphanumeric characters, hyphens, and underscores')
    .transform((val) => val.toUpperCase())
    .optional(),
  address: z.string().trim().min(5).optional(),
  email: z.string().trim().toLowerCase().email().optional(),
  phone: z.string().trim().min(7).max(20).optional(),
  principal: z.string().trim().min(2).optional(),
  logoUrl: z.string().url().optional().nullable(),
  metadata: z.record(z.unknown()).optional(),
});

export const updateCollegeStatusSchema = z.object({
  status: z.nativeEnum(CollegeStatus),
});

export const collegeQuerySchema = z.object({
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
  status: z.nativeEnum(CollegeStatus).optional(),
  sortBy: z.enum(['name', 'code', 'status', 'createdAt', 'updatedAt']).optional().default('name'),
  sortOrder: z.enum(['asc', 'desc']).optional().default('asc'),
});
