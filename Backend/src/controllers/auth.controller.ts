import { Request, Response } from 'express';
import { AuthService } from '../services/auth.service';
import { ApiResponse } from '../utils/apiResponse';
import { asyncHandler } from '../utils/asyncHandler';
import { ApiError } from '../utils/apiError';

export class AuthController {
  /**
   * POST /api/v1/auth/login
   */
  static login = asyncHandler(async (req: Request, res: Response) => {
    const { identifier, password, collegeId, preferredWorkspaceId } = req.body;

    if (!identifier || !password) {
      throw ApiError.badRequest('Identifier (PIN Number, email, or phone) and password are required');
    }

    const rawHeaderWorkspaceId = req.headers['x-workspace-id'];
    const headerWorkspaceId = (
      Array.isArray(rawHeaderWorkspaceId) ? rawHeaderWorkspaceId[0] : rawHeaderWorkspaceId
    )?.trim();

    const metadata = {
      userAgent: req.headers['user-agent'],
      ipAddress: req.ip || req.socket.remoteAddress,
      preferredWorkspaceId: preferredWorkspaceId || collegeId || headerWorkspaceId,
      collegeId: collegeId || preferredWorkspaceId || headerWorkspaceId,
    };

    const result = await AuthService.login(identifier, password, metadata);

    return ApiResponse.success(res, result, 'Login successful');
  });

  /**
   * POST /api/v1/auth/refresh
   */
  static refresh = asyncHandler(async (req: Request, res: Response) => {
    const { refreshToken } = req.body;

    if (!refreshToken) {
      throw ApiError.badRequest('Refresh token is required');
    }

    const metadata = {
      userAgent: req.headers['user-agent'],
      ipAddress: req.ip || req.socket.remoteAddress,
    };

    const result = await AuthService.refreshToken(refreshToken, metadata);

    return ApiResponse.success(res, result, 'Token refreshed successfully');
  });

  /**
   * POST /api/v1/auth/logout
   */
  static logout = asyncHandler(async (req: Request, res: Response) => {
    const sessionId = req.user?.sessionId;
    const userId = req.user?.id;

    await AuthService.logout(sessionId, userId);

    return ApiResponse.success(res, null, 'Logged out successfully');
  });

  /**
   * POST /api/v1/auth/logout-all
   */
  static logoutAll = asyncHandler(async (req: Request, res: Response) => {
    const userId = req.user?.id;

    if (!userId) {
      throw ApiError.unauthorized('User not authenticated');
    }

    await AuthService.logoutAll(userId);

    return ApiResponse.success(res, null, 'All sessions have been revoked successfully');
  });

  /**
   * GET /api/v1/auth/me
   */
  static getMe = asyncHandler(async (req: Request, res: Response) => {
    const userId = req.user?.id;

    if (!userId) {
      throw ApiError.unauthorized('User not authenticated');
    }

    const user = await AuthService.getMe(userId);

    const activeCollegeId = req.user?.collegeId || user.collegeId?.toString() || null;
    const activeRole = req.user?.role || user.role;
    const activeDeptId = (req.user?.authorizedDepartmentIds && req.user.authorizedDepartmentIds.length > 0
      ? req.user.authorizedDepartmentIds[0]
      : null) || user.departmentId?.toString() || null;

    return ApiResponse.success(res, {
      id: user.id,
      instituteId: req.user?.instituteId || user.instituteId,
      name: user.name,
      email: user.email || null,
      phone: user.phone || null,
      role: activeRole,
      accountStatus: user.accountStatus,
      activationStatus: user.activationStatus,
      collegeId: activeCollegeId,
      departmentId: activeDeptId,
      courseId: user.courseId?.toString() || null,
      sectionId: user.sectionId?.toString() || null,
      semesterId: user.semesterId?.toString() || null,
      profilePictureUrl: user.profilePictureUrl || null,
      lastLoginAt: user.lastLoginAt || null,
      createdAt: user.createdAt,
      workspaceMembershipId: req.user?.workspaceMembershipId || null,
      activeRoles: req.user?.activeRoles || [activeRole],
      activeWorkspace: req.workspace || null,
    });
  });

  /**
   * POST /api/v1/auth/forgot-password
   */
  static forgotPassword = asyncHandler(async (req: Request, res: Response) => {
    const { identifier } = req.body;

    if (!identifier) {
      throw ApiError.badRequest('Identifier (email or phone) is required');
    }

    const result = await AuthService.forgotPassword(identifier);

    return ApiResponse.success(res, null, result.message);
  });

  /**
   * POST /api/v1/auth/verify-password-reset-otp
   */
  static verifyPasswordResetOtp = asyncHandler(async (req: Request, res: Response) => {
    const { identifier, otp } = req.body;

    if (!identifier || !otp) {
      throw ApiError.badRequest('Identifier and OTP are required');
    }

    const result = await AuthService.verifyPasswordResetOtp(identifier, otp);

    return ApiResponse.success(res, { resetToken: result.resetToken }, result.message);
  });

  /**
   * POST /api/v1/auth/reset-password
   */
  static resetPassword = asyncHandler(async (req: Request, res: Response) => {
    const { resetToken, newPassword } = req.body;

    if (!resetToken || !newPassword) {
      throw ApiError.badRequest('Reset token and new password are required');
    }

    const result = await AuthService.resetPassword(resetToken, newPassword);

    return ApiResponse.success(res, null, result.message);
  });

