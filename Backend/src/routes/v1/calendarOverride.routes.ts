import { Router } from 'express';
import { CalendarOverrideController } from '../../controllers/calendarOverride.controller';
import { authenticateRequest } from '../../middleware/auth.middleware';
import { requireHodOrAbove } from '../../middleware/role.middleware';

const router = Router();

router.use(authenticateRequest);

router.post('/', requireHodOrAbove, CalendarOverrideController.create);
router.get('/', CalendarOverrideController.list);
router.get('/:id', CalendarOverrideController.getById);
router.delete('/:id', requireHodOrAbove, CalendarOverrideController.delete);

export const calendarOverrideRouter = router;
