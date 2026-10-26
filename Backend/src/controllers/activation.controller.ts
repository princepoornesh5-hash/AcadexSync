import { Request, Response } from 'express';
import { ActivationService } from '../services/activation.service';
import { ApiResponse } from '../utils/apiResponse';
import { asyncHandler } from '../utils/asyncHandler';
import { ApiError } from '../utils/apiError';

export class ActivationController {
  /**
   * POST /api/v1/auth/activate/validate-code
   * Validates single-use activation code and returns identity confirmation details.
   */
  static validateCode = asyncHandler(async (req: Request, res: Response) => {
    const { activationCode } = req.body;

    if (!activationCode || typeof activationCode !== 'string' || activationCode.trim() === '') {
      throw ApiError.badRequest('activationCode must be a non-empty string');
    }

    const result = await ActivationService.validateActivationCode(activationCode.trim());

    return ApiResponse.success(res, result, 'Activation code verified successfully');
  });

  /**
   * POST /api/v1/auth/activate/send-otp
   * Dispatches OTP to selected registered contact method (email or phone).
   */
  static sendOtp = asyncHandler(async (req: Request, res: Response) => {
    const { activationFlowId, contactMethod } = req.body;

    if (!activationFlowId || typeof activationFlowId !== 'string') {
      throw ApiError.badRequest('activationFlowId must be a valid token string');
    }

    if (!contactMethod || (contactMethod !== 'email' && contactMethod !== 'phone')) {
      throw ApiError.badRequest('contactMethod must be either "email" or "phone"');
    }

    const result = await ActivationService.sendActivationOtp(activationFlowId, contactMethod);

    return ApiResponse.success(res, result, result.message);
  });

  /**
   * POST /api/v1/auth/activate/verify-otp
   * Verifies OTP and issues short-lived activation authorization token.
   */
  static verifyOtp = asyncHandler(async (req: Request, res: Response) => {
    const { activationFlowId, contactMethod, otp } = req.body;

    if (!activationFlowId || typeof activationFlowId !== 'string') {
      throw ApiError.badRequest('activationFlowId must be a valid token string');
    }

    if (!contactMethod || (contactMethod !== 'email' && contactMethod !== 'phone')) {
      throw ApiError.badRequest('contactMethod must be either "email" or "phone"');
    }

    if (otp === undefined || otp === null) {
      throw ApiError.badRequest('otp is required');
    }

    const rawOtp = typeof otp === 'number' ? String(otp) : otp;
    if (typeof rawOtp !== 'string' || rawOtp.trim() === '') {
      throw ApiError.badRequest('otp must be a valid verification code string');
    }

    const result = await ActivationService.verifyActivationOtp(
      activationFlowId,
      contactMethod,
      rawOtp.trim()
    );

    return ApiResponse.success(res, result, result.message);
  });

  /**
   * POST /api/v1/auth/activate/complete
   * Sets password (for new user) and completes account/workspace activation atomically.
   */
  static complete = asyncHandler(async (req: Request, res: Response) => {
    const { activationToken, password, confirmPassword } = req.body;

    if (!activationToken || typeof activationToken !== 'string') {
      throw ApiError.badRequest('activationToken must be a valid token string');
    }

    if (password !== undefined && typeof password !== 'string') {
      throw ApiError.badRequest('password must be a string');
    }

    if (confirmPassword !== undefined && typeof confirmPassword !== 'string') {
      throw ApiError.badRequest('confirmPassword must be a string');
    }

    const result = await ActivationService.completeActivation(
      activationToken,
      password,
      confirmPassword
    );

    return ApiResponse.success(res, result.data, result.message);
  });
}
