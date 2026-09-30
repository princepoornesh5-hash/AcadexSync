import { Request, Response } from 'express';
import { ProfileService } from '../services/profile.service';
import { ApiResponse } from '../utils/apiResponse';
import { asyncHandler } from '../utils/asyncHandler';
import { AuthenticatedUser } from '../types/auth.types';

export class ProfileController {
  static getMyProfile = asyncHandler(async (req: Request, res: Response) => {
    const requester = req.user as AuthenticatedUser;
    const profile = await ProfileService.getComposedProfile(requester.id, requester);
    return ApiResponse.success(res, profile, 'Profile retrieved successfully');
  });

  static updateMyProfile = asyncHandler(async (req: Request, res: Response) => {
    const requester = req.user as AuthenticatedUser;
    const updated = await ProfileService.updateProfile(requester.id, req.body, requester);
    return ApiResponse.success(res, updated, 'Profile updated successfully');
  });

  static requestMyAvatarUpload = asyncHandler(async (req: Request, res: Response) => {
    const requester = req.user as AuthenticatedUser;
    const result = await ProfileService.requestAvatarUploadAuth(requester.id, req.body, requester);
    return ApiResponse.success(res, result, 'Avatar upload session initialized');
  });

  static completeMyAvatarUpload = asyncHandler(async (req: Request, res: Response) => {
    const requester = req.user as AuthenticatedUser;
    const result = await ProfileService.completeAvatarUpload(requester.id, req.body, requester);
    return ApiResponse.success(res, result, 'Avatar updated successfully');
  });

  static getProfileById = asyncHandler(async (req: Request, res: Response) => {
    const requester = req.user as AuthenticatedUser;
    const profile = await ProfileService.getComposedProfile(req.params.id, requester);
    return ApiResponse.success(res, profile, 'Profile retrieved successfully');
  });

  static updateProfileById = asyncHandler(async (req: Request, res: Response) => {
    const requester = req.user as AuthenticatedUser;
    const updated = await ProfileService.updateProfile(req.params.id, req.body, requester);
    return ApiResponse.success(res, updated, 'Profile updated successfully');
  });

  static requestAvatarUploadById = asyncHandler(async (req: Request, res: Response) => {
    const requester = req.user as AuthenticatedUser;
    const result = await ProfileService.requestAvatarUploadAuth(req.params.id, req.body, requester);
    return ApiResponse.success(res, result, 'Avatar upload session initialized');
  });

  static completeAvatarUploadById = asyncHandler(async (req: Request, res: Response) => {
    const requester = req.user as AuthenticatedUser;
    const result = await ProfileService.completeAvatarUpload(req.params.id, req.body, requester);
    return ApiResponse.success(res, result, 'Avatar updated successfully');
  });

  static getDirectory = asyncHandler(async (req: Request, res: Response) => {
    const requester = req.user as AuthenticatedUser;
    const directory = await ProfileService.getDirectory(req.query as any, requester);
    return ApiResponse.success(res, directory, 'Directory retrieved successfully');
  });
}
