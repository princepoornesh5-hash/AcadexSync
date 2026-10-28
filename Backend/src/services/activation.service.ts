import crypto from 'crypto';
import mongoose from 'mongoose';
import { Invitation } from '../models/invitation.model';
import { User } from '../models/user.model';
import { College } from '../models/college.model';
import { WorkspaceMembership } from '../models/workspaceMembership.model';
import { WorkspaceRoleAssignment } from '../models/workspaceRoleAssignment.model';
import { AuditLog } from '../models/auditLog.model';
import { AuditService } from './audit.service';
import { PasswordService } from './password.service';
import { OtpService } from './otp.service';
import { OtpDeliveryService } from './otpDelivery.service';
import { AppRole } from '../constants/roles';
import {
  AccountStatus,
  CollegeStatus,
  InvitationStatus,
  MembershipStatus,
  MembershipType,
  RoleAssignmentStatus,
  OtpPurpose,
  OtpDeliveryMethod,
} from '../constants/status';
import {
  hashActivationCode,
  normalizeActivationCode,
} from '../utils/activationCode';
import {
  signActivationFlowToken,
  verifyActivationFlowToken,
  signActivationCompletionToken,
  verifyActivationCompletionToken,
  signEmailVerificationToken,
  verifyEmailVerificationToken,
} from '../utils/token';
import { maskEmail, maskPhone, normalizeEmail } from '../utils/identifier';
import { ApiError } from '../utils/apiError';
import { Logger } from '../utils/logger';
import { env } from '../config/env';

export interface ValidateCodeResult {
  activationFlowId: string;
  displayName: string;
  name: string;
  institutionName: string;
  collegeName: string;
  collegeCode: string;
  role: AppRole;
  isExistingUser: boolean;
  isExistingActiveUser: boolean;
  contactOptions: Array<{
    method: 'email' | 'phone';
    maskedValue: string;
  }>;
  availableChannels: Array<{
    type: 'email' | 'phone';
    masked: string;
  }>;
  permittedNextAction: string;
}

export interface SendOtpResult {
  message: string;
  maskedDestination: string;
  cooldownSeconds: number;
  expiresInSeconds: number;
}

export interface VerifyOtpResult {
  activationToken: string;
  isExistingActiveUser: boolean;
  message: string;
}

export interface CompleteActivationResult {
  success: boolean;
  message: string;
  data: {
    message?: string;
    user: {
      id: string;
      instituteId: string;
      name: string;
      role: AppRole;
      collegeCode: string;
      accountStatus: AccountStatus;
    };
  };
}

