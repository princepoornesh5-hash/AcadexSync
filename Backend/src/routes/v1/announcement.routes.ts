import { Router } from 'express';
import { AnnouncementController } from '../../controllers/announcement.controller';
import { authenticateToken } from '../../middleware/auth.middleware';
import { requireCollegeScope } from '../../middleware/tenant.middleware';
import { validateBody, validateQuery } from '../../middleware/validate.middleware';
import {
  createAnnouncementSchema,
  updateAnnouncementSchema,
  announcementQuerySchema,
} from '../../validations/announcement.validation';
import { asyncHandler } from '../../utils/asyncHandler';

const router = Router();

router.use(authenticateToken);
router.use(requireCollegeScope);

// 1. Create Announcement
router.post(
  '/',
  validateBody(createAnnouncementSchema),
  asyncHandler(AnnouncementController.createAnnouncement)
);

// 2. List Announcements (Admin Management or User Feed)
router.get(
  '/',
  validateQuery(announcementQuerySchema),
  asyncHandler(AnnouncementController.listAnnouncements)
);

// 3. Single Announcement Operations
router.get('/:id', asyncHandler(AnnouncementController.getById));
router.put(
  '/:id',
  validateBody(updateAnnouncementSchema),
  asyncHandler(AnnouncementController.updateAnnouncement)
);
router.post('/:id/publish', asyncHandler(AnnouncementController.publishAnnouncement));
router.post('/:id/archive', asyncHandler(AnnouncementController.archiveAnnouncement));
router.delete('/:id', asyncHandler(AnnouncementController.deleteAnnouncement));

export const announcementRouter = router;
