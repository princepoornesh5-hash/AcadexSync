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
      throw ApiError.unauthorized('Authentication required to access ACADEXSYNC AI Assistant');
    }

    const validatedInput = chatRequestSchema.parse(req.body);
    const correlationId =
      (req.headers['x-correlation-id'] as string) ||
      `req_${Date.now().toString(36)}_${Math.random().toString(36).slice(2, 6)}`;
    res.setHeader('X-Correlation-ID', correlationId);

    const result = await AiService.generateChatResponse({
      message: validatedInput.message,
      history: validatedInput.history,
      user: req.user,
      collegeId: req.user.collegeId || req.collegeId,
      correlationId,
    });

    Logger.info('AI assistant query processed successfully', {
      userId: req.user.id,
      role: req.user.role,
      model: result.model,
      correlationId,
      hasProposal: Boolean(result.proposal),
      providerCallsCount: result.providerCallsCount,
    });

    return ApiResponse.success(res, result, 'AI response generated successfully');
  });

  /**
   * Process authenticated conversational query through Gemini AI with real-time SSE streaming
   */
  static chatStream = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) {
      throw ApiError.unauthorized('Authentication required to access ACADEXSYNC AI Assistant');
    }

    const validatedInput = chatRequestSchema.parse(req.body);
    const correlationId =
      (req.headers['x-correlation-id'] as string) ||
      `req_${Date.now().toString(36)}_${Math.random().toString(36).slice(2, 6)}`;

    // Set Server-Sent Events (SSE) headers
    res.setHeader('Content-Type', 'text/event-stream; charset=utf-8');
    res.setHeader('Cache-Control', 'no-cache, no-transform');
    res.setHeader('Connection', 'keep-alive');
    res.setHeader('X-Accel-Buffering', 'no');
    res.setHeader('X-Correlation-ID', correlationId);
    res.flushHeaders?.();

    const abortController = new AbortController();
    req.on('close', () => {
      abortController.abort();
    });

    const sendSseEvent = (event: string, data: any) => {
      if (res.writableEnded) return;
      res.write(`event: ${event}\ndata: ${JSON.stringify(data)}\n\n`);
      if (typeof (res as any).flush === 'function') {
        (res as any).flush();
      }
    };

    await AiService.streamChatResponse({
      message: validatedInput.message,
      history: validatedInput.history,
      user: req.user,
      collegeId: req.user.collegeId || req.collegeId,
      correlationId,
      abortSignal: abortController.signal,
      callbacks: {
        onStart: (data) => sendSseEvent('start', data),
        onDelta: (text) => sendSseEvent('delta', { text }),
        onProposal: (proposal) => sendSseEvent('proposal', proposal),
        onDone: (data) => {
          sendSseEvent('done', data);
          res.end();
        },
        onError: (err) => {
          sendSseEvent('error', err);
          res.end();
        },
      },
    });
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
