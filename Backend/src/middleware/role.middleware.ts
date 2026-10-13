import { Request, Response, NextFunction } from 'express';
import { ApiError } from '../utils/apiError';
import { AppRole, ROLE_HIERARCHY } from '../constants/roles';

/**
 * Restricts route access to specific allowed roles
 */
export function requireRoles(...allowedRoles: AppRole[]) {
  return (req: Request, _res: Response, next: NextFunction): void => {
    if (!req.user) {
      return next(ApiError.unauthorized('Authentication required'));
    }

    const hasAllowedRole =
      allowedRoles.includes(req.user.role) ||
      (req.user.activeRoles && req.user.activeRoles.some((r) => allowedRoles.includes(r)));

    if (!hasAllowedRole) {
      return next(
        ApiError.forbidden(
          `Access denied. Role "${req.user.role}" does not have permission to perform this action.`
        )
      );
    }

    return next();
  };
}

/**
 * Restricts route access to users with at least the given role level in the hierarchy
 */
export function requireMinRole(minRole: AppRole) {
  return (req: Request, _res: Response, next: NextFunction): void => {
    if (!req.user) {
      return next(ApiError.unauthorized('Authentication required'));
    }

    const effectiveRoles =
      req.user.activeRoles && req.user.activeRoles.length > 0
        ? req.user.activeRoles
        : [req.user.role];
    const userMaxLevel = Math.max(...effectiveRoles.map((r) => ROLE_HIERARCHY[r] || 0));
    const requiredLevel = ROLE_HIERARCHY[minRole] || 0;

    if (userMaxLevel < requiredLevel) {
      return next(
        ApiError.forbidden(
          `Access denied. Requires at least "${minRole}" level privileges.`
        )
      );
    }

    return next();
  };
}

export const requireSuperAdmin = requireRoles(AppRole.SUPER_ADMIN);
export const requireCollegeAdmin = requireRoles(AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN);
export const requireHodOrAbove = requireRoles(AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN, AppRole.HOD);
export const requireFacultyOrAbove = requireRoles(
  AppRole.SUPER_ADMIN,
  AppRole.COLLEGE_ADMIN,
  AppRole.HOD,
  AppRole.FACULTY
);
