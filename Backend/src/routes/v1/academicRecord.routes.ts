import { Router } from 'express';
import { authenticateRequest } from '../../middleware/auth.middleware';
import { requireCollegeScope } from '../../middleware/tenant.middleware';
import { validateBody } from '../../middleware/validate.middleware';
import { AcademicRecordController } from '../../controllers/academicRecord.controller';
import {
  initializeRecordSchema,
  updateProgressionSchema,
  updateSubjectStatusSchema,
} from '../../validations/academicRecord.validation';

const router = Router();

// Authentication and tenant boundaries
router.use(authenticateRequest);
router.use(requireCollegeScope);

// 1. Initialize record from enrollment
router.post(
  '/initialize',
  validateBody(initializeRecordSchema),
  AcademicRecordController.initializeRecord
);

// 2. Student history across all semesters
router.get('/history', AcademicRecordController.getStudentHistory);

// 3. Department records listing (for HOD / College Admin)
router.get('/department', AcademicRecordController.listDepartmentRecords);

// 4. Single academic record detail with subject breakdowns
router.get('/:id', AcademicRecordController.getRecordDetail);

// 5. Progression status update (HOD / College Admin)
router.patch(
  '/:id/progression',
  validateBody(updateProgressionSchema),
  AcademicRecordController.updateProgressionStatus
);

// 6. Subject status update
router.patch(
  '/subjects/:subjectRecordId/status',
  validateBody(updateSubjectStatusSchema),
  AcademicRecordController.updateSubjectStatus
);

export default router;
