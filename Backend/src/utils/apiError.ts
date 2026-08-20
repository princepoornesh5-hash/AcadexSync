export class ApiError extends Error {
  public readonly statusCode: number;
  public readonly isOperational: boolean;
  public readonly code?: string;
  public readonly details?: unknown;

  constructor(
    statusCode: number,
    message: string,
    code?: string,
    details?: unknown,
    isOperational = true
  ) {
    super(message);
    this.statusCode = statusCode;
    this.code = code;
    this.details = details;
    this.isOperational = isOperational;

    Object.setPrototypeOf(this, new.target.prototype);
    Error.captureStackTrace(this, this.constructor);
  }

  static badRequest(message = 'Bad Request', code = 'BAD_REQUEST', details?: unknown): ApiError {
    return new ApiError(400, message, code, details);
  }

  static unauthorized(message = 'Unauthorized access', code = 'UNAUTHORIZED', details?: unknown): ApiError {
    return new ApiError(401, message, code, details);
  }

  static forbidden(message = 'Access forbidden', code = 'FORBIDDEN', details?: unknown): ApiError {
    return new ApiError(403, message, code, details);
  }

  static notFound(message = 'Resource not found', code = 'NOT_FOUND', details?: unknown): ApiError {
    return new ApiError(404, message, code, details);
  }

  static conflict(message = 'Resource already exists or conflict occurred', code = 'CONFLICT', details?: unknown): ApiError {
    return new ApiError(409, message, code, details);
  }

  static unprocessable(message = 'Validation failed', code = 'UNPROCESSABLE_ENTITY', details?: unknown): ApiError {
    return new ApiError(422, message, code, details);
  }

  static tooManyRequests(message = 'Too many requests. Please try again later.', code = 'TOO_MANY_REQUESTS', details?: unknown): ApiError {
    return new ApiError(429, message, code, details);
  }

  static internal(message = 'Internal server error', code = 'INTERNAL_ERROR', details?: unknown): ApiError {
    return new ApiError(500, message, code, details, false);
  }
}
