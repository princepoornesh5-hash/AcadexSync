import { Router } from 'express';
import { authenticateRequest } from '../../middleware/auth.middleware';
import { requireCollegeScope } from '../../middleware/tenant.middleware';
import { validateBody } from '../../middleware/validate.middleware';
import { PracticalController } from '../../controllers/practical.controller';
import { practicalValidation } from '../../validations/practical.validation';

const router = Router();

// Authentication and tenant boundaries
router.use(authenticateRequest);
router.use(requireCollegeScope);

// 1. Practical Definitions (Curriculum level)
router.post(
  '/definitions',
  validateBody(practicalValidation.createDefinition.shape.body),
  PracticalController.createDefinition
);

router.get('/definitions', PracticalController.listDefinitions);

// 2. Practical Sessions (Operational level)
router.post(
  '/sessions',
  validateBody(practicalValidation.createSession.shape.body),
  PracticalController.createSession
);

router.get('/sessions', PracticalController.listSessions);

router.get('/sessions/:id', PracticalController.getSessionById);

router.post('/sessions/:id/open', PracticalController.openSession);

router.post('/sessions/:id/complete', PracticalController.completeSession);

router.post(
  '/sessions/:id/cancel',
  validateBody(practicalValidation.cancelSession.shape.body),
  PracticalController.cancelSession
);

// 3. Participation & Roster Execution
router.patch(
  '/sessions/:id/students/:studentId',
  validateBody(practicalValidation.updateParticipation.shape.body),
  PracticalController.updateParticipation
);

router.post(
  '/sessions/:id/participation/bulk',
  validateBody(practicalValidation.bulkUpdateParticipation.shape.body),
  PracticalController.bulkUpdateParticipation
);

// 4. Student Practical History (Read-only for student, inspectable by faculty/admin)
router.get('/history', PracticalController.getStudentPracticalHistory);

export default router;
