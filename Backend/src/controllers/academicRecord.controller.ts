import { Request, Response } from 'express';
import { AcademicRecordService } from '../services/academicRecord.service';
import { AuthenticatedUser } from '../types/auth.types';
import { AppRole } from '../constants/roles';
import { ApiError } from '../utils/apiError';
import {
  initializeRecordSchema,
  updateProgressionSchema,
  updateSubjectStatusSchema,
  queryDepartmentRecordsSchema,
} from '../validations/academicRecord.validation';

export class AcademicRecordController {
  /**
   * POST /api/v1/academic-records/initialize
   */
  static async initializeRecord(req: Request, res: Response) {
    const user = req.user as AuthenticatedUser;
    const collegeId = user.collegeId;
    if (!collegeId) throw ApiError.badRequest('College ID missing from context');

    const parsed = initializeRecordSchema.parse(req.body);

    const record = await AcademicRecordService.initializeFromEnrollment(
      collegeId,
      parsed.studentEnrollmentId,
      user.id
    );

    return res.status(201).json({
      success: true,
      message: 'Academic record initialized successfully',
      data: record,
    });
  }

  /**
   * GET /api/v1/academic-records/history
   * Retrieves complete student academic history across all semesters
   */
  static async getStudentHistory(req: Request, res: Response) {
    const user = req.user as AuthenticatedUser;
    const collegeId = user.collegeId;
    if (!collegeId) throw ApiError.badRequest('College ID missing from context');

    let targetStudentId = (req.query.studentId as string) || '';

    // If requester is student, force self
    if (user.role === AppRole.STUDENT) {
      targetStudentId = user.id;
    } else if (!targetStudentId) {
      throw ApiError.badRequest('studentId query parameter is required');
    }

    const history = await AcademicRecordService.getStudentAcademicHistory(
      collegeId,
      targetStudentId,
      user
    );

    return res.status(200).json({
      success: true,
      data: history,
    });
  }

  /**
   * GET /api/v1/academic-records/:id
   * Retrieves structured detail for a single academic period record
   */
  static async getRecordDetail(req: Request, res: Response) {
    const user = req.user as AuthenticatedUser;
    const collegeId = user.collegeId;
    if (!collegeId) throw ApiError.badRequest('College ID missing from context');

    const { id } = req.params;
    const detail = await AcademicRecordService.getRecordDetail(collegeId, id, user);

    return res.status(200).json({
      success: true,
      data: detail,
    });
  }

  /**
   * PATCH /api/v1/academic-records/:id/progression
   * Updates student progression status (HOD / College Admin)
   */
  static async updateProgressionStatus(req: Request, res: Response) {
    const user = req.user as AuthenticatedUser;
    const collegeId = user.collegeId;
    if (!collegeId) throw ApiError.badRequest('College ID missing from context');

    const { id } = req.params;
    const parsed = updateProgressionSchema.parse(req.body);

    const updated = await AcademicRecordService.updateProgressionStatus(
      collegeId,
      id,
      parsed.progressionStatus,
      parsed.remarks,
      user
    );

    return res.status(200).json({
      success: true,
      message: `Academic progression updated to ${parsed.progressionStatus}`,
      data: updated,
    });
  }

  /**
   * PATCH /api/v1/academic-records/subjects/:subjectRecordId/status
   */
  static async updateSubjectStatus(req: Request, res: Response) {
    const user = req.user as AuthenticatedUser;
    const collegeId = user.collegeId;
    if (!collegeId) throw ApiError.badRequest('College ID missing from context');

    const { subjectRecordId } = req.params;
    const parsed = updateSubjectStatusSchema.parse(req.body);

    const updated = await AcademicRecordService.updateSubjectStatus(
      collegeId,
      subjectRecordId,
      parsed.status,
      parsed.remarks,
      user
    );

    return res.status(200).json({
      success: true,
      message: `Subject status updated to ${parsed.status}`,
      data: updated,
    });
  }

  /**
   * GET /api/v1/academic-records/department
   * Lists records in department for HOD / Admin
   */
  static async listDepartmentRecords(req: Request, res: Response) {
    const user = req.user as AuthenticatedUser;
    const collegeId = user.collegeId;
    if (!collegeId) throw ApiError.badRequest('College ID missing from context');

    const parsed = queryDepartmentRecordsSchema.parse(req.query);

    const result = await AcademicRecordService.listDepartmentRecords(
      collegeId,
      parsed,
      user
    );

    return res.status(200).json({
      success: true,
      data: result.records,
      meta: result.meta,
    });
  }
}
