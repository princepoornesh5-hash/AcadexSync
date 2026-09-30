import { Request, Response } from 'express';
import { PracticalService } from '../services/practical.service';
import { ApiError } from '../utils/apiError';
import { ApiResponse } from '../utils/apiResponse';
import { asyncHandler } from '../utils/asyncHandler';

export class PracticalController {
  static createDefinition = asyncHandler(async (req: Request, res: Response) => {
    const collegeId = (req as any).collegeId || (req as any).user?.collegeId;
    if (!collegeId) throw ApiError.unauthorized('College context missing');

    const definition = await PracticalService.createDefinition(
      collegeId.toString(),
      (req as any).user,
      req.body
    );

    return ApiResponse.created(res, definition, 'Practical definition created successfully');
  });

  static listDefinitions = asyncHandler(async (req: Request, res: Response) => {
    const collegeId = (req as any).collegeId || (req as any).user?.collegeId;
    if (!collegeId) throw ApiError.unauthorized('College context missing');

    const definitions = await PracticalService.listDefinitions(
      collegeId.toString(),
      req.query as any
    );

    return ApiResponse.success(res, definitions, 'Practical definitions retrieved');
  });

  static createSession = asyncHandler(async (req: Request, res: Response) => {
    const collegeId = (req as any).collegeId || (req as any).user?.collegeId;
    if (!collegeId) throw ApiError.unauthorized('College context missing');

    const session = await PracticalService.createSession(
      collegeId.toString(),
      (req as any).user,
      req.body
    );

    return ApiResponse.created(res, session, 'Practical session scheduled successfully');
  });

  static listSessions = asyncHandler(async (req: Request, res: Response) => {
    const collegeId = (req as any).collegeId || (req as any).user?.collegeId;
    if (!collegeId) throw ApiError.unauthorized('College context missing');

    const sessions = await PracticalService.listSessions(
      collegeId.toString(),
      (req as any).user,
      req.query as any
    );

    return ApiResponse.success(res, sessions, 'Practical sessions retrieved successfully');
  });

  static getSessionById = asyncHandler(async (req: Request, res: Response) => {
    const collegeId = (req as any).collegeId || (req as any).user?.collegeId;
    if (!collegeId) throw ApiError.unauthorized('College context missing');

    const { id } = req.params;
    const data = await PracticalService.getSessionById(
      collegeId.toString(),
      (req as any).user,
      id
    );

    return ApiResponse.success(res, data, 'Practical session retrieved successfully');
  });

  static openSession = asyncHandler(async (req: Request, res: Response) => {
    const collegeId = (req as any).collegeId || (req as any).user?.collegeId;
    if (!collegeId) throw ApiError.unauthorized('College context missing');

    const { id } = req.params;
    const session = await PracticalService.openSession(
      collegeId.toString(),
      (req as any).user,
      id
    );

    return ApiResponse.success(res, session, 'Practical session opened for execution');
  });

  static updateParticipation = asyncHandler(async (req: Request, res: Response) => {
    const collegeId = (req as any).collegeId || (req as any).user?.collegeId;
    if (!collegeId) throw ApiError.unauthorized('College context missing');

    const { id, studentId } = req.params;
    const record = await PracticalService.updateParticipation(
      collegeId.toString(),
      (req as any).user,
      id,
      studentId,
      req.body
    );

    return ApiResponse.success(res, record, 'Student practical participation updated');
  });

  static bulkUpdateParticipation = asyncHandler(async (req: Request, res: Response) => {
    const collegeId = (req as any).collegeId || (req as any).user?.collegeId;
    if (!collegeId) throw ApiError.unauthorized('College context missing');

    const { id } = req.params;
    const result = await PracticalService.bulkUpdateParticipation(
      collegeId.toString(),
      (req as any).user,
      id,
      req.body.updates
    );

    return ApiResponse.success(res, result, 'Student participation updated successfully');
  });

  static completeSession = asyncHandler(async (req: Request, res: Response) => {
    const collegeId = (req as any).collegeId || (req as any).user?.collegeId;
    if (!collegeId) throw ApiError.unauthorized('College context missing');

    const { id } = req.params;
    const session = await PracticalService.completeSession(
      collegeId.toString(),
      (req as any).user,
      id
    );

    return ApiResponse.success(res, session, 'Practical session completed successfully');
  });

  static cancelSession = asyncHandler(async (req: Request, res: Response) => {
    const collegeId = (req as any).collegeId || (req as any).user?.collegeId;
    if (!collegeId) throw ApiError.unauthorized('College context missing');

    const { id } = req.params;
    const session = await PracticalService.cancelSession(
      collegeId.toString(),
      (req as any).user,
      id,
      req.body?.reason
    );

    return ApiResponse.success(res, session, 'Practical session cancelled');
  });

  static getStudentPracticalHistory = asyncHandler(async (req: Request, res: Response) => {
    const collegeId = (req as any).collegeId || (req as any).user?.collegeId;
    if (!collegeId) throw ApiError.unauthorized('College context missing');

    const studentId = req.query.studentId as string | undefined;
    const subjectId = req.query.subjectId as string | undefined;

    const history = await PracticalService.getStudentPracticalHistory(
      collegeId.toString(),
      (req as any).user,
      studentId,
      subjectId ? { subjectId } : undefined
    );

    return ApiResponse.success(res, history, 'Student practical history retrieved');
  });
}
