import mongoose from 'mongoose';
import { Invitation, IInvitation } from '../models/invitation.model';
import { User, IUser } from '../models/user.model';
import { College } from '../models/college.model';
import { Department } from '../models/department.model';
import { AuditLog } from '../models/auditLog.model';
import { WorkspaceMembership } from '../models/workspaceMembership.model';
import { WorkspaceRoleAssignment } from '../models/workspaceRoleAssignment.model';
import { AppRole } from '../constants/roles';
import { AccountStatus, CollegeStatus, DepartmentStatus, InvitationStatus, MembershipStatus, MembershipType, RoleAssignmentStatus } from '../constants/status';
import { PasswordService } from './password.service';
import {
  generateActivationCode,
  hashActivationCode,
  verifyActivationCode,
} from '../utils/activationCode';
import { normalizeEmail, normalizePhone } from '../utils/identifier';
import { ApiError } from '../utils/apiError';
import { env } from '../config/env';
import { AuthenticatedUser } from '../types/auth.types';

export interface CreateInvitationInput {
  name: string;
  instituteId: string;
  email?: string;
  phone?: string;
  role: AppRole;
  collegeId?: string;
  departmentId?: string;
  courseId?: string;
  sectionId?: string;
  semesterId?: string;
}

export interface CreateInvitationResult {
  invitation: IInvitation;
  activationCode: string;
  user: IUser;
  collegeCode?: string;
  collegeName?: string;
  isNewUser: boolean;
  isNewMembership: boolean;
  membershipId?: string;
}

export interface ReissueInvitationResult {
  invitation: IInvitation;
  activationCode: string;
  collegeCode?: string;
  collegeName?: string;
}

export interface ActivationResult {
  user: IUser;
  message: string;
}