export class ActivationService {
  /**
   * Step 1: Validate single-use activation code.
   * Resolves invitation without requiring College Code or Institute ID.
   * Returns minimum identity confirmation and available masked contacts.
   */
  static async validateActivationCode(rawCode: string): Promise<ValidateCodeResult> {
    if (!rawCode || typeof rawCode !== 'string' || rawCode.trim() === '') {
      throw ApiError.badRequest('Activation code is required');
    }

    const normalized = normalizeActivationCode(rawCode);
    if (!normalized || normalized.length !== 12) {
      throw ApiError.badRequest('Activation code must be formatted as XXXX-XXXX-XXXX');
    }

    const codeHash = hashActivationCode(normalized);
    const invitation = await Invitation.findOne({ codeHash });

    if (!invitation) {
      throw ApiError.badRequest('Invalid or unknown activation code');
    }

    // Verify invitation lifecycle state
    if (invitation.status === InvitationStatus.USED) {
      throw ApiError.badRequest('This activation code has already been used. Please log in with your credentials.');
    }

    if (invitation.status === InvitationStatus.REVOKED) {
      throw ApiError.badRequest('This activation code has been revoked. Please contact your campus administrator.');
    }

    if (invitation.status === InvitationStatus.EXPIRED || invitation.isExpired()) {
      if (invitation.status !== InvitationStatus.EXPIRED) {
        invitation.status = InvitationStatus.EXPIRED;
        await invitation.save();
      }
      throw ApiError.badRequest('This activation code has expired. Please contact your campus administrator for a new code.');
    }

    // Verify associated user exists and is eligible
    const user = await User.findById(invitation.userId);
    if (!user) {
      throw ApiError.badRequest('Associated user account could not be located');
    }

    if (user.accountStatus === AccountStatus.DEACTIVATED) {
      throw ApiError.forbidden('Account has been deactivated. Please contact your administrator.');
    }

    if (user.accountStatus === AccountStatus.SUSPENDED) {
      throw ApiError.forbidden('Account is currently suspended. Please contact your administrator.');
    }

    // Verify associated college
    const college = await College.findById(invitation.collegeId);
    if (!college || college.status === CollegeStatus.INACTIVE || !college.isActive) {
      throw ApiError.forbidden('The associated institution is currently inactive. Please contact your administrator.');
    }

    const isExistingActiveUser =
      user.accountStatus === AccountStatus.ACTIVE && !!user.passwordHash;

    // Build available contact channels
    const availableChannels: Array<{ type: 'email' | 'phone'; masked: string }> = [];
    if (user.email && user.email.trim() !== '') {
      availableChannels.push({ type: 'email', masked: maskEmail(user.email) });
    }
    if (user.phone && user.phone.trim() !== '') {
      availableChannels.push({ type: 'phone', masked: maskPhone(user.phone) });
    }

    if (availableChannels.length === 0) {
      throw ApiError.badRequest(
        'No registered email or phone number is associated with this account. Please contact your campus administrator to update your contact details.'
      );
    }

    const flowId = crypto.randomUUID();
    const activationFlowId = signActivationFlowToken({
      flowId,
      invitationId: invitation.id,
      userId: user.id,
      collegeId: college.id,
    });

    return {
      activationFlowId,
      displayName: user.name,
      name: user.name,
      institutionName: college.name,
      collegeName: college.name,
      collegeCode: college.code,
      role: invitation.role,
      isExistingUser: isExistingActiveUser,
      isExistingActiveUser,
      contactOptions: availableChannels.map((c) => ({
        method: c.type,
        maskedValue: c.masked,
      })),
      availableChannels,
      permittedNextAction: 'CONFIRM_IDENTITY_AND_SELECT_CONTACT',
    };
  }

  /**
   * Step 2: Send OTP to selected registered contact method.
   */
  static async sendActivationOtp(
    activationFlowId: string,
    contactMethod: 'email' | 'phone'
  ): Promise<SendOtpResult> {
    if (!activationFlowId || typeof activationFlowId !== 'string') {
      throw ApiError.badRequest('activationFlowId is required');
    }

    if (contactMethod !== 'email' && contactMethod !== 'phone') {
      throw ApiError.badRequest('Invalid contactMethod. Must be "email" or "phone".');
    }

    // Cryptographically verify flow token
    const payload = verifyActivationFlowToken(activationFlowId);

    // Recheck invitation status
    const invitation = await Invitation.findById(payload.invitationId);
    if (!invitation || invitation.status !== InvitationStatus.PENDING || invitation.isExpired()) {
      throw ApiError.badRequest('Activation invitation is no longer eligible or has expired.');
    }

    // Recheck user status
    const user = await User.findById(payload.userId);
    if (!user || user.accountStatus === AccountStatus.DEACTIVATED || user.accountStatus === AccountStatus.SUSPENDED) {
      throw ApiError.forbidden('Target account is no longer eligible for activation.');
    }

    // Resolve destination
    let destination: string | undefined;
    let deliveryMethod: OtpDeliveryMethod;

    if (contactMethod === 'email') {
      destination = user.email;
      deliveryMethod = OtpDeliveryMethod.EMAIL;
      if (!destination || destination.trim() === '') {
        throw ApiError.badRequest('No registered email address found on this account.');
      }
    } else {
      destination = user.phone;
      deliveryMethod = OtpDeliveryMethod.SMS;
      if (!destination || destination.trim() === '') {
        throw ApiError.badRequest('No registered phone number found on this account.');
      }
    }

    // Enforce delivery configuration
    OtpDeliveryService.assertConfigured(deliveryMethod);

    // Dispatch OTP via OtpService (enforces cooldown, hashing, expiry, 5-attempt limits)
    await OtpService.requestOtp(user._id, OtpPurpose.ACCOUNT_ACTIVATION, destination, deliveryMethod);

    // Audit log
    await AuditService.log({
      collegeId: payload.collegeId,
      actorUserId: user.id,
      action: 'ACTIVATION_OTP_SENT',
      entityType: 'User',
      entityId: user.id,
      metadata: {
        contactMethod,
        invitationId: invitation.id,
      },
    }).catch(() => {});

    const maskedDestination =
      contactMethod === 'email' ? maskEmail(destination) : maskPhone(destination);

    return {
      message: `Verification code has been sent to your registered ${contactMethod}.`,
      maskedDestination,
      cooldownSeconds: env.OTP_RESEND_COOLDOWN,
      expiresInSeconds: env.OTP_EXPIRES_IN,
    };
  }

