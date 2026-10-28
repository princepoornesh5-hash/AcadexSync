import crypto from 'crypto';
import mongoose from 'mongoose';
import { User, IUser } from '../models/user.model';
import { AuthSession } from '../models/authSession.model';
import { College } from '../models/college.model';
import { WorkspaceMembership } from '../models/workspaceMembership.model';
import { WorkspaceRoleAssignment } from '../models/workspaceRoleAssignment.model';
import { WorkspaceMembershipService } from './workspaceMembership.service';
import { WorkspaceCompatibilityService } from './workspaceCompatibility.service';
import { PasswordService } from './password.service';
import { OtpService } from './otp.service';
import { AppRole, normalizeRole } from '../constants/roles';
import {
  AccountStatus,
  CollegeStatus,
  OtpPurpose,
  OtpDeliveryMethod,
  TokenType,
  MembershipStatus,
  RoleAssignmentStatus,
} from '../constants/status';
import {
  signAccessToken,
  signRefreshToken,
  signPasswordResetToken,
  signRegistrationToken,
  verifyRegistrationToken,
  verifyJwtToken,
  hashToken,
} from '../utils/token';
import { normalizeIdentifier, normalizeEmail } from '../utils/identifier';
import { ApiError } from '../utils/apiError';
import { env } from '../config/env';
import { AuditService } from './audit.service';
import { Logger } from '../utils/logger';

export interface ClientMetadata {
  userAgent?: string;
  ipAddress?: string;
  preferredWorkspaceId?: string;
  collegeId?: string;
}

export interface LoginResult {
  accessToken: string;
  refreshToken: string;
  user: Record<string, unknown>;
  activeWorkspace?: {
    collegeId: string;
    collegeName: string;
    membershipId: string | null;
    role: string;
    instituteId?: string | null;
  } | null;
  availableWorkspaces?: Array<{
    collegeId: string;
    collegeName: string;
    membershipId: string;
    role: string;
    instituteId?: string | null;
    isDefault?: boolean;
  }>;
  requiresWorkspaceSelection?: boolean;
}

export class AuthService {
  /**
   * Primary Login Flow:
   * 1. Normalize identifier (Email or Phone)
   * 2. Locate user
   * 3. Verify account state (ACTIVE required)
   * 4. Verify college state (ACTIVE required for non-super-admins)
   * 5. Verify password hash
   * 6. Create persistent AuthSession
   * 7. Issue Access & Refresh tokens
   */
  static async login(
    rawIdentifier: string,
    password: string,
    metadata: ClientMetadata = {}
  ): Promise<LoginResult> {
    const { type, normalized } = normalizeIdentifier(rawIdentifier);

    // Look up user by email, phone, or PIN Number (instituteId)
    let query: Record<string, unknown>;
    if (type === 'email') {
      query = { email: normalized };
    } else if (type === 'phone') {
      query = { $or: [{ phone: normalized }, { instituteId: rawIdentifier.trim().toUpperCase() }] };
    } else {
      query = { instituteId: normalized };
    }
    let user = await User.findOne(query);

    if (!user) {
      // Check if identifier matches a WorkspaceMembership institutional PIN
      const normalizedPin = rawIdentifier.trim().toUpperCase();
      const membershipWithPin = await WorkspaceMembership.findOne({
        instituteId: normalizedPin,
        status: { $in: [MembershipStatus.ACTIVE, MembershipStatus.PENDING] },
      });
      if (membershipWithPin) {
        user = await User.findById(membershipWithPin.userId);
      }
    }

    if (!user) {
      throw ApiError.unauthorized('Invalid credentials');
    }

    // Check account status
    if (user.accountStatus === AccountStatus.DEACTIVATED) {
      throw ApiError.forbidden('Account has been deactivated. Please contact your administrator.');
    }

    if (user.accountStatus === AccountStatus.PENDING_ACTIVATION) {
      throw ApiError.forbidden('Account is pending activation. Please activate your account first.');
    }

    if (user.accountStatus !== AccountStatus.ACTIVE) {
      throw ApiError.forbidden('Account is currently not active.');
    }

    // Verify password
    const isPasswordValid = await PasswordService.verifyPassword(password, user.passwordHash);
    if (!isPasswordValid) {
      throw ApiError.unauthorized('Invalid credentials');
    }

    // Update last login
    user.lastLoginAt = new Date();
    await user.save();

    return this.issueSessionForUser(user, metadata, 'USER_LOGIN');
  }

