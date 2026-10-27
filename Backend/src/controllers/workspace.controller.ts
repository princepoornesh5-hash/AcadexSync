import { Request, Response } from 'express';
import mongoose from 'mongoose';
import { WorkspaceMembershipService } from '../services/workspaceMembership.service';
import { WorkspaceMembership } from '../models/workspaceMembership.model';
import { WorkspaceRoleAssignment } from '../models/workspaceRoleAssignment.model';
import { College } from '../models/college.model';
import { User } from '../models/user.model';
import { AuditService } from '../services/audit.service';
import { ApiResponse } from '../utils/apiResponse';
import { ApiError } from '../utils/apiError';
import { asyncHandler } from '../utils/asyncHandler';
import { AppRole, ROLE_HIERARCHY } from '../constants/roles';
import { MembershipStatus, RoleAssignmentStatus, CollegeStatus } from '../constants/status';
import { signAccessToken } from '../utils/token';

export interface WorkspaceResponseItem {
  membershipId: string;
  collegeId: string;
  collegeName: string;
  collegeCode: string;
  instituteId?: string | null;
  status: string;
  isDefault: boolean;
  roles: AppRole[];
  primaryRole?: AppRole;
  departments: Array<{
    id: string;
    name: string;
    code: string;
  }>;
  joinedAt?: Date;
  effectiveStartDate?: Date;
  effectiveEndDate?: Date | null;
}

export class WorkspaceController {
  /**
   * GET /api/v1/workspaces/my-memberships
   * Returns all eligible, active workspace memberships for the authenticated user.
   */
  static getMyMemberships = asyncHandler(async (req: Request, res: Response) => {
    const userId = req.user?.id;
    if (!userId) {
      throw ApiError.unauthorized('User identity not authenticated');
    }

    // Super Admin platform access
    if (req.user?.isSuperAdmin || req.user?.role === AppRole.SUPER_ADMIN) {
      const activeColleges = await College.find({
        status: { $ne: CollegeStatus.INACTIVE },
        isActive: true,
      })
        .sort({ name: 1 })
        .lean();

      const platformWorkspaces: WorkspaceResponseItem[] = activeColleges.map((col) => ({
        membershipId: `super-admin-${col._id.toString()}`,
        collegeId: col._id.toString(),
        collegeName: col.name,
        collegeCode: col.code,
        status: 'ACTIVE',
        isDefault: false,
        roles: [AppRole.SUPER_ADMIN],
        primaryRole: AppRole.SUPER_ADMIN,
        departments: [],
      }));

      return ApiResponse.success(
        res,
        platformWorkspaces,
        'Platform workspaces retrieved successfully'
      );
    }

    // Authoritative lookup via WorkspaceMembershipService
    const rawMemberships = await WorkspaceMembershipService.getMembershipsForUser(
      userId,
      [MembershipStatus.ACTIVE]
    );

    const now = new Date();

    // Format response deterministically with date-validity check
    const formatted: WorkspaceResponseItem[] = rawMemberships
      .filter((mem) => {
        if (!mem.college || (mem.college as any).isActive === false) return false;
        if (mem.effectiveStartDate && new Date(mem.effectiveStartDate) > now) return false;
        if (mem.effectiveEndDate && new Date(mem.effectiveEndDate) < now) return false;
        return true;
      })
      .map((mem) => {
        const collegeObj = mem.college as any;
        const activeRoles = mem.roles.map((r) => r.role);
        let primaryRole = activeRoles[0] || AppRole.STUDENT;
        let maxWeight = ROLE_HIERARCHY[primaryRole] ?? 0;
        for (const r of activeRoles) {
          const weight = ROLE_HIERARCHY[r] ?? 0;
          if (weight > maxWeight) {
            maxWeight = weight;
            primaryRole = r;
          }
        }

        const departments = mem.roles
          .filter((r) => r.departmentId)
          .map((r) => {
            const deptObj = r.departmentId as any;
            return {
              id: deptObj._id?.toString() || deptObj.toString(),
              name: deptObj.name || '',
              code: deptObj.code || '',
            };
          });

        return {
          membershipId: mem._id.toString(),
          collegeId: collegeObj._id?.toString() || collegeObj.toString(),
          collegeName: collegeObj.name || 'Campus Workspace',
          collegeCode: collegeObj.code || '',
          instituteId: mem.instituteId || null,
          status: mem.status,
          isDefault: mem.isDefault || false,
          roles: activeRoles,
          primaryRole,
          departments,
          joinedAt: mem.joinedAt,
          effectiveStartDate: mem.effectiveStartDate,
          effectiveEndDate: mem.effectiveEndDate,
        };
      });

    return ApiResponse.success(res, formatted, 'User workspaces retrieved successfully');
  });

