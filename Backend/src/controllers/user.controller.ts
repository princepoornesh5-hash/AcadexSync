import { Request, Response } from 'express';
import { UserService } from '../services/user.service';
import { ApiResponse } from '../utils/apiResponse';
import { asyncHandler } from '../utils/asyncHandler';
import { AppRole } from '../constants/roles';

export class UserController {
  static create = asyncHandler(async (req: Request, res: Response) => {
    const userData = { ...req.body };
    if (!req.tenant?.isSuperAdmin && req.collegeId) {
      userData.collegeId = req.collegeId;
    }
    const user = await UserService.createUser(userData);
    return ApiResponse.created(res, user, 'User created successfully');
  });

  static getById = asyncHandler(async (req: Request, res: Response) => {
    const isSuperAdmin = req.tenant?.isSuperAdmin || false;
    const user = await UserService.getUserById(req.params.id, req.collegeId, isSuperAdmin);
    return ApiResponse.success(res, user);
  });

  static getByInstituteId = asyncHandler(async (req: Request, res: Response) => {
    const isSuperAdmin = req.tenant?.isSuperAdmin || false;
    const user = await UserService.getUserByInstituteId(
      req.params.instituteId,
      req.collegeId,
      isSuperAdmin
    );
    return ApiResponse.success(res, user);
  });

  static list = asyncHandler(async (req: Request, res: Response) => {
    const isSuperAdmin = req.tenant?.isSuperAdmin || false;
    const collegeId = isSuperAdmin ? (req.query.collegeId as string) : req.collegeId;
    const role = req.query.role as AppRole | undefined;
    const users = await UserService.listUsers(collegeId, role, isSuperAdmin);
    return ApiResponse.success(res, users);
  });

  static update = asyncHandler(async (req: Request, res: Response) => {
    const isSuperAdmin = req.tenant?.isSuperAdmin || false;
    const user = await UserService.updateUser(req.params.id, req.body, req.collegeId, isSuperAdmin);
    return ApiResponse.success(res, user, 'User updated successfully');
  });

  static requestProfileImageUploadUrl = asyncHandler(async (req: Request, res: Response) => {
    const targetUserId = req.params.id || req.user?.id;
    const result = await UserService.requestProfileImageUploadUrl(
      targetUserId as string,
      req.body,
      req.user as any
    );
    return ApiResponse.success(res, result, 'Profile image upload session initialized');
  });

  static completeProfileImageUpload = asyncHandler(async (req: Request, res: Response) => {
    const targetUserId = req.params.id || req.user?.id;
    const user = await UserService.completeProfileImageUpload(
      targetUserId as string,
      req.body,
      req.user as any
    );
    return ApiResponse.success(res, user, 'Profile image updated successfully');
  });

  static deletePermanently = asyncHandler(async (req: Request, res: Response) => {
    await UserService.deleteUserPermanently(req.params.id, req.user as any);
    return ApiResponse.success(res, null, 'User permanently deleted successfully');
  });
}