  /**
   * Step 3: Verify OTP and issue short-lived activation authorization token.
   */
  static async verifyActivationOtp(
    activationFlowId: string,
    contactMethod: 'email' | 'phone',
    rawOtp: string
  ): Promise<VerifyOtpResult> {
    if (!activationFlowId || typeof activationFlowId !== 'string') {
      throw ApiError.badRequest('activationFlowId is required');
    }

    if (contactMethod !== 'email' && contactMethod !== 'phone') {
      throw ApiError.badRequest('Invalid contactMethod. Must be "email" or "phone".');
    }

    if (!rawOtp || typeof rawOtp !== 'string' || rawOtp.trim() === '') {
      throw ApiError.badRequest('Verification code is required');
    }

    // Cryptographically verify flow token
    const payload = verifyActivationFlowToken(activationFlowId);

    // Recheck invitation & user
    const invitation = await Invitation.findById(payload.invitationId);
    if (!invitation || invitation.status !== InvitationStatus.PENDING || invitation.isExpired()) {
      throw ApiError.badRequest('Activation invitation is no longer eligible or has expired.');
    }

    const user = await User.findById(payload.userId);
    if (!user || user.accountStatus === AccountStatus.DEACTIVATED || user.accountStatus === AccountStatus.SUSPENDED) {
      throw ApiError.forbidden('Target account is no longer eligible for activation.');
    }

    let destination: string;
    let deliveryMethod: OtpDeliveryMethod;

    if (contactMethod === 'email') {
      destination = user.email || '';
      deliveryMethod = OtpDeliveryMethod.EMAIL;
    } else {
      destination = user.phone || '';
      deliveryMethod = OtpDeliveryMethod.SMS;
    }

    // Verify and consume OTP with destination matching
    await OtpService.verifyAndConsumeOtp(
      user._id,
      OtpPurpose.ACCOUNT_ACTIVATION,
      rawOtp.trim(),
      destination,
      deliveryMethod
    );

    const isExistingActiveUser =
      user.accountStatus === AccountStatus.ACTIVE && !!user.passwordHash;

    // Issue short-lived activation authorization token
    const tokenId = crypto.randomUUID();
    const activationToken = signActivationCompletionToken({
      tokenId,
      invitationId: invitation.id,
      userId: user.id,
      collegeId: payload.collegeId || invitation.collegeId.toString(),
      contactMethod,
    });

    // Authoritatively bind active tokenId to invitation metadata for single-use & supersession tracking
    const invMetadata = (invitation.metadata as Record<string, unknown>) || {};
    invMetadata.activeActivationTokenId = tokenId;
    invMetadata.activationTokenIssuedAt = new Date();
    await Invitation.findByIdAndUpdate(invitation._id, {
      $set: {
        metadata: invMetadata,
      },
    });

    // Audit log
    await AuditService.log({
      collegeId: payload.collegeId,
      actorUserId: user.id,
      action: 'ACTIVATION_OTP_VERIFIED',
      entityType: 'User',
      entityId: user.id,
      metadata: {
        contactMethod,
        invitationId: invitation.id,
      },
    }).catch(() => {});

    return {
      activationToken,
      isExistingActiveUser,
      message: 'Verification code verified successfully.',
    };
  }

