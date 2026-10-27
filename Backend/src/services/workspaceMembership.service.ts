import mongoose from 'mongoose';
import { WorkspaceMembership, IWorkspaceMembership } from '../models/workspaceMembership.model';
import { WorkspaceRoleAssignment, IWorkspaceRoleAssignment } from '../models/workspaceRoleAssignment.model';
import { User } from '../models/user.model';
import { College } from '../models/college.model';
import { Department } from '../models/department.model';
import { AuditService } from './audit.service';
import { AppRole, ROLE_HIERARCHY } from '../constants/roles';
import { MembershipStatus, RoleAssignmentStatus, CollegeStatus } from '../constants/status';
import { ApiError } from '../utils/apiError';
import { logger } from '../utils/logger';

export interface CreateMembershipInput {
  userId: string | mongoose.Types.ObjectId;
  collegeId: string | mongoose.Types.ObjectId;
  status?: MembershipStatus;
  isDefault?: boolean;
  title?: string;
  joinedAt?: Date;
  statusReason?: string;
  metadata?: Record<string, unknown>;
}

export interface AddRoleAssignmentInput {
  membershipId: string | mongoose.Types.ObjectId;
  role: AppRole;
  departmentId?: string | mongoose.Types.ObjectId | null;
  status?: RoleAssignmentStatus;
  scope?: Record<string, unknown> | null;
  statusReason?: string;
}

export interface ActorContext {
  id: string;
  email?: string;
  role?: string;
}

export class WorkspaceMembershipService {
  /**
   * Creates or establishes a canonical WorkspaceMembership for a user and college.
   */
  static async createMembership(
    input: CreateMembershipInput,
    actor?: ActorContext
  ): Promise<IWorkspaceMembership> {
    const userObjectId = new mongoose.Types.ObjectId(input.userId);
    const collegeObjectId = new mongoose.Types.ObjectId(input.collegeId);

    // 1. Verify User exists
    const user = await User.findById(userObjectId);
    if (!user) {
      throw ApiError.notFound('User identity does not exist');
    }

    // 2. Verify College exists and is active
    const college = await College.findById(collegeObjectId);
    if (!college) {
      throw ApiError.notFound('Target college does not exist');
    }
    if (college.status === CollegeStatus.INACTIVE || !college.isActive) {
      throw ApiError.forbidden('Cannot create membership in an inactive college');
    }

    // 3. Check for existing membership (idempotency & duplicate protection)
    const existing = await WorkspaceMembership.findOne({
      userId: userObjectId,
      collegeId: collegeObjectId,
    });

    if (existing) {
      return existing;
    }

    // 4. Create WorkspaceMembership
    const membership = await WorkspaceMembership.create({
      userId: userObjectId,
      collegeId: collegeObjectId,
      status: input.status || MembershipStatus.PENDING,
      isDefault: input.isDefault ?? false,
      title: input.title || null,
      joinedAt: input.joinedAt || new Date(),
      statusReason: input.statusReason || null,
      metadata: input.metadata || null,
      createdBy: actor?.id || null,
    });

    // 5. Audit Log
    await AuditService.log({
      collegeId: collegeObjectId.toString(),
      workspaceMembershipId: membership.id,
      actorUserId: actor?.id || user.id,
      actorEmail: actor?.email,
      actorRole: actor?.role,
      action: 'WORKSPACE_MEMBERSHIP_CREATED',
      entityType: 'WorkspaceMembership',
      entityId: membership.id,
      newValue: {
        userId: userObjectId.toString(),
        collegeId: collegeObjectId.toString(),
        status: membership.status,
        isDefault: membership.isDefault,
      },
    }).catch((err) => logger.warn(`Audit log failed for membership creation: ${err.message}`));

    return membership;
  }

