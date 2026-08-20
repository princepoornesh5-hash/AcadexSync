import { z } from 'zod';
import { DateRangePreset } from '../constants/report.constants';

export const dateRangeQuerySchema = z
  .object({
    preset: z.nativeEnum(DateRangePreset).optional(),
    startDate: z.string().datetime().optional().or(z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional()),
    endDate: z.string().datetime().optional().or(z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional()),
    semesterId: z.string().optional(),
    courseId: z.string().optional(),
    departmentId: z.string().optional(),
    collegeId: z.string().optional(),
    subjectId: z.string().optional(),
    sectionId: z.string().optional(),
    facultyId: z.string().optional(),
    studentId: z.string().optional(),
    page: z.coerce.number().min(1).default(1),
    limit: z.coerce.number().min(1).max(100).default(20),
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

export type DateRangeQueryInput = z.infer<typeof dateRangeQuerySchema>;