  /**
   * Step 4: Complete activation and password setup.
   * Atomic consumption, password policy validation, and multi-workspace binding.
   */
  static async completeActivation(
    activationToken: string,
    password?: string,
    confirmPassword?: string
  ): Promise<CompleteActivationResult> {
    if (!activationToken || typeof activationToken !== 'string') {
      throw ApiError.badRequest('activationToken is required');
    }

    // Validate activation token
    const payload = verifyActivationCompletionToken(activationToken);

    // Recheck invitation status: PENDING and not expired
    const invitation = await Invitation.findOne({
      _id: new mongoose.Types.ObjectId(payload.invitationId),
      status: InvitationStatus.PENDING,
    });

    if (!invitation) {
      throw ApiError.badRequest('This invitation has already been consumed, expired, or revoked.');
    }

    if (invitation.isExpired()) {
      invitation.status = InvitationStatus.EXPIRED;
      await invitation.save();
      throw ApiError.badRequest('This invitation has expired. Please contact your administrator.');
    }

    // Locate user and college
    const user = await User.findById(payload.userId);
    if (!user) {
      throw ApiError.notFound('Target user account not found');
    }

    if (user.accountStatus === AccountStatus.DEACTIVATED) {
      throw ApiError.forbidden('Account has been deactivated. Please contact your administrator.');
    }

    const college = await College.findById(payload.collegeId);
    if (!college || college.status === CollegeStatus.INACTIVE || !college.isActive) {
      throw ApiError.forbidden('Target institution is currently inactive.');
    }

    const isExistingUser =
      user.accountStatus === AccountStatus.ACTIVE && !!user.passwordHash;

    let newPasswordHash: string | null = null;
    if (!isExistingUser) {
      // New user requires password and password matching
      if (!password || !confirmPassword) {
        throw ApiError.badRequest('Password and Confirm Password are required to activate your account.');
      }

      if (password !== confirmPassword) {
        throw ApiError.badRequest('Passwords do not match');
      }

      const policyValidation = PasswordService.validatePassword(password);
      if (!policyValidation.valid) {
        throw ApiError.badRequest(policyValidation.message || 'Password does not meet security requirements.');
      }

      newPasswordHash = await PasswordService.hashPassword(password);
    }

    // Verify token binding: ensure this exact tokenId was issued for this invitation and is still active
    const invMetadata = (invitation.metadata as Record<string, unknown>) || {};
    if (invMetadata.activeActivationTokenId && invMetadata.activeActivationTokenId !== payload.tokenId) {
      throw ApiError.badRequest('Activation token is invalid, superseded, or has already been consumed.');
    }

    // Atomic consumption lock: ensures single-use and prevents concurrent duplicate activation
    const consumedInvitation = await Invitation.findOneAndUpdate(
      {
        _id: invitation._id,
        status: InvitationStatus.PENDING,
        ...(invMetadata.activeActivationTokenId
          ? { 'metadata.activeActivationTokenId': payload.tokenId }
          : {}),
      },
      {
        $set: {
          status: InvitationStatus.USED,
          usedAt: new Date(),
          'metadata.activeActivationTokenId': null,
          'metadata.consumedActivationTokenId': payload.tokenId,
          'metadata.activationCompletedAt': new Date(),
        },
      },
      { new: true }
    );

    if (!consumedInvitation) {
      throw ApiError.conflict('This invitation or activation token has already been consumed.');
    }

    try {
      if (!isExistingUser && newPasswordHash) {
        user.passwordHash = newPasswordHash;
        user.accountStatus = AccountStatus.ACTIVE;
        user.activationStatus = 'activated';

        if (!user.collegeId) {
          user.collegeId = college._id;
          user.role = invitation.role;
          user.departmentId = invitation.departmentId;
        }
        await user.save();
      }
      // Note: If isExistingUser, user.passwordHash is PRESERVED UNCHANGED!

      // Establish WorkspaceMembership for this college idempotently
      const membership = await WorkspaceMembership.findOneAndUpdate(
        {
          userId: user._id,
          collegeId: college._id,
        },
        {
          $set: {
            status: MembershipStatus.ACTIVE,
            joinedAt: new Date(),
          },
          $setOnInsert: {
            isDefault: !isExistingUser,
          },
        },
        { new: true, upsert: true }
      );

      // Establish WorkspaceRoleAssignment for this college idempotently
      await WorkspaceRoleAssignment.findOneAndUpdate(
        {
          membershipId: membership._id,
          role: invitation.role,
          departmentId: invitation.departmentId || null,
        },
        {
          $set: {
            status: RoleAssignmentStatus.ACTIVE,
            assignedAt: new Date(),
          },
          $setOnInsert: {
            userId: user._id,
            collegeId: college._id,
          },
        },
        { new: true, upsert: true }
      );

      // Audit log
      await AuditLog.create({
        collegeId: college.id,
        workspaceMembershipId: membership.id,
        actorUserId: user.id,
        action: isExistingUser ? 'WORKSPACE_MEMBERSHIP_ACTIVATED' : 'ACCOUNT_ACTIVATED',
        entityType: 'User',
        entityId: user.id,
        newValue: {
          instituteId: user.instituteId,
          role: invitation.role,
          collegeId: college.id,
          isExistingUser,
        },
      });
    } catch (persistenceError) {
      // Compensating rollback for database persistence failures:
      // Revert invitation back to PENDING so user is not stranded with an un-activated account
      await Invitation.findByIdAndUpdate(invitation._id, {
        $set: {
          status: InvitationStatus.PENDING,
          usedAt: null,
          'metadata.activeActivationTokenId': payload.tokenId,
        },
      }).catch(() => {});
      throw persistenceError;
    }

    const completionMessage = isExistingUser
      ? 'College workspace access has been activated successfully. Please log in with your existing credentials.'
      : 'Account activated successfully. You may now log in with your credentials.';

    return {
      success: true,
      message: completionMessage,
      data: {
        message: completionMessage,
        user: {
          id: user.id,
          instituteId: user.instituteId,
          name: user.name,
          role: invitation.role,
          collegeCode: college.code,
          accountStatus: user.accountStatus,
        },
      },
    };
  }

