import { Router } from 'express';
import { NotificationController } from '../../controllers/notification.controller';
import { authenticateToken } from '../../middleware/auth.middleware';
import { requireCollegeScope } from '../../middleware/tenant.middleware';
import { validateBody, validateQuery } from '../../middleware/validate.middleware';
import { deviceTokenRateLimiter } from '../../middleware/rateLimiter.middleware';
import {
  registerDeviceTokenSchema,
  updateNotificationPreferencesSchema,
  notificationQuerySchema,
} from '../../validations/notification.validation';
import { asyncHandler } from '../../utils/asyncHandler';

const router = Router();

router.use(authenticateToken);
router.use(requireCollegeScope);

// 1. Unread Count
router.get('/unread-count', asyncHandler(NotificationController.getUnreadCount));

// 2. Preferences
router.get('/preferences', asyncHandler(NotificationController.getPreferences));
router.put(
  '/preferences',
  validateBody(updateNotificationPreferencesSchema),
  asyncHandler(NotificationController.updatePreferences)
);

// 3. Device Tokens
router.post(
  '/device-tokens',
  deviceTokenRateLimiter,
  validateBody(registerDeviceTokenSchema),
  asyncHandler(NotificationController.registerDeviceToken)
);
router.post(
  '/device-token',
  deviceTokenRateLimiter,
  validateBody(registerDeviceTokenSchema),
  asyncHandler(NotificationController.registerDeviceToken)
);
router.delete(
  '/device-tokens/:token',
  deviceTokenRateLimiter,
  asyncHandler(NotificationController.removeDeviceToken)
);
router.delete(
  '/device-token/:token',
  deviceTokenRateLimiter,
  asyncHandler(NotificationController.removeDeviceToken)
);

// 4. Batch Mark Read
router.patch('/read-all', asyncHandler(NotificationController.markAllAsRead));
router.post('/read-all', asyncHandler(NotificationController.markAllAsRead));

// 5. Individual Notification
router.patch('/:id/read', asyncHandler(NotificationController.markAsRead));
router.post('/:id/read', asyncHandler(NotificationController.markAsRead));
router.get('/:id', asyncHandler(NotificationController.getById));

// 6. List Notifications
router.get(
  '/',
  validateQuery(notificationQuerySchema),
  asyncHandler(NotificationController.listNotifications)
);

export const notificationRouter = router;
