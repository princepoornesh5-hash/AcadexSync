import { Router } from 'express';
import { authenticateRequest } from '../../middleware/auth.middleware';
import { requireCollegeScope } from '../../middleware/tenant.middleware';
import { requireRoles } from '../../middleware/role.middleware';
import { validateRequest } from '../../middleware/validate.middleware';
import {
  scheduleAssessmentSchema,
  previewScopeSchema,
  checkScheduleConflictsSchema,
} from '../../validations/internalAssessment.validation';
import { AppRole } from '../../constants/roles';
import { InternalAssessmentController } from '../../controllers/internalAssessment.controller';

const router = Router();

// Multi-tenant and authentication boundaries
router.use(authenticateRequest);
router.use(requireCollegeScope);

// Assessment Queries & Context
router.get('/context', InternalAssessmentController.getContext);
router.get('/', InternalAssessmentController.listAssessments);
router.post('/', InternalAssessmentController.createAssessment);

// Scope Preview & Conflict Detection for Common Examinations
router.post(
  '/preview-scope',
  validateRequest(previewScopeSchema),
  InternalAssessmentController.previewScope
);
router.post(
  '/check-conflicts',
  validateRequest(checkScheduleConflictsSchema),
  InternalAssessmentController.checkScheduleConflicts
);

// Exam Timetable & Migration Utilities (Placed before /:id routes to avoid collision)
router.get('/schedules/timetable', InternalAssessmentController.getExamTimetable);
router.post(
  '/migration/run',
  requireRoles(AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN),
  InternalAssessmentController.runMigration
);

// Lifecycle Operations
router.post('/open', InternalAssessmentController.open);
router.post('/:id/open', InternalAssessmentController.open);
router.post('/close', InternalAssessmentController.close);
router.post('/:id/close', InternalAssessmentController.close);
router.post('/archive', InternalAssessmentController.archive);
router.post('/:id/archive', InternalAssessmentController.archive);

// Mark Entry & Management
router.get('/roster', InternalAssessmentController.getRoster);
router.get('/:id/roster', InternalAssessmentController.getRoster);
router.post('/complete', InternalAssessmentController.complete);
router.post('/:id/complete', InternalAssessmentController.complete);
router.post('/draft', InternalAssessmentController.saveDraft);
router.post('/:id/draft', InternalAssessmentController.saveDraft);
router.put('/draft', InternalAssessmentController.saveDraft);
router.put('/:id/draft', InternalAssessmentController.saveDraft);
router.post('/marks/bulk', InternalAssessmentController.bulkSaveMarks);
router.post('/:id/marks/bulk', InternalAssessmentController.bulkSaveMarks);
router.post('/submit', InternalAssessmentController.submit);
router.post('/:id/submit', InternalAssessmentController.submit);
router.post('/lock', InternalAssessmentController.lock);
router.post('/:id/lock', InternalAssessmentController.lock);
router.get('/submission-state', InternalAssessmentController.getSubmissionState);
router.get('/:id/submission-state', InternalAssessmentController.getSubmissionState);

// Controlled Mark Correction Workflow
router.post('/marks/correct', InternalAssessmentController.correctMark);
router.post('/:id/marks/correct', InternalAssessmentController.correctMark);
router.post('/corrections/request', InternalAssessmentController.requestCorrection);
router.post('/:id/corrections/request', InternalAssessmentController.requestCorrection);
router.post('/corrections/:requestId/respond', InternalAssessmentController.respondCorrection);

// Review, Publish, and Unlock
router.post('/review', InternalAssessmentController.review);
router.post('/:id/review', InternalAssessmentController.review);
router.post('/publish', InternalAssessmentController.publish);
router.post('/:id/publish', InternalAssessmentController.publish);
router.post('/unlock', InternalAssessmentController.unlock);
router.post('/:id/unlock', InternalAssessmentController.unlock);

// Subject Summary & Student Views
router.get('/subject-summary', InternalAssessmentController.getSubjectSummary);
router.get('/student/my-marks', InternalAssessmentController.getStudentMarks);
router.get('/student/:studentId', InternalAssessmentController.getStudentAssessmentHistory);

// Sync Lab Experiment scores into Internal Assessment breakdown
router.post('/sync-lab', InternalAssessmentController.syncLab);

// Lab / Practical Activity Management
router.post('/labs/experiments', InternalAssessmentController.createExperiment);
router.get('/labs/experiments', InternalAssessmentController.getExperiments);
router.put('/labs/experiments/:id/submissions', InternalAssessmentController.updateExperimentSubmissions);

// Single Assessment & Scheduling Operations
router.get('/:id', InternalAssessmentController.getAssessmentById);
router.put('/:id', InternalAssessmentController.updateAssessment);
router.post('/:id/schedule', validateRequest(scheduleAssessmentSchema), InternalAssessmentController.scheduleAssessment);
router.get('/:id/schedule', InternalAssessmentController.getAssessmentSchedule);
router.delete('/:id/schedule', InternalAssessmentController.cancelAssessmentSchedule);
router.post('/:id/publish-exam', InternalAssessmentController.publishAssessment);

export default router;
