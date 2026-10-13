import mongoose from 'mongoose';
import { WorkspaceMembership } from '../models/workspaceMembership.model';
import { WorkspaceRoleAssignment } from '../models/workspaceRoleAssignment.model';
import { MembershipStatus, RoleAssignmentStatus } from '../constants/status';
import { AppRole } from '../constants/roles';

export interface EffectiveWorkspaceContext {
  collegeId: string;
  role: AppRole;
  departmentId?: string | null;
  membershipId?: string | null;
  isAuthoritative: boolean;
}

export class WorkspaceCompatibilityService {
  /**
   * Global configuration switch controlling whether legacy fallback is permitted.
   * Can be toggled via environment or test fixtures. Defaults to true during transition.
   */
  private static legacyFallbackEnabled: boolean = true;

  public static setLegacyFallbackEnabled(enabled: boolean): void {
    this.legacyFallbackEnabled = enabled;
  }

  public static isLegacyFallbackEnabled(): boolean {
    return this.legacyFallbackEnabled;
  }

  /**
   * Resolves the effective workspace context for a user and requested college.
   *
   * RULES:
   * 1. If an authoritative WorkspaceMembership exists:
   *    - If status is SUSPENDED, REVOKED, or INACTIVE: FAILS CLOSED (returns null).
   *      Legacy fields CANNOT restore access.
   *    - If status is ACTIVE: Returns verified membership and primary role assignment.
   * 2. If NO WorkspaceMembership exists and legacy fallback is enabled:
   *    - Validates legacy user.collegeId matches requested college.
   *    - Returns legacy college and role as unmigrated context.
   * 3. If legacy fallback is disabled:
   *    - Requires authoritative WorkspaceMembership. Fails closed if absent.
   */
  static async resolveEffectiveWorkspace(
    userId: string,
    requestedCollegeId?: string,
    legacyUserFallback?: {
      collegeId?: string | null;
      role?: AppRole | null;
      departmentId?: string | null;
    }
  ): Promise<EffectiveWorkspaceContext | null> {
    const userObjectId = new mongoose.Types.ObjectId(userId);

    // If requestedCollegeId is provided, look up authoritative membership for that college
    if (requestedCollegeId && mongoose.Types.ObjectId.isValid(requestedCollegeId)) {
      const collegeObjectId = new mongoose.Types.ObjectId(requestedCollegeId);
      const membership = await WorkspaceMembership.findOne({
        userId: userObjectId,
        collegeId: collegeObjectId,
      });

      if (membership) {
        // Authoritative membership exists: enforce explicit lifecycle state
        if (membership.status !== MembershipStatus.ACTIVE) {
          // Bounded rule: A revoked/suspended membership CAN NEVER be overridden by legacy fields
          return null;
        }

        // Fetch active role assignment
        const roleAssignment = await WorkspaceRoleAssignment.findOne({
          membershipId: membership._id,
          status: RoleAssignmentStatus.ACTIVE,
        }).sort({ createdAt: 1 });

        if (!roleAssignment) {
          return null;
        }

        return {
          collegeId: membership.collegeId.toString(),
          role: roleAssignment.role,
          departmentId: roleAssignment.departmentId ? roleAssignment.departmentId.toString() : null,
          membershipId: membership.id,
          isAuthoritative: true,
        };
      }
    }

    // No authoritative membership was found for the requested college.
    // Check if legacy fallback is permitted.
    if (!this.legacyFallbackEnabled || !legacyUserFallback || !legacyUserFallback.collegeId) {
      return null;
    }

    // If a specific college was requested, verify it matches legacy college
    if (requestedCollegeId && requestedCollegeId !== legacyUserFallback.collegeId) {
      return null;
    }

    // Verify user doesn't have an inactive/revoked membership for this legacy college
    const existingMembership = await WorkspaceMembership.findOne({
      userId: userObjectId,
      collegeId: new mongoose.Types.ObjectId(legacyUserFallback.collegeId),
    });

    if (existingMembership && existingMembership.status !== MembershipStatus.ACTIVE) {
      return null;
    }

    return {
      collegeId: legacyUserFallback.collegeId,
      role: legacyUserFallback.role || AppRole.STUDENT,
      departmentId: legacyUserFallback.departmentId || null,
      membershipId: null,
      isAuthoritative: false,
    };
  }
}
