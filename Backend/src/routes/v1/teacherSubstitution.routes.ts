import { Router } from 'express';
import { TeacherSubstitutionController } from '../../controllers/teacherSubstitution.controller';
import { authenticateRequest } from '../../middleware/auth.middleware';
import { requireHodOrAbove } from '../../middleware/role.middleware';

const router = Router();

router.use(authenticateRequest);

router.post('/', requireHodOrAbove, TeacherSubstitutionController.create);
router.get('/', TeacherSubstitutionController.list);
router.get('/:id', TeacherSubstitutionController.getById);
router.delete('/:id', requireHodOrAbove, TeacherSubstitutionController.delete);

export const teacherSubstitutionRouter = router;