  /**
   * Internal session issuance engine:
   * Resolves authorized workspaces, creates AuthSession, signs JWTs,
   * records audit logs, and formats the unified login/session response.
   */
  static async issueSessionForUser(
    user: IUser,
    metadata: ClientMetadata,
    action: string = 'USER_LOGIN'
  ): Promise<LoginResult> {
    const sessionId = crypto.randomUUID();

    // -------------------------------------------------------------------------
    // PLATFORM SUPER ADMIN LOGIN
    // -------------------------------------------------------------------------
    if (user.role === AppRole.SUPER_ADMIN) {
      const refreshToken = signRefreshToken({
        userId: user.id,
        instituteId: user.instituteId,
        email: user.email,
        phone: user.phone,
        name: user.name,
        role: AppRole.SUPER_ADMIN,
        collegeId: undefined,
        departmentId: undefined,
        sessionId,
      });

      const refreshTokenHash = hashToken(refreshToken);
      const expiresAt = new Date(Date.now() + env.REFRESH_TOKEN_EXPIRES_IN * 1000);

      await AuthSession.create({
        userId: user._id,
        sessionId,
        refreshTokenHash,
        userAgent: metadata.userAgent,
        ipAddress: metadata.ipAddress,
        expiresAt,
        lastUsedAt: new Date(),
      });

      const accessToken = signAccessToken({
        userId: user.id,
        instituteId: user.instituteId,
        email: user.email,
        phone: user.phone,
        name: user.name,
        role: AppRole.SUPER_ADMIN,
        collegeId: undefined,
        departmentId: undefined,
        sessionId,
      });

      await AuditService.log({
        actorUserId: user.id,
        actorEmail: user.email,
        actorRole: AppRole.SUPER_ADMIN,
        action,
        entityType: 'User',
        entityId: user.id,
        metadata: { loginType: 'SUPER_ADMIN' },
        ipAddress: metadata.ipAddress,
        userAgent: metadata.userAgent,
      });

      return {
        accessToken,
        refreshToken,
        user: user.toJSON(),
        activeWorkspace: null,
        availableWorkspaces: [],
        requiresWorkspaceSelection: false,
      };
    }

    // -------------------------------------------------------------------------
    // INSTITUTIONAL TENANT USER MEMBERSHIP RESOLUTION
    // -------------------------------------------------------------------------
    const eligibleMemberships = await WorkspaceMembershipService.getEligibleMembershipsForUser(user.id);

    let activeCollegeId: string | undefined;
    let activeRole: AppRole;
    let activeDepartmentId: string | null = null;
    let activeInstituteId: string;
    let activeMembershipId: string | null = null;
    let activeCollegeName = '';
    let requiresWorkspaceSelection = false;

    if (eligibleMemberships.length > 0) {
      let selected: any = null;
      if (metadata.preferredWorkspaceId) {
        selected = eligibleMemberships.find(
          (m: any) =>
            (m.collegeId?._id || m.collegeId)?.toString() === metadata.preferredWorkspaceId ||
            (m._id || m.id)?.toString() === metadata.preferredWorkspaceId
        );
      }
      if (!selected) {
        selected = eligibleMemberships.find((m: any) => m.isDefault);
      }
      if (!selected) {
        selected = eligibleMemberships[0];
      }

      activeCollegeId = (selected.collegeId?._id || selected.collegeId)?.toString();
      activeCollegeName = selected.college?.name || 'Institutional Workspace';
      activeRole = selected.primaryRole;
      const dept = selected.roles?.find((r: any) => r.departmentId)?.departmentId;
      activeDepartmentId = dept ? (dept._id || dept).toString() : null;
      activeInstituteId = selected.instituteId || user.instituteId;
      activeMembershipId = (selected._id || selected.id)?.toString();

      requiresWorkspaceSelection =
        eligibleMemberships.length > 1 &&
        !metadata.preferredWorkspaceId &&
        !eligibleMemberships.some((m: any) => m.isDefault);
    } else {
      // Legacy compatibility fallback
      if (WorkspaceCompatibilityService.isLegacyFallbackEnabled() && user.collegeId) {
        const legacyCollege = await College.findById(user.collegeId);
        if (!legacyCollege || legacyCollege.status === CollegeStatus.INACTIVE || !legacyCollege.isActive) {
          throw ApiError.forbidden(
            'Your institution is currently inactive. Please contact your administrator.'
          );
        }
        activeCollegeId = legacyCollege.id;
        activeCollegeName = legacyCollege.name;
        activeRole = user.role;
        activeDepartmentId = user.departmentId?.toString() || null;
        activeInstituteId = user.instituteId;
        activeMembershipId = null;
        requiresWorkspaceSelection = false;
      } else if (!user.collegeId) {
        // Global identity with no institutional memberships (e.g. self-registered email user)
        activeCollegeId = undefined;
        activeCollegeName = '';
        activeRole = user.role || AppRole.STUDENT;
        activeDepartmentId = null;
        activeInstituteId = user.instituteId || '';
        activeMembershipId = null;
        requiresWorkspaceSelection = false;
      } else {
        throw ApiError.forbidden('No active workspace memberships found for this user.');
      }
    }

    const refreshToken = signRefreshToken({
      userId: user.id,
      instituteId: activeInstituteId,
      email: user.email,
      phone: user.phone,
      name: user.name,
      role: activeRole,
      collegeId: activeCollegeId,
      departmentId: activeDepartmentId || undefined,
      sessionId,
      workspaceMembershipId: activeMembershipId,
      membershipId: activeMembershipId,
    });

    const refreshTokenHash = hashToken(refreshToken);
    const expiresAt = new Date(Date.now() + env.REFRESH_TOKEN_EXPIRES_IN * 1000);

    await AuthSession.create({
      userId: user._id,
      sessionId,
      refreshTokenHash,
      userAgent: metadata.userAgent,
      ipAddress: metadata.ipAddress,
      expiresAt,
      lastUsedAt: new Date(),
    });

    const accessToken = signAccessToken({
      userId: user.id,
      instituteId: activeInstituteId,
      email: user.email,
      phone: user.phone,
      name: user.name,
      role: activeRole,
      collegeId: activeCollegeId,
      departmentId: activeDepartmentId || undefined,
      courseId: user.courseId?.toString(),
      sectionId: user.sectionId?.toString(),
      semesterId: user.semesterId?.toString(),
      sessionId,
      workspaceMembershipId: activeMembershipId,
      membershipId: activeMembershipId,
    });

    await AuditService.log({
      actorUserId: user.id,
      actorEmail: user.email,
      actorRole: activeRole,
      action,
      entityType: 'User',
      entityId: user.id,
      collegeId: activeCollegeId,
      workspaceMembershipId: activeMembershipId || undefined,
      metadata: {
        activeCollegeId,
        activeRole,
        activeInstituteId,
        workspaceMembershipId: activeMembershipId,
      },
      ipAddress: metadata.ipAddress,
      userAgent: metadata.userAgent,
    });

    const availableWorkspaces = eligibleMemberships.map((m: any) => ({
      collegeId: (m.collegeId?._id || m.collegeId)?.toString() || '',
      collegeName: m.college?.name || 'Institutional Workspace',
      membershipId: (m._id || m.id)?.toString() || '',
      role: m.primaryRole,
      instituteId: m.instituteId || null,
      isDefault: !!m.isDefault,
    }));

    const activeWorkspace = activeCollegeId
      ? {
          collegeId: activeCollegeId,
          collegeName: activeCollegeName,
          membershipId: activeMembershipId,
          role: activeRole,
          instituteId: activeInstituteId,
        }
      : null;

    const userJson: any = user.toJSON();
    userJson.collegeId = activeCollegeId || null;
    userJson.role = activeRole;
    userJson.instituteId = activeInstituteId;
    userJson.departmentId = activeDepartmentId;
    userJson.workspaceMembershipId = activeMembershipId;

    return {
      accessToken,
      refreshToken,
      user: userJson,
      activeWorkspace,
      availableWorkspaces,
      requiresWorkspaceSelection,
    };
  }

