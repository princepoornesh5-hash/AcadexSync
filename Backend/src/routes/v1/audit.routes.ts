import { Router } from 'express';
import { AuditController } from '../../controllers/audit.controller';
import { authenticateToken } from '../../middleware/auth.middleware';
import { requireCollegeAdmin } from '../../middleware/role.middleware';
import { requireCollegeScope } from '../../middleware/tenant.middleware';

const router = Router();

router.use(authenticateToken);
router.use(requireCollegeScope);

router.get('/', requireCollegeAdmin, AuditController.list);

export const auditRouter = router;
