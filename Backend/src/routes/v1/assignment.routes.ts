import { Router } from 'express';
import { authenticateRequest } from '../../middleware/auth.middleware';
import { requireCollegeScope } from '../../middleware/tenant.middleware';
import { validateBody } from '../../middleware/validate.middleware';
import { AssignmentController } from '../../controllers/assignment.controller';
import {
  createAssignmentSchema,
  updateAssignmentSchema,
  recordMarksSchema,
  submissionUploadAuthSchema,
  submitAssignmentSchema,
  singleReviewSchema,
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

// Edit assignment
router.put(
  '/:id',
  validateBody(updateAssignmentSchema),
  AssignmentController.updateAssignment
);

// Publish & Close & Archive actions
router.post(
  '/:id/publish',
  AssignmentController.publishAssignment
);

router.post(
  '/:id/close',
  AssignmentController.closeAssignment
);

router.post(
  '/:id/archive',
  AssignmentController.archiveAssignment
);

// Safe delete draft assignment
router.delete(
  '/:id',
  AssignmentController.deleteAssignment
);

// Student marks Done (Legacy / quick submit)
router.post(
  '/:id/complete',
  AssignmentController.completeAssignment
);

// Student Submission Endpoints (Prompt 40)
router.get(
  '/:id/submission',
  AssignmentController.getStudentSubmission
);

router.post(
  '/:id/submission/upload-auth',
  validateBody(submissionUploadAuthSchema),
  AssignmentController.getSubmissionUploadAuth
);

router.post(
  '/:id/submission/draft',
  validateBody(submitAssignmentSchema),
  AssignmentController.saveDraftSubmission
);

router.post(
  '/:id/submission',
  validateBody(submitAssignmentSchema),
  AssignmentController.submitAssignment
);

router.get(
  '/:id/submission/files/:fileId/download-url',
  AssignmentController.getSubmissionFileDownloadUrl
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

// Single Submission Review & Grading (Prompt 40)
router.patch(
  '/:id/submissions/:submissionId/review',
  validateBody(singleReviewSchema),
  AssignmentController.reviewSingleSubmission
);

export const assignmentRouter = router;