export class InvitationService {
  /**
   * Verifies hierarchical role provisioning permissions.
   */
  private static async validateProvisioningAuthority(
    creator: AuthenticatedUser,
    targetRole: AppRole,
    targetCollegeId?: string,
    targetDepartmentId?: string
  ): Promise<{ collegeId: mongoose.Types.ObjectId; departmentId?: mongoose.Types.ObjectId }> {
    // 1. SUPER_ADMIN can provision COLLEGE_ADMIN or HOD
    if (creator.role === AppRole.SUPER_ADMIN) {
      if (targetRole === AppRole.COLLEGE_ADMIN) {
        if (!targetCollegeId) {
          throw ApiError.badRequest('collegeId is required when provisioning a College Admin');
        }
        const college = await College.findById(targetCollegeId);
        if (!college) {
          throw ApiError.notFound(`College with ID "${targetCollegeId}" not found`);
        }
        if (college.status === CollegeStatus.INACTIVE || !college.isActive) {
          throw ApiError.forbidden('Cannot provision administrators for an inactive college');
        }
        return { collegeId: college._id };
      }

      if (targetRole === AppRole.HOD) {
        if (!targetDepartmentId) {
          throw ApiError.badRequest('departmentId is required when provisioning an HOD');
        }
        if (!mongoose.Types.ObjectId.isValid(targetDepartmentId)) {
          throw ApiError.badRequest(`Invalid Department ID format: "${targetDepartmentId}"`);
        }
        const dept = await Department.findById(targetDepartmentId);
        if (!dept) {
          throw ApiError.notFound(`Department with ID "${targetDepartmentId}" not found`);
        }
        if (dept.status === DepartmentStatus.INACTIVE || !dept.isActive) {
          throw ApiError.forbidden('Cannot provision HOD for an inactive department');
        }
        const college = await College.findById(dept.collegeId);
        if (!college) {
          throw ApiError.notFound('Referenced college not found');
        }
        if (college.status === CollegeStatus.INACTIVE || !college.isActive) {
          throw ApiError.forbidden('Cannot provision HOD for an inactive college');
        }

        // Enforce ONE ACTIVE HOD per department
        const existingHod = await User.findOne({
          departmentId: dept._id,
          role: AppRole.HOD,
          accountStatus: { $in: [AccountStatus.ACTIVE, AccountStatus.PENDING_ACTIVATION] },
        });
        if (existingHod) {
          throw ApiError.conflict('Department already has an active or pending HOD');
        }

        return { collegeId: dept.collegeId, departmentId: dept._id };
      }

      if (targetRole === AppRole.FACULTY) {
        if (!targetDepartmentId) {
          throw ApiError.badRequest('departmentId is required when provisioning a Faculty');
        }
        if (!mongoose.Types.ObjectId.isValid(targetDepartmentId)) {
          throw ApiError.badRequest(`Invalid Department ID format: "${targetDepartmentId}"`);
        }
        const dept = await Department.findById(targetDepartmentId);
        if (!dept) {
          throw ApiError.notFound(`Department with ID "${targetDepartmentId}" not found`);
        }
        if (dept.status === DepartmentStatus.INACTIVE || !dept.isActive) {
          throw ApiError.forbidden('Cannot provision faculty for an inactive department');
        }
        const college = await College.findById(dept.collegeId);
        if (!college) {
          throw ApiError.notFound('Referenced college not found');
        }
        if (college.status === CollegeStatus.INACTIVE || !college.isActive) {
          throw ApiError.forbidden('Cannot provision faculty for an inactive college');
        }

        return { collegeId: dept.collegeId, departmentId: dept._id };
      }

      if (targetRole === AppRole.STUDENT) {
        if (!targetDepartmentId) {
          throw ApiError.badRequest('departmentId is required when provisioning a Student');
        }
        if (!mongoose.Types.ObjectId.isValid(targetDepartmentId)) {
          throw ApiError.badRequest(`Invalid Department ID format: "${targetDepartmentId}"`);
        }
        const dept = await Department.findById(targetDepartmentId);
        if (!dept) {
          throw ApiError.notFound(`Department with ID "${targetDepartmentId}" not found`);
        }
        if (dept.status === DepartmentStatus.INACTIVE || !dept.isActive) {
          throw ApiError.forbidden('Cannot provision student for an inactive department');
        }
        const college = await College.findById(dept.collegeId);
        if (!college) {
          throw ApiError.notFound('Referenced college not found');
        }
        if (college.status === CollegeStatus.INACTIVE || !college.isActive) {
          throw ApiError.forbidden('Cannot provision student for an inactive college');
        }

        return { collegeId: dept.collegeId, departmentId: dept._id };
      }

      throw ApiError.forbidden(
        'Super Admin can only provision College Admin, HOD, Faculty, or Student accounts directly.'
      );
    }

    // 2. COLLEGE_ADMIN can provision HOD, FACULTY, STUDENT for their own college
    if (creator.role === AppRole.COLLEGE_ADMIN) {
      if (!creator.collegeId) {
        throw ApiError.forbidden('Creator has no college scope assigned');
      }

      if (targetCollegeId && targetCollegeId !== creator.collegeId) {
        throw ApiError.forbidden('College Admin cannot create invitations for another college');
      }

      const collegeId = new mongoose.Types.ObjectId(creator.collegeId);

      const college = await College.findById(collegeId);
      if (!college || college.status === CollegeStatus.INACTIVE || !college.isActive) {
        throw ApiError.forbidden('Cannot provision accounts for an inactive college');
      }

      // Allowed target roles: HOD, FACULTY, STUDENT
      const allowedRoles = [AppRole.HOD, AppRole.FACULTY, AppRole.STUDENT];
      if (!allowedRoles.includes(targetRole)) {
        throw ApiError.forbidden(
          `College Admin cannot provision accounts with role "${targetRole}"`
        );
      }

      let deptObjectId: mongoose.Types.ObjectId | undefined;
      if (targetDepartmentId) {
        if (!mongoose.Types.ObjectId.isValid(targetDepartmentId)) {
          throw ApiError.badRequest(`Invalid Department ID format: "${targetDepartmentId}"`);
        }
        const dept = await Department.findById(targetDepartmentId);
        if (!dept) {
          throw ApiError.notFound(`Target department does not exist`);
        }
        if (dept.collegeId.toString() !== collegeId.toString()) {
          throw ApiError.forbidden('Cross-college tenant access is strictly prohibited: Target department does not belong to your college');
        }
        if (dept.status === DepartmentStatus.INACTIVE || !dept.isActive) {
          throw ApiError.forbidden(`Cannot provision ${targetRole.toLowerCase()} for an inactive department`);
        }

        if (targetRole === AppRole.HOD) {
          const existingHod = await User.findOne({
            departmentId: dept._id,
            role: AppRole.HOD,
            accountStatus: { $in: [AccountStatus.ACTIVE, AccountStatus.PENDING_ACTIVATION] },
          });
          if (existingHod) {
            throw ApiError.conflict('Department already has an active or pending HOD');
          }
        }

        deptObjectId = dept._id;
      } else if (
        targetRole === AppRole.HOD ||
        targetRole === AppRole.FACULTY ||
        targetRole === AppRole.STUDENT
      ) {
        throw ApiError.badRequest(`departmentId is required when provisioning a ${targetRole}`);
      }

      return { collegeId, departmentId: deptObjectId };
    }

    // 3. HOD can provision FACULTY and STUDENT for their assigned department
    if (creator.role === AppRole.HOD) {
      if (!creator.collegeId || !creator.departmentId) {
        throw ApiError.forbidden('HOD has no college or department scope assigned');
      }

      if (targetCollegeId && targetCollegeId !== creator.collegeId) {
        throw ApiError.forbidden('HOD cannot create invitations for another college');
      }

      if (targetDepartmentId && targetDepartmentId !== creator.departmentId) {
        throw ApiError.forbidden('HOD cannot create invitations outside their assigned department');
      }

      const college = await College.findById(creator.collegeId);
      if (!college || college.status === CollegeStatus.INACTIVE || !college.isActive) {
        throw ApiError.forbidden('Cannot provision accounts for an inactive college');
      }

      const dept = await Department.findById(creator.departmentId);
      if (!dept || dept.status === DepartmentStatus.INACTIVE || !dept.isActive) {
        throw ApiError.forbidden('Cannot provision accounts for an inactive department');
      }

      const allowedRoles = [AppRole.FACULTY, AppRole.STUDENT];
      if (!allowedRoles.includes(targetRole)) {
        throw ApiError.forbidden(`HOD cannot provision accounts with role "${targetRole}". Only Faculty and Student accounts can be created.`);
      }

      return {
        collegeId: new mongoose.Types.ObjectId(creator.collegeId),
        departmentId: new mongoose.Types.ObjectId(creator.departmentId),
      };
    }

    // 4. FACULTY can provision STUDENT for their assigned department
    if (creator.role === AppRole.FACULTY) {
      if (!creator.collegeId || !creator.departmentId) {
        throw ApiError.forbidden('Faculty has no college or department scope assigned');
      }

      if (targetCollegeId && targetCollegeId !== creator.collegeId) {
        throw ApiError.forbidden('Faculty cannot create invitations for another college');
      }

      if (targetDepartmentId && targetDepartmentId !== creator.departmentId) {
        throw ApiError.forbidden('Faculty cannot create invitations outside their assigned department');
      }

      const college = await College.findById(creator.collegeId);
      if (!college || college.status === CollegeStatus.INACTIVE || !college.isActive) {
        throw ApiError.forbidden('Cannot provision accounts for an inactive college');
      }

      const dept = await Department.findById(creator.departmentId);
      if (!dept || dept.status === DepartmentStatus.INACTIVE || !dept.isActive) {
        throw ApiError.forbidden('Cannot provision accounts for an inactive department');
      }

      if (targetRole !== AppRole.STUDENT) {
        throw ApiError.forbidden('Faculty can only provision Student accounts');
      }

      return {
        collegeId: new mongoose.Types.ObjectId(creator.collegeId),
        departmentId: new mongoose.Types.ObjectId(creator.departmentId),
      };
    }

    throw ApiError.forbidden('Your role is not authorized to create invitations');
  }

