import crypto from 'crypto';
import { User, IUser } from '../models/user.model';
import { AuthSession } from '../models/authSession.model';
import { College } from '../models/college.model';
import { PasswordService } from './password.service';
import { OtpService } from './otp.service';
import { AppRole } from '../constants/roles';
import {
  AccountStatus,
  CollegeStatus,
  OtpPurpose,
  OtpDeliveryMethod,
  TokenType,
} from '../constants/status';
import {
  signAccessToken,
  signRefreshToken,
  signPasswordResetToken,
  verifyJwtToken,
  hashToken,
} from '../utils/token';
import { normalizeIdentifier } from '../utils/identifier';
import { ApiError } from '../utils/apiError';
import { env } from '../config/env';

export interface ClientMetadata {
  userAgent?: string;
  ipAddress?: string;
}

export interface LoginResult {
  accessToken: string;
  refreshToken: string;
  user: Record<string, unknown>;
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

    // Look up user by email or phone
    const query = type === 'email' ? { email: normalized } : { phone: normalized };
    const user = await User.findOne(query);

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

    // Check institution status for tenant users
    if (user.role !== AppRole.SUPER_ADMIN && user.collegeId) {
      const college = await College.findById(user.collegeId);
      if (college && (college.status === CollegeStatus.INACTIVE || !college.isActive)) {
        throw ApiError.forbidden(
          'Your institution is currently inactive. Please contact your administrator.'
        );
      }
    }

    // Verify password
    const isPasswordValid = await PasswordService.verifyPassword(password, user.passwordHash);
    if (!isPasswordValid) {
      throw ApiError.unauthorized('Invalid credentials');
    }

    // Update last login
    user.lastLoginAt = new Date();
    await user.save();

    // Create session
    const sessionId = crypto.randomUUID();
    const refreshToken = signRefreshToken({
      userId: user.id,
      instituteId: user.instituteId,
      email: user.email,
      phone: user.phone,
      name: user.name,
      role: user.role,
      collegeId: user.collegeId?.toString(),
      departmentId: user.departmentId?.toString(),
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
      role: user.role,
      collegeId: user.collegeId?.toString(),
      departmentId: user.departmentId?.toString(),
      courseId: user.courseId?.toString(),
      sectionId: user.sectionId?.toString(),
      semesterId: user.semesterId?.toString(),
      sessionId,
    });

    return {
      accessToken,
      refreshToken,
      user: user.toJSON(),
    };
  }

  /**
   * Session Refresh Flow:
   * Validates refresh token, checks session revocation, verifies user and college are active, issues new access token.
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

    // Verify college is still active for non-super-admin users
    if (user.role !== AppRole.SUPER_ADMIN && user.collegeId) {
      const college = await College.findById(user.collegeId);
      if (college && (college.status === CollegeStatus.INACTIVE || !college.isActive)) {
        throw ApiError.forbidden(
          'Your institution is currently inactive. Please contact your administrator.'
        );
      }
    }

    // Update session activity
    session.lastUsedAt = new Date();
    if (metadata.ipAddress) session.ipAddress = metadata.ipAddress;
    if (metadata.userAgent) session.userAgent = metadata.userAgent;
    await session.save();

    const accessToken = signAccessToken({
      userId: user.id,
      instituteId: user.instituteId,
      email: user.email,
      phone: user.phone,
      name: user.name,
      role: user.role,
      collegeId: user.collegeId?.toString(),
      departmentId: user.departmentId?.toString(),
      courseId: user.courseId?.toString(),
      sectionId: user.sectionId?.toString(),
      semesterId: user.semesterId?.toString(),
      sessionId: session.sessionId,
    });

    return {
      accessToken,
      user: user.toJSON(),
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
      const query = type === 'email' ? { email: normalized } : { phone: normalized };
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
    const query = type === 'email' ? { email: normalized } : { phone: normalized };
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
}
