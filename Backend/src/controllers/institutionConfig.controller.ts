import { Request, Response } from 'express';
import { institutionConfigService } from '../services/institutionConfig.service';
import { ApiResponse } from '../utils/apiResponse';
import { ApiError } from '../utils/apiError';
import { AppRole } from '../constants/roles';
import { asyncHandler } from '../utils/asyncHandler';

export class InstitutionConfigController {
  static getConfig = asyncHandler(async (req: Request, res: Response) => {
    const collegeId =
      req.user?.role === AppRole.SUPER_ADMIN
        ? (req.query.collegeId as string) || (req as any).collegeId || req.user?.collegeId
        : (req as any).collegeId || req.user?.collegeId;

    if (!collegeId) {
      throw ApiError.badRequest('College ID is required to fetch configuration');
    }

    const config = await institutionConfigService.getEffectiveConfiguration(
      collegeId.toString()
    );

    return ApiResponse.success(res, config, 'Institution configuration retrieved successfully');
  });

  static updateConfig = asyncHandler(async (req: Request, res: Response) => {
    const collegeId =
      req.user?.role === AppRole.SUPER_ADMIN
        ? (req.query.collegeId as string) || (req as any).collegeId || req.user?.collegeId
        : (req as any).collegeId || req.user?.collegeId;

    if (!collegeId) {
      throw ApiError.badRequest('College ID is required to update configuration');
    }

    const userId = req.user?.id || (req.user as any)?._id;
    const updated = await institutionConfigService.updateConfiguration(
      collegeId.toString(),
      userId.toString(),
      req.body
    );

    return ApiResponse.success(res, updated, 'Institution configuration updated successfully');
  });

  static getPresets = asyncHandler(async (_req: Request, res: Response) => {
    const presets = institutionConfigService.getPresets();
    return ApiResponse.success(res, presets, 'Institution presets retrieved successfully');
  });
}
