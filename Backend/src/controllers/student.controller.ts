import { Request, Response } from 'express';
import { StudentService } from '../services/student.service';
import { ApiResponse } from '../utils/apiResponse';
import { asyncHandler } from '../utils/asyncHandler';
import { ApiError } from '../utils/apiError';
import {
  provisionStudentSchema,
  updateStudentProfileSchema,
  correctStudentInstituteIdSchema,
  transferStudentDepartmentSchema,
  createPhoneRequestSchema,
  resolvePhoneRequestSchema,
  studentQuerySchema,
  contactRequestQuerySchema,
} from '../validations/student.validation';

export class StudentController {
  /**
   * POST /api/v1/academics/students
   * Provision Student Account & Profile + Generate Phase 9C Invitation
   */
  static provision = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) {
      throw ApiError.unauthorized('User not authenticated');
    }

    const validatedData = provisionStudentSchema.parse(req.body);
    const result = await StudentService.provisionStudent(validatedData, req.user);

    return ApiResponse.created(
      res,
      {
        user: result.user,
        student: result.student,
        invitation: result.invitation,
        activationCode: result.activationCode,
      },
      'Student account provisioned successfully. Activation invitation created.'
    );
  });

  /**
   * GET /api/v1/academics/students
   * List Students (Admin, College Admin, HOD, Faculty)
   */
  static list = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) {
      throw ApiError.unauthorized('User not authenticated');
    }

    const validatedQuery = studentQuerySchema.parse(req.query);
    const result = await StudentService.listStudents(req.user, validatedQuery);

    return ApiResponse.success(res, result);
  });

  /**
   * GET /api/v1/academics/students/:id
   * Get Student Details
   */
  static getById = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) {
      throw ApiError.unauthorized('User not authenticated');
    }

    const result = await StudentService.getStudentById(req.params.id, req.user);
    return ApiResponse.success(res, result);
  });

  /**
   * PUT /api/v1/academics/students/:id
   * Update Student Profile
   */
  static updateProfile = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) {
      throw ApiError.unauthorized('User not authenticated');
    }

    const validatedData = updateStudentProfileSchema.parse(req.body);
    const result = await StudentService.updateStudentProfile(req.params.id, validatedData, req.user);

    return ApiResponse.success(res, result, 'Student profile updated successfully');
  });

  /**
   * PATCH /api/v1/academics/students/:id/institute-id
   * Correct Student Institute ID
   */
  static correctInstituteId = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) {
      throw ApiError.unauthorized('User not authenticated');
    }

    const { instituteId } = correctStudentInstituteIdSchema.parse(req.body);
    const result = await StudentService.correctInstituteId(req.params.id, instituteId, req.user);

    return ApiResponse.success(res, result, 'Student institutional identifier updated successfully');
  });

  /**
   * PATCH /api/v1/academics/students/:id/department
   * Safe Administrative Department Transfer
   */
  static transferDepartment = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) {
      throw ApiError.unauthorized('User not authenticated');
    }

    const { departmentId } = transferStudentDepartmentSchema.parse(req.body);
    const result = await StudentService.transferStudentDepartment(req.params.id, departmentId, req.user);

    return ApiResponse.success(res, result, 'Student department transferred successfully');
  });

  /**
   * GET /api/v1/academics/students/:id/summary
   * Get Student Summary Metrics
   */
  static getSummary = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) {
      throw ApiError.unauthorized('User not authenticated');
    }

    const summary = await StudentService.getStudentSummary(req.params.id, req.user);
    return ApiResponse.success(res, summary);
  });

  /**
   * GET /api/v1/departments/:departmentId/students
   * Lookup Students in a Department
   */
  static getByDepartmentId = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) {
      throw ApiError.unauthorized('User not authenticated');
    }

    const studentList = await StudentService.getDepartmentStudents(req.params.departmentId, req.user);
    return ApiResponse.success(res, studentList);
  });

  /**
   * POST /api/v1/academics/students/me/phone-request
   * Student Requests Teacher/Admin to Add Mobile Number
   */
  static createPhoneRequest = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) {
      throw ApiError.unauthorized('User not authenticated');
    }

    const { requestedPhone, notes } = createPhoneRequestSchema.parse(req.body);
    const requestRecord = await StudentService.createContactRequest(requestedPhone, notes, req.user);

    return ApiResponse.created(
      res,
      requestRecord,
      'Contact number addition request submitted to teachers and administrators successfully.'
    );
  });

  /**
   * GET /api/v1/academics/student-contact-requests
   * List Contact Requests (Scoped)
   */
  static listContactRequests = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) {
      throw ApiError.unauthorized('User not authenticated');
    }

    const query = contactRequestQuerySchema.parse(req.query);
    const result = await StudentService.listContactRequests(req.user, query);

    return ApiResponse.success(res, result);
  });

  /**
   * PATCH /api/v1/academics/student-contact-requests/:id
   * Staff/Admin Resolves (Approve / Reject) Contact Request
   */
  static resolveContactRequest = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) {
      throw ApiError.unauthorized('User not authenticated');
    }

    const resolution = resolvePhoneRequestSchema.parse(req.body);
    const result = await StudentService.resolveContactRequest(req.params.id, resolution, req.user);

    return ApiResponse.success(res, result, `Contact request has been ${resolution.status.toLowerCase()}`);
  });
}
