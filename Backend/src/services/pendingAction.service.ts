import crypto from 'crypto';
import { PendingAction, IPendingAction, PendingActionType } from '../models/pendingAction.model';
import { AssignmentService } from './assignment.service';
import { AcademicCalendarService } from './academicCalendar.service';
import { AssignmentStatus, AssignmentType } from '../constants/assignment.constants';
import { ApiError } from '../utils/apiError';
import { Logger } from '../utils/logger';
import { AuthenticatedUser } from '../types/auth.types';
import { AppRole } from '../constants/roles';
import { AuditLog } from '../models/auditLog.model';

export interface CreatePendingActionDTO {
  userId: string;
  userRole: string;
  collegeId: string;
  actionType: PendingActionType;
  draftPayload: Record<string, any>;
  summary: string;
  preview: Record<string, any>;
  expiryMinutes?: number;
}

export class PendingActionService {
  /**
   * Registers a server-verifiable pending action proposal with short expiry
   */
  static async createPendingAction(data: CreatePendingActionDTO): Promise<IPendingAction> {
    const actionId = crypto.randomUUID();
    const expiryMinutes = data.expiryMinutes || 10;
    const expiresAt = new Date(Date.now() + expiryMinutes * 60 * 1000);

    const pendingAction = await PendingAction.create({
      actionId,
      userId: data.userId,
      userRole: data.userRole,
      collegeId: data.collegeId,
      actionType: data.actionType,
      status: 'PENDING',
      draftPayload: data.draftPayload,
      summary: data.summary,
      preview: data.preview,
      expiresAt,
    });

    Logger.info('Pending AI action created', {
      actionId,
      actionType: data.actionType,
      userId: data.userId,
      collegeId: data.collegeId,
    });

    return pendingAction;
  }