  /**
   * Provision User in PENDING_ACTIVATION state and generate single-use invitation.
   */
  static async createInvitation(
    creator: AuthenticatedUser,
    data: CreateInvitationInput
  ): Promise<CreateInvitationResult> {
    if (!data.name || data.name.trim() === '') {
      throw ApiError.badRequest('User name is required');
    }

    if (!data.instituteId || data.instituteId.trim() === '') {
      throw ApiError.badRequest('instituteId is required');
    }

    const normalizedInstituteId = data.instituteId.trim().toUpperCase();

    // Verify provisioning authority
    const { collegeId, departmentId } = await this.validateProvisioningAuthority(
      creator,
      data.role,
      data.collegeId,
      data.departmentId
    );

    // Check if canonical User identity already exists
    let existingUser: InstanceType<typeof User> | null = null;
    let normalizedEmail: string | undefined = undefined;
    let normalizedPhone: string | undefined = undefined;

    if (data.email && data.email.trim() !== '') {
      normalizedEmail = normalizeEmail(data.email);
    }
    if (data.phone && data.phone.trim() !== '') {
      normalizedPhone = normalizePhone(data.phone);
    }

    if (!normalizedEmail && !normalizedPhone) {
      throw ApiError.badRequest('At least one contact method (email or phone) is required to issue an invitation.');
    }

    const userByInstituteId = await User.findOne({ instituteId: normalizedInstituteId });
    const userByEmail = normalizedEmail ? await User.findOne({ email: normalizedEmail }) : null;
    const userByPhone = normalizedPhone ? await User.findOne({ phone: normalizedPhone }) : null;

    // Detect conflicting or ambiguous identity matches across identifiers
    const matchedUsers = [userByInstituteId, userByEmail, userByPhone].filter(Boolean) as InstanceType<typeof User>[];
    const uniqueMatchedUserIds = new Set(matchedUsers.map((u) => u._id.toString()));

    if (uniqueMatchedUserIds.size > 1) {
      throw ApiError.conflict(
        'Ambiguous or conflicting identity match across provided instituteId, email, or phone. Identity verification required.'
      );
    }

    if (userByInstituteId && userByInstituteId.collegeId?.toString() === collegeId.toString()) {
      throw ApiError.conflict('User with this instituteId already exists');
    }

    if (userByEmail && userByEmail.collegeId?.toString() === collegeId.toString()) {
      throw ApiError.conflict('User with this email already exists');
    }

    if (uniqueMatchedUserIds.size === 1) {
      existingUser = matchedUsers[0];
    }

    let user: InstanceType<typeof User>;

    if (existingUser) {
      user = existingUser;

      // Check if user already holds active membership and role in this college
      const existingMembership = await WorkspaceMembership.findOne({
        userId: user._id,
        collegeId,
      });

      if (existingMembership && existingMembership.status === MembershipStatus.ACTIVE) {
        const existingRole = await WorkspaceRoleAssignment.findOne({
          membershipId: existingMembership._id,
          role: data.role,
          departmentId: departmentId || null,
          status: RoleAssignmentStatus.ACTIVE,
        });

        if (existingRole) {
          // Existing person already holds this exact active membership and role: return deterministic safe result
          const college = await College.findById(collegeId);
          const existingInv = await Invitation.findOne({
            userId: user._id,
            collegeId,
            role: data.role,
          }).sort({ createdAt: -1 });

          return {
            invitation: existingInv || ({} as any),
            activationCode: 'ALREADY_ACTIVE',
            user,
            collegeCode: college?.code,
            collegeName: college?.name,
            isNewUser: false,
            isNewMembership: false,
            membershipId: existingMembership._id.toString(),
          };
        }
      }
    } else {
      // 1. Create canonical User in PENDING_ACTIVATION state (new identity)
      user = await User.create({
        instituteId: normalizedInstituteId,
        name: data.name.trim(),
        email: normalizedEmail,
        phone: normalizedPhone,
        role: data.role,
        collegeId,
        departmentId: departmentId || undefined,
        courseId: data.courseId ? new mongoose.Types.ObjectId(data.courseId) : undefined,
        sectionId: data.sectionId ? new mongoose.Types.ObjectId(data.sectionId) : undefined,
        semesterId: data.semesterId ? new mongoose.Types.ObjectId(data.semesterId) : undefined,
        accountStatus: AccountStatus.PENDING_ACTIVATION,
        activationStatus: 'pending',
        passwordHash: null,
      });
    }

    // 2. Establish WorkspaceMembership in PENDING status (or keep existing active)
    let membership = await WorkspaceMembership.findOne({
      userId: user._id,
      collegeId,
    });

    let isNewMembership = false;
    if (!membership) {
      membership = await WorkspaceMembership.create({
        userId: user._id,
        collegeId,
        instituteId: normalizedInstituteId,
        memberType:
          data.role === AppRole.STUDENT
            ? MembershipType.STUDENT
            : data.role === AppRole.FACULTY || data.role === AppRole.HOD
            ? MembershipType.FACULTY
            : MembershipType.ADMINISTRATOR,
        status: user.accountStatus === AccountStatus.ACTIVE ? MembershipStatus.ACTIVE : MembershipStatus.PENDING,
        isDefault: !existingUser,
        joinedAt: new Date(),
        effectiveStartDate: new Date(),
        createdBy: creator.id,
      });
      isNewMembership = true;
    } else if (!membership.instituteId) {
      membership.instituteId = normalizedInstituteId;
      await membership.save();
    }

    // 3. Establish WorkspaceRoleAssignment in PENDING (or ACTIVE if already active user)
    const existingRoleAssignment = await WorkspaceRoleAssignment.findOne({
      membershipId: membership._id,
      role: data.role,
      departmentId: departmentId || null,
    });

    if (!existingRoleAssignment) {
      await WorkspaceRoleAssignment.create({
        membershipId: membership._id,
        userId: user._id,
        collegeId,
        role: data.role,
        departmentId: departmentId || null,
        status: membership.status === MembershipStatus.ACTIVE ? RoleAssignmentStatus.ACTIVE : RoleAssignmentStatus.PENDING,
        assignedAt: new Date(),
        assignedBy: creator.id,
      });
    }

    // 4. Generate secure activation code and hash
    const rawActivationCode = generateActivationCode();
    const codeHash = hashActivationCode(rawActivationCode);
    const expiresAt = new Date(Date.now() + env.INVITATION_EXPIRES_IN * 1000);

    // 5. Create Invitation record
    const invitation = await Invitation.create({
      userId: user._id,
      collegeId,
      departmentId: departmentId || undefined,
      role: data.role,
      codeHash,
      status: InvitationStatus.PENDING,
      expiresAt,
      createdBy: creator.id,
      lastSentAt: new Date(),
    });

    // 6. Record Audit Log
    await AuditLog.create({
      collegeId: collegeId.toString(),
      workspaceMembershipId: membership.id,
      departmentId: departmentId ? departmentId.toString() : undefined,
      actorUserId: creator.id,
      action: 'INVITATION_CREATED',
      entityType: 'Invitation',
      entityId: invitation.id,
      newValue: {
        targetUserId: user.id,
        instituteId: user.instituteId,
        role: data.role,
        collegeId: collegeId.toString(),
        isExistingUser: !!existingUser,
      },
    });

    if (data.role === AppRole.COLLEGE_ADMIN) {
      await AuditLog.create({
        collegeId: collegeId.toString(),
        workspaceMembershipId: membership.id,
        actorUserId: creator.id,
        action: 'COLLEGE_ADMIN_PROVISIONED',
        entityType: 'User',
        entityId: user.id,
        newValue: {
          targetUserId: user.id,
          instituteId: user.instituteId,
          role: data.role,
          collegeId: collegeId.toString(),
        },
      });
    }

    if (data.role === AppRole.HOD && departmentId) {
      await Department.findByIdAndUpdate(departmentId, { hodId: user._id.toString() });

      await AuditLog.create({
        collegeId: collegeId.toString(),
        workspaceMembershipId: membership.id,
        departmentId: departmentId.toString(),
        actorUserId: creator.id,
        action: 'HOD_PROVISIONED',
        entityType: 'User',
        entityId: user.id,
        newValue: {
          targetUserId: user.id,
          instituteId: user.instituteId,
          role: data.role,
          collegeId: collegeId.toString(),
          departmentId: departmentId.toString(),
        },
      });
    }

    const college = await College.findById(collegeId);

    return {
      invitation,
      activationCode: rawActivationCode,
      user,
      collegeCode: college?.code,
      collegeName: college?.name,
      isNewUser: !existingUser,
      isNewMembership,
      membershipId: membership.id,
    };
  }