  /**
   * Institutional Account Activation - Step 1: Request OTP for registered email.
   * Generic response prevents account enumeration.
   */
  static async requestInstitutionalActivationOtp(rawEmail: string): Promise<{ message: string }> {
    const genericResponse = {
      message: 'If an institutional invitation is associated with this email, a verification code has been sent.',
    };

    if (!rawEmail || typeof rawEmail !== 'string' || !rawEmail.includes('@')) {
      return genericResponse;
    }

    const normalizedEmail = normalizeEmail(rawEmail);
    const user = await User.findOne({ email: normalizedEmail });
    if (!user) {
      return genericResponse;
    }

    // Check for an eligible pending invitation
    const invitation = await Invitation.findOne({
      userId: user._id,
      status: InvitationStatus.PENDING,
    }).sort({ createdAt: -1 });

    if (!invitation || invitation.isExpired()) {
      return genericResponse;
    }

    // Verify institution is active
    const college = await College.findById(invitation.collegeId);
    if (!college || college.status === CollegeStatus.INACTIVE || !college.isActive) {
      return genericResponse;
    }

    try {
      await OtpService.requestOtp({
        destination: normalizedEmail,
        purpose: OtpPurpose.ACCOUNT_ACTIVATION,
        userId: user._id,
        invitationId: invitation._id,
        deliveryMethod: OtpDeliveryMethod.EMAIL,
        expiresInSeconds: env.OTP_EXPIRES_IN || 300,
      });
    } catch (err: unknown) {
      if (err instanceof ApiError && err.statusCode === 429) {
        throw err;
      }
      Logger.error('[ACTIVATION] Institutional activation OTP dispatch failed', err);
      throw ApiError.internal('Failed to deliver verification code. Please try again later.');
    }

    return genericResponse;
  }

