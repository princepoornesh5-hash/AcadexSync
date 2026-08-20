import { z } from 'zod';
import { AccountStatus } from '../constants/status';

export const provisionStudentSchema = z.object({
  departmentId: z.string().min(1, 'departmentId is required'),
  name: z.string().trim().min(2, 'Name must be at least 2 characters').max(100),
  instituteId: z.string().trim().min(2, 'instituteId must be at least 2 characters').max(50).toUpperCase(),
  email: z.string().trim().email('Invalid email address').toLowerCase().optional(),
  phone: z.string().trim().optional(),
  rollNumber: z.string().trim().min(1).max(50).optional(),
  admissionNumber: z.string().trim().min(1).max(50).optional(),
  parentName: z.string().trim().max(100).optional(),
  parentPhone: z.string().trim().max(30).optional(),
  bloodGroup: z.string().trim().max(10).optional(),
  address: z.string().trim().max(255).optional(),
  dateOfBirth: z.string().datetime().optional(),
  admissionDate: z.string().datetime().optional(),
  metadata: z.record(z.unknown()).optional(),
});

export const updateStudentProfileSchema = z.object({
  name: z.string().trim().min(2).max(100).optional(),
  email: z.string().trim().email('Invalid email address').toLowerCase().optional(),
  phone: z.string().trim().optional(),
  rollNumber: z.string().trim().min(1).max(50).optional(),
  admissionNumber: z.string().trim().min(1).max(50).optional(),
  parentName: z.string().trim().max(100).optional(),
  parentPhone: z.string().trim().max(30).optional(),
  bloodGroup: z.string().trim().max(10).optional(),
  address: z.string().trim().max(255).optional(),
  dateOfBirth: z.string().datetime().optional(),
  admissionDate: z.string().datetime().optional(),
  profilePictureUrl: z.string().trim().url().optional(),
  metadata: z.record(z.unknown()).optional(),
});

export const correctStudentInstituteIdSchema = z.object({
  instituteId: z.string().trim().min(2, 'instituteId must be at least 2 characters').max(50).toUpperCase(),
});

export const transferStudentDepartmentSchema = z.object({
  departmentId: z.string().min(1, 'departmentId is required'),
});

export const createPhoneRequestSchema = z.object({
  requestedPhone: z.string().trim().min(5, 'Requested phone number must be at least 5 digits'),
  notes: z.string().trim().max(255).optional(),
});

export const resolvePhoneRequestSchema = z.object({
  status: z.enum(['APPROVED', 'REJECTED']),
  rejectionReason: z.string().trim().max(255).optional(),
  notes: z.string().trim().max(255).optional(),
});

export const studentQuerySchema = z.object({
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
  sortBy: z.enum(['name', 'instituteId', 'rollNumber', 'createdAt']).optional().default('name'),
  sortOrder: z.enum(['asc', 'desc']).optional().default('asc'),
});

export const contactRequestQuerySchema = z.object({
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
  departmentId: z.string().optional(),
  status: z.enum(['PENDING', 'APPROVED', 'REJECTED', 'CANCELLED']).optional(),
});