  /**
   * Account & Workspace Activation Endpoint:
   * Validates collegeCode, instituteId, activationCode, sets password if new,
   * activates WorkspaceMembership and WorkspaceRoleAssignment.
   */
  static async activateAccount(
    collegeCode: string,
    instituteId: string,
    rawActivationCode: string,
    newPassword?: string
  ): Promise<{ success: boolean; message: string; user: Record<string, unknown> }> {
    if (!collegeCode || !instituteId || !rawActivationCode) {
      throw ApiError.badRequest(
        'collegeCode, instituteId, and activationCode are required'
      );
    }

    // 1. Locate institution by college code (case-insensitive & trimmed)
    const normalizedCollegeCode = collegeCode.trim().toUpperCase();
    const college = await College.findOne({
      code: { $regex: new RegExp(`^${normalizedCollegeCode.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}$`, 'i') },
    });
    if (!college) {
      throw ApiError.badRequest('Invalid activation details');
    }

    // 2. Locate user by instituteId or Email
    const normalizedInstituteId = instituteId.trim().toUpperCase();
    const normalizedEmail = instituteId.trim().toLowerCase();
    const user = await User.findOne({
      $or: [
        { instituteId: { $regex: new RegExp(`^${normalizedInstituteId.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}$`, 'i') } },
        { email: normalizedEmail },
      ],
    });
    if (!user) {
      throw ApiError.badRequest('Invalid activation details');
    }

    // If user has a home college different from the requested one and has no invitation here
    if (user.collegeId && user.collegeId.toString() !== college._id.toString()) {
      const anyCollegeInvite = await Invitation.findOne({
        userId: user._id,
        collegeId: college._id,
      });
      if (!anyCollegeInvite) {
        throw ApiError.badRequest('Invalid activation details');
      }
    }

    // 3. Find pending invitation for user and this specific college
    const invitation = await Invitation.findOne({
      userId: user._id,
      collegeId: college._id,
      status: { $in: [InvitationStatus.PENDING, 'pending', 'PENDING'] },
    }).sort({ createdAt: -1 });

    if (!invitation) {
      const usedInvitation = await Invitation.findOne({
        userId: user._id,
        collegeId: college._id,
        status: { $in: [InvitationStatus.USED, 'used', 'USED'] },
      });
      if (
        usedInvitation ||
        (user.accountStatus === AccountStatus.ACTIVE &&
          user.collegeId?.toString() === college._id.toString())
      ) {
        throw ApiError.badRequest('This account has already been activated. Please log in with your credentials.');
      }
      throw ApiError.badRequest('No pending invitation found for this account in this institution');
    }

    if (user.accountStatus === AccountStatus.DEACTIVATED) {
      throw ApiError.forbidden('Account has been deactivated. Please contact your administrator.');
    }

    // 4. Check expiration
    if (invitation.isExpired()) {
      invitation.status = InvitationStatus.EXPIRED;
      await invitation.save();
      throw ApiError.badRequest('Invitation has expired. Please request a new invitation.');
    }

    // 5. Verify activation code match
    const isCodeMatch = verifyActivationCode(rawActivationCode, invitation.codeHash);
    if (!isCodeMatch) {
      invitation.attemptCount += 1;
      await invitation.save();
      throw ApiError.badRequest('Invalid activation code');
    }

    // 6. Handle password: new user requires password; existing active user preserves existing password
    if (!user.passwordHash || user.accountStatus !== AccountStatus.ACTIVE) {
      if (!newPassword) {
        throw ApiError.badRequest('Password is required to activate a new account');
      }
      const validation = PasswordService.validatePassword(newPassword);
      if (!validation.valid) {
        throw ApiError.badRequest(validation.message || 'Invalid password format');
      }
      const passwordHash = await PasswordService.hashPassword(newPassword);
      user.passwordHash = passwordHash;
      user.accountStatus = AccountStatus.ACTIVE;
      user.activationStatus = 'activated';
      if (!user.collegeId) {
        user.collegeId = college._id;
        user.role = invitation.role;
        user.departmentId = invitation.departmentId;
      }
      await user.save();
    }

    // 7. Activate WorkspaceMembership for this college
    let membership = await WorkspaceMembership.findOne({
      userId: user._id,
      collegeId: college._id,
    });

    if (!membership) {
      membership = await WorkspaceMembership.create({
        userId: user._id,
        collegeId: college._id,
        status: MembershipStatus.ACTIVE,
        joinedAt: new Date(),
      });
    } else {
      membership.status = MembershipStatus.ACTIVE;
      membership.joinedAt = new Date();
      await membership.save();
    }

    // 8. Activate WorkspaceRoleAssignment for this college
    await WorkspaceRoleAssignment.updateMany(
      {
        membershipId: membership._id,
        role: invitation.role,
      },
      {
        $set: {
          status: RoleAssignmentStatus.ACTIVE,
          assignedAt: new Date(),
        },
      }
    );

    // 9. Mark invitation as USED
    invitation.status = InvitationStatus.USED;
    invitation.usedAt = new Date();
    await invitation.save();

    // 10. Audit log
    await AuditLog.create({
      collegeId: college.id,
      workspaceMembershipId: membership.id,
      actorUserId: user.id,
      action: 'ACCOUNT_ACTIVATED',
      entityType: 'User',
      entityId: user.id,
      newValue: {
        instituteId: user.instituteId,
        role: invitation.role,
        collegeId: college.id,
      },
    });

    return {
      success: true,
      message: 'Account activated successfully. You may now log in with your credentials.',
      user: user.toJSON(),
    };
  }

