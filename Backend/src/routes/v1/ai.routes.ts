import { Router } from 'express';
import { authenticateRequest } from '../../middleware/auth.middleware';
import { requireCollegeScope } from '../../middleware/tenant.middleware';
import { validateBody } from '../../middleware/validate.middleware';
import { createRateLimiter } from '../../middleware/rateLimiter.middleware';
import { env } from '../../config/env';
import { AiController } from '../../controllers/ai.controller';
import {
  chatRequestSchema,
  confirmActionSchema,
  cancelActionSchema,
} from '../../validations/ai.validation';

const router = Router();

// Multi-tenant and authentication boundaries
router.use(authenticateRequest);
router.use(requireCollegeScope);

// AI-specific rate limiter (configurable per minute)
const aiRateLimiter = createRateLimiter({
  windowMs: 60 * 1000, // 1 minute
  maxRequests: env.AI_RATE_LIMIT_MAX,
  message: 'Too many AI requests. Please wait a minute before asking another question.',
});

// Authenticated AI chat endpoint with tool calling
router.post(
  '/chat',
  aiRateLimiter,
  validateBody(chatRequestSchema),
  AiController.chat
);

// Explicit user confirmation endpoint for pending AI write actions
router.post(
  '/action/confirm',
  validateBody(confirmActionSchema),
  AiController.confirmAction
);

// Explicit cancellation endpoint for pending AI write actions
router.post(
  '/action/cancel',
  validateBody(cancelActionSchema),
  AiController.cancelAction
);

// Read-only action status lookup for client reconciliation
router.get(
  '/action/:actionId',
  AiController.getActionStatus
);

export const aiRouter = router;
