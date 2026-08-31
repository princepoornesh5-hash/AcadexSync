import express, { Express } from 'express';
import helmet from 'helmet';
import cors, { CorsOptions } from 'cors';
import morgan from 'morgan';
import { env } from './config/env';
import { healthRouter } from './routes/health.routes';
import { v1Router } from './routes/v1';
import { errorHandler } from './middleware/error.middleware';
import { notFoundHandler } from './middleware/notFound.middleware';
import { generalApiRateLimiter } from './middleware/rateLimiter.middleware';
import { Logger } from './utils/logger';

export function createApp(): Express {
  const app = express();

  // 1. Security Headers via Helmet
  app.use(
    helmet({
      contentSecurityPolicy: {
        directives: {
          defaultSrc: ["'self'"],
          scriptSrc: ["'self'"],
          styleSrc: ["'self'", "'unsafe-inline'"],
          imgSrc: ["'self'", 'data:', 'https://ik.imagekit.io'],
          connectSrc: ["'self'", 'https://ik.imagekit.io', 'https://fcm.googleapis.com'],
          fontSrc: ["'self'"],
          objectSrc: ["'none'"],
          mediaSrc: ["'self'", 'https://ik.imagekit.io'],
          frameAncestors: ["'none'"],
        },
      },
      crossOriginEmbedderPolicy: false,
      crossOriginResourcePolicy: { policy: 'cross-origin' },
      dnsPrefetchControl: { allow: false },
      frameguard: { action: 'deny' },
      hidePoweredBy: true,
      hsts:
        env.NODE_ENV === 'production'
          ? {
              maxAge: 31536000,
              includeSubDomains: true,
              preload: true,
            }
          : false,
      noSniff: true,
      referrerPolicy: { policy: 'strict-origin-when-cross-origin' },
      xssFilter: true,
    })
  );

  // 2. Production-Hardened CORS Configuration
  const isLocalhostPattern = /^https?:\/\/(localhost|127\.0\.0\.1|0\.0\.0\.0)(:\d+)?$/;

  const allowedOrigins = env.CORS_ORIGIN === '*'
    ? ['*']
    : env.CORS_ORIGIN.split(',').map((o) => o.trim()).filter((o) => o.length > 0);

  const corsOptions: CorsOptions = {
    origin: (origin, callback) => {
      // 1. Allow non-browser clients (Flutter mobile app, cURL, server-to-server health checks)
      if (!origin) {
        return callback(null, true);
      }

      // 2. In development and test environments, allow any localhost / 127.0.0.1 port (dynamic Flutter Web dev port)
      if (env.NODE_ENV !== 'production' && isLocalhostPattern.test(origin)) {
        return callback(null, true);
      }

      // 3. Allow wildcard origin if explicitly configured
      if (allowedOrigins.includes('*')) {
        if (env.NODE_ENV === 'production') {
          Logger.warn('CORS wildcard origin (*) is not recommended in production.');
        }
        return callback(null, true);
      }

      // 4. Match against configured allowlist (exact match or localhost pattern if localhost in list)
      if (
        allowedOrigins.includes(origin) ||
        (allowedOrigins.some((ao) => ao.startsWith('http://localhost') || ao.startsWith('http://127.0.0.1')) &&
          isLocalhostPattern.test(origin))
      ) {
        return callback(null, true);
      }

      Logger.warn(`CORS rejected request from unauthorized origin: ${origin}`);
      return callback(new Error('Not allowed by CORS'));
    },
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS', 'HEAD'],
    allowedHeaders: [
      'Content-Type',
      'Authorization',
      'Accept',
      'Origin',
      'X-Requested-With',
      'x-college-id',
      'x-client-id',
      'x-platform',
      'x-app-version',
      'x-device-id',
      'x-correlation-id',
      'x-request-id',
      'x-mock-role',
      'x-mock-user-id',
      'x-mock-college-id',
      'x-mock-department-id',
      'x-mock-email',
      'x-mock-name',
      'x-test-enable-ratelimit',
      'sentry-trace',
      'baggage',
    ],
    exposedHeaders: [
      'Content-Range',
      'X-Content-Range',
      'X-RateLimit-Limit',
      'X-RateLimit-Remaining',
      'X-RateLimit-Reset',
      'Retry-After',
    ],
    maxAge: 86400,
    optionsSuccessStatus: 204,
  };

  app.use(cors(corsOptions));
  app.options('*', cors(corsOptions));

  // 3. Request Body Parsing
  app.use(express.json({ limit: '10mb' }));
  app.use(express.urlencoded({ extended: true, limit: '10mb' }));

  // 4. Request Logging
  if (env.NODE_ENV !== 'test') {
    app.use(morgan('combined'));
  }

  // 5. Public Health Endpoint (unthrottled for load balancers)
  app.use('/health', healthRouter);

  // 6. Versioned API Routes with General Rate Limiting
  app.use('/api/v1', generalApiRateLimiter, v1Router);

  // 7. 404 Handler
  app.use(notFoundHandler);

  // 8. Centralized Error Handler
  app.use(errorHandler);

  return app;
}

export const app = createApp();
