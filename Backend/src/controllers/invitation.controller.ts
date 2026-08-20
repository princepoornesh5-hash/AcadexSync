import { Request, Response } from 'express';
import { InvitationService } from '../services/invitation.service';
import { ApiResponse } from '../utils/apiResponse';
import { asyncHandler } from '../utils/asyncHandler';
import { ApiError } from '../utils/apiError';
import { AppRole } from '../constants/roles';
import { InvitationStatus } from '../constants/status';

export class InvitationController {
  /**
   * POST /api/v1/auth/invitations
   * Create account in PENDING_ACTIVATION and generate single-use invitation.
   */
  static create = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) {
      throw ApiError.unauthorized('User not authenticated');
    }

    const {
      name,
      instituteId,
      email,
      phone,
      role,
      collegeId,
      departmentId,
      courseId,
      sectionId,
      semesterId,
    } = req.body;

    const result = await InvitationService.createInvitation(req.user, {
      name,
      instituteId,
      email,
      phone,
      role,
      collegeId,
      departmentId,
      courseId,
      sectionId,
      semesterId,
    });

    return ApiResponse.created(
      res,
      {
        invitation: result.invitation,
        activationCode: result.activationCode, // returned once to creator for delivery
        user: result.user.toJSON(),
      },
      'Invitation created successfully'
    );
  });

  /**
   * POST /api/v1/auth/activate
   * Public Account Activation Endpoint
   */
  static activate = asyncHandler(async (req: Request, res: Response) => {
    const { collegeCode, instituteId, activationCode, password } = req.body;

    const result = await InvitationService.activateAccount(
      collegeCode,
      instituteId,
      activationCode,
      password
    );

    return ApiResponse.success(res, { user: result.user }, result.message);
  });

  /**
   * GET /api/v1/auth/invitations
   * List invitations scoped to caller's tenant
   */
  static list = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) {
      throw ApiError.unauthorized('User not authenticated');
    }

    const status = req.query.status as InvitationStatus | undefined;
    const role = req.query.role as AppRole | undefined;
    const departmentId = req.query.departmentId as string | undefined;

    const invitations = await InvitationService.listInvitations(req.user, {
      status,
      role,
      departmentId,
    });

    return ApiResponse.success(res, invitations);
  });

  /**
   * GET /api/v1/auth/invitations/:id
   */
  static getById = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) {
      throw ApiError.unauthorized('User not authenticated');
    }

    const invitation = await InvitationService.getInvitationById(req.params.id, req.user);
    return ApiResponse.success(res, invitation);
  });

  /**
   * POST /api/v1/auth/invitations/:id/reissue
   */
  static reissue = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) {
      throw ApiError.unauthorized('User not authenticated');
    }

    const result = await InvitationService.reissueInvitation(req.params.id, req.user);

    return ApiResponse.success(
      res,
      {
        invitation: result.invitation,
        activationCode: result.activationCode,
      },
      'Invitation reissued successfully'
    );
  });

  /**
   * POST /api/v1/auth/invitations/:id/revoke
   */
  static revoke = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) {
      throw ApiError.unauthorized('User not authenticated');
    }

    const result = await InvitationService.revokeInvitation(req.params.id, req.user);
    return ApiResponse.success(res, null, result.message);
  });
}