  /**
   * Assigns an explicitly authorized institutional role to an existing WorkspaceMembership.
   */
  static async addRoleAssignment(
    input: AddRoleAssignmentInput,
    actor?: ActorContext
  ): Promise<IWorkspaceRoleAssignment> {
    const membershipObjectId = new mongoose.Types.ObjectId(input.membershipId);

    // 1. Find Membership
    const membership = await WorkspaceMembership.findById(membershipObjectId);
    if (!membership) {
      throw ApiError.notFound('Workspace membership not found');
    }

    // 2. Validate department if supplied
    let departmentObjectId: mongoose.Types.ObjectId | null = null;
    if (input.departmentId) {
      departmentObjectId = new mongoose.Types.ObjectId(input.departmentId);
      const dept = await Department.findById(departmentObjectId);
      if (!dept) {
        throw ApiError.notFound('Department not found');
      }
      if (dept.collegeId.toString() !== membership.collegeId.toString()) {
        throw ApiError.badRequest('Department does not belong to the target college');
      }
    }

    // 3. HOD and Faculty roles require department scope
    if (input.role === AppRole.HOD && !departmentObjectId) {
      throw ApiError.badRequest('departmentId is strictly required for HOD role assignment');
    }

    // 4. Prevent duplicate identical assignment
    const query: Record<string, unknown> = {
      membershipId: membership._id,
      role: input.role,
      departmentId: departmentObjectId,
    };

    const existing = await WorkspaceRoleAssignment.findOne(query);
    if (existing) {
      if (existing.status !== RoleAssignmentStatus.ACTIVE && input.status === RoleAssignmentStatus.ACTIVE) {
        existing.status = RoleAssignmentStatus.ACTIVE;
        existing.revokedAt = null;
        existing.statusReason = input.statusReason || 'Reactivated role assignment';
        await existing.save();
      }
      return existing;
    }

    // 5. Create role assignment
    const roleAssignment = await WorkspaceRoleAssignment.create({
      membershipId: membership._id,
      userId: membership.userId,
      collegeId: membership.collegeId,
      role: input.role,
      departmentId: departmentObjectId,
      status: input.status || RoleAssignmentStatus.ACTIVE,
      scope: input.scope || null,
      assignedAt: new Date(),
      assignedBy: actor?.id || null,
      statusReason: input.statusReason || null,
    });

    // 6. Audit Log
    await AuditService.log({
      collegeId: membership.collegeId.toString(),
      workspaceMembershipId: membership.id,
      departmentId: departmentObjectId ? departmentObjectId.toString() : undefined,
      actorUserId: actor?.id || membership.userId.toString(),
      actorEmail: actor?.email,
      actorRole: actor?.role,
      action: 'WORKSPACE_ROLE_ASSIGNED',
      entityType: 'WorkspaceRoleAssignment',
      entityId: roleAssignment.id,
      newValue: {
        membershipId: membership.id,
        userId: membership.userId.toString(),
        collegeId: membership.collegeId.toString(),
        role: input.role,
        departmentId: departmentObjectId ? departmentObjectId.toString() : null,
        status: roleAssignment.status,
      },
    }).catch((err) => logger.warn(`Audit log failed for role assignment: ${err.message}`));

    // Authoritative Realtime Role Revalidation
    try {
      const { RoomManager } = await import('../realtime/roomManager');
      await RoomManager.getInstance().revalidateUserAuthorization(
        membership.userId.toString(),
        membership.collegeId.toString()
      );
    } catch (_) {}

    return roleAssignment;
  }

