import { z } from 'zod';

export const provisionFacultySchema = z.object({
  departmentId: z.string().min(1, 'departmentId is required'),
  name: z.string().trim().min(2, 'Name must be at least 2 characters').max(100),
  instituteId: z.string().trim().min(2, 'instituteId must be at least 2 characters').max(50).toUpperCase(),
  email: z.string().trim().email('Invalid email address').toLowerCase(),
  phone: z.string().trim().optional(),
  employeeId: z.string().trim().min(1).max(50).optional(),
  designation: z.string().trim().max(100).optional().default('Assistant Professor'),
  qualification: z.string().trim().max(100).optional().default(''),
  specialization: z.string().trim().max(100).optional().default(''),
  joiningDate: z.string().datetime().optional(),
  metadata: z.record(z.unknown()).optional(),
});

export const updateFacultyProfileSchema = z.object({
  name: z.string().trim().min(2).max(100).optional(),
  email: z.string().trim().email().toLowerCase().optional(),
  phone: z.string().trim().optional(),
  employeeId: z.string().trim().min(1).max(50).optional(),
  designation: z.string().trim().max(100).optional(),
  qualification: z.string().trim().max(100).optional(),
  specialization: z.string().trim().max(100).optional(),
  profilePictureUrl: z.string().trim().url().optional(),
  metadata: z.record(z.unknown()).optional(),
});

export const transferFacultyDepartmentSchema = z.object({
  departmentId: z.string().min(1, 'departmentId is required'),
});

export const facultyQuerySchema = z.object({
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
  status: z.string().optional(),
  sortBy: z.enum(['name', 'instituteId', 'employeeId', 'createdAt']).optional().default('name'),
  sortOrder: z.enum(['asc', 'desc']).optional().default('asc'),
});
