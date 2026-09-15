import { Router } from 'express';
import { DepartmentAnalyticsController } from '../../controllers/departmentAnalytics.controller';
import { authenticateToken } from '../../middleware/auth.middleware';
import { requireCollegeScope } from '../../middleware/tenant.middleware';
import { requireHodOrAbove } from '../../middleware/role.middleware';
import { asyncHandler } from '../../utils/asyncHandler';

const router = Router();

// Base middleware for all analytics endpoints
router.use(authenticateToken);
router.use(requireCollegeScope);
router.use(requireHodOrAbove);

// Department Analytics Endpoints
router.get('/department/overview', asyncHandler(DepartmentAnalyticsController.getOverview));
router.get('/department/courses', asyncHandler(DepartmentAnalyticsController.getCourses));
router.get('/department/sections', asyncHandler(DepartmentAnalyticsController.getSections));
router.get('/department/subjects', asyncHandler(DepartmentAnalyticsController.getSubjects));
router.get('/department/students', asyncHandler(DepartmentAnalyticsController.getStudents));
router.get('/department/trends', asyncHandler(DepartmentAnalyticsController.getTrends));

export const analyticsRouter = router;
