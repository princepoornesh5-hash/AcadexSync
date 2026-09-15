import { z } from 'zod';

export const departmentAnalyticsQuerySchema = z
  .object({
    collegeId: z.string().optional(),
    departmentId: z.string().optional(),
    courseId: z.string().optional(),
    academicYearId: z.string().optional(),
    semesterId: z.string().optional(),
    sectionId: z.string().optional(),
    subjectId: z.string().optional(),
    studentId: z.string().optional(),
    startDate: z
      .string()
      .datetime()
      .optional()
      .or(z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional()),
    endDate: z
      .string()
      .datetime()
      .optional()
      .or(z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional()),
    atRiskThreshold: z.coerce.number().min(0).max(100).optional(),
    atRiskOnly: z
      .enum(['true', 'false'])
      .transform((v) => v === 'true')
      .optional(),
    search: z.string().optional(),
    page: z.coerce.number().min(1).default(1),
    limit: z.coerce.number().min(1).max(200).default(50),
    interval: z.enum(['daily', 'weekly']).default('daily'),
  })
  .refine(
    (data) => {
      if (data.startDate && data.endDate) {
        return new Date(data.startDate) <= new Date(data.endDate);
      }
      return true;
    },
    { message: 'startDate must be before or equal to endDate', path: ['startDate'] }
  );

export type DepartmentAnalyticsQueryInput = z.infer<typeof departmentAnalyticsQuerySchema>;