  /**
   * POST /api/v1/auth/change-password
   * Authenticated endpoint to change the current user's password.
   */
  static changePassword = asyncHandler(async (req: Request, res: Response) => {
    const userId = req.user?.id;
    const sessionId = req.user?.sessionId;

    if (!userId) {
      throw ApiError.unauthorized('User not authenticated');
    }

    const { currentPassword, newPassword } = req.body;

    if (!currentPassword || !newPassword) {
      throw ApiError.badRequest('Current password and new password are required');
    }

    const result = await AuthService.changePassword(userId, currentPassword, newPassword, sessionId);

    return ApiResponse.success(res, null, result.message);
  });

  /**
   * POST /api/v1/auth/dev-login
   * Development-only role quick-login.
   */
  static devLogin = asyncHandler(async (req: Request, res: Response) => {
    const { role, identifier } = req.body;

    const metadata = {
      userAgent: req.headers['user-agent'],
      ipAddress: req.ip || req.socket.remoteAddress,
    };

    const result = await AuthService.devLogin(role, identifier, metadata);

    return ApiResponse.success(res, result, 'Development session established successfully');
  });

  /**
   * POST /api/v1/auth/login/request-otp
   * Request email OTP challenge for login.
   */
  static requestLoginOtp = asyncHandler(async (req: Request, res: Response) => {
    const { email } = req.body;

    if (!email || typeof email !== 'string') {
      throw ApiError.badRequest('Email is required');
    }

    const result = await AuthService.requestLoginOtp(email.trim());

    return ApiResponse.success(res, null, result.message);
  });

  /**
   * POST /api/v1/auth/login/verify-otp
   * Verify email OTP and establish authenticated session.
   */
  static loginWithOtp = asyncHandler(async (req: Request, res: Response) => {
    const { email, otp, collegeId, preferredWorkspaceId } = req.body;

    if (!email || typeof email !== 'string') {
      throw ApiError.badRequest('Email is required');
    }

    if (otp === undefined || otp === null) {
      throw ApiError.badRequest('Verification code is required');
    }

    const rawHeaderWorkspaceId = req.headers['x-workspace-id'];
    const headerWorkspaceId = (
      Array.isArray(rawHeaderWorkspaceId) ? rawHeaderWorkspaceId[0] : rawHeaderWorkspaceId
    )?.trim();

    const metadata = {
      userAgent: req.headers['user-agent'],
      ipAddress: req.ip || req.socket.remoteAddress,
      preferredWorkspaceId: preferredWorkspaceId || collegeId || headerWorkspaceId,
      collegeId: collegeId || preferredWorkspaceId || headerWorkspaceId,
    };

    const rawOtp = typeof otp === 'number' ? String(otp) : otp;
    const result = await AuthService.loginWithOtp(email.trim(), rawOtp.trim(), metadata);

    return ApiResponse.success(res, result, 'Login successful');
  });

  /**
   * POST /api/v1/auth/register/request-otp
   * Request email OTP for self-registration.
   */
  static registerRequestOtp = asyncHandler(async (req: Request, res: Response) => {
    const { email } = req.body;

    if (!email || typeof email !== 'string') {
      throw ApiError.badRequest('Email is required');
    }

    const result = await AuthService.registerRequestOtp(email.trim());

    return ApiResponse.success(res, null, result.message);
  });

  /**
   * POST /api/v1/auth/register/verify-otp
   * Verify email OTP and issue registrationToken for self-registration.
   */
  static registerVerifyOtp = asyncHandler(async (req: Request, res: Response) => {
    const { email, otp } = req.body;

    if (!email || typeof email !== 'string') {
      throw ApiError.badRequest('Email is required');
    }

    if (otp === undefined || otp === null) {
      throw ApiError.badRequest('Verification code is required');
    }

    const rawOtp = typeof otp === 'number' ? String(otp) : otp;
    const result = await AuthService.registerVerifyOtp(email.trim(), rawOtp.trim());

    return ApiResponse.success(
      res,
      { registrationToken: result.registrationToken },
      result.message
    );
  });

  /**
   * POST /api/v1/auth/register/complete
   * Complete registration with registrationToken and password.
   */
  static registerComplete = asyncHandler(async (req: Request, res: Response) => {
    const { registrationToken, password, confirmPassword, name, termsAccepted, termsVersion } = req.body;

    if (!registrationToken || typeof registrationToken !== 'string') {
      throw ApiError.badRequest('registrationToken is required');
    }

    if (!password || typeof password !== 'string') {
      throw ApiError.badRequest('Password is required');
    }

    if (!confirmPassword || typeof confirmPassword !== 'string') {
      throw ApiError.badRequest('Confirm Password is required');
    }

    const metadata = {
      userAgent: req.headers['user-agent'],
      ipAddress: req.ip || req.socket.remoteAddress,
    };

    const result = await AuthService.registerComplete(
      registrationToken.trim(),
      password,
      confirmPassword,
      name,
      metadata,
      termsAccepted,
      termsVersion
    );

    return ApiResponse.success(res, result, 'Account created successfully');
  });

  /**
   * POST /api/v1/auth/terms/accept
   * Record terms acceptance for authenticated user.
   */
  static acceptTerms = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user?.id) {
      throw ApiError.unauthorized('Authentication required to accept terms');
    }

    const { termsVersion } = req.body;
    const metadata = {
      userAgent: req.headers['user-agent'],
      ipAddress: req.ip || req.socket.remoteAddress,
    };

    const result = await AuthService.acceptTerms(
      req.user.id,
      termsVersion || '2026.1-draft',
      metadata
    );

    return ApiResponse.success(res, result, 'Terms & Conditions accepted successfully');
  });

  /**
   * GET /api/v1/auth/terms/status
   * Get terms acceptance status for authenticated user.
   */
  static getTermsStatus = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user?.id) {
      throw ApiError.unauthorized('Authentication required to view terms status');
    }

    const result = await AuthService.getTermsStatus(req.user.id);

    return ApiResponse.success(res, result, 'Terms status retrieved successfully');
  });
}

