import { Router } from 'express';
import { CollegeController } from '../../controllers/college.controller';
import { authenticateRequest } from '../../middleware/auth.middleware';
import { requireSuperAdmin } from '../../middleware/role.middleware';

const router = Router();

// Public / Scoped List & Retrieval
router.get('/', authenticateRequest, CollegeController.list);
router.get('/:id', authenticateRequest, CollegeController.getById);
router.get('/:id/admins', authenticateRequest, CollegeController.getAdmins);
router.get('/:id/summary', authenticateRequest, CollegeController.getSummary);

// Super Admin Management Operations
router.post('/', authenticateRequest, requireSuperAdmin, CollegeController.create);
router.put('/:id', authenticateRequest, requireSuperAdmin, CollegeController.update);
router.patch('/:id/status', authenticateRequest, requireSuperAdmin, CollegeController.updateStatus);
router.post('/:id/admins', authenticateRequest, requireSuperAdmin, CollegeController.provisionAdmin);

export const collegeRouter = router;