  /**
   * Reissues an invitation:
   * Invalidates old code, generates new code for the same User, updates expiration.
   */
  static async reissueInvitation(
    invitationId: string,
    creator: AuthenticatedUser
  ): Promise<ReissueInvitationResult> {
    const allowedRoles = [AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN, AppRole.HOD, AppRole.FACULTY];
    if (!allowedRoles.includes(creator.role)) {
      throw ApiError.forbidden('You are not authorized to manage invitations');
    }

    const invitation = await Invitation.findById(invitationId);
    if (!invitation) {
      throw ApiError.notFound('Invitation not found');
    }

    // Verify creator authority over this invitation
    if (creator.role !== AppRole.SUPER_ADMIN) {
      if (!creator.collegeId || creator.collegeId !== invitation.collegeId.toString()) {
        throw ApiError.forbidden('Cannot manage invitations for another college');
      }
      if (
        creator.role === AppRole.HOD &&
        invitation.departmentId &&
        creator.departmentId !== invitation.departmentId.toString()
      ) {
        throw ApiError.forbidden('HOD cannot manage invitations outside their department');
      }
    }

    if (invitation.status === InvitationStatus.USED) {
      throw ApiError.badRequest('Cannot reissue an already used invitation.');
    }

    // 1. Revoke existing invitation
    invitation.status = InvitationStatus.REVOKED;
    invitation.revokedAt = new Date();
    invitation.revokedBy = creator.id;
    await invitation.save();

    // 2. Generate new code and create new invitation for the same User
    const rawActivationCode = generateActivationCode();
    const codeHash = hashActivationCode(rawActivationCode);
    const expiresAt = new Date(Date.now() + env.INVITATION_EXPIRES_IN * 1000);

    const newInvitation = await Invitation.create({
      userId: invitation.userId,
      collegeId: invitation.collegeId,
      departmentId: invitation.departmentId,
      role: invitation.role,
      codeHash,
      status: InvitationStatus.PENDING,
      expiresAt,
      createdBy: creator.id,
      lastSentAt: new Date(),
    });

    // 3. Audit log
    await AuditLog.create({
      collegeId: invitation.collegeId.toString(),
      actorUserId: creator.id,
      action: 'INVITATION_REISSUED',
      entityType: 'Invitation',
      entityId: newInvitation.id,
      metadata: { previousInvitationId: invitation.id },
    });

    const college = await College.findById(invitation.collegeId);

    return {
      invitation: newInvitation,
      activationCode: rawActivationCode,
      collegeCode: college?.code,
      collegeName: college?.name,
    };
  }

