import mongoose from 'mongoose';
import { Invitation, IInvitation } from '../models/invitation.model';
import { User, IUser } from '../models/user.model';
import { College } from '../models/college.model';
import { Department } from '../models/department.model';
import { AuditLog } from '../models/auditLog.model';
import { AppRole } from '../constants/roles';
import { AccountStatus, CollegeStatus, DepartmentStatus, InvitationStatus } from '../constants/status';
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
        const dept = await Department.findOne({
          _id: targetDepartmentId,
          collegeId,
        });
        if (!dept) {
          throw ApiError.badRequest(
            'Target department does not exist or does not belong to your college'
          );
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
        throw ApiError.forbidden(`HOD cannot provision accounts with role "${targetRole}"`);
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
  ): Promise<{ invitation: IInvitation; activationCode: string; user: IUser }> {
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

    // Verify instituteId uniqueness
    const existingInstituteId = await User.findOne({ instituteId: normalizedInstituteId });
    if (existingInstituteId) {
      throw ApiError.conflict(
        `User with instituteId "${normalizedInstituteId}" already exists`
      );
    }

    // Verify email uniqueness if provided
    let normalizedEmail: string | undefined = undefined;
    if (data.email && data.email.trim() !== '') {
      normalizedEmail = normalizeEmail(data.email);
      const existingEmail = await User.findOne({ email: normalizedEmail });
      if (existingEmail) {
        throw ApiError.conflict(`User with email "${normalizedEmail}" already exists`);
      }
    }

    // Verify phone uniqueness if provided
    let normalizedPhone: string | undefined = undefined;
    if (data.phone && data.phone.trim() !== '') {
      normalizedPhone = normalizePhone(data.phone);
      const existingPhone = await User.findOne({ phone: normalizedPhone });
      if (existingPhone) {
        throw ApiError.conflict(`User with phone "${normalizedPhone}" already exists`);
      }
    }

    // 1. Create User in PENDING_ACTIVATION state
    const user = await User.create({
      instituteId: normalizedInstituteId,
      name: data.name.trim(),
      email: normalizedEmail,
      phone: normalizedPhone,
      role: data.role,
      collegeId,
      departmentId,
      courseId: data.courseId ? new mongoose.Types.ObjectId(data.courseId) : undefined,
      sectionId: data.sectionId ? new mongoose.Types.ObjectId(data.sectionId) : undefined,
      semesterId: data.semesterId ? new mongoose.Types.ObjectId(data.semesterId) : undefined,
      accountStatus: AccountStatus.PENDING_ACTIVATION,
      activationStatus: 'pending',
      passwordHash: null,
    });

    // 2. Generate secure activation code and hash
    const rawActivationCode = generateActivationCode();
    const codeHash = hashActivationCode(rawActivationCode);
    const expiresAt = new Date(Date.now() + env.INVITATION_EXPIRES_IN * 1000);

    // 3. Create Invitation record
    const invitation = await Invitation.create({
      userId: user._id,
      collegeId,
      departmentId,
      role: data.role,
      codeHash,
      status: InvitationStatus.PENDING,
      expiresAt,
      createdBy: creator.id,
      lastSentAt: new Date(),
    });

    // 4. Record Audit Log
    await AuditLog.create({
      collegeId: collegeId.toString(),
      actorUserId: creator.id,
      action: 'INVITATION_CREATED',
      entityType: 'Invitation',
      entityId: invitation.id,
      newValue: {
        targetUserId: user.id,
        instituteId: user.instituteId,
        role: user.role,
        collegeId: collegeId.toString(),
      },
    });

    if (data.role === AppRole.COLLEGE_ADMIN) {
      await AuditLog.create({
        collegeId: collegeId.toString(),
        actorUserId: creator.id,
        action: 'COLLEGE_ADMIN_PROVISIONED',
        entityType: 'User',
        entityId: user.id,
        newValue: {
          targetUserId: user.id,
          instituteId: user.instituteId,
          role: user.role,
          collegeId: collegeId.toString(),
        },
      });
    }

    if (data.role === AppRole.HOD && departmentId) {
      await Department.findByIdAndUpdate(departmentId, { hodId: user._id.toString() });

      await AuditLog.create({
        collegeId: collegeId.toString(),
        actorUserId: creator.id,
        action: 'HOD_PROVISIONED',
        entityType: 'User',
        entityId: user.id,
        newValue: {
          targetUserId: user.id,
          instituteId: user.instituteId,
          role: user.role,
          collegeId: collegeId.toString(),
          departmentId: departmentId.toString(),
        },
      });
    }

    return {
      invitation,
      activationCode: rawActivationCode,
      user,
    };
  }

  /**
   * Account Activation Endpoint:
   * Validates collegeCode, instituteId, activationCode, sets password, marks account ACTIVE.
   */
  static async activateAccount(
    collegeCode: string,
    instituteId: string,
    rawActivationCode: string,
    newPassword: string
  ): Promise<{ success: boolean; message: string; user: Record<string, unknown> }> {
    if (!collegeCode || !instituteId || !rawActivationCode || !newPassword) {
      throw ApiError.badRequest(
        'collegeCode, instituteId, activationCode, and password are required'
      );
    }

    // 1. Locate institution by college code
    const normalizedCollegeCode = collegeCode.trim().toUpperCase();
    const college = await College.findOne({ code: normalizedCollegeCode });
    if (!college) {
      throw ApiError.badRequest('Invalid activation details');
    }

    // 2. Locate user by instituteId
    const normalizedInstituteId = instituteId.trim().toUpperCase();
    const user = await User.findOne({ instituteId: normalizedInstituteId });
    if (!user) {
      throw ApiError.badRequest('Invalid activation details');
    }

    // 3. Confirm user belongs to this college
    if (!user.collegeId || user.collegeId.toString() !== college._id.toString()) {
      throw ApiError.badRequest('Invalid activation details');
    }

    // 4. Check account state
    if (user.accountStatus === AccountStatus.ACTIVE) {
      throw ApiError.badRequest('Account has already been activated. Please log in.');
    }

    if (user.accountStatus === AccountStatus.DEACTIVATED) {
      throw ApiError.forbidden('Account has been deactivated. Please contact your administrator.');
    }

    // 5. Find pending invitation for user
    const invitation = await Invitation.findOne({
      userId: user._id,
      status: InvitationStatus.PENDING,
    }).sort({ createdAt: -1 });

    if (!invitation) {
      throw ApiError.badRequest('No pending invitation found for this account');
    }

    // 6. Check expiration
    if (invitation.isExpired()) {
      invitation.status = InvitationStatus.EXPIRED;
      await invitation.save();
      throw ApiError.badRequest('Invitation has expired. Please request a new invitation.');
    }

    // 7. Verify activation code match
    const isCodeMatch = verifyActivationCode(rawActivationCode, invitation.codeHash);
    if (!isCodeMatch) {
      invitation.attemptCount += 1;
      await invitation.save();
      throw ApiError.badRequest('Invalid activation code');
    }

    // 8. Validate password policy & hash
    const validation = PasswordService.validatePassword(newPassword);
    if (!validation.valid) {
      throw ApiError.badRequest(validation.message || 'Invalid password format');
    }

    const passwordHash = await PasswordService.hashPassword(newPassword);

    // 9. Activate user account (preserves _id and instituteId)
    user.passwordHash = passwordHash;
    user.accountStatus = AccountStatus.ACTIVE;
    user.activationStatus = 'activated';
    await user.save();

    // 10. Mark invitation as USED (single-use)
    invitation.status = InvitationStatus.USED;
    invitation.usedAt = new Date();
    await invitation.save();

    // 11. Audit log
    await AuditLog.create({
      collegeId: college.id,
      actorUserId: user.id,
      action: 'ACCOUNT_ACTIVATED',
      entityType: 'User',
      entityId: user.id,
      newValue: {
        instituteId: user.instituteId,
        role: user.role,
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
  ): Promise<{ invitation: IInvitation; activationCode: string }> {
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

    return {
      invitation: newInvitation,
      activationCode: rawActivationCode,
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
