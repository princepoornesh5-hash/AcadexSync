import { Request, Response, NextFunction } from 'express';
import { ZodError } from 'zod';
import { ApiError } from '../utils/apiError';
import { Logger } from '../utils/logger';
import { env } from '../config/env';

export function errorHandler(
  err: Error | ApiError | unknown,
  req: Request,
  res: Response,
  _next: NextFunction
): Response {
  let statusCode = 500;
  let message = 'Internal server error';
  let code = 'INTERNAL_ERROR';
  let details: unknown = undefined;

  if (err instanceof ApiError) {
    statusCode = err.statusCode;
    message = err.message;
    code = err.code || 'API_ERROR';
    details = err.details;

    // Propagate Retry-After header on 429 errors if present in details
    if (statusCode === 429 && details && typeof details === 'object' && 'retryAfter' in (details as any)) {
      const wait = (details as any).retryAfter;
      if (wait && !res.getHeader('Retry-After')) {
        res.setHeader('Retry-After', String(wait));
      }
    }
  } else if (err instanceof ZodError) {
    statusCode = 422;
    code = 'VALIDATION_ERROR';
    message = err.errors.map((e) => `${e.path.join('.')}: ${e.message}`).join(', ') || 'Validation failed';
    details = err.errors;
  } else if (err && typeof err === 'object' && 'name' in err) {
    const errorObj = err as { name: string; message: string; code?: number; errors?: unknown; keyValue?: unknown };

    // MongoDB / Mongoose duplicate key error (code 11000)
    if (errorObj.code === 11000) {
      statusCode = 409;
      code = 'DUPLICATE_RESOURCE';
      const duplicateKey = errorObj.keyValue ? Object.keys(errorObj.keyValue as object).join(', ') : 'field';
      message = `A resource with that ${duplicateKey} already exists.`;
      details = errorObj.keyValue;
    }
    // Mongoose schema validation error
    else if (errorObj.name === 'ValidationError') {
      statusCode = 422;
      code = 'VALIDATION_ERROR';
      message = 'Validation failed for one or more fields.';
      details = errorObj.errors;
    }
    // Mongoose invalid ObjectId / CastError
    else if (errorObj.name === 'CastError') {
      statusCode = 400;
      code = 'INVALID_IDENTIFIER';
      message = 'Invalid resource identifier format.';
    }
    // JSON parse error in body
    else if (errorObj.name === 'SyntaxError') {
      statusCode = 400;
      code = 'INVALID_JSON';
      message = 'Malformed JSON in request body.';
    }
    // Multer upload / body size limit error
    else if (errorObj.name === 'MulterError' || (err as any).type === 'entity.too.large') {
      statusCode = 400;
      code = 'FILE_TOO_LARGE';
      message = 'File size exceeds maximum permitted limit';
    } else {
      message = errorObj.message || message;
    }
  }

  Logger.error(`Error processing ${req.method} ${req.originalUrl}: ${message}`, err);

  const responsePayload: Record<string, unknown> = {
    success: false,
    error: {
      code,
      message: Logger.sanitize(message),
      ...(details ? { details: Logger.sanitizeObject(details) } : {}),
    },
    timestamp: new Date().toISOString(),
  };

  // Only attach stack trace in local non-production development environments
  if (env.NODE_ENV === 'development' && err instanceof Error && err.stack) {
    responsePayload.stack = Logger.sanitize(err.stack);
  }

  return res.status(statusCode).json(responsePayload);
}
