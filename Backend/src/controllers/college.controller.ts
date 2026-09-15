import { Request, Response } from 'express';
import { CollegeService } from '../services/college.service';
import { InvitationService } from '../services/invitation.service';
import { ApiResponse } from '../utils/apiResponse';
import { asyncHandler } from '../utils/asyncHandler';
import { ApiError } from '../utils/apiError';
import { AppRole } from '../constants/roles';
import {
  createCollegeSchema,
  updateCollegeSchema,
  updateCollegeStatusSchema,
  collegeQuerySchema,
} from '../validations/college.validation';

export class CollegeController {
  /**
   * POST /api/v1/colleges
   * Super Admin College Creation
   */
  static create = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user || req.user.role !== AppRole.SUPER_ADMIN) {
      throw ApiError.forbidden('Only Super Admin can create colleges');
    }

    const validatedData = createCollegeSchema.parse(req.body);
    const college = await CollegeService.createCollege(validatedData, req.user.id);

    return ApiResponse.created(res, college, 'College created successfully');
  });

  /**
   * GET /api/v1/colleges
   * List Colleges (Paginated + Search + Sort for SuperAdmin, Single for CollegeAdmin)
   */
  static list = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) {
      throw ApiError.unauthorized('User not authenticated');
    }

    const validatedQuery = collegeQuerySchema.parse(req.query);
    const result = await CollegeService.listColleges(req.user, validatedQuery);

    return ApiResponse.success(res, result);
  });

  /**
   * GET /api/v1/colleges/:id
   * Get College Profile
   */
  static getById = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) {
      throw ApiError.unauthorized('User not authenticated');
    }

    const college = await CollegeService.getCollegeById(req.params.id, req.user);
    return ApiResponse.success(res, college);
  });

  /**
   * PUT /api/v1/colleges/:id
   * Super Admin Global College Update
   */
  static update = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user || req.user.role !== AppRole.SUPER_ADMIN) {
      throw ApiError.forbidden('Only Super Admin can update college details');
    }

    const validatedData = updateCollegeSchema.parse(req.body);
    const college = await CollegeService.updateCollege(req.params.id, validatedData, req.user.id);

    return ApiResponse.success(res, college, 'College updated successfully');
  });

  /**
   * PATCH /api/v1/colleges/:id/status
   * Super Admin Status Change (Deactivate / Reactivate)
   */
  static updateStatus = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user || req.user.role !== AppRole.SUPER_ADMIN) {
      throw ApiError.forbidden('Only Super Admin can change college status');
    }

    const { status } = updateCollegeStatusSchema.parse(req.body);
    const college = await CollegeService.updateCollegeStatus(req.params.id, status, req.user.id);

    return ApiResponse.success(res, college, `College status changed to ${status}`);
  });

  /**
   * GET /api/v1/colleges/:id/admins
   * List College Administrators
   */
  static getAdmins = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) {
      throw ApiError.unauthorized('User not authenticated');
    }

    const admins = await CollegeService.getCollegeAdmins(req.params.id, req.user);
    return ApiResponse.success(res, admins);
  });

  /**
   * GET /api/v1/colleges/:id/summary
   * Summary Analytics for College
   */
  static getSummary = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) {
      throw ApiError.unauthorized('User not authenticated');
    }

    const summary = await CollegeService.getCollegeSummary(req.params.id, req.user);
    return ApiResponse.success(res, summary);
  });

  /**
   * POST /api/v1/colleges/:id/admins
   * Super Admin Provision College Admin Invitation for College
   */
  static provisionAdmin = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user || req.user.role !== AppRole.SUPER_ADMIN) {
      throw ApiError.forbidden('Only Super Admin can provision College Admins');
    }

    const collegeId = req.params.id;
    const { name, instituteId, email, phone } = req.body;

    const result = await InvitationService.createInvitation(req.user, {
      name,
      instituteId,
      email,
      phone,
      role: AppRole.COLLEGE_ADMIN,
      collegeId,
    });

    return ApiResponse.created(
      res,
      {
        invitation: result.invitation,
        activationCode: result.activationCode,
        user: result.user.toJSON(),
        collegeCode: result.collegeCode,
        collegeName: result.collegeName,
      },
      'College Admin invitation provisioned successfully'
    );
  });

  /**
   * DELETE /api/v1/colleges/:id
   * Super Admin Permanent College Deletion
   */
  static deletePermanently = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user || req.user.role !== AppRole.SUPER_ADMIN) {
      throw ApiError.forbidden('Only Super Admin can permanently delete colleges');
    }

    await CollegeService.deleteCollegePermanently(req.params.id, req.user.id);
    return ApiResponse.success(res, null, 'College permanently deleted successfully');
  });
}