  /**
   * Institutional Account Activation - Step 2: Verify OTP and issue emailVerificationToken.
   */
  static async verifyInstitutionalActivationOtp(
    rawEmail: string,
    rawOtp: string
  ): Promise<{ success: boolean; message: string; emailVerificationToken: string }> {
    if (!rawEmail || typeof rawEmail !== 'string') {
      throw ApiError.badRequest('Email is required');
    }
    if (!rawOtp || typeof rawOtp !== 'string') {
      throw ApiError.badRequest('Verification code is required');
    }

    const normalizedEmail = normalizeEmail(rawEmail);
    const user = await User.findOne({ email: normalizedEmail });
    if (!user) {
      throw ApiError.badRequest('Invalid verification code or email');
    }

    await OtpService.verifyAndConsumeOtp({
      destination: normalizedEmail,
      purpose: OtpPurpose.ACCOUNT_ACTIVATION,
      otp: rawOtp.trim(),
      userId: user._id,
    });

    const emailVerificationToken = signEmailVerificationToken({ email: normalizedEmail }, 900);

    return {
      success: true,
      message: 'Email ownership verified successfully.',
      emailVerificationToken,
    };
  }

  /**
   * Institutional Account Activation - Step 3: Validate activation code and complete activation.
   * Strictly enforces verified email === invitation email.
   * Attaches workspace membership without creating duplicate identities for existing users.
   * Preserves institution-scoped PIN numbers.
   */
  static async completeInstitutionalActivation(
    emailVerificationToken: string,
    rawCode: string,
    password?: string,
    confirmPassword?: string
  ): Promise<CompleteActivationResult> {
    if (!emailVerificationToken || typeof emailVerificationToken !== 'string') {
      throw ApiError.badRequest('emailVerificationToken is required');
    }
    if (!rawCode || typeof rawCode !== 'string' || rawCode.trim() === '') {
      throw ApiError.badRequest('Activation code is required');
    }

    // Cryptographically verify token
    const payload = verifyEmailVerificationToken(emailVerificationToken);
    const verifiedEmail = normalizeEmail(payload.email);

    // Validate activation code format
    const normalizedCode = normalizeActivationCode(rawCode);
    if (!normalizedCode || normalizedCode.length !== 12) {
      throw ApiError.badRequest('Activation code must be formatted as XXXX-XXXX-XXXX');
    }

    const codeHash = hashActivationCode(normalizedCode);
    const invitation = await Invitation.findOne({ codeHash });

    if (!invitation) {
      throw ApiError.badRequest('Invalid or unknown activation code');
    }

    if (invitation.status === InvitationStatus.USED) {
      throw ApiError.badRequest('This activation code has already been used. Please log in with your credentials.');
    }

    if (invitation.status === InvitationStatus.REVOKED) {
      throw ApiError.badRequest('This activation code has been revoked. Please contact your campus administrator.');
    }

    if (invitation.status === InvitationStatus.EXPIRED || invitation.isExpired()) {
      if (invitation.status !== InvitationStatus.EXPIRED) {
        invitation.status = InvitationStatus.EXPIRED;
        await invitation.save();
      }
      throw ApiError.badRequest('This activation code has expired. Please contact your campus administrator for a new code.');
    }

    // Locate invited user
    const user = await User.findById(invitation.userId);
    if (!user) {
      throw ApiError.badRequest('Associated user account could not be located');
    }

    if (user.accountStatus === AccountStatus.DEACTIVATED) {
      throw ApiError.forbidden('Account has been deactivated. Please contact your administrator.');
    }

    if (user.accountStatus === AccountStatus.SUSPENDED) {
      throw ApiError.forbidden('Account is currently suspended. Please contact your administrator.');
    }

    // STRICT VALIDATION: Verified email MUST match the invitation's associated user email!
    if (!user.email || normalizeEmail(user.email) !== verifiedEmail) {
      throw ApiError.forbidden('The verified email does not match the invitation email.');
    }

    // Verify institution
    const college = await College.findById(invitation.collegeId);
    if (!college || college.status === CollegeStatus.INACTIVE || !college.isActive) {
      throw ApiError.forbidden('The associated institution is currently inactive. Please contact your administrator.');
    }

    const isExistingUser = user.accountStatus === AccountStatus.ACTIVE && !!user.passwordHash;
    let newPasswordHash: string | null = null;

    if (!isExistingUser) {
      if (!password || !confirmPassword) {
        throw ApiError.badRequest('Password and Confirm Password are required to activate your account.');
      }
      if (password !== confirmPassword) {
        throw ApiError.badRequest('Passwords do not match');
      }
      const policyValidation = PasswordService.validatePassword(password);
      if (!policyValidation.valid) {
        throw ApiError.badRequest(policyValidation.message || 'Password does not meet security requirements.');
      }
      newPasswordHash = await PasswordService.hashPassword(password);
    }

    // Atomic consumption lock: prevents concurrent duplicate activations
    const consumedInvitation = await Invitation.findOneAndUpdate(
      {
        _id: invitation._id,
        status: InvitationStatus.PENDING,
      },
      {
        $set: {
          status: InvitationStatus.USED,
          usedAt: new Date(),
          'metadata.activationCompletedAt': new Date(),
          'metadata.verifiedEmail': verifiedEmail,
        },
      },
      { new: true }
    );

    if (!consumedInvitation) {
      throw ApiError.conflict('This invitation has already been consumed.');
    }

    try {
      if (!isExistingUser && newPasswordHash) {
        user.passwordHash = newPasswordHash;
        user.accountStatus = AccountStatus.ACTIVE;
        user.activationStatus = 'activated';
        if (!user.collegeId) {
          user.collegeId = college._id;
          user.role = invitation.role;
          user.departmentId = invitation.departmentId;
        }
        await user.save();
      }

      // Activate only the intended membership for this college
      const membership = await WorkspaceMembership.findOneAndUpdate(
        {
          userId: user._id,
          collegeId: college._id,
        },
        {
          $set: {
            status: MembershipStatus.ACTIVE,
            joinedAt: new Date(),
          },
          $setOnInsert: {
            instituteId: user.instituteId,
            memberType:
              invitation.role === AppRole.STUDENT
                ? MembershipType.STUDENT
                : invitation.role === AppRole.FACULTY || invitation.role === AppRole.HOD
                ? MembershipType.FACULTY
                : MembershipType.ADMINISTRATOR,
            isDefault: !isExistingUser,
            effectiveStartDate: new Date(),
          },
        },
        { new: true, upsert: true }
      );

      // Activate only the intended role assignment in this workspace
      await WorkspaceRoleAssignment.findOneAndUpdate(
        {
          membershipId: membership._id,
          role: invitation.role,
          departmentId: invitation.departmentId || null,
        },
        {
          $set: {
            status: RoleAssignmentStatus.ACTIVE,
            assignedAt: new Date(),
          },
          $setOnInsert: {
            userId: user._id,
            collegeId: college._id,
            effectiveStartDate: new Date(),
          },
        },
        { new: true, upsert: true }
      );

      await AuditLog.create({
        collegeId: college.id,
        workspaceMembershipId: membership.id,
        actorUserId: user.id,
        action: isExistingUser ? 'WORKSPACE_MEMBERSHIP_ACTIVATED' : 'ACCOUNT_ACTIVATED',
        entityType: 'User',
        entityId: user.id,
        newValue: {
          instituteId: user.instituteId,
          role: invitation.role,
          collegeId: college.id,
          isExistingUser,
        },
      });
    } catch (persistenceError) {
      await Invitation.findByIdAndUpdate(invitation._id, {
        $set: {
          status: InvitationStatus.PENDING,
          usedAt: null,
        },
      }).catch(() => {});
      throw persistenceError;
    }

    const completionMessage = isExistingUser
      ? 'College workspace access has been activated successfully. Please log in with your existing credentials.'
      : 'Account activated successfully. You may now log in with your credentials.';

    return {
      success: true,
      message: completionMessage,
      data: {
        message: completionMessage,
        user: {
          id: user.id,
          instituteId: user.instituteId,
          name: user.name,
          role: invitation.role,
          collegeCode: college.code,
          accountStatus: user.accountStatus,
        },
      },
    };
  }
}
