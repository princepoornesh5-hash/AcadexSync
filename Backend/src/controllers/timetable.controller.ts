import { Request, Response } from 'express';
import { TimetableService } from '../services/timetable.service';
import { ApiResponse } from '../utils/apiResponse';
import { asyncHandler } from '../utils/asyncHandler';
import { ApiError } from '../utils/apiError';
import {
  createRoomSchema,
  updateRoomSchema,
  roomQuerySchema,
  createTimetableSchema,
  updateTimetableSchema,
  timetableQuerySchema,
} from '../validations/timetable.validation';
import { TimetableDay } from '../constants/status';
import { AppRole } from '../constants/roles';

export class TimetableController {
  // =========================================================================
  // 1. ROOM MANAGEMENT
  // =========================================================================

  static createRoom = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) throw ApiError.unauthorized('User not authenticated');

    const collegeId = req.user.role === AppRole.SUPER_ADMIN
      ? (req.body.collegeId || req.collegeId)
      : req.user.collegeId;

    if (!collegeId) throw ApiError.badRequest('collegeId is required');

    const validatedData = createRoomSchema.parse(req.body);
    const room = await TimetableService.createRoom(collegeId, validatedData, req.user);
    return ApiResponse.created(res, room, 'Room created successfully');
  });

  static listRooms = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) throw ApiError.unauthorized('User not authenticated');
    const query = roomQuerySchema.parse(req.query);
    const result = await TimetableService.listRooms(req.user, query);
    return ApiResponse.success(res, result);
  });

  static getRoomById = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) throw ApiError.unauthorized('User not authenticated');
    const room = await TimetableService.getRoomById(req.params.id, req.user);
    return ApiResponse.success(res, room);
  });

  static updateRoom = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) throw ApiError.unauthorized('User not authenticated');
    const validatedData = updateRoomSchema.parse(req.body);
    const room = await TimetableService.updateRoom(req.params.id, validatedData, req.user);
    return ApiResponse.success(res, room, 'Room updated successfully');
  });

  // =========================================================================
  // 2. TIMETABLE MANAGEMENT
  // =========================================================================

  static create = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) throw ApiError.unauthorized('User not authenticated');

    if (req.user.role === AppRole.COLLEGE_ADMIN && req.body.collegeId && req.body.collegeId !== req.user.collegeId) {
      throw ApiError.forbidden('Cross-college timetable creation is strictly prohibited');
    }

    const collegeId = req.user.role === AppRole.SUPER_ADMIN
      ? (req.body.collegeId || req.collegeId)
      : req.user.collegeId;

    if (!collegeId) throw ApiError.badRequest('collegeId is required');

    const validatedData = createTimetableSchema.parse(req.body);
    const timetable = await TimetableService.createTimetable(collegeId, validatedData as any, req.user);
    return ApiResponse.created(res, timetable, 'Timetable created successfully');
  });

  static getById = asyncHandler(async (req: Request, res: Response) => {
    const isSuperAdmin = req.user?.role === AppRole.SUPER_ADMIN || req.tenant?.isSuperAdmin || false;
    const timetable = await TimetableService.getTimetableById(
      req.params.id,
      req.user?.collegeId || req.collegeId,
      isSuperAdmin,
      req.user
    );
    return ApiResponse.success(res, timetable);
  });

  static list = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) {
      // Fallback for unauthenticated legacy queries
      const query = timetableQuerySchema.parse(req.query);
      const result = await TimetableService.listTimetables(undefined, query);
      return ApiResponse.success(res, result);
    }
    const query = timetableQuerySchema.parse(req.query);
    const result = await TimetableService.listTimetables(req.user, query);
    return ApiResponse.success(res, result);
  });

  static update = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) throw ApiError.unauthorized('User not authenticated');
    const validatedData = updateTimetableSchema.parse(req.body);
    const timetable = await TimetableService.updateTimetable(req.params.id, validatedData as any, req.user);
    return ApiResponse.success(res, timetable, 'Timetable updated successfully');
  });

  static publish = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) throw ApiError.unauthorized('User not authenticated');
    const isSuperAdmin = req.user.role === AppRole.SUPER_ADMIN || req.tenant?.isSuperAdmin || false;
    const publishedBy = req.user.id;
    const timetable = await TimetableService.publishTimetable(
      req.params.id,
      publishedBy,
      req.user.collegeId || req.collegeId,
      isSuperAdmin,
      req.user
    );
    return ApiResponse.success(res, timetable, 'Timetable published successfully');
  });

  static unpublish = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) throw ApiError.unauthorized('User not authenticated');
    const timetable = await TimetableService.unpublishTimetable(req.params.id, req.user);
    return ApiResponse.success(res, timetable, 'Timetable unpublished successfully');
  });

  static archive = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) throw ApiError.unauthorized('User not authenticated');
    const timetable = await TimetableService.archiveTimetable(req.params.id, req.user);
    return ApiResponse.success(res, timetable, 'Timetable archived successfully');
  });

  static delete = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) throw ApiError.unauthorized('User not authenticated');
    await TimetableService.deleteTimetable(req.params.id, req.user);
    return ApiResponse.noContent(res);
  });

  // =========================================================================
  // 3. SPECIALIZED RETRIEVALS
  // =========================================================================

  static getSectionTimetable = asyncHandler(async (req: Request, res: Response) => {
    const day = req.query.day as TimetableDay | undefined;
    const date = req.query.date as string | undefined;
    const entries = await TimetableService.getSectionTimetable(req.params.sectionId, day, req.user, date);
    return ApiResponse.success(res, entries);
  });

  static getFacultyTimetable = asyncHandler(async (req: Request, res: Response) => {
    const facultyId = req.params.facultyId || 'me';
    const day = req.query.day as TimetableDay | undefined;
    const date = req.query.date as string | undefined;
    const entries = await TimetableService.getFacultyTimetable(facultyId, day, req.user, date);
    return ApiResponse.success(res, entries);
  });

  static getStudentTimetable = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) throw ApiError.unauthorized('User not authenticated');
    const day = req.query.day as TimetableDay | undefined;
    const date = req.query.date as string | undefined;
    const entries = await TimetableService.getStudentTimetable(req.user, day, date);
    return ApiResponse.success(res, entries);
  });

  static getDepartmentTimetable = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) throw ApiError.unauthorized('User not authenticated');
    const day = req.query.day as TimetableDay | undefined;
    const date = req.query.date as string | undefined;
    const entries = await TimetableService.getDepartmentTimetable(
      req.params.departmentId,
      day,
      req.user,
      date
    );
    return ApiResponse.success(res, entries);
  });
}
