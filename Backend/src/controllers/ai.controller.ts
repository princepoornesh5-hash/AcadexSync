import { Request, Response } from 'express';
import { asyncHandler } from '../utils/asyncHandler';
import { ApiError } from '../utils/apiError';
import { ApiResponse } from '../utils/apiResponse';
import { Logger } from '../utils/logger';
import { AiService } from '../services/ai.service';
import { PendingActionService } from '../services/pendingAction.service';
import {
  chatRequestSchema,
  confirmActionSchema,
  cancelActionSchema,
} from '../validations/ai.validation';

export class AiController {
  /**
   * Process authenticated conversational query through Gemini AI with tool calling
   */
  static chat = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) {
      throw ApiError.unauthorized('Authentication required to access ACADEX AI Assistant');
    }

    const validatedInput = chatRequestSchema.parse(req.body);

    const result = await AiService.generateChatResponse({
      message: validatedInput.message,
      history: validatedInput.history,
      user: req.user,
      collegeId: req.user.collegeId || req.collegeId,
    });

    Logger.info('AI assistant query processed successfully', {
      userId: req.user.id,
      role: req.user.role,
      model: result.model,
      hasProposal: Boolean(result.proposal),
    });

    return ApiResponse.success(res, result, 'AI response generated successfully');
  });

  /**
   * Confirms and persists an approved pending action proposal
   */
  static confirmAction = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) {
      throw ApiError.unauthorized('Authentication required to confirm AI actions');
    }

    const validatedInput = confirmActionSchema.parse(req.body);

    const { action, result } = await PendingActionService.confirmPendingAction(
      validatedInput.actionId,
      req.user,
      validatedInput.idempotencyKey
    );

    Logger.info('AI action confirmed and executed', {
      actionId: action.actionId,
      actionType: action.actionType,
      userId: req.user.id,
    });

    return ApiResponse.success(
      res,
      {
        actionId: action.actionId,
        actionType: action.actionType,
        status: action.status,
        result,
      },
      'Action confirmed and executed successfully'
    );
  });

  /**
   * Cancels an unconfirmed pending action proposal
   */
  static cancelAction = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) {
      throw ApiError.unauthorized('Authentication required to cancel AI actions');
    }

    const validatedInput = cancelActionSchema.parse(req.body);

    const action = await PendingActionService.cancelPendingAction(
      validatedInput.actionId,
      req.user
    );

    Logger.info('AI action proposal cancelled', {
      actionId: action.actionId,
      userId: req.user.id,
    });

    return ApiResponse.success(
      res,
      {
        actionId: action.actionId,
        status: action.status,
      },
      'Action proposal cancelled successfully'
    );
  });

  /**
   * Safely retrieves status of a pending action for client reconciliation
   */
  static getActionStatus = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) {
      throw ApiError.unauthorized('Authentication required to inspect AI action status');
    }

    const { actionId } = req.params;
    if (!actionId || typeof actionId !== 'string') {
      throw ApiError.badRequest('actionId parameter is required');
    }

    const statusResult = await PendingActionService.getActionStatus(actionId, req.user);

    return ApiResponse.success(res, statusResult, 'Action status retrieved successfully');
  });
}
