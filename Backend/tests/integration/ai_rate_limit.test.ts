import request from 'supertest';
import express, { Request, Response } from 'express';
import { createRateLimiter, createConcurrencyLimiter } from '../../src/middleware/rateLimiter.middleware';
import { errorHandler } from '../../src/middleware/error.middleware';
import { AiService } from '../../src/services/ai.service';

describe('Rate Limiter, Concurrency Limiter & Gemini Quota Safety Tests', () => {
  describe('createConcurrencyLimiter middleware', () => {
    it('should block simultaneous requests for the same user and release when finished', () => {
      const concurrencyLimiter = createConcurrencyLimiter({
        keyGenerator: (req) => (req.headers['x-user-id'] as string) || 'default',
        message: 'You have an active request in progress. Please wait for it to finish.',
        skipInTest: false,
      });

      const req1: any = { headers: { 'x-user-id': 'user_concur' } };
      let finishCallback: (() => void) | undefined;
      const res1: any = {
        on: jest.fn((event: string, cb: () => void) => {
          if (event === 'finish') {
            finishCallback = cb;
          }
        }),
      };
      let next1Called = false;
      concurrencyLimiter(req1, res1, () => {
        next1Called = true;
      });
      expect(next1Called).toBe(true);

      // Second request from same user before res1 finishes -> must be rejected with 429 CONCURRENT_REQUEST_LIMIT
      const req2: any = { headers: { 'x-user-id': 'user_concur' } };
      let err2: any;
      concurrencyLimiter(req2, {} as any, (err) => {
        err2 = err;
      });
      expect(err2).toBeDefined();
      expect(err2.statusCode).toBe(429);
      expect(err2.code).toBe('CONCURRENT_REQUEST_LIMIT');

      // Simultaneous request from user_other should proceed without blocking
      const reqOther: any = { headers: { 'x-user-id': 'user_other' } };
      let nextOtherCalled = false;
      concurrencyLimiter(reqOther, { on: jest.fn() } as any, () => {
        nextOtherCalled = true;
      });
      expect(nextOtherCalled).toBe(true);

      // Finish first request
      finishCallback?.();

      // Now a new request from user_concur should succeed
      const req3: any = { headers: { 'x-user-id': 'user_concur' } };
      let next3Called = false;
      concurrencyLimiter(req3, { on: jest.fn() } as any, () => {
        next3Called = true;
      });
      expect(next3Called).toBe(true);
    });
  });

  describe('createRateLimiter middleware with per-user scoping and Retry-After', () => {
    it('should isolate limits by keyGenerator so User A limit does not block User B', async () => {
      const app = express();
      app.use(express.json());

      const testLimiter = createRateLimiter({
        windowMs: 60 * 1000,
        maxRequests: 2,
        skipInTest: false,
        code: 'APP_RATE_LIMIT_EXCEEDED',
        message: "You've sent several requests. Please wait a moment before trying again.",
        keyGenerator: (req) => `user:${req.headers['x-user-id']}`,
      });

      app.post('/test-rate-limit', testLimiter, (_req: Request, res: Response) => {
        res.json({ ok: true });
      });
      app.use(errorHandler);

      // User A makes 2 requests (reaches limit)
      const resA1 = await request(app).post('/test-rate-limit').set('x-user-id', 'userA');
      expect(resA1.status).toBe(200);

      const resA2 = await request(app).post('/test-rate-limit').set('x-user-id', 'userA');
      expect(resA2.status).toBe(200);

      // User A 3rd request -> 429
      const resA3 = await request(app).post('/test-rate-limit').set('x-user-id', 'userA');
      expect(resA3.status).toBe(429);
      expect(resA3.body.error.code).toBe('APP_RATE_LIMIT_EXCEEDED');
      expect(resA3.body.error.message).toContain("You've sent several requests");
      expect(resA3.headers['retry-after']).toBeDefined();

      // User B makes 1st request -> should SUCCEED
      const resB1 = await request(app).post('/test-rate-limit').set('x-user-id', 'userB');
      expect(resB1.status).toBe(200);
    });
  });

  describe('AiService Gemini quota error detection and backoff rules', () => {
    it('should distinguish daily quota exhaustion from transient rate limit', () => {
      const dailyQuotaError = new Error(
        '429 Resource has been exhausted (e.g. check quota). ' +
        'Quota exceeded for quota metric \'GenerateRequestsPerDayPerProjectPerModel-FreeTier\' ' +
        'and limit \'Generate requests per day per project per model: 20\'. Please retry in 72430s.'
      );

      const retryDelay = AiService.extractRetryDelaySeconds(dailyQuotaError);
      expect(retryDelay).toBe(72430);

      // handleUpstreamError should classify this as AI_UPSTREAM_QUOTA_EXCEEDED
      const err = AiService.handleUpstreamError(dailyQuotaError, 'gemini-model', Date.now());
      expect(err.statusCode).toBe(429);
      expect(err.code).toBe('AI_UPSTREAM_QUOTA_EXCEEDED');
      expect(err.message).toBe('The AI service has reached its current usage limit. Please try again later.');
      expect((err.details as any)?.retryAfter).toBe(72430);
    });

    it('should classify transient 429 with short delay as AI_RATE_LIMIT_EXCEEDED', () => {
      const transientError = new Error('429 Too Many Requests. Please retry in 3s.');

      const err = AiService.handleUpstreamError(transientError, 'gemini-model', Date.now());
      expect(err.statusCode).toBe(429);
      expect(err.code).toBe('AI_RATE_LIMIT_EXCEEDED');
      expect((err.details as any)?.retryAfter).toBe(3);
    });

    it('should NOT retry daily quota exhaustion in executeWithTransientRetry', async () => {
      const dailyQuotaError = new Error(
        '429 Resource has been exhausted: quota exceeded for FreeTier free_tier_requests. Retry in 50000s.'
      );

      let attempts = 0;
      await expect(
        AiService.executeWithTransientRetry(
          async () => {
            attempts++;
            throw dailyQuotaError;
          }
        )
      ).rejects.toThrow();

      // Must fail on attempt 1 without spinning retries
      expect(attempts).toBe(1);
    });

    it('should NOT retry non-transient 400, 401, 403, 404 errors', async () => {
      const authError = new Error('401 API_KEY_INVALID');
      let attempts = 0;

      await expect(
        AiService.executeWithTransientRetry(
          async () => {
            attempts++;
            throw authError;
          }
        )
      ).rejects.toThrow();

      expect(attempts).toBe(1);
    });

    it('should retry transient error and succeed on second attempt', async () => {
      let attempts = 0;
      const { result, attempts: totalAttempts } = await AiService.executeWithTransientRetry(
        async () => {
          attempts++;
          if (attempts === 1) {
            throw new Error('503 Service Unavailable');
          }
          return { success: true };
        }
      );

      expect(attempts).toBe(2);
      expect(totalAttempts).toBe(2);
      expect(result).toEqual({ success: true });
    });
  });
});