  /**
   * POST /api/v1/workspaces/switch
   * Explicitly switches the authenticated active workspace.
   * Validates target membership server-side, audits the switch, and returns updated context.
   */
  static switchWorkspace = asyncHandler(async (req: Request, res: Response) => {
    const userId = req.user?.id;
    if (!userId) {
      throw ApiError.unauthorized('User not authenticated');
    }

    const { targetCollegeId, targetMembershipId } = req.body;

    const dbUser = await User.findById(userId);
    if (!dbUser) {
      throw ApiError.unauthorized('User record does not exist');
    }

    // 1. SUPER_ADMIN Handling
    if (dbUser.role === AppRole.SUPER_ADMIN || req.user?.isSuperAdmin) {
      // Returning to platform context
      if (!targetCollegeId || targetCollegeId === 'platform' || targetCollegeId === 'global') {
        const accessToken = signAccessToken({
          userId: dbUser.id,
          instituteId: dbUser.instituteId,
          email: dbUser.email,
          phone: dbUser.phone,
          name: dbUser.name,
          role: AppRole.SUPER_ADMIN,
          collegeId: undefined,
          sessionId: req.user?.sessionId,
        });

        await AuditService.log({
          actorUserId: dbUser.id,
          actorRole: AppRole.SUPER_ADMIN,
          action: 'WORKSPACE_SWITCHED_PLATFORM',
          entityType: 'User',
          entityId: dbUser.id,
          metadata: {
            previousWorkspaceId: req.user?.collegeId,
            targetWorkspaceId: 'platform',
          },
        });

        return ApiResponse.success(
          res,
          {
            accessToken,
            activeWorkspace: {
              workspaceId: 'platform',
              membershipId: 'platform-super-admin',
              collegeName: 'Acadex Global Platform',
              collegeCode: 'PLATFORM',
              status: 'ACTIVE',
              roles: [AppRole.SUPER_ADMIN],
              isPlatform: true,
            },
            user: {
              id: dbUser.id,
              name: dbUser.name,
              email: dbUser.email,
              role: AppRole.SUPER_ADMIN,
              collegeId: null,
              activeRoles: [AppRole.SUPER_ADMIN],
              departmentId: null,
            },
          },
          'Returned to platform context successfully'
        );
      }

      // Switching into an institutional college
      if (!mongoose.Types.ObjectId.isValid(targetCollegeId)) {
        throw ApiError.badRequest('A valid targetCollegeId is required for workspace switching');
      }

      const targetCollege = await College.findById(targetCollegeId);
      if (!targetCollege || !targetCollege.isActive || targetCollege.status === CollegeStatus.INACTIVE) {
        throw ApiError.notFound('Target workspace does not exist or is currently inactive');
      }

      const accessToken = signAccessToken({
        userId: dbUser.id,
        instituteId: dbUser.instituteId,
        email: dbUser.email,
        phone: dbUser.phone,
        name: dbUser.name,
        role: AppRole.SUPER_ADMIN,
        collegeId: targetCollege.id,
        sessionId: req.user?.sessionId,
      });

      await AuditService.log({
        collegeId: targetCollege.id,
        actorUserId: dbUser.id,
        actorRole: AppRole.SUPER_ADMIN,
        action: 'WORKSPACE_SWITCHED',
        entityType: 'College',
        entityId: targetCollege.id,
        metadata: {
          previousWorkspaceId: req.user?.collegeId,
          targetWorkspaceId: targetCollege.id,
        },
      });

      return ApiResponse.success(
        res,
        {
          accessToken,
          activeWorkspace: {
            workspaceId: targetCollege.id,
            membershipId: `super-admin-${targetCollege.id}`,
            collegeName: targetCollege.name,
            collegeCode: targetCollege.code,
            status: 'ACTIVE',
            roles: [AppRole.SUPER_ADMIN],
            isPlatform: true,
          },
          user: {
            id: dbUser.id,
            name: dbUser.name,
            email: dbUser.email,
            role: AppRole.SUPER_ADMIN,
            collegeId: targetCollege.id,
            activeRoles: [AppRole.SUPER_ADMIN],
          },
        },
        'Workspace switched successfully'
      );
    }

    // 2. Regular institutional users: resolve target membership & college
    let membership = null;
    let targetCollege = null;

    if (targetMembershipId) {
      if (!mongoose.Types.ObjectId.isValid(targetMembershipId)) {
        throw ApiError.badRequest('Invalid membership identifier format');
      }
      membership = await WorkspaceMembership.findById(targetMembershipId);
      if (!membership) {
        throw ApiError.notFound('Target workspace membership not found');
      }
      if (membership.userId.toString() !== dbUser.id) {
        await AuditService.log({
          actorUserId: dbUser.id,
          action: 'WORKSPACE_ACCESS_DENIED',
          entityType: 'WorkspaceMembership',
          entityId: membership.id,
          collegeId: membership.collegeId.toString(),
          metadata: { reason: 'Unauthorized access to requested workspace membership' },
        });
        throw ApiError.forbidden('Unauthorized access to requested workspace membership');
      }
      targetCollege = await College.findById(membership.collegeId);
      if (!targetCollege || !targetCollege.isActive || targetCollege.status === CollegeStatus.INACTIVE) {
        throw ApiError.notFound('Target workspace does not exist or is currently inactive');
      }
    } else {
      if (!targetCollegeId || !mongoose.Types.ObjectId.isValid(targetCollegeId)) {
        throw ApiError.badRequest('A valid targetCollegeId or targetMembershipId is required for workspace switching');
      }

      targetCollege = await College.findById(targetCollegeId);
      if (!targetCollege || !targetCollege.isActive || targetCollege.status === CollegeStatus.INACTIVE) {
        throw ApiError.notFound('Target workspace does not exist or is currently inactive');
      }

      membership = await WorkspaceMembership.findOne({
        userId: dbUser._id,
        collegeId: targetCollege._id,
      });

      if (!membership) {
        throw ApiError.forbidden(
          'User does not hold an active membership in the requested workspace.'
        );
      }
    }

    if (membership.status !== MembershipStatus.ACTIVE) {
      throw ApiError.forbidden(
        `Workspace membership is ${membership.status.toLowerCase()}. Access denied.`
      );
    }

    const now = new Date();
    if (membership.effectiveStartDate && new Date(membership.effectiveStartDate) > now) {
      throw ApiError.forbidden('Workspace membership is not yet effective.');
    }
    if (membership.effectiveEndDate && new Date(membership.effectiveEndDate) < now) {
      throw ApiError.forbidden('Workspace membership has expired.');
    }

    // Load active role assignments for this workspace
    const rawRoleAssignments = await WorkspaceRoleAssignment.find({
      membershipId: membership._id,
      status: RoleAssignmentStatus.ACTIVE,
    }).populate('departmentId');

    const roleAssignments = rawRoleAssignments.filter((ra) => {
      if (ra.effectiveStartDate && new Date(ra.effectiveStartDate) > now) return false;
      if (ra.effectiveEndDate && new Date(ra.effectiveEndDate) < now) return false;
      return true;
    });

    if (roleAssignments.length === 0) {
      throw ApiError.forbidden('No active role assignments found for this workspace membership.');
    }

    // Determine primary active role by highest hierarchy
    const activeRoles = roleAssignments.map((ra) => ra.role);
    let primaryRole = activeRoles[0];
    let maxWeight = ROLE_HIERARCHY[primaryRole] ?? 0;

    for (const r of activeRoles) {
      const weight = ROLE_HIERARCHY[r] ?? 0;
      if (weight > maxWeight) {
        maxWeight = weight;
        primaryRole = r;
      }
    }

    const authorizedDepartmentIds = roleAssignments
      .filter((ra) => ra.departmentId)
      .map((ra) => (ra.departmentId as any)._id?.toString() || ra.departmentId?.toString());

    // Resolve institution-specific PIN Number (DO NOT use global if membership has its own PIN)
    const activeInstituteId = membership.instituteId || dbUser.instituteId;

    // Issue refreshed token for the current session bound to the target workspace
    const accessToken = signAccessToken({
      userId: dbUser.id,
      instituteId: activeInstituteId,
      email: dbUser.email,
      phone: dbUser.phone,
      name: dbUser.name,
      role: primaryRole,
      collegeId: targetCollege.id,
      departmentId: authorizedDepartmentIds[0],
      workspaceMembershipId: membership.id,
      membershipId: membership.id,
      sessionId: req.user?.sessionId,
    });

    // Authoritative Audit Logging
    await AuditService.logAuthoritativeAction(
      {
        ...req.user!,
        collegeId: targetCollege.id,
        workspaceMembershipId: membership._id.toString(),
        instituteId: activeInstituteId,
        role: primaryRole,
        activeRoles,
        authorizedDepartmentIds,
      },
      'WORKSPACE_SWITCHED',
      'WorkspaceMembership',
      membership._id.toString(),
      {
        metadata: {
          previousWorkspaceId: req.user?.collegeId,
          targetWorkspaceId: targetCollege.id,
          instituteId: activeInstituteId,
          activeRoles,
        },
      }
    );

    return ApiResponse.success(
      res,
      {
        accessToken,
        activeWorkspace: {
          workspaceId: targetCollege.id,
          membershipId: membership._id.toString(),
          collegeName: targetCollege.name,
          collegeCode: targetCollege.code,
          instituteId: activeInstituteId,
          status: membership.status,
          roles: activeRoles,
          role: primaryRole,
          primaryRole,
          departmentId: authorizedDepartmentIds[0] || null,
          isPlatform: false,
        },
        user: {
          id: dbUser.id,
          name: dbUser.name,
          email: dbUser.email,
          role: primaryRole,
          collegeId: targetCollege.id,
          instituteId: activeInstituteId,
          workspaceMembershipId: membership._id.toString(),
          activeRoles,
          departmentId: authorizedDepartmentIds[0] || null,
        },
      },
      'Workspace switched successfully'
    );
  });
}
