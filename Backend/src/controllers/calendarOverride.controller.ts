import { Request, Response } from 'express';
import { CalendarOverrideService } from '../services/calendarOverride.service';
import { ApiResponse } from '../utils/apiResponse';
import { asyncHandler } from '../utils/asyncHandler';
import { ApiError } from '../utils/apiError';
import {
  createCalendarOverrideSchema,
  calendarOverrideQuerySchema,
} from '../validations/calendarOverride.validation';

export class CalendarOverrideController {
  static create = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) throw ApiError.unauthorized('User not authenticated');
    const validatedData = createCalendarOverrideSchema.parse(req.body);
    const override = await CalendarOverrideService.createOverride(validatedData as any, req.user);
    return ApiResponse.created(res, override, 'Calendar override created successfully');
  });

  static list = asyncHandler(async (req: Request, res: Response) => {
    const query = calendarOverrideQuerySchema.parse(req.query);
    const result = await CalendarOverrideService.listOverrides(query, req.user);
    return ApiResponse.success(res, result);
  });

  static getById = asyncHandler(async (req: Request, res: Response) => {
    const override = await CalendarOverrideService.getOverrideById(req.params.id, req.user);
    return ApiResponse.success(res, override);
  });

  static delete = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) throw ApiError.unauthorized('User not authenticated');
    await CalendarOverrideService.deleteOverride(req.params.id, req.user);
    return ApiResponse.noContent(res);
  });
}
