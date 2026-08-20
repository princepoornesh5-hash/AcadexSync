import { Request, Response, NextFunction } from 'express';
import { ApiError } from '../utils/apiError';
import { env } from '../config/env';

interface RateLimitRecord {
  count: number;
  resetTime: number;
}

export interface RateLimiterOptions {
  windowMs?: number;
  maxRequests?: number;
  message?: string;
  keyGenerator?: (req: Request) => string;
  skipInTest?: boolean;
}

/**
 * In-memory sliding-window rate limiter factory.
 * Provides configurable rate limiting with standard HTTP headers.
 */
export function createRateLimiter(options: RateLimiterOptions = {}) {
  const store = new Map<string, RateLimitRecord>();

  const windowMs = options.windowMs ?? env.RATE_LIMIT_WINDOW_MS;
  const maxRequests = options.maxRequests ?? env.RATE_LIMIT_MAX;
  const skipInTest = options.skipInTest ?? true;

  // Periodic cleanup of expired records every 5 minutes
  setInterval(() => {
    const now = Date.now();
    for (const [key, record] of store.entries()) {
      if (now > record.resetTime) {
        store.delete(key);
      }
    }
  }, 5 * 60 * 1000).unref();

  return (req: Request, res: Response, next: NextFunction): void => {
    // In test environment, skip throttling unless explicitly configured or requested via header
    const forceEnable = req.headers['x-test-enable-ratelimit'] === 'true';
    if (process.env.NODE_ENV === 'test' && skipInTest && !forceEnable) {
      return next();
    }

    const key = options.keyGenerator
      ? options.keyGenerator(req)
      : (req as any).user?.id
      ? `user:${(req as any).user.id}`
      : req.ip || req.socket.remoteAddress || 'unknown-client';

    const now = Date.now();
    let record = store.get(key);

    if (!record || now > record.resetTime) {
      record = {
        count: 1,
        resetTime: now + windowMs,
      };
      store.set(key, record);

      res.setHeader('X-RateLimit-Limit', maxRequests);
      res.setHeader('X-RateLimit-Remaining', Math.max(0, maxRequests - 1));
      res.setHeader('X-RateLimit-Reset', Math.ceil(record.resetTime / 1000));

      return next();
    }

    record.count += 1;

    const remaining = Math.max(0, maxRequests - record.count);
    res.setHeader('X-RateLimit-Limit', maxRequests);
    res.setHeader('X-RateLimit-Remaining', remaining);
    res.setHeader('X-RateLimit-Reset', Math.ceil(record.resetTime / 1000));

    if (record.count > maxRequests) {
      const waitSeconds = Math.ceil((record.resetTime - now) / 1000);
      res.setHeader('Retry-After', waitSeconds);
      return next(
        ApiError.tooManyRequests(
          options.message || `Too many requests. Please try again in ${waitSeconds} seconds.`
        )
      );
    }

    return next();
  };
}

// 1. General API Rate Limiter
export const generalApiRateLimiter = createRateLimiter({
  windowMs: env.RATE_LIMIT_WINDOW_MS,
  maxRequests: env.RATE_LIMIT_MAX,
  message: 'API rate limit exceeded. Please reduce request frequency.',
});

// 2. Authentication Rate Limiters
export const loginRateLimiter = createRateLimiter({
  windowMs: 5 * 60 * 1000,
  maxRequests: env.AUTH_RATE_LIMIT_MAX,
  message: 'Too many login attempts. Please try again in 5 minutes.',
});

export const forgotPasswordRateLimiter = createRateLimiter({
  windowMs: 10 * 60 * 1000,
  maxRequests: Math.min(env.AUTH_RATE_LIMIT_MAX, 10),
  message: 'Too many password reset requests. Please try again in 10 minutes.',
});

export const otpVerifyRateLimiter = createRateLimiter({
  windowMs: 5 * 60 * 1000,
  maxRequests: env.AUTH_RATE_LIMIT_MAX,
  message: 'Too many verification attempts. Please try again in 5 minutes.',
});

export const resetPasswordRateLimiter = createRateLimiter({
  windowMs: 10 * 60 * 1000,
  maxRequests: Math.min(env.AUTH_RATE_LIMIT_MAX, 10),
  message: 'Too many password reset submissions. Please try again in 10 minutes.',
});

export const activationRateLimiter = createRateLimiter({
  windowMs: 10 * 60 * 1000,
  maxRequests: env.AUTH_RATE_LIMIT_MAX,
  message: 'Too many activation attempts. Please try again in 10 minutes.',
});

export const changePasswordRateLimiter = createRateLimiter({
  windowMs: 10 * 60 * 1000,
  maxRequests: 5,
  message: 'Too many password change attempts. Please try again in 10 minutes.',
});

// 3. Invitation Management Limiters
export const invitationCreationRateLimiter = createRateLimiter({
  windowMs: 5 * 60 * 1000,
  maxRequests: env.INVITATION_RATE_LIMIT_MAX,
  message: 'Too many invitations created. Please wait before creating more.',
});

export const invitationReissueRateLimiter = createRateLimiter({
  windowMs: 5 * 60 * 1000,
  maxRequests: Math.min(env.INVITATION_RATE_LIMIT_MAX, 15),
  message: 'Too many reissue requests. Please wait before reissuing again.',
});

// 4. Upload Authorization Rate Limiter (Notes & Profile Images)
export const uploadRateLimiter = createRateLimiter({
  windowMs: 5 * 60 * 1000,
  maxRequests: env.UPLOAD_RATE_LIMIT_MAX,
  message: 'Too many upload authorizations requested. Please wait before uploading more files.',
});

// 5. Reports & Analytics Aggregation Rate Limiter
export const reportRateLimiter = createRateLimiter({
  windowMs: 5 * 60 * 1000,
  maxRequests: env.REPORT_RATE_LIMIT_MAX,
  message: 'Too many report requests. Please wait before generating additional reports.',
});

// 6. Device Token Management Rate Limiter
export const deviceTokenRateLimiter = createRateLimiter({
  windowMs: 5 * 60 * 1000,
  maxRequests: env.DEVICE_TOKEN_RATE_LIMIT_MAX,
  message: 'Too many device token registration requests.',
});
