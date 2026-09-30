import { Router } from 'express';
import { authenticateRequest } from '../../middleware/auth.middleware';
import { requireCollegeScope } from '../../middleware/tenant.middleware';
import { validateBody, validateQuery } from '../../middleware/validate.middleware';
import { uploadRateLimiter } from '../../middleware/rateLimiter.middleware';
import { ProfileController } from '../../controllers/profile.controller';
import {
  updateProfileSchema,
  avatarUploadAuthSchema,
  avatarCompleteSchema,
  directoryQuerySchema,
} from '../../validations/profile.validation';

const router = Router();

// Authentication and Multi-Tenant Isolation boundary
router.use(authenticateRequest);
router.use(requireCollegeScope);

// Authenticated User Profile Endpoints
router.get('/me', ProfileController.getMyProfile);
router.patch('/me', validateBody(updateProfileSchema), ProfileController.updateMyProfile);
router.post(
  '/me/avatar/upload-url',
  uploadRateLimiter,
  validateBody(avatarUploadAuthSchema),
  ProfileController.requestMyAvatarUpload
);
router.post(
  '/me/avatar/complete',
  validateBody(avatarCompleteSchema),
  ProfileController.completeMyAvatarUpload
);

// Scoped Directory
router.get('/directory', validateQuery(directoryQuerySchema), ProfileController.getDirectory);

// Scoped User Profile Lookup by ID
router.get('/:id', ProfileController.getProfileById);
router.patch('/:id', validateBody(updateProfileSchema), ProfileController.updateProfileById);
router.post(
  '/:id/avatar/upload-url',
  uploadRateLimiter,
  validateBody(avatarUploadAuthSchema),
  ProfileController.requestAvatarUploadById
);
router.post(
  '/:id/avatar/complete',
  validateBody(avatarCompleteSchema),
  ProfileController.completeAvatarUploadById
);

export const profileRouter = router;
