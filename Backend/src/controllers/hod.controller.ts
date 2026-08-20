import { Request, Response } from 'express';
import { HodService } from '../services/hod.service';
import { ApiResponse } from '../utils/apiResponse';
import { asyncHandler } from '../utils/asyncHandler';
import { ApiError } from '../utils/apiError';
import {
  provisionHodSchema,
  updateHodProfileSchema,
  transferHodDepartmentSchema,
  hodQuerySchema,
} from '../validations/hod.validation';

export class HodController {
  /**
   * POST /api/v1/academics/hods
   * Provision HOD Account & Generate Invitation
   */
  static provision = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) {
      throw ApiError.unauthorized('User not authenticated');
    }

    const validatedData = provisionHodSchema.parse(req.body);
    const result = await HodService.provisionHod(validatedData, req.user);

    return ApiResponse.created(
      res,
      {
        user: result.user,
        invitation: result.invitation,
        activationCode: result.activationCode,
      },
      'HOD account provisioned successfully. Activation invitation created.'
    );
  });

  /**
   * GET /api/v1/academics/hods
   * List HODs (Admin only)
   */
  static list = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) {
      throw ApiError.unauthorized('User not authenticated');
    }

    const validatedQuery = hodQuerySchema.parse(req.query);
    const result = await HodService.listHods(req.user, validatedQuery);

    return ApiResponse.success(res, result);
  });

  /**
   * GET /api/v1/academics/hods/:id
   * Get HOD Details
   */
  static getById = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) {
      throw ApiError.unauthorized('User not authenticated');
    }

    const hod = await HodService.getHodById(req.params.id, req.user);
    return ApiResponse.success(res, hod);
  });

  /**
   * PUT /api/v1/academics/hods/:id
   * Update HOD Profile
   */
  static updateProfile = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) {
      throw ApiError.unauthorized('User not authenticated');
    }

    const validatedData = updateHodProfileSchema.parse(req.body);
    const hod = await HodService.updateHodProfile(req.params.id, validatedData, req.user);

    return ApiResponse.success(res, hod, 'HOD profile updated successfully');
  });

  /**
   * PATCH /api/v1/academics/hods/:id/department
   * Safe Transfer of HOD to another Department
   */
  static transferDepartment = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) {
      throw ApiError.unauthorized('User not authenticated');
    }

    const { departmentId } = transferHodDepartmentSchema.parse(req.body);
    const hod = await HodService.transferHodDepartment(req.params.id, departmentId, req.user);

    return ApiResponse.success(res, hod, 'HOD department transferred successfully');
  });

  /**
   * GET /api/v1/academics/hods/:id/summary
   * Get HOD Summary Metrics
   */
  static getSummary = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) {
      throw ApiError.unauthorized('User not authenticated');
    }

    const summary = await HodService.getHodSummary(req.params.id, req.user);
    return ApiResponse.success(res, summary);
  });

  /**
   * GET /api/v1/departments/:departmentId/hod
   * Lookup HOD for a Department
   */
  static getByDepartmentId = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) {
      throw ApiError.unauthorized('User not authenticated');
    }

    const hod = await HodService.getDepartmentHod(req.params.departmentId, req.user);
    if (!hod) {
      return ApiResponse.success(res, null, 'No HOD currently assigned to this department');
    }
    return ApiResponse.success(res, hod);
  });
}
