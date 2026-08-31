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
    const { identifier, password } = req.body;

    if (!identifier || !password) {
      throw ApiError.badRequest('Identifier (PIN Number, email, or phone) and password are required');
    }

    const metadata = {
      userAgent: req.headers['user-agent'],
      ipAddress: req.ip || req.socket.remoteAddress,
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

    return ApiResponse.success(res, {
      id: user.id,
      instituteId: user.instituteId,
      name: user.name,
      email: user.email || null,
      phone: user.phone || null,
      role: user.role,
      accountStatus: user.accountStatus,
      activationStatus: user.activationStatus,
      collegeId: user.collegeId?.toString() || null,
      departmentId: user.departmentId?.toString() || null,
      courseId: user.courseId?.toString() || null,
      sectionId: user.sectionId?.toString() || null,
      semesterId: user.semesterId?.toString() || null,
      profilePictureUrl: user.profilePictureUrl || null,
      lastLoginAt: user.lastLoginAt || null,
      createdAt: user.createdAt,
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
}
