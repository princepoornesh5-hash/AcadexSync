import { Router } from 'express';
import { authenticateRequest } from '../../middleware/auth.middleware';
import { requireCollegeScope } from '../../middleware/tenant.middleware';
import { validateBody, validateQuery } from '../../middleware/validate.middleware';
import { RequestController } from '../../controllers/request.controller';
import {
  createRequestSchema,
  respondRequestSchema,
  updateRequestStatusSchema,
  requestQuerySchema,
} from '../../validations/request.validation';

const router = Router();

// Authentication and Multi-Tenant Isolation boundary
router.use(authenticateRequest);
router.use(requireCollegeScope);

// Operational Endpoints
router.post(
  '/',
  validateBody(createRequestSchema),
  RequestController.createRequest
);

router.get(
  '/my',
  validateQuery(requestQuerySchema),
  RequestController.listMyRequests
);

router.get(
  '/incoming',
  validateQuery(requestQuerySchema),
  RequestController.listIncomingRequests
);

router.get(
  '/counts',
  RequestController.getSummaryCounts
);

router.get(
  '/:id',
  RequestController.getById
);

router.post(
  '/:id/respond',
  validateBody(respondRequestSchema),
  RequestController.respondToRequest
);

router.patch(
  '/:id/status',
  validateBody(updateRequestStatusSchema),
  RequestController.updateStatus
);

export const requestRouter = router;
