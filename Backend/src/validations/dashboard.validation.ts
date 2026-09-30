import { z } from 'zod';

export const homeDashboardQuerySchema = z.object({
  date: z
    .string()
    .regex(/^\d{4}-\d{2}-\d{2}$/, 'Date must be formatted as YYYY-MM-DD')
    .optional(),
  refresh: z
    .string()
    .transform((val) => val === 'true' || val === '1')
    .optional(),
  limit: z
    .string()
    .regex(/^\d+$/)
    .transform(Number)
    .pipe(z.number().min(1).max(20))
    .optional(),
});
