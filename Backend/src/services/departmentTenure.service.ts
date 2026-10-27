import mongoose from 'mongoose';
import {
  DepartmentTenure,
  IDepartmentTenure,
  Department,
  User,
  Faculty,
  WorkspaceMembership,
  WorkspaceRoleAssignment,
  AuditLog,
} from '../models';
import { AppRole } from '../constants/roles';
import { RoleAssignmentStatus, MembershipStatus } from '../constants/status';
import { ApiError } from '../utils/apiError';
import { AuthenticatedUser } from '../types/auth.types';

export interface AppointHodInput {
  collegeId?: string;
  departmentId: string;
  newHodUserId: string;
  notes?: string;
}

export class DepartmentTenureService {
  /**
   * Appoint a new HOD for a department:
   * 1. Closes any existing active tenure for the department (status: 'COMPLETED', endDate: now).
   * 2. Revokes former HOD's WorkspaceRoleAssignment for HOD in this department.
   * 3. Creates new active DepartmentTenure record.
   * 4. Ensures new HOD has an active WorkspaceRoleAssignment for role: AppRole.HOD.
   * 5. Updates Department.hodId pointer for backward compatibility.
   * 6. Ensures former HOD's past approvals, marks, and audit events remain attributed to them.
   */
  static async appointHod(
    requester: AuthenticatedUser,
    input: AppointHodInput
  ): Promise<{
    tenure: IDepartmentTenure;
    previousTenure?: IDepartmentTenure | null;
  }> {
    // 1. Authorize actor
    if (![AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN].includes(requester.role)) {
      throw ApiError.forbidden('Only College Administrators or Super Admins can appoint Department HODs');
    }

    // 2. Resolve college scope
    const collegeIdStr = requester.role === AppRole.SUPER_ADMIN && input.collegeId
      ? input.collegeId
      : requester.collegeId;

    if (!collegeIdStr || !mongoose.Types.ObjectId.isValid(collegeIdStr)) {
      throw ApiError.badRequest('Valid college identifier is required');
    }
    const collegeId = new mongoose.Types.ObjectId(collegeIdStr);

    if (!mongoose.Types.ObjectId.isValid(input.departmentId)) {
      throw ApiError.badRequest('Invalid departmentId format');
    }
    if (!mongoose.Types.ObjectId.isValid(input.newHodUserId)) {
      throw ApiError.badRequest('Invalid newHodUserId format');
    }

    const department = await Department.findOne({
      _id: new mongoose.Types.ObjectId(input.departmentId),
      collegeId,
    });
    if (!department) {
      throw ApiError.notFound('Department not found in this institution');
    }

    // 3. Resolve target user & institutional membership
    const user = await User.findById(input.newHodUserId);
    if (!user) {
      throw ApiError.notFound('Target user not found');
    }

    // Check membership in this college
    let membership = await WorkspaceMembership.findOne({
      userId: user._id,
      collegeId,
      status: { $in: [MembershipStatus.ACTIVE, MembershipStatus.PENDING] },
    });

    if (!membership) {
      // Auto-create membership if user has legacy collegeId match
      if (user.collegeId && user.collegeId.toString() === collegeId.toString()) {
        membership = await WorkspaceMembership.create({
          userId: user._id,
          collegeId,
          instituteId: user.instituteId || `HOD-${Date.now().toString().slice(-4)}`,
          status: MembershipStatus.ACTIVE,
          effectiveStartDate: new Date(),
        });
      } else {
        throw ApiError.badRequest('Target user does not possess an active membership in this college');
      }
    }

    // Resolve optional faculty profile
    const faculty = await Faculty.findOne({
      userId: user._id,
      collegeId,
    });

    // 4. Close any currently active DepartmentTenure
    const activeTenure = await DepartmentTenure.findOne({
      departmentId: department._id,
      status: 'ACTIVE',
    });

    let previousTenure: IDepartmentTenure | null = null;

    if (activeTenure) {
      if (activeTenure.userId.toString() === user._id.toString()) {
        throw ApiError.conflict('User is already the active HOD for this department');
      }

      activeTenure.status = 'COMPLETED';
      activeTenure.endDate = new Date();
      activeTenure.revokedBy = new mongoose.Types.ObjectId(requester.id);
      activeTenure.revokedAt = new Date();
      await activeTenure.save();
      previousTenure = activeTenure;

      // Revoke former HOD's active role assignment for HOD in this department
      await WorkspaceRoleAssignment.updateMany(
        {
          userId: activeTenure.userId,
          collegeId,
          departmentId: department._id,
          role: AppRole.HOD,
          status: RoleAssignmentStatus.ACTIVE,
        },
        {
          $set: {
            status: RoleAssignmentStatus.REVOKED,
            revokedAt: new Date(),
            revokedBy: requester.id,
            effectiveEndDate: new Date(),
            statusReason: 'Succession to new HOD appointment',
          },
        }
      );
    }

    // 5. Create new DepartmentTenure
    const newTenure = await DepartmentTenure.create({
      collegeId,
      departmentId: department._id,
      userId: user._id,
      facultyId: faculty?._id || null,
      membershipId: membership._id,
      startDate: new Date(),
      status: 'ACTIVE',
      appointedBy: new mongoose.Types.ObjectId(requester.id),
      notes: input.notes || null,
    });

    // 6. Ensure active WorkspaceRoleAssignment for new HOD
    const existingRoleAssignment = await WorkspaceRoleAssignment.findOne({
      membershipId: membership._id,
      role: AppRole.HOD,
      departmentId: department._id,
    });

    if (existingRoleAssignment) {
      existingRoleAssignment.status = RoleAssignmentStatus.ACTIVE;
      existingRoleAssignment.revokedAt = null;
      existingRoleAssignment.revokedBy = null;
      existingRoleAssignment.effectiveStartDate = new Date();
      existingRoleAssignment.effectiveEndDate = null;
      await existingRoleAssignment.save();
    } else {
      await WorkspaceRoleAssignment.create({
        membershipId: membership._id,
        userId: user._id,
        collegeId,
        role: AppRole.HOD,
        departmentId: department._id,
        status: RoleAssignmentStatus.ACTIVE,
        assignedBy: requester.id,
        effectiveStartDate: new Date(),
      });
    }

    // 7. Update Department.hodId backward compatibility pointer
    department.hodId = user._id.toString();
    await department.save();

    // 8. Backward compatibility: sync user.role & departmentId
    user.role = AppRole.HOD;
    user.departmentId = department._id;
    await user.save();

    // 9. Audit log
    await AuditLog.create({
      collegeId: collegeId.toString(),
      actorUserId: requester.id,
      action: 'HOD_TENURE_APPOINTED',
      entityType: 'DepartmentTenure',
      entityId: newTenure.id,
      previousValue: previousTenure
        ? {
            tenureId: previousTenure.id,
            formerHodUserId: previousTenure.userId.toString(),
          }
        : null,
      newValue: {
        tenureId: newTenure.id,
        newHodUserId: user.id,
        departmentId: department.id,
      },
    });

    return {
      tenure: newTenure,
      previousTenure,
    };
  }

  /**
   * Get complete leadership tenure history for a department.
   */
  static async getTenureHistory(
    requester: AuthenticatedUser,
    collegeIdStr: string,
    departmentIdStr: string
  ): Promise<IDepartmentTenure[]> {
    if (!collegeIdStr || !mongoose.Types.ObjectId.isValid(collegeIdStr)) {
      throw ApiError.badRequest('Valid college identifier is required');
    }
    if (!departmentIdStr || !mongoose.Types.ObjectId.isValid(departmentIdStr)) {
      throw ApiError.badRequest('Valid departmentId format is required');
    }

    const collegeId = new mongoose.Types.ObjectId(collegeIdStr);
    const departmentId = new mongoose.Types.ObjectId(departmentIdStr);

    // Cross-tenant check
    if (requester.role === AppRole.COLLEGE_ADMIN && requester.collegeId) {
      if (requester.collegeId.toString() !== collegeId.toString()) {
        throw ApiError.forbidden('Cross-college tenant access is strictly prohibited');
      }
    }

    return DepartmentTenure.find({ collegeId, departmentId })
      .populate('userId', 'name email instituteId')
      .populate('facultyId', 'name designation')
      .sort({ startDate: -1 });
  }
}
