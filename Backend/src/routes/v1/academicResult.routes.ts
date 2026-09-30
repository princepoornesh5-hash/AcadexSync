import { Router } from 'express';
import { AcademicResultController } from '../../controllers/academicResult.controller';
import { authenticateRequest } from '../../middleware/auth.middleware';
import { requireRoles } from '../../middleware/role.middleware';
import { requireCollegeScope } from '../../middleware/tenant.middleware';
import { validateBody, validateQuery } from '../../middleware/validate.middleware';
import { AppRole } from '../../constants/roles';
import {
  createAcademicRuleConfigSchema,
  calculateSemesterResultSchema,
  calculateClassResultsSchema,
  reviewResultSchema,
  finalizeResultSchema,
  publishResultSchema,
  reopenResultSchema,
  queryResultsSchema,
} from '../../validations/academicResult.validation';

const router = Router();

// Authentication and tenant boundaries
router.use(authenticateRequest);
router.use(requireCollegeScope);

// Student Endpoint: View Own Official Published Result
router.get(
  '/student/my-result',
  requireRoles(AppRole.STUDENT),
  AcademicResultController.getStudentOfficialResult
);

// Rules Configuration Endpoints
router.get(
  '/rules',
  requireRoles(AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN, AppRole.HOD, AppRole.FACULTY),
  AcademicResultController.getRuleConfig
);

router.post(
  '/rules',
  requireRoles(AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN),
  validateBody(createAcademicRuleConfigSchema),
  AcademicResultController.saveRuleConfig
);

// Result Calculation Endpoints
router.post(
  '/calculate',
  requireRoles(AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN, AppRole.HOD),
  validateBody(calculateSemesterResultSchema),
  AcademicResultController.calculateSemesterResult
);

router.post(
  '/calculate/class',
  requireRoles(AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN, AppRole.HOD),
  validateBody(calculateClassResultsSchema),
  AcademicResultController.calculateClassResults
);

// Lifecycle Transitions
router.post(
  '/:id/review',
  requireRoles(AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN, AppRole.HOD),
  validateBody(reviewResultSchema),
  AcademicResultController.reviewResult
);

router.post(
  '/:id/finalize',
  requireRoles(AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN, AppRole.HOD),
  validateBody(finalizeResultSchema),
  AcademicResultController.finalizeResult
);

router.post(
  '/:id/publish',
  requireRoles(AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN, AppRole.HOD),
  validateBody(publishResultSchema),
  AcademicResultController.publishResult
);

router.post(
  '/:id/reopen',
  requireRoles(AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN, AppRole.HOD),
  validateBody(reopenResultSchema),
  AcademicResultController.reopenResult
);

// Query & Admin Inspection Endpoints
router.get(
  '/',
  requireRoles(AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN, AppRole.HOD),
  validateQuery(queryResultsSchema),
  AcademicResultController.queryAdminResults
);

router.get(
  '/:id',
  requireRoles(AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN, AppRole.HOD),
  AcademicResultController.getResultDetail
);

export default router;
