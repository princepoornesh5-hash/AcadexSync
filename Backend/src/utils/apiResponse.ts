import { Response } from 'express';

export interface ApiResponsePayload<T = unknown> {
  success: boolean;
  message?: string;
  data?: T;
  meta?: Record<string, unknown>;
  timestamp: string;
}

export class ApiResponse {
  static success<T>(
    res: Response,
    data?: T,
    message = 'Success',
    statusCode = 200,
    meta?: Record<string, unknown>
  ): Response {
    const payload: ApiResponsePayload<T> = {
      success: true,
      message,
      data,
      meta,
      timestamp: new Date().toISOString(),
    };
    return res.status(statusCode).json(payload);
  }

  static created<T>(
    res: Response,
    data?: T,
    message = 'Resource created successfully',
    meta?: Record<string, unknown>
  ): Response {
    return ApiResponse.success(res, data, message, 201, meta);
  }

  static noContent(res: Response): Response {
    return res.status(204).send();
  }
}
