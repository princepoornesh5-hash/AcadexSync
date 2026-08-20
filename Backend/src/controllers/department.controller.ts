import { Request, Response } from 'express';
import { DepartmentService } from '../services/department.service';
import { ApiResponse } from '../utils/apiResponse';
import { asyncHandler } from '../utils/asyncHandler';
import { ApiError } from '../utils/apiError';
import {
  createDepartmentSchema,
  updateDepartmentSchema,
  updateDepartmentStatusSchema,
  departmentQuerySchema,
} from '../validations/department.validation';

export class DepartmentController {
  /**
   * POST /api/v1/departments
   * Create Department
   */
  static create = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) {
      throw ApiError.unauthorized('User not authenticated');
    }

    const validatedData = createDepartmentSchema.parse(req.body);
    const department = await DepartmentService.createDepartment(validatedData, req.user);

    return ApiResponse.created(res, department, 'Department created successfully');
  });

  /**
   * GET /api/v1/departments
   * List Departments
   */
  static list = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) {
      throw ApiError.unauthorized('User not authenticated');
    }

    const validatedQuery = departmentQuerySchema.parse(req.query);
    const result = await DepartmentService.listDepartments(req.user, validatedQuery);

    return ApiResponse.success(res, result);
  });

  /**
   * GET /api/v1/departments/:id
   * Get Single Department
   */
  static getById = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) {
      throw ApiError.unauthorized('User not authenticated');
    }

    const department = await DepartmentService.getDepartmentById(req.params.id, req.user);
    return ApiResponse.success(res, department);
  });

  /**
   * PUT /api/v1/departments/:id
   * Update Department
   */
  static update = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) {
      throw ApiError.unauthorized('User not authenticated');
    }

    const validatedData = updateDepartmentSchema.parse(req.body);
    const department = await DepartmentService.updateDepartment(
      req.params.id,
      validatedData,
      req.user
    );

    return ApiResponse.success(res, department, 'Department updated successfully');
  });

  /**
   * PATCH /api/v1/departments/:id/status
   * Update Department Status
   */
  static updateStatus = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) {
      throw ApiError.unauthorized('User not authenticated');
    }

    const { status } = updateDepartmentStatusSchema.parse(req.body);
    const department = await DepartmentService.updateDepartmentStatus(
      req.params.id,
      status,
      req.user
    );

    return ApiResponse.success(res, department, `Department status changed to ${status}`);
  });

  /**
   * GET /api/v1/departments/:id/summary
   * Summary Metrics for Department
   */
  static getSummary = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) {
      throw ApiError.unauthorized('User not authenticated');
    }

    const summary = await DepartmentService.getDepartmentSummary(req.params.id, req.user);
    return ApiResponse.success(res, summary);
  });
}
