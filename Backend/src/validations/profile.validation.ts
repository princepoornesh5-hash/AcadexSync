import { z } from 'zod';

export const PROTECTED_PROFILE_FIELDS = [
  'role',
  'collegeId',
  'studentId',
  'facultyId',
  'departmentId',
  'courseId',
  'semesterId',
  'sectionId',
  'academicYearId',
  'rollNumber',
  'employeeId',
  'email',
  'accountStatus',
  'activationStatus',
  'passwordHash',
  'permissions',
  'isSuperAdmin',
  'status',
  'currentEnrollment',
  'assignments',
  'subjectIds',
  'sectionIds',
] as const;

export const updateProfileSchema = z
  .object({
    name: z
      .string()
      .trim()
      .min(2, 'Name must be at least 2 characters')
      .max(100, 'Name cannot exceed 100 characters')
      .optional(),
    phone: z
      .string()
      .trim()
      .min(5, 'Phone must be at least 5 characters')
      .max(20, 'Phone cannot exceed 20 characters')
      .regex(/^[+0-9\s()-]+$/, 'Please enter a valid phone number')
      .optional()
      .nullable(),
    bio: z
      .string()
      .trim()
      .max(500, 'Bio cannot exceed 500 characters')
      .optional()
      .nullable(),
    specialization: z
      .string()
      .trim()
      .max(200, 'Specialization cannot exceed 200 characters')
      .optional()
      .nullable(),
    qualification: z
      .string()
      .trim()
      .max(200, 'Qualification cannot exceed 200 characters')
      .optional()
      .nullable(),
  })
  .passthrough()
  .superRefine((data, ctx) => {
    const rawKeys = Object.keys(data);
    for (const key of rawKeys) {
      if ((PROTECTED_PROFILE_FIELDS as readonly string[]).includes(key)) {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          message: `Protected field '${key}' cannot be modified through the profile endpoint. Academic and identity fields remain authoritative in their respective source modules.`,
          path: [key],
        });
      }
    }
  });

export const avatarUploadAuthSchema = z.object({
  fileName: z.string().trim().min(1, 'File name is required'),
  mimeType: z
    .string()
    .trim()
    .toLowerCase()
    .refine(
      (val) => ['image/jpeg', 'image/png', 'image/webp'].includes(val),
      'Only JPEG, PNG, and WebP images are allowed for profile avatars'
    ),
  fileSize: z
    .number()
    .positive('File size must be positive')
    .max(5 * 1024 * 1024, 'Avatar image size cannot exceed 5MB'),
});

export const avatarCompleteSchema = z.object({
  fileId: z.string().trim().min(1, 'File ID is required'),
  fileUrl: z.string().url().optional(),
});

export const directoryQuerySchema = z.object({
  search: z.string().trim().optional(),
  role: z.enum(['STUDENT', 'FACULTY', 'HOD', 'COLLEGE_ADMIN']).optional(),
  departmentId: z.string().trim().optional(),
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
});
