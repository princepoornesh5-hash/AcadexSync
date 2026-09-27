import { Router } from 'express';
import { authenticateRequest } from '../../middleware/auth.middleware';
import { requireCollegeScope } from '../../middleware/tenant.middleware';
import { validateBody } from '../../middleware/validate.middleware';
import { AssignmentController } from '../../controllers/assignment.controller';
import {
  createAssignmentSchema,
  recordMarksSchema,
} from '../../validations/assignment.validation';

const router = Router();

// Multi-tenant and authentication boundaries
router.use(authenticateRequest);
router.use(requireCollegeScope);

// Faculty operations
router.post(
  '/',
  validateBody(createAssignmentSchema),
  AssignmentController.createAssignment
);

router.get(
  '/',
  AssignmentController.getFacultyAssignments
);

// Student assignments view
router.get(
  '/my',
  AssignmentController.getStudentAssignments
);

// Single assignment detail
router.get(
  '/:id',
  AssignmentController.getAssignmentDetail
);

// Publish & Close actions
router.post(
  '/:id/publish',
  AssignmentController.publishAssignment
);

router.post(
  '/:id/close',
  AssignmentController.closeAssignment
);

// Student marks Done
router.post(
  '/:id/complete',
  AssignmentController.completeAssignment
);

// Faculty Activity & Marks
router.get(
  '/:id/activity',
  AssignmentController.getAssignmentActivity
);

router.patch(
  '/:id/marks',
  validateBody(recordMarksSchema),
  AssignmentController.recordMarks
);

export const assignmentRouter = router;
