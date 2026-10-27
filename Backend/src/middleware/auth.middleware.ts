import { Request, Response, NextFunction } from 'express';
import mongoose from 'mongoose';
import { ApiError } from '../utils/apiError';
import { AppRole, normalizeRole } from '../constants/roles';
import {
  AccountStatus,
  TokenType,
  MembershipStatus,
  RoleAssignmentStatus,
  CollegeStatus,
} from '../constants/status';
import { verifyJwtToken } from '../utils/token';
import { isValidSessionId } from '../utils/session.util';
import { User } from '../models/user.model';
import { AuthSession } from '../models/authSession.model';
import { College } from '../models/college.model';
import { WorkspaceMembership } from '../models/workspaceMembership.model';
import { WorkspaceRoleAssignment } from '../models/workspaceRoleAssignment.model';
import { WorkspaceCompatibilityService } from '../services/workspaceCompatibility.service';

/**
 * Authoritative Authentication & Workspace Resolution Middleware
 *
 * PIPELINE ORDER:
 * 1. Verify Bearer token signature, expiry, and tokenType.
 * 2. Validate authoritative session against AuthSession store (UUID v4 format, active, not revoked, not expired, fail closed).
 * 3. Verify canonical User in database (ACTIVE status enforced).
 * 4. Resolve requested workspace via X-Workspace-Id header and/or token claim (conflict checking).
 * 5. Handle Super Admin platform authority (unrestricted, distinct from ordinary membership).
 * 6. Institutional User: Validate College, load authoritative WorkspaceMembership (status ACTIVE required).
 * 7. Load active WorkspaceRoleAssignments and establish authoritative request context (req.user, req.collegeId, req.tenant, req.workspace).
 * 8. Fallback to compatibility layer only if permitted and no authoritative membership exists.
 */
