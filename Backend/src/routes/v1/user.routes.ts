import { Router } from 'express';
import { UserController } from '../../controllers/user.controller';
import { authenticateRequest } from '../../middleware/auth.middleware';
import { requireCollegeAdmin } from '../../middleware/role.middleware';
import { requireCollegeScope } from '../../middleware/tenant.middleware';
import { uploadRateLimiter } from '../../middleware/rateLimiter.middleware';

const router = Router();

router.use(authenticateRequest);

router.post('/me/profile-image/upload-url', uploadRateLimiter, UserController.requestProfileImageUploadUrl);
router.post('/me/profile-image/complete', UserController.completeProfileImageUpload);
router.post('/:id/profile-image/upload-url', uploadRateLimiter, requireCollegeScope, UserController.requestProfileImageUploadUrl);
router.post('/:id/profile-image/complete', requireCollegeScope, UserController.completeProfileImageUpload);

router.get('/', requireCollegeAdmin, requireCollegeScope, UserController.list);
router.get('/institute/:instituteId', requireCollegeScope, UserController.getByInstituteId);
router.get('/:id', requireCollegeScope, UserController.getById);
router.post('/', requireCollegeAdmin, requireCollegeScope, UserController.create);
router.put('/:id', requireCollegeScope, UserController.update);

export const userRouter = router;
