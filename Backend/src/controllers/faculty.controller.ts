import { Request, Response } from 'express';
import { FacultyService } from '../services/faculty.service';
import { ApiResponse } from '../utils/apiResponse';
import { asyncHandler } from '../utils/asyncHandler';
import { ApiError } from '../utils/apiError';
import {
  provisionFacultySchema,
  updateFacultyProfileSchema,
  transferFacultyDepartmentSchema,
  facultyQuerySchema,
} from '../validations/faculty.validation';

export class FacultyController {
  /**
   * POST /api/v1/academics/faculty
   * Provision Faculty Account & Profile + Generate Invitation
   */
  static provision = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) {
      throw ApiError.unauthorized('User not authenticated');
    }

    const validatedData = provisionFacultySchema.parse(req.body);
    const result = await FacultyService.provisionFaculty(validatedData, req.user);

    return ApiResponse.created(
      res,
      {
        user: result.user,
        faculty: result.faculty,
        invitation: result.invitation,
        activationCode: result.activationCode,
      },
      'Faculty account provisioned successfully. Activation invitation created.'
    );
  });

  /**
   * GET /api/v1/academics/faculty
   * List Faculty (Admin, College Admin, HOD)
   */
  static list = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) {
      throw ApiError.unauthorized('User not authenticated');
    }

    const validatedQuery = facultyQuerySchema.parse(req.query);
    const result = await FacultyService.listFaculty(req.user, validatedQuery);

    return ApiResponse.success(res, result);
  });

  /**
   * GET /api/v1/academics/faculty/:id
   * Get Faculty Details
   */
  static getById = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) {
      throw ApiError.unauthorized('User not authenticated');
    }

    const result = await FacultyService.getFacultyById(req.params.id, req.user);
    return ApiResponse.success(res, result);
  });

  /**
   * PUT /api/v1/academics/faculty/:id
   * Update Faculty Profile
   */
  static updateProfile = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) {
      throw ApiError.unauthorized('User not authenticated');
    }

    const validatedData = updateFacultyProfileSchema.parse(req.body);
    const result = await FacultyService.updateFacultyProfile(req.params.id, validatedData, req.user);

    return ApiResponse.success(res, result, 'Faculty profile updated successfully');
  });

  /**
   * PATCH /api/v1/academics/faculty/:id/department
   * Safe Administrative Department Transfer
   */
  static transferDepartment = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) {
      throw ApiError.unauthorized('User not authenticated');
    }

    const { departmentId } = transferFacultyDepartmentSchema.parse(req.body);
    const result = await FacultyService.transferFacultyDepartment(req.params.id, departmentId, req.user);

    return ApiResponse.success(res, result, 'Faculty department transferred successfully');
  });

  /**
   * GET /api/v1/academics/faculty/:id/summary
   * Get Faculty Summary Metrics
   */
  static getSummary = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) {
      throw ApiError.unauthorized('User not authenticated');
    }

    const summary = await FacultyService.getFacultySummary(req.params.id, req.user);
    return ApiResponse.success(res, summary);
  });

  /**
   * GET /api/v1/departments/:departmentId/faculty
   * Lookup Faculty in a Department
   */
  static getByDepartmentId = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) {
      throw ApiError.unauthorized('User not authenticated');
    }

    const facultyList = await FacultyService.getDepartmentFaculty(req.params.departmentId, req.user);
    return ApiResponse.success(res, facultyList);
  });
}