  /**
   * Updates membership lifecycle status with cascading role protection.
   */
  static async updateMembershipStatus(
    membershipId: string | mongoose.Types.ObjectId,
    newStatus: MembershipStatus,
    reason?: string,
    actor?: ActorContext
  ): Promise<IWorkspaceMembership> {
    const membership = await WorkspaceMembership.findById(membershipId);
    if (!membership) {
      throw ApiError.notFound('Workspace membership not found');
    }

    const previousStatus = membership.status;
    membership.status = newStatus;
    membership.statusReason = reason || null;
    membership.updatedBy = actor?.id || null;

    if (newStatus === MembershipStatus.SUSPENDED) {
      membership.suspendedAt = new Date();
    } else if (newStatus === MembershipStatus.REVOKED) {
      membership.revokedAt = new Date();
    } else if (newStatus === MembershipStatus.ACTIVE) {
      membership.suspendedAt = null;
      membership.revokedAt = null;
    }

    await membership.save();

    // Cascading role assignment protection: if membership is revoked or suspended, suspend roles
    if (newStatus === MembershipStatus.SUSPENDED || newStatus === MembershipStatus.REVOKED) {
      const targetRoleStatus =
        newStatus === MembershipStatus.REVOKED
          ? RoleAssignmentStatus.REVOKED
          : RoleAssignmentStatus.SUSPENDED;

      await WorkspaceRoleAssignment.updateMany(
        { membershipId: membership._id, status: RoleAssignmentStatus.ACTIVE },
        {
          $set: {
            status: targetRoleStatus,
            revokedAt: new Date(),
            revokedBy: actor?.id || null,
            statusReason: `Cascaded from membership transition to ${newStatus}`,
          },
        }
      );
    }

    // Audit log
    await AuditService.log({
      collegeId: membership.collegeId.toString(),
      workspaceMembershipId: membership.id,
      actorUserId: actor?.id || 'system',
      actorEmail: actor?.email,
      actorRole: actor?.role,
      action: `WORKSPACE_MEMBERSHIP_${newStatus.toUpperCase()}`,
      entityType: 'WorkspaceMembership',
      entityId: membership.id,
      previousValue: { status: previousStatus },
      newValue: { status: newStatus, reason },
    }).catch((err) => logger.warn(`Audit log failed for membership status update: ${err.message}`));

    // Authoritative Realtime Revocation / Revalidation
    try {
      const { RoomManager } = await import('../realtime/roomManager');
      if (newStatus !== MembershipStatus.ACTIVE) {
        RoomManager.getInstance().revokeWorkspaceForUser(
          membership.userId.toString(),
          membership.collegeId.toString(),
          `Membership transitioned to ${newStatus}`
        );
      } else {
        await RoomManager.getInstance().revalidateUserAuthorization(
          membership.userId.toString(),
          membership.collegeId.toString()
        );
      }
    } catch (e: any) {
      logger.warn(`Realtime invalidation hook skipped: ${e?.message}`);
    }

    return membership;
  }

  /**
   * Updates role assignment lifecycle status independently.
   */
  static async updateRoleAssignmentStatus(
    assignmentId: string | mongoose.Types.ObjectId,
    newStatus: RoleAssignmentStatus,
    reason?: string,
    actor?: ActorContext
  ): Promise<IWorkspaceRoleAssignment> {
    const assignment = await WorkspaceRoleAssignment.findById(assignmentId);
    if (!assignment) {
      throw ApiError.notFound('Role assignment not found');
    }

    const previousStatus = assignment.status;
    assignment.status = newStatus;
    assignment.statusReason = reason || null;

    if (newStatus === RoleAssignmentStatus.REVOKED || newStatus === RoleAssignmentStatus.SUSPENDED) {
      assignment.revokedAt = new Date();
      assignment.revokedBy = actor?.id || null;
    } else if (newStatus === RoleAssignmentStatus.ACTIVE) {
      assignment.revokedAt = null;
      assignment.revokedBy = null;
    }

    await assignment.save();

    await AuditService.log({
      collegeId: assignment.collegeId.toString(),
      workspaceMembershipId: assignment.membershipId.toString(),
      departmentId: assignment.departmentId ? assignment.departmentId.toString() : undefined,
      actorUserId: actor?.id || 'system',
      actorEmail: actor?.email,
      actorRole: actor?.role,
      action: `WORKSPACE_ROLE_${newStatus.toUpperCase()}`,
      entityType: 'WorkspaceRoleAssignment',
      entityId: assignment.id,
      previousValue: { status: previousStatus },
      newValue: { status: newStatus, reason },
    }).catch((err) => logger.warn(`Audit log failed for role status update: ${err.message}`));

    // Authoritative Realtime Role Revalidation
    try {
      const { RoomManager } = await import('../realtime/roomManager');
      await RoomManager.getInstance().revalidateUserAuthorization(
        assignment.userId.toString(),
        assignment.collegeId.toString()
      );
    } catch (e: any) {
      logger.warn(`Realtime role revalidation failed: ${e?.message}`);
    }

    return assignment;
  }

  /**
   * Retrieves all eligible memberships for a given user.
   */
  static async getMembershipsForUser(
    userId: string | mongoose.Types.ObjectId,
    statuses: MembershipStatus[] = [MembershipStatus.ACTIVE]
  ): Promise<Array<IWorkspaceMembership & { roles: IWorkspaceRoleAssignment[]; college?: any }>> {
    const memberships = await WorkspaceMembership.find({
      userId: new mongoose.Types.ObjectId(userId),
      status: { $in: statuses },
    })
      .populate('collegeId')
      .sort({ isDefault: -1, createdAt: 1 });

    const results = [];
    for (const mem of memberships) {
      const roles = await WorkspaceRoleAssignment.find({
        membershipId: mem._id,
        status: RoleAssignmentStatus.ACTIVE,
      }).populate('departmentId');

      results.push({
        ...mem.toObject(),
        instituteId: mem.instituteId || null,
        roles,
        college: (mem as any).collegeId,
      });
    }

    return results as any;
  }

