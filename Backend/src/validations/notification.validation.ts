import { z } from 'zod';
import { DevicePlatform, NotificationCategory } from '../constants/notification.constants';

export const registerDeviceTokenSchema = z.object({
  deviceToken: z.string().min(1, 'deviceToken is required'),
  platform: z.nativeEnum(DevicePlatform, {
    errorMap: () => ({ message: 'platform must be android, ios, or web' }),
  }),
  appVersion: z.string().optional(),
});

export const updateNotificationPreferencesSchema = z.object({
  notes: z.boolean().optional(),
  attendance: z.boolean().optional(),
  timetable: z.boolean().optional(),
  pushEnabled: z.boolean().optional(),
});

export const notificationQuerySchema = z.object({
  isRead: z
    .string()
    .optional()
    .transform((val) => {
      if (val === 'true') return true;
      if (val === 'false') return false;
      return undefined;
    }),
  category: z.nativeEnum(NotificationCategory).optional(),
  page: z
    .string()
    .optional()
    .transform((val) => (val ? parseInt(val, 10) : 1)),
  limit: z
    .string()
    .optional()
    .transform((val) => (val ? parseInt(val, 10) : 20)),
});
