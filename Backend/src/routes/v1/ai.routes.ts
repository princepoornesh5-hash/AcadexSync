import { Router } from 'express';
import { authenticateRequest } from '../../middleware/auth.middleware';
import { requireCollegeScope } from '../../middleware/tenant.middleware';
import { validateBody } from '../../middleware/validate.middleware';
import { createRateLimiter, createConcurrencyLimiter } from '../../middleware/rateLimiter.middleware';
import { env } from '../../config/env';
import { AiController } from '../../controllers/ai.controller';
import {
  chatRequestSchema,
  confirmActionSchema,
  cancelActionSchema,
} from '../../validations/ai.validation';

const router = Router();

// AI-specific rate limiter for unauthenticated public support inquiries (strictly per IP)
const publicSupportRateLimiter = createRateLimiter({
  windowMs: 60 * 1000, // 1 minute
  maxRequests: 20,
  code: 'AI_PUBLIC_RATE_LIMIT_EXCEEDED',
  message: "You've sent several support questions. Please wait a moment before asking again.",
  keyGenerator: (req) => {
    return `ai:public:ip:${(req.headers['x-forwarded-for'] as string) || req.ip || 'unknown-client'}`;
  },
});

// Unauthenticated public AI support endpoint (restricted to platform support & onboarding)
router.post(
  '/public-chat',
  publicSupportRateLimiter,
  validateBody(chatRequestSchema),
  AiController.publicChat
);

// Multi-tenant and authentication boundaries
router.use(authenticateRequest);
router.use(requireCollegeScope);

// AI-specific rate limiter (strictly scoped per authenticated user principal)
const aiRateLimiter = createRateLimiter({
  windowMs: 60 * 1000, // 1 minute
  maxRequests: env.AI_RATE_LIMIT_MAX,
  code: 'APP_RATE_LIMIT_EXCEEDED',
  message: "You've sent several requests. Please wait a moment before trying again.",
  keyGenerator: (req) => {
    return (req as any).user?.id
      ? `ai:user:${(req as any).user.id}`
      : `ai:ip:${(req.headers['x-forwarded-for'] as string) || req.ip || 'unknown-client'}`;
  },
});

// AI concurrency limiter (strictly 1 active response per authenticated user)
const aiConcurrencyLimiter = createConcurrencyLimiter({
  maxConcurrent: 1,
  message: 'A response is already in progress. Please wait for it to complete.',
  keyGenerator: (req) => {
    return (req as any).user?.id
      ? `ai:conc:${(req as any).user.id}`
      : `ai:conc:ip:${(req.headers['x-forwarded-for'] as string) || req.ip || 'unknown-client'}`;
  },
});

// Authenticated AI chat endpoint with tool calling
router.post(
  '/chat',
  aiConcurrencyLimiter,
  aiRateLimiter,
  validateBody(chatRequestSchema),
  AiController.chat
);

// Authenticated real-time streaming AI chat endpoint (Server-Sent Events)
router.post(
  '/chat/stream',
  aiConcurrencyLimiter,
  aiRateLimiter,
  validateBody(chatRequestSchema),
  AiController.chatStream
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