  /**
   * Revokes an unused invitation.
   */
  static async revokeInvitation(
    invitationId: string,
    creator: AuthenticatedUser
  ): Promise<{ message: string }> {
    const allowedRoles = [AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN, AppRole.HOD, AppRole.FACULTY];
    if (!allowedRoles.includes(creator.role)) {
      throw ApiError.forbidden('You are not authorized to manage invitations');
    }

    const invitation = await Invitation.findById(invitationId);
    if (!invitation) {
      throw ApiError.notFound('Invitation not found');
    }

    // Verify creator authority
    if (creator.role !== AppRole.SUPER_ADMIN) {
      if (!creator.collegeId || creator.collegeId !== invitation.collegeId.toString()) {
        throw ApiError.forbidden('Cannot manage invitations for another college');
      }
      if (
        creator.role === AppRole.HOD &&
        invitation.departmentId &&
        creator.departmentId !== invitation.departmentId.toString()
      ) {
        throw ApiError.forbidden('HOD cannot manage invitations outside their department');
      }
    }

    if (invitation.status === InvitationStatus.USED) {
      throw ApiError.badRequest('Cannot revoke an already used invitation.');
    }

    invitation.status = InvitationStatus.REVOKED;
    invitation.revokedAt = new Date();
    invitation.revokedBy = creator.id;
    await invitation.save();

    await AuditLog.create({
      collegeId: invitation.collegeId.toString(),
      actorUserId: creator.id,
      action: 'INVITATION_REVOKED',
      entityType: 'Invitation',
      entityId: invitation.id,
    });

    return { message: 'Invitation has been revoked successfully' };
  }