  /**
   * Login with Email OTP - Step 1: Request OTP challenge
   */
  static async requestLoginOtp(rawEmail: string): Promise<{ message: string }> {
    const genericResponse = {
      message: 'If an active account exists with this email, a verification code has been sent.',
    };

    if (!rawEmail || typeof rawEmail !== 'string' || !rawEmail.includes('@')) {
      return genericResponse;
    }

    const normalizedEmail = normalizeEmail(rawEmail);
    const user = await User.findOne({ email: normalizedEmail });

    if (!user || user.accountStatus !== AccountStatus.ACTIVE) {
      return genericResponse;
    }

    try {
      await OtpService.requestOtp({
        userId: user._id,
        destination: normalizedEmail,
        purpose: OtpPurpose.LOGIN,
        deliveryMethod: OtpDeliveryMethod.EMAIL,
        expiresInSeconds: 300,
      });
    } catch (err: unknown) {
      if (err instanceof ApiError && err.statusCode === 429) {
        throw err;
      }
      Logger.error('[AUTH] Login OTP dispatch failed', err);
      throw ApiError.internal('Failed to deliver verification code. Please try again later.');
    }

    return genericResponse;
  }

  /**
   * Login with Email OTP - Step 2: Verify OTP and issue session
   */
  static async loginWithOtp(
    rawEmail: string,
    otp: string,
    metadata: ClientMetadata = {}
  ): Promise<LoginResult> {
    if (!rawEmail || typeof rawEmail !== 'string') {
      throw ApiError.badRequest('Email is required');
    }
    if (!otp || typeof otp !== 'string') {
      throw ApiError.badRequest('Verification code is required');
    }

    const normalizedEmail = normalizeEmail(rawEmail);
    const user = await User.findOne({ email: normalizedEmail });

    if (!user || user.accountStatus !== AccountStatus.ACTIVE) {
      throw ApiError.unauthorized('Invalid verification code or email');
    }

    // Verify and consume OTP server-side
    await OtpService.verifyAndConsumeOtp({
      userId: user._id,
      destination: normalizedEmail,
      purpose: OtpPurpose.LOGIN,
      otp: otp.trim(),
    });

    user.lastLoginAt = new Date();
    await user.save();

    return this.issueSessionForUser(user, metadata, 'USER_LOGIN_OTP');
  }

