import { ApiError } from '../../src/utils/apiError';

describe('ApiError Utility', () => {
  it('should instantiate badRequest with status 400', () => {
    const err = ApiError.badRequest('Invalid input');
    expect(err.statusCode).toBe(400);
    expect(err.code).toBe('BAD_REQUEST');
    expect(err.message).toBe('Invalid input');
    expect(err.isOperational).toBe(true);
  });

  it('should instantiate unauthorized with status 401', () => {
    const err = ApiError.unauthorized();
    expect(err.statusCode).toBe(401);
    expect(err.code).toBe('UNAUTHORIZED');
  });

  it('should instantiate forbidden with status 403', () => {
    const err = ApiError.forbidden('Tenant boundary violation');
    expect(err.statusCode).toBe(403);
    expect(err.code).toBe('FORBIDDEN');
    expect(err.message).toBe('Tenant boundary violation');
  });

  it('should instantiate notFound with status 404', () => {
    const err = ApiError.notFound('College not found');
    expect(err.statusCode).toBe(404);
    expect(err.code).toBe('NOT_FOUND');
  });

  it('should instantiate conflict with status 409', () => {
    const err = ApiError.conflict('Duplicate code');
    expect(err.statusCode).toBe(409);
    expect(err.code).toBe('CONFLICT');
  });
});
