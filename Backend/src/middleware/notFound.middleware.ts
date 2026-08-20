import { Request, Response } from 'express';
import { ApiError } from '../utils/apiError';

export function notFoundHandler(req: Request, res: Response): Response {
  const error = ApiError.notFound(`Route not found: ${req.method} ${req.originalUrl}`);
  return res.status(404).json({
    success: false,
    error: {
      code: 'ROUTE_NOT_FOUND',
      message: error.message,
    },
    timestamp: new Date().toISOString(),
  });
}
