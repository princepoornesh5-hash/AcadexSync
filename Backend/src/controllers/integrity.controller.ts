import { Request, Response } from 'express';
import { IntegrityService } from '../services/integrity.service';
import { ApiResponse } from '../utils/apiResponse';
import { asyncHandler } from '../utils/asyncHandler';
import { ApiError } from '../utils/apiError';

export class IntegrityController {
  /**
   * GET /api/v1/academics/integrity/audit
   * Forensic Academic Relationship & Orphan Audit
   */
  static audit = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) {
      throw ApiError.unauthorized('User not authenticated');
    }

    const collegeId = (req.query.collegeId as string) || req.user.collegeId;
    const result = await IntegrityService.runForensicAudit(req.user, collegeId);

    return ApiResponse.success(res, result, 'Forensic integrity audit completed');
  });

  /**
   * POST /api/v1/academics/integrity/repair
   * Safely repair detected orphans without destroying historical data
   */
  static repair = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) {
      throw ApiError.unauthorized('User not authenticated');
    }

    const collegeId = (req.query.collegeId as string) || req.user.collegeId;
    const result = await IntegrityService.repairOrphans(req.user, collegeId);

    return ApiResponse.success(res, result, 'Orphaned relationships repaired safely');
  });
}