  /**
   * Account Registration - Step 1: Request Email OTP
   */
  static async registerRequestOtp(rawEmail: string): Promise<{ message: string }> {
    const genericResponse = {
      message: 'If this email is eligible for registration, a verification code has been sent.',
    };

    if (!rawEmail || typeof rawEmail !== 'string' || !rawEmail.includes('@')) {
      throw ApiError.badRequest('A valid email address is required');
    }

    const normalizedEmail = normalizeEmail(rawEmail);

    // Basic format check
    const emailRegex = /^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$/;
    if (!emailRegex.test(normalizedEmail)) {
      throw ApiError.badRequest('Invalid email address format');
    }

    // Check if account already exists for this email
    const existingUser = await User.findOne({ email: normalizedEmail });
    if (existingUser) {
      // Generic response prevents account enumeration
      return genericResponse;
    }

    try {
      await OtpService.requestOtp({
        destination: normalizedEmail,
        purpose: OtpPurpose.REGISTRATION,
        deliveryMethod: OtpDeliveryMethod.EMAIL,
        expiresInSeconds: 300,
      });
    } catch (err: unknown) {
      if (err instanceof ApiError && err.statusCode === 429) {
        throw err;
      }
      Logger.error('[AUTH] Registration OTP dispatch failed', err);
      throw ApiError.internal('Failed to deliver verification code. Please try again later.');
    }

    return genericResponse;
  }

  /**
   * Account Registration - Step 2: Verify Email OTP and issue registrationToken
   */
  static async registerVerifyOtp(
    rawEmail: string,
    otp: string
  ): Promise<{ registrationToken: string; message: string }> {
    if (!rawEmail || typeof rawEmail !== 'string') {
      throw ApiError.badRequest('Email is required');
    }
    if (!otp || typeof otp !== 'string') {
      throw ApiError.badRequest('Verification code is required');
    }

    const normalizedEmail = normalizeEmail(rawEmail);

    // Verify and consume OTP
    await OtpService.verifyAndConsumeOtp({
      destination: normalizedEmail,
      purpose: OtpPurpose.REGISTRATION,
      otp: otp.trim(),
    });

    // Issue short-lived registration token
    const registrationToken = signRegistrationToken({ email: normalizedEmail }, 600);

    return {
      registrationToken,
      message: 'Email verified successfully. Please set your password to complete registration.',
    };
  }

  /**
   * Account Registration - Step 3: Complete registration and password setup
   */
  static async registerComplete(
    registrationToken: string,
    password: string,
    confirmPassword: string,
    name?: string,
    metadata: ClientMetadata = {}
  ): Promise<LoginResult> {
    if (!registrationToken || typeof registrationToken !== 'string') {
      throw ApiError.badRequest('registrationToken is required');
    }
    if (!password || typeof password !== 'string') {
      throw ApiError.badRequest('Password is required');
    }
    if (!confirmPassword || typeof confirmPassword !== 'string') {
      throw ApiError.badRequest('Confirm Password is required');
    }

    if (password !== confirmPassword) {
      throw ApiError.badRequest('Passwords do not match');
    }

    // Validate password policy
    const policy = PasswordService.validatePassword(password);
    if (!policy.valid) {
      throw ApiError.badRequest(policy.message || 'Password does not meet security requirements.');
    }

    // Validate registration token
    const { email: verifiedEmail } = verifyRegistrationToken(registrationToken);
    const normalizedEmail = normalizeEmail(verifiedEmail);

    // Prevent duplicate user creation
    const existingUser = await User.findOne({ email: normalizedEmail });
    if (existingUser) {
      throw ApiError.conflict('An account with this email address already exists.');
    }

    const passwordHash = await PasswordService.hashPassword(password);
    const userName = name?.trim() || normalizedEmail.split('@')[0];

    // Create user with base role and NO institutional college access
    const newUser = await User.create({
      name: userName,
      email: normalizedEmail,
      passwordHash,
      role: AppRole.STUDENT,
      collegeId: null,
      departmentId: null,
      accountStatus: AccountStatus.ACTIVE,
      activationStatus: 'activated',
    });

    await AuditService.log({
      actorUserId: newUser.id,
      actorEmail: newUser.email,
      actorRole: AppRole.STUDENT,
      action: 'USER_REGISTERED',
      entityType: 'User',
      entityId: newUser.id,
      metadata: { registrationMethod: 'EMAIL_OTP' },
      ipAddress: metadata.ipAddress,
      userAgent: metadata.userAgent,
    });

    // Issue supported session response
    return this.issueSessionForUser(newUser, metadata, 'USER_REGISTERED');
  }

