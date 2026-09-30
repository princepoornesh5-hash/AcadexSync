import { Router } from 'express';
import { authenticateRequest } from '../../middleware/auth.middleware';
import { requireCollegeScope } from '../../middleware/tenant.middleware';
import { validateQuery } from '../../middleware/validate.middleware';
import { DashboardController } from '../../controllers/dashboard.controller';
import { homeDashboardQuerySchema } from '../../validations/dashboard.validation';

const router = Router();

// Multi-tenant boundary & user authentication
router.use(authenticateRequest);
router.use(requireCollegeScope);

// GET /api/v1/dashboard/home - Role-aware operational home summary
router.get('/home', validateQuery(homeDashboardQuerySchema), DashboardController.getHomeDashboard);

export const dashboardRouter = router;
