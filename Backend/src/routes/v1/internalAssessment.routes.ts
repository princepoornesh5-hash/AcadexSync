import { Router } from 'express';
import { authenticateRequest } from '../../middleware/auth.middleware';
import { requireCollegeScope } from '../../middleware/tenant.middleware';
import { InternalAssessmentController } from '../../controllers/internalAssessment.controller';

const router = Router();

// Multi-tenant and authentication boundaries
router.use(authenticateRequest);
router.use(requireCollegeScope);

// Assessment Creation & Context
router.get('/context', InternalAssessmentController.getContext);
router.post('/', InternalAssessmentController.createAssessment);

// Lifecycle Operations
router.post('/open', InternalAssessmentController.open);
router.post('/:id/open', InternalAssessmentController.open);
router.post('/close', InternalAssessmentController.close);
router.post('/:id/close', InternalAssessmentController.close);
router.post('/archive', InternalAssessmentController.archive);
router.post('/:id/archive', InternalAssessmentController.archive);

// Mark Entry & Management
router.post('/draft', InternalAssessmentController.saveDraft);
router.post('/marks/bulk', InternalAssessmentController.bulkSaveMarks);
router.post('/:id/marks/bulk', InternalAssessmentController.bulkSaveMarks);
router.post('/marks/correct', InternalAssessmentController.correctMark);
router.post('/:id/marks/correct', InternalAssessmentController.correctMark);

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

// Sync Lab Experiment scores into Internal Assessment breakdown
router.post('/sync-lab', InternalAssessmentController.syncLab);

// Lab / Practical Activity Management
router.post('/labs/experiments', InternalAssessmentController.createExperiment);
router.get('/labs/experiments', InternalAssessmentController.getExperiments);
router.put('/labs/experiments/:id/submissions', InternalAssessmentController.updateExperimentSubmissions);

export default router;