  /**
   * Revalidates authorization, prevents replay, and executes the approved action
   */
  static async confirmPendingAction(
    actionId: string,
    user: AuthenticatedUser,
    idempotencyKey?: string
  ): Promise<{ action: IPendingAction; result: Record<string, any> }> {
    if (!actionId || typeof actionId !== 'string') {
      throw ApiError.badRequest('Valid actionId is required');
    }

    const action = await PendingAction.findOne({ actionId });
    if (!action) {
      throw ApiError.notFound('Pending action proposal not found');
    }

    // 1. Validate user and tenant ownership
    if (action.userId.toString() !== user.id.toString()) {
      throw ApiError.forbidden('You are not authorized to confirm this action proposal');
    }

    const userCollegeId = user.collegeId ? user.collegeId.toString() : '';
    if (user.role !== AppRole.SUPER_ADMIN && action.collegeId.toString() !== userCollegeId) {
      throw ApiError.forbidden('Action proposal belongs to a different institutional tenant');
    }

    // 2. Check Expiry
    if (new Date() > action.expiresAt || action.status === 'EXPIRED') {
      await PendingAction.updateOne({ _id: action._id }, { $set: { status: 'EXPIRED' } });
      throw ApiError.badRequest('Action proposal has expired. Please request a fresh preview.');
    }

    // 3. Prevent Replay or Duplicate Confirmations
    if (action.status === 'EXECUTED') {
      if (idempotencyKey && action.idempotencyKey === idempotencyKey && action.executionResult) {
        Logger.info('Idempotency replay: returning existing execution result', {
          actionId: action.actionId,
          idempotencyKey,
        });
        return { action, result: action.executionResult };
      }
      throw ApiError.conflict('This action has already been executed.');
    }

    if (action.status === 'CANCELLED') {
      throw ApiError.badRequest('This action proposal has been cancelled.');
    }

    // Atomically transition status to EXECUTED to guarantee single-execution idempotency
    const lockedAction = await PendingAction.findOneAndUpdate(
      { _id: action._id, status: 'PENDING' },
      {
        $set: {
          status: 'EXECUTED',
          executedAt: new Date(),
          idempotencyKey: idempotencyKey || null,
        },
      },
      { new: true }
    );

    if (!lockedAction) {
      throw ApiError.conflict('Action was already confirmed or is currently being executed.');
    }

    // 4. Authoritative Write Execution
    try {
      let executionResult: Record<string, any>;

      if (lockedAction.actionType === 'CREATE_ASSIGNMENT') {
        // Re-verify faculty/HOD authorization
        if (user.role === AppRole.STUDENT) {
          throw ApiError.forbidden('Students are not authorized to create assignments');
        }

        const draft = lockedAction.draftPayload;
        let assignmentType = AssignmentType.HOMEWORK;
        const rawType = (draft.assignmentType || '').toString().toLowerCase();
        if (rawType.includes('lab')) assignmentType = AssignmentType.LAB_WORK;
        else if (rawType.includes('quiz')) assignmentType = AssignmentType.QUIZ;
        else if (rawType.includes('proj')) assignmentType = AssignmentType.PROJECT;
        else if (rawType.includes('other')) assignmentType = AssignmentType.OTHER;

        let status = AssignmentStatus.PUBLISHED;
        const rawStatus = (draft.status || '').toString().toUpperCase();
        if (rawStatus === 'DRAFT') status = AssignmentStatus.DRAFT;
        else if (rawStatus === 'CLOSED') status = AssignmentStatus.CLOSED;
        else if (rawStatus === 'ARCHIVED') status = AssignmentStatus.ARCHIVED;

        const assignmentDoc = await AssignmentService.createAssignment(
          lockedAction.collegeId,
          {
            id: user.id,
            name: user.name,
            role: user.role,
            email: user.email,
            departmentId: user.departmentId,
          },
          {
            facultyAssignmentId: draft.facultyAssignmentId,
            title: draft.title,
            description: draft.description || '',
            assignmentType,
            dueDate: draft.dueDate,
            dueTime: draft.dueTime || '11:59 PM',
            maximumMarks: draft.maximumMarks || 100,
            status,
          }
        );

        executionResult = {
          assignmentId: assignmentDoc.id,
          title: assignmentDoc.title,
          status: assignmentDoc.status,
          dueDate: assignmentDoc.dueDateTime,
          subjectId: assignmentDoc.subjectId,
          sectionId: assignmentDoc.sectionId,
        };
      } else if (lockedAction.actionType === 'CREATE_CALENDAR_EVENT') {
        if (user.role === AppRole.STUDENT) {
          throw ApiError.forbidden('Students are not authorized to create calendar events');
        }

        const draft = lockedAction.draftPayload;
        const eventDoc = await AcademicCalendarService.createEvent(
          {
            title: draft.title,
            description: draft.description,
            eventType: draft.eventType,
            scope: draft.scope,
            startDate: draft.startDate,
            endDate: draft.endDate || draft.startDate,
            startTime: draft.startTime || null,
            endTime: draft.endTime || null,
            allDay: draft.allDay ?? (!draft.startTime && !draft.endTime),
            departmentId: draft.departmentId || null,
            sectionId: draft.sectionId || null,
            location: draft.location || null,
          },
          user
        );

        executionResult = {
          eventId: eventDoc.id,
          title: eventDoc.title,
          eventType: eventDoc.eventType,
          startDate: eventDoc.startDate,
          endDate: eventDoc.endDate,
          startTime: eventDoc.startTime,
          endTime: eventDoc.endTime,
          location: eventDoc.location,
        };
      } else {
        throw ApiError.badRequest(`Unsupported action type: ${lockedAction.actionType}`);
      }

      // Persist the actual execution result
      lockedAction.executionResult = executionResult;
      await lockedAction.save();

      Logger.info('Pending AI action successfully executed', {
        actionId: lockedAction.actionId,
        actionType: lockedAction.actionType,
        userId: user.id,
      });

      // Production audit logging
      try {
        await AuditLog.create({
          collegeId: lockedAction.collegeId,
          departmentId: user.departmentId || undefined,
          actorUserId: user.id,
          actorEmail: user.email,
          actorRole: user.role,
          action: `AI_${lockedAction.actionType}_CONFIRMED`,
          entityType: lockedAction.actionType === 'CREATE_ASSIGNMENT' ? 'Assignment' : 'CalendarEvent',
          entityId: (executionResult.assignmentId || executionResult.eventId || lockedAction.actionId).toString(),
          newValue: {
            actionId: lockedAction.actionId,
            summary: lockedAction.summary,
            executionResult,
          },
          metadata: {
            source: 'AI_ASSISTANT_CONFIRMATION',
            idempotencyKey: idempotencyKey || null,
          },
          timestamp: new Date(),
        });
      } catch (auditErr: any) {
        Logger.warn('AuditLog creation warning on action confirmation', { error: auditErr.message });
      }

      return { action: lockedAction, result: executionResult };
    } catch (error) {
      // Revert status to PENDING if write failed, allowing user to retry or fix parameters
      await PendingAction.updateOne(
        { _id: lockedAction._id },
        { $set: { status: 'PENDING', executedAt: null, idempotencyKey: null } }
      );

      // Log failure audit record
      try {
        await AuditLog.create({
          collegeId: lockedAction.collegeId,
          departmentId: user.departmentId || undefined,
          actorUserId: user.id,
          actorEmail: user.email,
          actorRole: user.role,
          action: `AI_${lockedAction.actionType}_FAILED`,
          entityType: lockedAction.actionType === 'CREATE_ASSIGNMENT' ? 'Assignment' : 'CalendarEvent',
          entityId: lockedAction.actionId,
          newValue: {
            actionId: lockedAction.actionId,
            error: (error as any)?.message || 'Write execution failed',
          },
          metadata: {
            source: 'AI_ASSISTANT_CONFIRMATION_FAILURE',
            idempotencyKey: idempotencyKey || null,
          },
          timestamp: new Date(),
        });
      } catch (auditErr: any) {
        Logger.warn('AuditLog creation warning on action failure', { error: auditErr.message });
      }

      throw error;
    }
  }