  /**
   * Retrieves strictly eligible memberships for a given user for active workspace entry.
   * Enforces:
   * 1. Membership status is ACTIVE
   * 2. Effective date range is valid (effectiveStartDate <= now <= effectiveEndDate)
   * 3. Target college is active (status !== INACTIVE && isActive !== false)
   * 4. Has at least one active, date-valid WorkspaceRoleAssignment
   */
  static async getEligibleMembershipsForUser(
    userId: string | mongoose.Types.ObjectId
  ): Promise<Array<IWorkspaceMembership & { roles: IWorkspaceRoleAssignment[]; primaryRole: AppRole; college: any }>> {
    const rawMemberships = await this.getMembershipsForUser(userId, [MembershipStatus.ACTIVE]);
    const now = new Date();

    const eligible = [];
    for (const mem of rawMemberships) {
      // 1. Check membership effective dates
      if (mem.effectiveStartDate && new Date(mem.effectiveStartDate) > now) {
        continue;
      }
      if (mem.effectiveEndDate && new Date(mem.effectiveEndDate) < now) {
        continue;
      }

      // 2. Check college is active
      const college = mem.college;
      if (!college || college.isActive === false || college.status === CollegeStatus.INACTIVE) {
        continue;
      }

      // 3. Filter roles by active status and date validity
      const validRoles = (mem.roles || []).filter((r: IWorkspaceRoleAssignment) => {
        if (r.status !== RoleAssignmentStatus.ACTIVE) return false;
        if (r.effectiveStartDate && new Date(r.effectiveStartDate) > now) return false;
        if (r.effectiveEndDate && new Date(r.effectiveEndDate) < now) return false;
        return true;
      });

      if (validRoles.length === 0) {
        continue;
      }

      // Resolve primary role by hierarchy
      let primaryRole = validRoles[0].role;
      let maxWeight = ROLE_HIERARCHY[primaryRole] ?? 0;
      for (const r of validRoles) {
        const weight = ROLE_HIERARCHY[r.role] ?? 0;
        if (weight > maxWeight) {
          maxWeight = weight;
          primaryRole = r.role;
        }
      }

      eligible.push({
        ...mem,
        instituteId: mem.instituteId || null,
        roles: validRoles,
        primaryRole,
        college,
      });
    }

    return eligible as any;
  }

  /**
   * Retrieves active membership and authorized role assignments in a specific college.
   */
  static async getActiveMembershipWithRoles(
    userId: string | mongoose.Types.ObjectId,
    collegeId: string | mongoose.Types.ObjectId
  ): Promise<{
    membership: IWorkspaceMembership;
    roles: IWorkspaceRoleAssignment[];
  } | null> {
    const membership = await WorkspaceMembership.findOne({
      userId: new mongoose.Types.ObjectId(userId),
      collegeId: new mongoose.Types.ObjectId(collegeId),
      status: MembershipStatus.ACTIVE,
    });

    if (!membership) {
      return null;
    }

    const roles = await WorkspaceRoleAssignment.find({
      membershipId: membership._id,
      status: RoleAssignmentStatus.ACTIVE,
    });

    return { membership, roles };
  }

  /**
   * Returns whether a user possesses an authorized role in a given college context.
   */
  static async hasRole(
    userId: string | mongoose.Types.ObjectId,
    collegeId: string | mongoose.Types.ObjectId,
    role: AppRole,
    departmentId?: string | mongoose.Types.ObjectId | null
  ): Promise<boolean> {
    const filter: Record<string, unknown> = {
      userId: new mongoose.Types.ObjectId(userId),
      collegeId: new mongoose.Types.ObjectId(collegeId),
      role,
      status: RoleAssignmentStatus.ACTIVE,
    };

    if (departmentId) {
      filter.departmentId = new mongoose.Types.ObjectId(departmentId);
    }

    const assignment = await WorkspaceRoleAssignment.findOne(filter);
    if (!assignment) {
      return false;
    }

    // Verify parent membership is also active
    const membership = await WorkspaceMembership.findById(assignment.membershipId);
    return membership !== null && membership.status === MembershipStatus.ACTIVE;
  }
}
