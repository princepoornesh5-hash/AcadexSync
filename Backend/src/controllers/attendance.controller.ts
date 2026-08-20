import { Request, Response } from 'express';
import { AttendanceService } from '../services/attendance.service';
import { ApiResponse } from '../utils/apiResponse';
import { asyncHandler } from '../utils/asyncHandler';
import { ApiError } from '../utils/apiError';
import {
  createAttendanceSessionSchema,
  submitAttendanceRecordsSchema,
  correctAttendanceRecordSchema,
  attendanceQuerySchema,
  attendanceAnalyticsQuerySchema,
} from '../validations/attendance.validation';
import { AppRole } from '../constants/roles';

export class AttendanceController {
  // =========================================================================
  // 1. SESSION CRUD & RECORD SUBMISSION
  // =========================================================================

  static createSession = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) throw ApiError.unauthorized('User not authenticated');

    const collegeId = req.user.role === AppRole.SUPER_ADMIN
      ? (req.body.collegeId || req.collegeId)
      : req.user.collegeId;

    if (!collegeId) throw ApiError.badRequest('collegeId is required');

    const validatedData = createAttendanceSessionSchema.parse(req.body);
    const session = await AttendanceService.createOrSubmitSession(
      collegeId,
      validatedData as any,
      req.user.id,
      req.user
    );
    return ApiResponse.created(res, session, 'Attendance session created successfully');
  });

  static getById = asyncHandler(async (req: Request, res: Response) => {
    const isSuperAdmin = req.user?.role === AppRole.SUPER_ADMIN || req.tenant?.isSuperAdmin || false;
    const session = await AttendanceService.getSessionById(
      req.params.id,
      req.user?.collegeId || req.collegeId,
      isSuperAdmin,
      req.user
    );
    return ApiResponse.success(res, session);
  });

  static list = asyncHandler(async (req: Request, res: Response) => {
    const query = attendanceQuerySchema.parse(req.query);
    const result = await AttendanceService.listSessions(req.user, query);
    return ApiResponse.success(res, result);
  });

  static submitRecords = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) throw ApiError.unauthorized('User not authenticated');
    const validatedData = submitAttendanceRecordsSchema.parse(req.body);
    const session = await AttendanceService.submitRecords(req.params.id, validatedData.records, req.user);
    return ApiResponse.success(res, session, 'Attendance marked successfully');
  });

  // =========================================================================
  // 2. SESSION LIFECYCLE: LOCK, CLOSE, CANCEL
  // =========================================================================

  static lockSession = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) throw ApiError.unauthorized('User not authenticated');
    const session = await AttendanceService.lockSession(req.params.id, req.user);
    return ApiResponse.success(res, session, 'Attendance session locked successfully');
  });

  static closeSession = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) throw ApiError.unauthorized('User not authenticated');
    const session = await AttendanceService.closeSession(req.params.id, req.user);
    return ApiResponse.success(res, session, 'Attendance session closed successfully');
  });

  static cancelSession = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) throw ApiError.unauthorized('User not authenticated');
    const session = await AttendanceService.cancelSession(req.params.id, req.user);
    return ApiResponse.success(res, session, 'Attendance session cancelled successfully');
  });

  // =========================================================================
  // 3. ATTENDANCE CORRECTIONS
  // =========================================================================

  static correctRecord = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) throw ApiError.unauthorized('User not authenticated');
    const validatedData = correctAttendanceRecordSchema.parse(req.body);
    const record = await AttendanceService.correctRecord(
      req.params.id,
      validatedData.newStatus,
      validatedData.reason,
      req.user
    );
    return ApiResponse.success(res, record, 'Attendance record corrected successfully');
  });

  // =========================================================================
  // 4. STUDENT PERSONAL ATTENDANCE VIEWS
  // =========================================================================

  static getStudentHistory = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) throw ApiError.unauthorized('User not authenticated');
    const query = attendanceQuerySchema.parse(req.query);
    const result = await AttendanceService.getStudentHistory(req.user, query);
    return ApiResponse.success(res, result);
  });

  static getStudentSubjects = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) throw ApiError.unauthorized('User not authenticated');
    const semesterId = req.query.semesterId as string | undefined;
    const result = await AttendanceService.getStudentSubjectsBreakdown(req.user, semesterId);
    return ApiResponse.success(res, result);
  });

  static getStudentSummary = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) throw ApiError.unauthorized('User not authenticated');
    const collegeId = req.user.collegeId || req.collegeId || (req.query.collegeId as string);
    if (!collegeId) throw ApiError.badRequest('collegeId is required');

    const studentId = req.params.studentId || req.user.id;
    const summary = await AttendanceService.getStudentAttendanceSummary(collegeId, studentId);
    return ApiResponse.success(res, summary);
  });

  // =========================================================================
  // 5. SECTION, FACULTY & AGGREGATE ANALYTICS
  // =========================================================================

  static getSectionAttendance = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) throw ApiError.unauthorized('User not authenticated');
    const result = await AttendanceService.getSectionAttendance(req.params.sectionId, req.user);
    return ApiResponse.success(res, result);
  });

  static getFacultySessions = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) throw ApiError.unauthorized('User not authenticated');
    const result = await AttendanceService.getFacultySessions(req.user);
    return ApiResponse.success(res, result);
  });

  static getAnalytics = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) throw ApiError.unauthorized('User not authenticated');
    const query = attendanceAnalyticsQuerySchema.parse(req.query);
    const result = await AttendanceService.getAttendanceAnalytics(req.user, query);
    return ApiResponse.success(res, result);
  });

  // Backwards compatibility for submit handler
  static submit = asyncHandler(async (req: Request, res: Response) => {
    const collegeId = req.collegeId || req.body.collegeId;
    if (!collegeId) throw ApiError.badRequest('collegeId is required');

    const session = await AttendanceService.createOrSubmitSession(
      collegeId,
      req.body,
      req.user?.id,
      req.user
    );
    return ApiResponse.created(res, session, 'Attendance submitted successfully');
  });

  static studentSummary = asyncHandler(async (req: Request, res: Response) => {
    const collegeId = req.collegeId || (req.query.collegeId as string);
    if (!collegeId) throw ApiError.badRequest('collegeId is required');

    const summary = await AttendanceService.getStudentAttendanceSummary(
      collegeId,
      req.params.studentId
    );
    return ApiResponse.success(res, summary);
  });
}
