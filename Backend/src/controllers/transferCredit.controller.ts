import { Request, Response } from 'express';
import { TransferCreditService } from '../services/transferCredit.service';
import {
  createTransferCreditSchema,
  updateTransferCreditStatusSchema,
} from '../validations/transferCredit.validation';
import { ApiResponse } from '../utils/apiResponse';
import { ApiError } from '../utils/apiError';

export class TransferCreditController {
  static async record(req: Request, res: Response) {
    if (!req.user) throw ApiError.unauthorized('User not authenticated');
    const validated = createTransferCreditSchema.parse(req.body);
    const result = await TransferCreditService.recordTransferCredit(
      req.user,
      validated,
      req.query.collegeId as string | undefined
    );
    return ApiResponse.created(res, result, 'Transfer credit recorded successfully');
  }

  static async list(req: Request, res: Response) {
    if (!req.user) throw ApiError.unauthorized('User not authenticated');
    const results = await TransferCreditService.list(req.user, {
      collegeId: req.query.collegeId as string | undefined,
      studentId: req.query.studentId as string | undefined,
      verificationStatus: req.query.status as string | undefined,
    });
    return ApiResponse.success(res, results, 'Transfer credits retrieved successfully');
  }

  static async getById(req: Request, res: Response) {
    if (!req.user) throw ApiError.unauthorized('User not authenticated');
    const result = await TransferCreditService.getById(req.params.id, req.user);
    return ApiResponse.success(res, result, 'Transfer credit retrieved successfully');
  }

  static async getByStudentId(req: Request, res: Response) {
    if (!req.user) throw ApiError.unauthorized('User not authenticated');
    const results = await TransferCreditService.getByStudent(req.params.studentId, req.user);
    return ApiResponse.success(res, results, 'Student transfer credits retrieved successfully');
  }

  static async updateStatus(req: Request, res: Response) {
    if (!req.user) throw ApiError.unauthorized('User not authenticated');
    const validated = updateTransferCreditStatusSchema.parse(req.body);
    const result = await TransferCreditService.updateStatus(req.params.id, req.user, validated);
    return ApiResponse.success(res, result, 'Transfer credit status updated successfully');
  }
}
