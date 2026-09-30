import { Request, Response } from 'express';
import { RequestService } from '../services/request.service';
import { ApiResponse } from '../utils/apiResponse';
import { asyncHandler } from '../utils/asyncHandler';

export class RequestController {
  static createRequest = asyncHandler(async (req: Request, res: Response): Promise<void> => {
    const created = await RequestService.createRequest(req.body, req.user!);
    ApiResponse.created(res, created, 'Request submitted successfully.');
  });

  static listMyRequests = asyncHandler(async (req: Request, res: Response): Promise<void> => {
    const result = await RequestService.listMyRequests(req.query as any, req.user!);
    ApiResponse.success(res, result, 'Requests retrieved successfully.');
  });

  static listIncomingRequests = asyncHandler(async (req: Request, res: Response): Promise<void> => {
    const result = await RequestService.listIncomingRequests(req.query as any, req.user!);
    ApiResponse.success(res, result, 'Incoming requests retrieved successfully.');
  });

  static getSummaryCounts = asyncHandler(async (req: Request, res: Response): Promise<void> => {
    const counts = await RequestService.getSummaryCounts(req.user!);
    ApiResponse.success(res, counts, 'Request counts retrieved successfully.');
  });

  static getById = asyncHandler(async (req: Request, res: Response): Promise<void> => {
    const request = await RequestService.getRequestById(req.params.id, req.user!);
    ApiResponse.success(res, request, 'Request details retrieved successfully.');
  });

  static respondToRequest = asyncHandler(async (req: Request, res: Response): Promise<void> => {
    const updated = await RequestService.respondToRequest(req.params.id, req.body, req.user!);
    ApiResponse.success(res, updated, 'Response submitted successfully.');
  });

  static updateStatus = asyncHandler(async (req: Request, res: Response): Promise<void> => {
    const updated = await RequestService.updateStatus(
      req.params.id,
      req.body.status,
      req.body.note,
      req.user!
    );
    ApiResponse.success(res, updated, 'Request status updated successfully.');
  });

  static submitRequest = asyncHandler(async (req: Request, res: Response): Promise<void> => {
    const updated = await RequestService.submitRequest(req.params.id, req.user!);
    ApiResponse.success(res, updated, 'Request submitted successfully.');
  });

  static cancelRequest = asyncHandler(async (req: Request, res: Response): Promise<void> => {
    const updated = await RequestService.cancelRequest(
      req.params.id,
      req.body?.reason,
      req.user!
    );
    ApiResponse.success(res, updated, 'Request cancelled successfully.');
  });

  static startReview = asyncHandler(async (req: Request, res: Response): Promise<void> => {
    const updated = await RequestService.startReview(req.params.id, req.user!);
    ApiResponse.success(res, updated, 'Request marked under review.');
  });
}