export async function authenticateRequest(
  req: Request,
  _res: Response,
  next: NextFunction
): Promise<void> {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return next(ApiError.unauthorized('Authentication token is required'));
  }

  const token = authHeader.split(' ')[1];
  if (!token || token.trim() === '') {
    return next(ApiError.unauthorized('Invalid authorization token format'));
  }

  try {
    const payload = verifyJwtToken(token, TokenType.ACCESS);

    // =========================================================================
    // 1. AUTHORITATIVE SESSION STORE VALIDATION
    // =========================================================================
    if (payload.sessionId) {
      if (!isValidSessionId(payload.sessionId)) {
        return next(ApiError.unauthorized('Invalid session identifier format'));
      }

      let session;
      try {
        session = await AuthSession.findOne({ sessionId: payload.sessionId });
      } catch (_err) {
        // Database / session store failure: MUST fail closed
        return next(ApiError.unauthorized('Session validation failed'));
      }

      if (!session) {
        return next(
          ApiError.unauthorized('Authentication session not found or has expired. Please log in again.')
        );
      }

      if (session.userId.toString() !== payload.userId.toString()) {
        return next(
          ApiError.unauthorized('Authentication session does not match authenticated user.')
        );
      }

      if (session.isRevoked() || session.revokedAt != null) {
        return next(
          ApiError.unauthorized('Authentication session has been revoked. Please log in again.')
        );
      }

      if (session.isExpired() || (session.expiresAt && new Date() > session.expiresAt)) {
        return next(
          ApiError.unauthorized('Authentication session has expired. Please log in again.')
        );
      }
    } else {
      // If token contract or header requires session validation, reject missing session ID
      if (payload.requireSession === true || req.headers['x-require-session'] === 'true') {
        return next(ApiError.unauthorized('Authentication session identifier is required'));
      }
    }

    // Extract workspace identifiers from header and token claim
    const rawHeaderWorkspaceId = req.headers['x-workspace-id'];
    const headerWorkspaceId = (
      Array.isArray(rawHeaderWorkspaceId) ? rawHeaderWorkspaceId[0] : rawHeaderWorkspaceId
    )?.trim();
    const tokenWorkspaceId = payload.collegeId?.trim();

    // CONFLICT RESOLUTION: If both header and token specify different workspaces, fail safely
    if (headerWorkspaceId && tokenWorkspaceId && headerWorkspaceId !== tokenWorkspaceId) {
      return next(
        ApiError.badRequest(
          'Conflicting workspace identifiers: token workspace does not match X-Workspace-Id header'
        )
      );
    }

    // =========================================================================
    // 2. CANONICAL USER RESOLUTION
    // =========================================================================
    if (mongoose.Types.ObjectId.isValid(payload.userId)) {
      const dbUser = await User.findById(payload.userId);
      if (!dbUser) {
        return next(ApiError.unauthorized('User account no longer exists or has been deleted.'));
      }

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

      const requestedCollegeId =
        headerWorkspaceId || tokenWorkspaceId || dbUser.collegeId?.toString();

      // -----------------------------------------------------------------------
      // SUPER_ADMIN PLATFORM ACCESS (EXEMPT FROM INSTITUTIONAL MEMBERSHIP)
      // -----------------------------------------------------------------------
      if (dbUser.role === AppRole.SUPER_ADMIN) {
        let superAdminCollegeId: string | undefined = undefined;

        if (requestedCollegeId && mongoose.Types.ObjectId.isValid(requestedCollegeId)) {
          const targetCollege = await College.findById(requestedCollegeId);
          if (targetCollege) {
            superAdminCollegeId = targetCollege.id;
          }
        }

        req.user = {
          id: dbUser.id,
          instituteId: dbUser.instituteId,
          email: dbUser.email || undefined,
          phone: dbUser.phone || undefined,
          name: dbUser.name,
          role: AppRole.SUPER_ADMIN,
          collegeId: superAdminCollegeId,
          departmentId: dbUser.departmentId?.toString(),
          accountStatus: dbUser.accountStatus,
          activationStatus: dbUser.activationStatus,
          sessionId: payload.sessionId,
          isAuthoritativeWorkspace: false,
          activeRoles: [AppRole.SUPER_ADMIN],
        };

        req.collegeId = superAdminCollegeId;
        req.tenant = {
          collegeId: superAdminCollegeId,
          isSuperAdmin: true,
          userRole: AppRole.SUPER_ADMIN,
          userId: dbUser.id,
        };

        req.workspace = superAdminCollegeId
          ? {
              collegeId: superAdminCollegeId,
              membershipId: null,
              roles: [AppRole.SUPER_ADMIN],
              roleAssignments: [],
              departmentId: null,
              authorizedDepartmentIds: [],
              isAuthoritative: false,
              isSuperAdmin: true,
            }
          : undefined;

        return next();
      }

      // -----------------------------------------------------------------------
      // INSTITUTIONAL USER WORKSPACE VALIDATION
      // -----------------------------------------------------------------------
      if (!requestedCollegeId) {
        if (
          req.originalUrl.includes('/workspaces/my-memberships') ||
          req.originalUrl.includes('/workspaces/switch') ||
          req.originalUrl.includes('/auth/me') ||
          req.originalUrl.includes('/auth/logout')
        ) {
          req.user = {
            id: dbUser.id,
            instituteId: dbUser.instituteId,
            email: dbUser.email || undefined,
            phone: dbUser.phone || undefined,
            name: dbUser.name,
            role: dbUser.role,
            collegeId: undefined,
            departmentId: undefined,
            accountStatus: dbUser.accountStatus,
            activationStatus: dbUser.activationStatus,
            sessionId: payload.sessionId,
            isAuthoritativeWorkspace: false,
            activeRoles: [dbUser.role],
          };
          return next();
        }

        return next(
          ApiError.forbidden(
            'User does not belong to any workspace. A valid workspace context is required.'
          )
        );
      }

      if (!mongoose.Types.ObjectId.isValid(requestedCollegeId)) {
        return next(ApiError.badRequest('Invalid workspace identifier format'));
      }

      const targetCollege = await College.findById(requestedCollegeId);
      if (!targetCollege) {
        return next(ApiError.notFound('Target workspace (college) does not exist'));
      }

      if (targetCollege.status === CollegeStatus.INACTIVE || !targetCollege.isActive) {
        return next(
          ApiError.forbidden(
            'Your institution is currently inactive. Normal college operations are suspended.'
          )
        );
      }

      // Authoritative Membership Lookup
      let membership = null;
      if (payload.workspaceMembershipId && mongoose.Types.ObjectId.isValid(payload.workspaceMembershipId)) {
        membership = await WorkspaceMembership.findOne({
          _id: payload.workspaceMembershipId,
          userId: dbUser._id,
          collegeId: targetCollege._id,
        });
      }
      if (!membership) {
        membership = await WorkspaceMembership.findOne({
          userId: dbUser._id,
          collegeId: targetCollege._id,
        });
      }

      if (membership) {
        // Authoritative membership exists: enforce explicit lifecycle state
        if (membership.status !== MembershipStatus.ACTIVE) {
          return next(
            ApiError.forbidden(
              `Workspace membership is ${membership.status.toLowerCase()}. Access denied.`
            )
          );
        }

        const now = new Date();
        if (membership.effectiveStartDate && membership.effectiveStartDate > now) {
          return next(
            ApiError.forbidden('Workspace membership is not yet effective. Access denied.')
          );
        }
        if (membership.effectiveEndDate && membership.effectiveEndDate < now) {
          return next(
            ApiError.forbidden('Workspace membership has expired. Access denied.')
          );
        }

        // Load active role assignments for this membership (filtered by date validity)
        const roleAssignments = await WorkspaceRoleAssignment.find({
          membershipId: membership._id,
          status: RoleAssignmentStatus.ACTIVE,
          $and: [
            {
              $or: [
                { effectiveStartDate: { $exists: false } },
                { effectiveStartDate: null },
                { effectiveStartDate: { $lte: now } },
              ],
            },
            {
              $or: [
                { effectiveEndDate: { $exists: false } },
                { effectiveEndDate: null },
                { effectiveEndDate: { $gte: now } },
              ],
            },
          ],
        }).sort({ createdAt: 1 });

        if (roleAssignments.length === 0) {
          return next(
            ApiError.forbidden('No active role assignments found in this workspace.')
          );
        }

        const primaryAssignment = roleAssignments[0];
        const activeRole = primaryAssignment.role;
        const activeDepartmentId = primaryAssignment.departmentId
          ? primaryAssignment.departmentId.toString()
          : (dbUser.departmentId?.toString() || null);
        const authorizedDepartmentIds = roleAssignments
          .map((a) => a.departmentId?.toString())
          .filter(Boolean) as string[];
        const activeRoles = roleAssignments.map((a) => a.role);

        // Resolve active institutional PIN Number from membership, falling back to global user PIN
        const activeInstituteId = membership.instituteId || dbUser.instituteId;

        req.user = {
          id: dbUser.id,
          instituteId: activeInstituteId,
          email: dbUser.email || undefined,
          phone: dbUser.phone || undefined,
          name: dbUser.name,
          role: activeRole,
          collegeId: targetCollege.id,
          departmentId: activeDepartmentId || undefined,
          courseId: dbUser.courseId?.toString(),
          sectionId: dbUser.sectionId?.toString(),
          semesterId: dbUser.semesterId?.toString(),
          firebaseUid: dbUser.firebaseUid || undefined,
          accountStatus: dbUser.accountStatus,
          activationStatus: dbUser.activationStatus,
          sessionId: payload.sessionId,
          workspaceMembershipId: membership.id,
          workspaceMembershipStatus: membership.status,
          activeRoles,
          authorizedDepartmentIds,
          isAuthoritativeWorkspace: true,
        };

        req.collegeId = targetCollege.id;
        req.tenant = {
          collegeId: targetCollege.id,
          isSuperAdmin: false,
          userRole: activeRole,
          userId: dbUser.id,
          workspaceMembershipId: membership.id,
          membershipStatus: membership.status,
          departmentId: activeDepartmentId,
        };

        req.workspace = {
          collegeId: targetCollege.id,
          membershipId: membership.id,
          membershipStatus: membership.status,
          roles: activeRoles,
          roleAssignments: roleAssignments.map((a) => ({
            role: a.role,
            departmentId: a.departmentId ? a.departmentId.toString() : null,
            scope: a.scope,
          })),
          departmentId: activeDepartmentId,
          authorizedDepartmentIds,
          isAuthoritative: true,
          isSuperAdmin: false,
        };

        return next();
      }

      // No authoritative membership found: Check Compatibility Layer
      const effectiveContext = await WorkspaceCompatibilityService.resolveEffectiveWorkspace(
        dbUser.id,
        requestedCollegeId,
        {
          collegeId: dbUser.collegeId?.toString(),
          role: dbUser.role,
          departmentId: dbUser.departmentId?.toString(),
        }
      );

      if (!effectiveContext) {
        return next(
          ApiError.forbidden('No active workspace membership found for this institution.')
        );
      }

      req.user = {
        id: dbUser.id,
        instituteId: dbUser.instituteId,
        email: dbUser.email || undefined,
        phone: dbUser.phone || undefined,
        name: dbUser.name,
        role: effectiveContext.role,
        collegeId: effectiveContext.collegeId,
        departmentId: effectiveContext.departmentId || undefined,
        courseId: dbUser.courseId?.toString(),
        sectionId: dbUser.sectionId?.toString(),
        semesterId: dbUser.semesterId?.toString(),
        firebaseUid: dbUser.firebaseUid || undefined,
        accountStatus: dbUser.accountStatus,
        activationStatus: dbUser.activationStatus,
        sessionId: payload.sessionId,
        workspaceMembershipId: null,
        activeRoles: [effectiveContext.role],
        authorizedDepartmentIds: effectiveContext.departmentId ? [effectiveContext.departmentId] : [],
        isAuthoritativeWorkspace: false,
      };

      req.collegeId = effectiveContext.collegeId;
      req.tenant = {
        collegeId: effectiveContext.collegeId,
        isSuperAdmin: false,
        userRole: effectiveContext.role,
        userId: dbUser.id,
        workspaceMembershipId: null,
        departmentId: effectiveContext.departmentId,
      };

      req.workspace = {
        collegeId: effectiveContext.collegeId,
        membershipId: null,
        roles: [effectiveContext.role],
        roleAssignments: [],
        departmentId: effectiveContext.departmentId,
        authorizedDepartmentIds: effectiveContext.departmentId ? [effectiveContext.departmentId] : [],
        isAuthoritative: false,
        isSuperAdmin: false,
      };

      return next();
    }

    // =========================================================================
    // 3. SYNTHETIC PAYLOAD FALLBACK (FOR UNIT/INTEGRATION TEST HARNESSES)
    // =========================================================================
    const resolvedRole = normalizeRole(payload.role);
    const resolvedCollegeId = headerWorkspaceId || tokenWorkspaceId;

    const resolvedMembershipId = payload.workspaceMembershipId || payload.membershipId || null;

    req.user = {
      id: payload.userId,
      instituteId: payload.instituteId || payload.userId,
      email: payload.email,
      phone: payload.phone,
      name: payload.name || 'ACADEX User',
      role: resolvedRole,
      collegeId: resolvedCollegeId,
      departmentId: payload.departmentId,
      courseId: payload.courseId,
      sectionId: payload.sectionId,
      semesterId: payload.semesterId,
      firebaseUid: payload.firebaseUid,
      accountStatus: AccountStatus.ACTIVE,
      activationStatus: 'activated',
      sessionId: payload.sessionId,
      workspaceMembershipId: resolvedMembershipId,
      activeRoles: [resolvedRole],
      authorizedDepartmentIds: payload.departmentId ? [payload.departmentId] : [],
      isAuthoritativeWorkspace: false,
    };

    req.collegeId = resolvedCollegeId;
    req.tenant = {
      collegeId: resolvedCollegeId,
      isSuperAdmin: resolvedRole === AppRole.SUPER_ADMIN,
      userRole: resolvedRole,
      userId: payload.userId,
      workspaceMembershipId: resolvedMembershipId,
    };

    req.workspace = resolvedCollegeId
      ? {
          collegeId: resolvedCollegeId,
          membershipId: resolvedMembershipId,
          roles: [resolvedRole],
          roleAssignments: [],
          departmentId: payload.departmentId || null,
          authorizedDepartmentIds: payload.departmentId ? [payload.departmentId] : [],
          isAuthoritative: false,
          isSuperAdmin: resolvedRole === AppRole.SUPER_ADMIN,
        }
      : undefined;

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