  /**
   * Get single invitation by ID with tenant scope check.
   */
  static async getInvitationById(
    invitationId: string,
    requester: AuthenticatedUser
  ): Promise<IInvitation> {
    const invitation = await Invitation.findById(invitationId);
    if (!invitation) {
      throw ApiError.notFound('Invitation not found');
    }

    if (requester.role !== AppRole.SUPER_ADMIN) {
      if (!requester.collegeId || requester.collegeId !== invitation.collegeId.toString()) {
        throw ApiError.forbidden('Cannot access invitations for another college');
      }
    }

    return invitation;
  }

  /**
   * List invitations scoped by college / department.
   */
  static async listInvitations(
    requester: AuthenticatedUser,
    filter: { status?: InvitationStatus; role?: AppRole; departmentId?: string } = {}
  ): Promise<IInvitation[]> {
    const query: Record<string, unknown> = {};

    if (requester.role !== AppRole.SUPER_ADMIN) {
      if (!requester.collegeId) {
        throw ApiError.forbidden('Requester has no college scope');
      }
      query.collegeId = new mongoose.Types.ObjectId(requester.collegeId);

      if (requester.role === AppRole.HOD && requester.departmentId) {
        query.departmentId = new mongoose.Types.ObjectId(requester.departmentId);
      }
    }

    if (filter.status) query.status = filter.status;
    if (filter.role) query.role = filter.role;
    if (filter.departmentId) query.departmentId = new mongoose.Types.ObjectId(filter.departmentId);

    return Invitation.find(query).sort({ createdAt: -1 });
  }
}