  /**
   * Safely retrieves the current status of an action proposal for network reconciliation
   */
  static async getActionStatus(
    actionId: string,
    user: AuthenticatedUser
  ): Promise<{
    actionId: string;
    actionType: PendingActionType;
    status: string;
    summary: string;
    preview: Record<string, any>;
    executionResult: Record<string, any> | null;
    expiresAt: Date;
    executedAt: Date | null;
  }> {
    if (!actionId || typeof actionId !== 'string') {
      throw ApiError.badRequest('Valid actionId is required');
    }

    const action = await PendingAction.findOne({ actionId });
    if (!action) {
      throw ApiError.notFound('Pending action proposal not found');
    }

    // Tenant and ownership isolation
    if (action.userId.toString() !== user.id.toString()) {
      throw ApiError.forbidden('You are not authorized to view this action proposal');
    }

    const userCollegeId = user.collegeId ? user.collegeId.toString() : '';
    if (user.role !== AppRole.SUPER_ADMIN && action.collegeId.toString() !== userCollegeId) {
      throw ApiError.forbidden('Action proposal belongs to a different institutional tenant');
    }

    // Reconcile expiry dynamically
    let status = action.status;
    if (status === 'PENDING' && new Date() > action.expiresAt) {
      status = 'EXPIRED';
      await PendingAction.updateOne({ _id: action._id }, { $set: { status: 'EXPIRED' } });
    }

    return {
      actionId: action.actionId,
      actionType: action.actionType,
      status,
      summary: action.summary,
      preview: action.preview,
      executionResult: action.executionResult || null,
      expiresAt: action.expiresAt,
      executedAt: action.executedAt || null,
    };
  }

  /**
   * Explicitly cancels an unconfirmed action proposal
   */
  static async cancelPendingAction(actionId: string, user: AuthenticatedUser): Promise<IPendingAction> {
    const action = await PendingAction.findOne({ actionId });
    if (!action) {
      throw ApiError.notFound('Pending action proposal not found');
    }

    if (action.userId.toString() !== user.id.toString()) {
      throw ApiError.forbidden('You are not authorized to cancel this action proposal');
    }

    if (action.status === 'EXECUTED') {
      throw ApiError.badRequest('Cannot cancel an action that has already been executed');
    }

    action.status = 'CANCELLED';
    await action.save();

    Logger.info('Pending AI action cancelled', {
      actionId,
      userId: user.id,
    });

    // Production audit logging on proposal cancellation
    try {
      await AuditLog.create({
        collegeId: action.collegeId,
        departmentId: user.departmentId || undefined,
        actorUserId: user.id,
        actorEmail: user.email,
        actorRole: user.role,
        action: `AI_${action.actionType}_CANCELLED`,
        entityType: 'PendingAction',
        entityId: action.actionId,
        newValue: {
          actionId: action.actionId,
          status: 'CANCELLED',
        },
        metadata: {
          source: 'AI_ASSISTANT_CANCELLATION',
        },
        timestamp: new Date(),
      });
    } catch (auditErr: any) {
      Logger.warn('AuditLog creation warning on action cancellation', { error: auditErr.message });
    }

    return action;
  }
}