  /**
   * Session Refresh Flow:
   * Validates refresh token, checks session revocation, verifies user, college, and membership status, issues new access token.
   */
  static async refreshToken(
    rawRefreshToken: string,
    metadata: ClientMetadata = {}
  ): Promise<{ accessToken: string; user: Record<string, unknown> }> {
    if (!rawRefreshToken || typeof rawRefreshToken !== 'string') {
      throw ApiError.unauthorized('Refresh token is required');
    }

    const payload = verifyJwtToken(rawRefreshToken, TokenType.REFRESH, env.JWT_REFRESH_SECRET);

    if (!payload.sessionId) {
      throw ApiError.unauthorized('Invalid refresh token session payload');
    }

    const session = await AuthSession.findOne({ sessionId: payload.sessionId });

    if (!session) {
      throw ApiError.unauthorized('Session not found or has expired');
    }

    if (session.isRevoked()) {
      throw ApiError.unauthorized('Session has been revoked. Please log in again.');
    }

    if (session.isExpired()) {
      throw ApiError.unauthorized('Session has expired. Please log in again.');
    }

    // Verify token hash
    const incomingHash = hashToken(rawRefreshToken);
    if (incomingHash !== session.refreshTokenHash) {
      throw ApiError.unauthorized('Invalid session refresh token');
    }

    // Verify user is still active
    const user = await User.findById(session.userId);
    if (!user || user.accountStatus !== AccountStatus.ACTIVE) {
      throw ApiError.unauthorized('User account is no longer active');
    }

    let activeRole = user.role;
    let activeDepartmentId = user.departmentId?.toString() || null;
    let activeInstituteId = user.instituteId;
    let activeMembershipId = payload.workspaceMembershipId || payload.membershipId || null;
    const targetCollegeId = payload.collegeId || user.collegeId?.toString();

    // Verify college and membership status for non-super-admin users
    if (user.role !== AppRole.SUPER_ADMIN && targetCollegeId) {
      const college = await College.findById(targetCollegeId);
      if (college && (college.status === CollegeStatus.INACTIVE || !college.isActive)) {
        throw ApiError.forbidden(
          'Your institution is currently inactive. Please contact your administrator.'
        );
      }

      // Check authoritative membership state
      let membership = null;
      if (activeMembershipId && mongoose.Types.ObjectId.isValid(activeMembershipId)) {
        membership = await WorkspaceMembership.findOne({
          _id: activeMembershipId,
          userId: user._id,
          collegeId: targetCollegeId,
        });
      }
      if (!membership) {
        membership = await WorkspaceMembership.findOne({
          userId: user._id,
          collegeId: targetCollegeId,
        });
      }

      if (membership) {
        if (membership.status !== MembershipStatus.ACTIVE) {
          throw ApiError.forbidden(`Workspace membership is ${membership.status.toLowerCase()}. Access denied.`);
        }

        const now = new Date();
        if (membership.effectiveStartDate && membership.effectiveStartDate > now) {
          throw ApiError.forbidden('Workspace membership is not yet effective. Access denied.');
        }
        if (membership.effectiveEndDate && membership.effectiveEndDate < now) {
          throw ApiError.forbidden('Workspace membership has expired. Access denied.');
        }

        // Check active role assignments
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
          throw ApiError.forbidden('No active role assignments found in this workspace.');
        }

        activeRole = roleAssignments[0].role;
        activeDepartmentId = roleAssignments[0].departmentId?.toString() || user.departmentId?.toString() || null;
        activeInstituteId = membership.instituteId || user.instituteId;
        activeMembershipId = membership.id;
      }
    }

