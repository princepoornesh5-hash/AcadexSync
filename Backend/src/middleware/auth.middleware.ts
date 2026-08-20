import { Request, Response, NextFunction } from 'express';
import { ApiError } from '../utils/apiError';
import { AppRole, normalizeRole } from '../constants/roles';
import { AccountStatus, TokenType } from '../constants/status';
import { verifyJwtToken } from '../utils/token';
import { User } from '../models/user.model';
import mongoose from 'mongoose';

/**
 * Authentication Boundary Middleware
 * Verifies standard cryptographically signed Bearer Access tokens on protected endpoints.
 * Resolves user state from database and enforces ACTIVE status.
 */
export async function authenticateRequest(
  req: Request,
  _res: Response,
  next: NextFunction
): Promise<void> {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return next(
      ApiError.unauthorized('Authentication token is required')
    );
  }

  const token = authHeader.split(' ')[1];
  if (!token || token.trim() === '') {
    return next(ApiError.unauthorized('Invalid authorization token format'));
  }

  try {
    const payload = verifyJwtToken(token, TokenType.ACCESS);
    const role = normalizeRole(payload.role);

    // If userId is a valid Mongo ObjectId, verify user exists in database and is ACTIVE
    if (mongoose.Types.ObjectId.isValid(payload.userId)) {
      const dbUser = await User.findById(payload.userId);
      if (dbUser) {
        if (dbUser.accountStatus === AccountStatus.DEACTIVATED) {
          return next(
            ApiError.forbidden('Account has been deactivated. Please contact your administrator.')
          );
        }
        if (dbUser.accountStatus === AccountStatus.PENDING_ACTIVATION) {
          return next(
            ApiError.forbidden('Account is pending activation. Please activate your account first.')
          );
        }
        if (dbUser.accountStatus !== AccountStatus.ACTIVE) {
          return next(ApiError.forbidden('Account is currently not active.'));
        }

        req.user = {
          id: dbUser.id,
          instituteId: dbUser.instituteId,
          email: dbUser.email || undefined,
          phone: dbUser.phone || undefined,
          name: dbUser.name,
          role: dbUser.role,
          collegeId: dbUser.collegeId?.toString(),
          departmentId: dbUser.departmentId?.toString(),
          courseId: dbUser.courseId?.toString(),
          sectionId: dbUser.sectionId?.toString(),
          semesterId: dbUser.semesterId?.toString(),
          firebaseUid: dbUser.firebaseUid || undefined,
          accountStatus: dbUser.accountStatus,
          activationStatus: dbUser.activationStatus,
          sessionId: payload.sessionId,
        };

        req.collegeId = dbUser.collegeId?.toString();
        req.tenant = {
          collegeId: dbUser.collegeId?.toString(),
          isSuperAdmin: dbUser.role === AppRole.SUPER_ADMIN,
          userRole: dbUser.role,
          userId: dbUser.id,
        };

        return next();
      }
    }

    // Fallback context from verified token payload
    req.user = {
      id: payload.userId,
      instituteId: payload.instituteId || payload.userId,
      email: payload.email,
      phone: payload.phone,
      name: payload.name || 'ACADEX User',
      role,
      collegeId: payload.collegeId,
      departmentId: payload.departmentId,
      courseId: payload.courseId,
      sectionId: payload.sectionId,
      semesterId: payload.semesterId,
      firebaseUid: payload.firebaseUid,
      accountStatus: AccountStatus.ACTIVE,
      activationStatus: 'activated',
      sessionId: payload.sessionId,
    };

    req.collegeId = payload.collegeId;
    req.tenant = {
      collegeId: payload.collegeId,
      isSuperAdmin: role === AppRole.SUPER_ADMIN,
      userRole: role,
      userId: payload.userId,
    };

    return next();
  } catch (error) {
    if (error instanceof ApiError) {
      return next(error);
    }
    return next(ApiError.unauthorized('Token validation failed'));
  }
}

// Export alias for backwards compatibility
export const authenticateToken = authenticateRequest;
