import { Request, Response, NextFunction } from 'express';
import { ApiError } from '../utils/apiError';
import { AppRole } from '../constants/roles';
import { College } from '../models/college.model';
import { CollegeStatus } from '../constants/status';

/**
 * Enforces College Multi-Tenancy Isolation.
 * Ensures non-SuperAdmins cannot access or mutate resources outside their assigned college.
 */
export function requireCollegeScope(
  req: Request,
  _res: Response,
  next: NextFunction
): void {
  if (!req.user) {
    return next(ApiError.unauthorized('User authentication required for tenant validation'));
  }

  // Super Admin has unrestricted platform access
  if (req.user.role === AppRole.SUPER_ADMIN) {
    return next();
  }

  // All other roles must have an associated collegeId
  const userCollegeId = req.user.collegeId;
  if (!userCollegeId) {
    return next(
      ApiError.forbidden('User does not belong to any registered college tenant')
    );
  }

  // Check if request attempts to target another collegeId in params/query/body
  const targetCollegeId =
    req.params.collegeId ||
    (req.query.collegeId as string) ||
    req.body?.collegeId;

  if (targetCollegeId && targetCollegeId.toString() !== userCollegeId.toString()) {
    return next(
      ApiError.forbidden(
        'Cross-college tenant access is strictly prohibited. You may only access your assigned college resources.'
      )
    );
  }

  // Bind verified tenant collegeId to request
  req.collegeId = userCollegeId;
  return next();
}

/**
 * Active Tenant Guard Middleware:
 * Ensures users belonging to an INACTIVE college cannot perform normal institutional operations.
 * SUPER_ADMIN is exempt.
 */
export async function requireActiveCollege(
  req: Request,
  _res: Response,
  next: NextFunction
): Promise<void> {
  if (!req.user) {
    return next(ApiError.unauthorized('User authentication required'));
  }

  if (req.user.role === AppRole.SUPER_ADMIN) {
    return next();
  }

  const collegeId = req.user.collegeId || req.collegeId;
  if (!collegeId) {
    return next(ApiError.forbidden('User does not belong to any registered college tenant'));
  }

  try {
    const college = await College.findById(collegeId);
    if (!college) {
      return next(ApiError.notFound('Associated college could not be found'));
    }

    if (college.status === CollegeStatus.INACTIVE || !college.isActive) {
      return next(
        ApiError.forbidden(
          'Your institution is currently inactive. Normal college operations are suspended.'
        )
      );
    }

    return next();
  } catch (error) {
    return next(error);
  }
}

/**
 * Helper to build safe tenant-scoped query filters
 */
export function buildTenantFilter(req: Request, baseFilter: Record<string, unknown> = {}): Record<string, unknown> {
  if (!req.user || req.user.role === AppRole.SUPER_ADMIN) {
    // If Super Admin provided a specific college filter, respect it; otherwise return base filter
    if (req.query.collegeId || req.params.collegeId) {
      return { ...baseFilter, collegeId: req.query.collegeId || req.params.collegeId };
    }
    return baseFilter;
  }

  return {
    ...baseFilter,
    collegeId: req.user.collegeId,
  };
}