    // Update session activity
    session.lastUsedAt = new Date();
    if (metadata.ipAddress) session.ipAddress = metadata.ipAddress;
    if (metadata.userAgent) session.userAgent = metadata.userAgent;
    await session.save();

    const accessToken = signAccessToken({
      userId: user.id,
      instituteId: activeInstituteId,
      email: user.email,
      phone: user.phone,
      name: user.name,
      role: activeRole,
      collegeId: targetCollegeId,
      departmentId: activeDepartmentId || undefined,
      courseId: user.courseId?.toString(),
      sectionId: user.sectionId?.toString(),
      semesterId: user.semesterId?.toString(),
      sessionId: session.sessionId,
      workspaceMembershipId: activeMembershipId,
      membershipId: activeMembershipId,
    });

    const userJson: any = user.toJSON();
    userJson.collegeId = targetCollegeId;
    userJson.role = activeRole;
    userJson.instituteId = activeInstituteId;
    userJson.departmentId = activeDepartmentId;
    userJson.workspaceMembershipId = activeMembershipId;

    return {
      accessToken,
      user: userJson,
    };
  }

  /**
   * Single Session Logout:
   * Revokes the specific active session.
   */
  static async logout(sessionId?: string, userId?: string): Promise<void> {
    if (!sessionId && !userId) {
      return;
    }

    const query: Record<string, unknown> = {};
    if (sessionId) query.sessionId = sessionId;
    if (userId) query.userId = userId;

    await AuthSession.updateOne(
      { ...query, revokedAt: null },
      { $set: { revokedAt: new Date() } }
    );

    // Audit session revocation (never log tokens or credentials)
    await AuditService.log({
      actorUserId: userId || 'unknown',
      action: 'SESSION_REVOKED',
      entityType: 'AuthSession',
      entityId: sessionId || userId || 'session',
      newValue: { sessionId },
    }).catch(() => {});

    // Realtime connection teardown
    try {
      const { RoomManager } = await import('../realtime/roomManager');
      if (sessionId) {
        RoomManager.getInstance().revokeSession(sessionId);
      } else if (userId) {
        RoomManager.getInstance().revokeAllUserSockets(userId, 'Session revoked');
      }
    } catch (_) {}
  }

  /**
   * Multi-Session Logout (Logout All):
   * Revokes all active sessions for the user.
   */
  static async logoutAll(userId: string): Promise<void> {
    await AuthSession.updateMany(
      { userId, revokedAt: null },
      { $set: { revokedAt: new Date() } }
    );

    await AuditService.log({
      actorUserId: userId,
      action: 'ALL_SESSIONS_REVOKED',
      entityType: 'AuthSession',
      entityId: userId,
      newValue: { userId },
    }).catch(() => {});

    // Teardown all realtime connections for user
    try {
      const { RoomManager } = await import('../realtime/roomManager');
      RoomManager.getInstance().revokeAllUserSockets(userId, 'All sessions revoked');
    } catch (_) {}
  }


  /**
   * Password Recovery Flow - Step 1: Request OTP
   * Generates secure 6-digit OTP and delivers via configured channel.
   * Always returns generic response to prevent account enumeration.
   */
  static async forgotPassword(rawIdentifier: string): Promise<{ message: string }> {
    const genericResponse = {
      message: 'If the account exists, a verification code has been sent.',
    };

    try {
      const { type, normalized } = normalizeIdentifier(rawIdentifier);
      let query: Record<string, unknown>;
      if (type === 'email') {
        query = { email: normalized };
      } else if (type === 'phone') {
        query = { $or: [{ phone: normalized }, { instituteId: rawIdentifier.trim().toUpperCase() }] };
      } else {
        query = { instituteId: normalized };
      }
      const user = await User.findOne(query);

      if (!user || user.accountStatus !== AccountStatus.ACTIVE) {
        return genericResponse;
      }

      // Check destination
      const destination = type === 'email' ? user.email : user.phone;
      if (!destination) {
        return genericResponse;
      }

      const method =
        type === 'email' ? OtpDeliveryMethod.EMAIL : OtpDeliveryMethod.SMS;

      await OtpService.requestOtp(user._id, OtpPurpose.PASSWORD_RESET, destination, method);

      return genericResponse;
    } catch {
      // In case of error or non-existent account, return generic message for privacy
      return genericResponse;
    }
  }

  /**
   * Password Recovery Flow - Step 2: Verify OTP
   * Validates OTP and issues temporary PASSWORD_RESET token.
   */
  static async verifyPasswordResetOtp(
    rawIdentifier: string,
    otpCode: string
  ): Promise<{ resetToken: string; message: string }> {
    const { type, normalized } = normalizeIdentifier(rawIdentifier);
    let query: Record<string, unknown>;
    if (type === 'email') {
      query = { email: normalized };
    } else if (type === 'phone') {
      query = { $or: [{ phone: normalized }, { instituteId: rawIdentifier.trim().toUpperCase() }] };
    } else {
      query = { instituteId: normalized };
    }
    const user = await User.findOne(query);

    if (!user || user.accountStatus !== AccountStatus.ACTIVE) {
      throw ApiError.badRequest('Invalid verification code or identifier');
    }

    // Verify and consume OTP
    await OtpService.verifyAndConsumeOtp(user._id, OtpPurpose.PASSWORD_RESET, otpCode);

    // Issue short-lived password reset authorization token
    const resetToken = signPasswordResetToken({
      userId: user.id,
      instituteId: user.instituteId,
      email: user.email,
      role: user.role,
      collegeId: user.collegeId?.toString(),
    });

    return {
      resetToken,
      message: 'Code verified successfully. You may now reset your password.',
    };
  }

  /**
   * Password Recovery Flow - Step 3: Reset Password
   * Validates password reset token, updates password hash, and REVOKES ALL EXISTING SESSIONS.
   */
  static async resetPassword(
    resetToken: string,
    newPassword: string
  ): Promise<{ message: string }> {
    if (!resetToken || !newPassword) {
      throw ApiError.badRequest('Reset token and new password are required');
    }

    // Verify token
    const payload = verifyJwtToken(
      resetToken,
      TokenType.PASSWORD_RESET,
      env.JWT_RESET_SECRET
    );

    // Validate password policy
    const policyValidation = PasswordService.validatePassword(newPassword);
    if (!policyValidation.valid) {
      throw ApiError.badRequest(policyValidation.message || 'Invalid password');
    }

    // Locate user
    const user = await User.findById(payload.userId);
    if (!user) {
      throw ApiError.notFound('User not found');
    }

    // Hash new password
    const newPasswordHash = await PasswordService.hashPassword(newPassword);

    // Update password
    user.passwordHash = newPasswordHash;
    await user.save();

    // CRITICAL: Revoke ALL existing active sessions for this user
    await this.logoutAll(user.id);

    return {
      message: 'Password has been reset successfully. Please log in with your new password.',
    };
  }

  /**
   * Authenticated Change Password Flow:
   * Validates current password, enforces policy on new password, hashes and updates,
   * then revokes ALL existing sessions except the current one for security.
   */
  static async changePassword(
    userId: string,
    currentPassword: string,
    newPassword: string,
    currentSessionId?: string
  ): Promise<{ message: string }> {
    if (!currentPassword || !newPassword) {
      throw ApiError.badRequest('Current password and new password are required');
    }

    const user = await User.findById(userId);
    if (!user) {
      throw ApiError.notFound('User not found');
    }

    if (user.accountStatus !== AccountStatus.ACTIVE) {
      throw ApiError.forbidden('Account is not active');
    }

    // Verify current password
    const isCurrentValid = await PasswordService.verifyPassword(currentPassword, user.passwordHash);
    if (!isCurrentValid) {
      throw ApiError.unauthorized('Current password is incorrect');
    }

    // Validate new password policy
    const validation = PasswordService.validatePassword(newPassword);
    if (!validation.valid) {
      throw ApiError.badRequest(validation.message || 'Invalid password');
    }

    // Prevent reuse of same password
    const isSamePassword = await PasswordService.verifyPassword(newPassword, user.passwordHash);
    if (isSamePassword) {
      throw ApiError.badRequest('New password must be different from the current password');
    }

    // Hash and update
    const newHash = await PasswordService.hashPassword(newPassword);
    user.passwordHash = newHash;
    await user.save();

    // Revoke all sessions except current for security
    if (currentSessionId) {
      await AuthSession.updateMany(
        { userId: user._id, revokedAt: null, sessionId: { $ne: currentSessionId } },
        { $set: { revokedAt: new Date() } }
      );
    } else {
      await this.logoutAll(userId);
    }

    return {
      message: 'Password changed successfully.',
    };
  }

  /**
   * Get Current Authenticated User Context
   */
  static async getMe(userId: string): Promise<IUser> {
    const user = await User.findById(userId);
    if (!user) {
      throw ApiError.notFound('User not found');
    }
    return user;
  }

  /**
   * Development Role Quick-Login
   * Strictly gated to NODE_ENV === 'development'.
   * Issues authoritative session, access token, and refresh token.
   */
  static async devLogin(
    roleInput?: string,
    identifier?: string,
    metadata: ClientMetadata = {}
  ): Promise<LoginResult & { workspaceId?: string }> {
    if (env.NODE_ENV !== 'development' && env.NODE_ENV !== 'test') {
      throw ApiError.forbidden('Development login is disabled in non-development environments');
    }

    let user: IUser | null = null;

    if (identifier && identifier.trim()) {
      const { type, normalized } = normalizeIdentifier(identifier.trim());
      user = await User.findOne(
        type === 'email' ? { email: normalized } : { instituteId: normalized }
      );
    }

    if (!user && roleInput) {
      let targetRole: AppRole;
      try {
        targetRole = normalizeRole(roleInput);
      } catch (err: any) {
        throw ApiError.badRequest(err.message || 'Invalid role value');
      }

      // Prioritize primary SVGP demo test identities
      const roleEmailMap: Record<string, string> = {
        [AppRole.SUPER_ADMIN]: 'admin@acadex.com',
        [AppRole.COLLEGE_ADMIN]: 'college@acadex.com',
        [AppRole.HOD]: 'hod@acadex.com',
        [AppRole.FACULTY]: 'faculty@acadex.com',
        [AppRole.STUDENT]: 'student@acadex.com',
      };

      const preferredEmail = roleEmailMap[targetRole];
      if (preferredEmail) {
        user = await User.findOne({ email: preferredEmail });
      }

      // If not found by email, lookup by role and SVGP college
      if (!user) {
        const svgp = await College.findOne({ code: 'SVGP' });
        const collegeFilter =
          svgp && targetRole !== AppRole.SUPER_ADMIN ? { collegeId: svgp._id } : {};
        user = await User.findOne({ role: targetRole, ...collegeFilter });
      }

      // Fallback for Super Admin
      if (!user && targetRole === AppRole.SUPER_ADMIN) {
        user = await User.findOne({ role: AppRole.SUPER_ADMIN });
      }
    }

    if (!user) {
      throw ApiError.notFound(
        `No demo user found for role "${roleInput || 'specified'}". Ensure SVGP demo data is seeded.`
      );
    }

    if (user.accountStatus !== AccountStatus.ACTIVE) {
      throw ApiError.forbidden('Demo user account is currently deactivated or inactive.');
    }

    // Resolve workspace membership
    let activeWorkspaceId: string | undefined = user.collegeId ? user.collegeId.toString() : undefined;
    let activeInstituteId: string = user.instituteId;
    let activeMembershipId: string | null = null;
    let activeRole: AppRole = user.role;

    const membership = await WorkspaceMembership.findOne({
      userId: user._id,
      status: MembershipStatus.ACTIVE,
    });
    if (membership) {
      activeWorkspaceId = membership.collegeId.toString();
      activeInstituteId = membership.instituteId || user.instituteId;
      activeMembershipId = membership.id;

      const roleAssignment = await WorkspaceRoleAssignment.findOne({
        membershipId: membership._id,
        status: RoleAssignmentStatus.ACTIVE,
      });
      if (roleAssignment) {
        activeRole = roleAssignment.role;
      }
    }

    // Create persistent AuthSession
    const sessionId = crypto.randomUUID();
    const refreshToken = signRefreshToken({
      userId: user.id,
      instituteId: activeInstituteId,
      email: user.email,
      phone: user.phone,
      name: user.name,
      role: activeRole,
      collegeId: activeWorkspaceId,
      departmentId: user.departmentId?.toString(),
      sessionId,
      workspaceMembershipId: activeMembershipId,
      membershipId: activeMembershipId,
    });

    const refreshTokenHash = hashToken(refreshToken);
    const expiresAt = new Date(Date.now() + env.REFRESH_TOKEN_EXPIRES_IN * 1000);

    await AuthSession.create({
      userId: user._id,
      sessionId,
      refreshTokenHash,
      userAgent: metadata.userAgent || 'ACADEX-DevMode',
      ipAddress: metadata.ipAddress || '127.0.0.1',
      expiresAt,
      lastUsedAt: new Date(),
    });

    const accessToken = signAccessToken({
      userId: user.id,
      instituteId: activeInstituteId,
      email: user.email,
      phone: user.phone,
      name: user.name,
      role: activeRole,
      collegeId: activeWorkspaceId,
      departmentId: user.departmentId?.toString(),
      courseId: user.courseId?.toString(),
      sectionId: user.sectionId?.toString(),
      semesterId: user.semesterId?.toString(),
      sessionId,
      workspaceMembershipId: activeMembershipId,
      membershipId: activeMembershipId,
    });

    user.lastLoginAt = new Date();
    await user.save();

    return {
      accessToken,
      refreshToken,
      workspaceId: activeWorkspaceId,
      user: user.toJSON(),
    };
  }
}
