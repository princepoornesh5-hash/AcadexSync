import { Request, Response } from 'express';
import { TeacherSubstitutionService } from '../services/teacherSubstitution.service';
import { ApiResponse } from '../utils/apiResponse';
import { asyncHandler } from '../utils/asyncHandler';
import { ApiError } from '../utils/apiError';
import {
  createTeacherSubstitutionSchema,
  queryTeacherSubstitutionSchema,
} from '../validations/teacherSubstitution.validation';

export class TeacherSubstitutionController {
  static create = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) throw ApiError.unauthorized('User not authenticated');
    const validated = createTeacherSubstitutionSchema.parse({ body: req.body });
    const substitution = await TeacherSubstitutionService.createSubstitution(validated.body, req.user);
    return ApiResponse.created(res, substitution, 'Teacher substitution created successfully');
  });

  static list = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) throw ApiError.unauthorized('User not authenticated');
    const validated = queryTeacherSubstitutionSchema.parse({ query: req.query });
    const result = await TeacherSubstitutionService.listSubstitutions(validated.query as any, req.user);
    return ApiResponse.success(res, result);
  });

  static getById = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) throw ApiError.unauthorized('User not authenticated');
    const substitution = await TeacherSubstitutionService.getSubstitutionById(req.params.id, req.user);
    return ApiResponse.success(res, substitution);
  });

  static delete = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) throw ApiError.unauthorized('User not authenticated');
    await TeacherSubstitutionService.deleteSubstitution(req.params.id, req.user);
    return ApiResponse.noContent(res);
  });
}
