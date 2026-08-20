import { Request, Response } from 'express';
import { AuditService } from '../services/audit.service';
import { ApiResponse } from '../utils/apiResponse';
import { asyncHandler } from '../utils/asyncHandler';

export class AuditController {
  static list = asyncHandler(async (req: Request, res: Response) => {
    const collegeId = req.tenant?.isSuperAdmin ? (req.query.collegeId as string) : req.collegeId;
    const entityType = req.query.entityType as string | undefined;
    const actorUserId = req.query.actorUserId as string | undefined;
    const limit = req.query.limit ? parseInt(req.query.limit as string, 10) : 50;

    const logs = await AuditService.listAuditLogs(collegeId, entityType, actorUserId, limit);
    return ApiResponse.success(res, logs);
  });
}
