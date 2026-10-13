import { Router, Request, Response, NextFunction } from 'express';
import { NotificationController } from '../../controllers/notification.controller';
import { authenticateToken } from '../../middleware/auth.middleware';
import { validateBody, validateQuery } from '../../middleware/validate.middleware';
import { deviceTokenRateLimiter } from '../../middleware/rateLimiter.middleware';
import {
  registerDeviceTokenSchema,
  updateNotificationPreferencesSchema,
  notificationQuerySchema,
} from '../../validations/notification.validation';
import { asyncHandler } from '../../utils/asyncHandler';
import { ApiError } from '../../utils/apiError';
import { AppRole } from '../../constants/roles';
import { WorkspaceMembership } from '../../models/workspaceMembership.model';
import { MembershipStatus } from '../../constants/status';

const router = Router();

router.use(authenticateToken);

/**
 * Workspace-aware notification tenant guard:
 * Ensures all notification operations are strictly bound to the authenticated user.
 * If an explicit institutional collegeId filter is provided, verifies that the user
 * holds an active membership in that college (or is Super Admin), preventing cross-tenant enumeration.
 */
const requireNotificationScope = async (
  req: Request,
  _res: Response,
  next: NextFunction
): Promise<void> => {
  if (!req.user) {
    return next(ApiError.unauthorized('User authentication required for notification access'));
  }

  // Super Admin has unrestricted platform access
  if (req.user.role === AppRole.SUPER_ADMIN || req.user.isSuperAdmin) {
    return next();
  }

  const requestedCollegeId = req.query.collegeId as string | undefined;
  if (
    requestedCollegeId &&
    requestedCollegeId !== 'global' &&
    requestedCollegeId !== req.user.collegeId
  ) {
    // Verify membership in requested college
    const membership = await WorkspaceMembership.findOne({
      userId: req.user.id,
      collegeId: requestedCollegeId,
      status: MembershipStatus.ACTIVE,
    });

    if (!membership) {
      return next(
        ApiError.forbidden(
          'Cross-college tenant access is strictly prohibited. You do not hold an active membership in the specified college.'
        )
      );
    }
  }

  return next();
};

router.use(asyncHandler(requireNotificationScope));

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
router.patch('/mark-all-read', asyncHandler(NotificationController.markAllAsRead));
router.post('/mark-all-read', asyncHandler(NotificationController.markAllAsRead));

// 5. Individual Notification Lifecycle
router.patch('/:id/read', asyncHandler(NotificationController.markAsRead));
router.post('/:id/read', asyncHandler(NotificationController.markAsRead));
router.patch('/:id/unread', asyncHandler(NotificationController.markAsUnread));
router.post('/:id/unread', asyncHandler(NotificationController.markAsUnread));
router.patch('/:id/archive', asyncHandler(NotificationController.archive));
router.post('/:id/archive', asyncHandler(NotificationController.archive));
router.delete('/:id', asyncHandler(NotificationController.delete));
router.get('/:id', asyncHandler(NotificationController.getById));

// 6. List Notifications
router.get(
  '/',
  validateQuery(notificationQuerySchema),
  asyncHandler(NotificationController.listNotifications)
);

export const notificationRouter = router;
