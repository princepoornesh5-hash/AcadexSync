import { Request, Response, NextFunction } from 'express';
import { z, AnyZodObject, ZodError } from 'zod';
import { ApiError } from '../utils/apiError';

export function validateRequest(schema: AnyZodObject) {
  return async (req: Request, _res: Response, next: NextFunction): Promise<void> => {
    try {
      const parsed = await schema.parseAsync({
        body: req.body,
        query: req.query,
        params: req.params,
      });
      req.body = parsed.body ?? req.body;
      req.query = parsed.query ?? req.query;
      req.params = parsed.params ?? req.params;
      return next();
    } catch (error) {
      if (error instanceof ZodError) {
        const details = error.errors.map((e) => ({
          field: e.path.join('.'),
          message: e.message,
        }));
        return next(
          ApiError.unprocessable('Validation error', 'VALIDATION_FAILED', details)
        );
      }
      return next(error);
    }
  };
}

export function validateBody(schema: z.ZodTypeAny) {
  return async (req: Request, _res: Response, next: NextFunction): Promise<void> => {
    try {
      req.body = await schema.parseAsync(req.body);
      return next();
    } catch (error) {
      if (error instanceof ZodError) {
        const details = error.errors.map((e) => ({
          field: e.path.join('.'),
          message: e.message,
        }));
        return next(
          ApiError.unprocessable('Validation error', 'VALIDATION_FAILED', details)
        );
      }
      return next(error);
    }
  };
}

export function validateQuery(schema: z.ZodTypeAny) {
  return async (req: Request, _res: Response, next: NextFunction): Promise<void> => {
    try {
      req.query = (await schema.parseAsync(req.query)) as any;
      return next();
    } catch (error) {
      if (error instanceof ZodError) {
        const details = error.errors.map((e) => ({
          field: e.path.join('.'),
          message: e.message,
        }));
        return next(
          ApiError.unprocessable('Validation error', 'VALIDATION_FAILED', details)
        );
      }
      return next(error);
    }
  };
}
