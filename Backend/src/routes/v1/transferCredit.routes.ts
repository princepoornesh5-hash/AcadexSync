import { Router } from 'express';
import { TransferCreditController } from '../../controllers/transferCredit.controller';
import { authenticateRequest } from '../../middleware/auth.middleware';
import { requireCollegeAdmin } from '../../middleware/role.middleware';

const router = Router();

router.use(authenticateRequest);

router.post('/', requireCollegeAdmin, TransferCreditController.record);
router.get('/', TransferCreditController.list);
router.get('/:id', TransferCreditController.getById);
router.patch('/:id/status', requireCollegeAdmin, TransferCreditController.updateStatus);
router.get('/student/:studentId', TransferCreditController.getByStudentId);

export const transferCreditRouter = router;
