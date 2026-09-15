import { Request, Response } from 'express';
import { AcademicService } from '../services/academic.service';
import { ApiResponse } from '../utils/apiResponse';
import { asyncHandler } from '../utils/asyncHandler';
import { ApiError } from '../utils/apiError';
import {
  createCourseSchema,
  updateCourseSchema,
  courseQuerySchema,
  createAcademicYearSchema,
  updateAcademicYearSchema,
  academicYearQuerySchema,
  createSemesterSchema,
  updateSemesterSchema,
  semesterQuerySchema,
  createSectionSchema,
  updateSectionSchema,
  sectionQuerySchema,
  createSubjectSchema,
  updateSubjectSchema,
  subjectQuerySchema,
  enrollStudentSchema,
  updateEnrollmentSchema,
  enrollmentQuerySchema,
  createFacultyAssignmentSchema,
  updateFacultyAssignmentSchema,
  facultyAssignmentQuerySchema,
} from '../validations/academic.validation';
import { AppRole } from '../constants/roles';

export class AcademicController {
  // =========================================================================
  // 1. COURSE ENDPOINTS
  // =========================================================================

  static createCourse = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) throw ApiError.unauthorized('User not authenticated');

    const collegeId = req.user.role === AppRole.SUPER_ADMIN
      ? (req.body.collegeId || req.collegeId)
      : req.user.collegeId;

    if (!collegeId) throw ApiError.badRequest('collegeId is required');

    // If HOD, automatically bind departmentId to requester.departmentId if not supplied,
    // and reject if attempting to target another department
    if (req.user.role === AppRole.HOD) {
      if (req.body.departmentId && req.body.departmentId !== req.user.departmentId) {
        throw ApiError.forbidden('HOD can only create courses within their assigned department');
      }
      req.body.departmentId = req.user.departmentId;
    }

    const validatedData = createCourseSchema.parse(req.body);
    const course = await AcademicService.createCourse(collegeId, validatedData, req.user);
    return ApiResponse.created(res, course, 'Course created successfully');
  });

  static listCourses = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) throw ApiError.unauthorized('User not authenticated');
    const query = courseQuerySchema.parse(req.query);
    const result = await AcademicService.listCourses(req.user, query);
    return ApiResponse.success(res, result);
  });

  static getCourseById = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) throw ApiError.unauthorized('User not authenticated');
    const course = await AcademicService.getCourseById(req.params.id, req.user);
    return ApiResponse.success(res, course);
  });

  static updateCourse = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) throw ApiError.unauthorized('User not authenticated');
    const validatedData = updateCourseSchema.parse(req.body);
    const course = await AcademicService.updateCourse(req.params.id, validatedData, req.user);
    return ApiResponse.success(res, course, 'Course updated successfully');
  });

  // =========================================================================
  // 2. ACADEMIC YEAR ENDPOINTS
  // =========================================================================

  static createAcademicYear = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) throw ApiError.unauthorized('User not authenticated');

    const collegeId = req.user.role === AppRole.SUPER_ADMIN
      ? (req.body.collegeId || req.collegeId)
      : req.user.collegeId;

    if (!collegeId) throw ApiError.badRequest('collegeId is required');

    const validatedData = createAcademicYearSchema.parse(req.body);
    const academicYear = await AcademicService.createAcademicYear(collegeId, validatedData, req.user);
    return ApiResponse.created(res, academicYear, 'Academic Year created successfully');
  });

  static listAcademicYears = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) throw ApiError.unauthorized('User not authenticated');
    const query = academicYearQuerySchema.parse(req.query);
    const result = await AcademicService.listAcademicYears(req.user, query);
    return ApiResponse.success(res, result);
  });

  static getAcademicYearById = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) throw ApiError.unauthorized('User not authenticated');
    const academicYear = await AcademicService.getAcademicYearById(req.params.id, req.user);
    return ApiResponse.success(res, academicYear);
  });

  static updateAcademicYear = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) throw ApiError.unauthorized('User not authenticated');
    const validatedData = updateAcademicYearSchema.parse(req.body);
    const academicYear = await AcademicService.updateAcademicYear(req.params.id, validatedData, req.user);
    return ApiResponse.success(res, academicYear, 'Academic Year updated successfully');
  });

  // =========================================================================
  // 3. SEMESTER ENDPOINTS
  // =========================================================================

  static createSemester = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) throw ApiError.unauthorized('User not authenticated');

    const collegeId = req.user.role === AppRole.SUPER_ADMIN
      ? (req.body.collegeId || req.collegeId)
      : req.user.collegeId;

    if (!collegeId) throw ApiError.badRequest('collegeId is required');

    const validatedData = createSemesterSchema.parse(req.body);
    const semester = await AcademicService.createSemester(collegeId, validatedData, req.user);
    return ApiResponse.created(res, semester, 'Semester created successfully');
  });

  static listSemesters = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) throw ApiError.unauthorized('User not authenticated');
    const query = semesterQuerySchema.parse(req.query);
    const result = await AcademicService.listSemesters(req.user, query);
    return ApiResponse.success(res, result);
  });

  static getSemesterById = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) throw ApiError.unauthorized('User not authenticated');
    const semester = await AcademicService.getSemesterById(req.params.id, req.user);
    return ApiResponse.success(res, semester);
  });

  static updateSemester = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) throw ApiError.unauthorized('User not authenticated');
    const validatedData = updateSemesterSchema.parse(req.body);
    const semester = await AcademicService.updateSemester(req.params.id, validatedData, req.user);
    return ApiResponse.success(res, semester, 'Semester updated successfully');
  });

  // =========================================================================
  // 4. SECTION ENDPOINTS
  // =========================================================================

  static createSection = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) throw ApiError.unauthorized('User not authenticated');

    const collegeId = req.user.role === AppRole.SUPER_ADMIN
      ? (req.body.collegeId || req.collegeId)
      : req.user.collegeId;

    if (!collegeId) throw ApiError.badRequest('collegeId is required');

    const validatedData = createSectionSchema.parse(req.body);
    const section = await AcademicService.createSection(collegeId, validatedData, req.user);
    return ApiResponse.created(res, section, 'Section created successfully');
  });

  static listSections = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) throw ApiError.unauthorized('User not authenticated');
    const query = sectionQuerySchema.parse(req.query);
    const result = await AcademicService.listSections(req.user, query);
    return ApiResponse.success(res, result);
  });

  static getSectionById = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) throw ApiError.unauthorized('User not authenticated');
    const section = await AcademicService.getSectionById(req.params.id, req.user);
    return ApiResponse.success(res, section);
  });

  static updateSection = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) throw ApiError.unauthorized('User not authenticated');
    const validatedData = updateSectionSchema.parse(req.body);
    const section = await AcademicService.updateSection(req.params.id, validatedData, req.user);
    return ApiResponse.success(res, section, 'Section updated successfully');
  });

  // =========================================================================
  // 5. SUBJECT ENDPOINTS
  // =========================================================================

  static createSubject = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) throw ApiError.unauthorized('User not authenticated');

    const collegeId = req.user.role === AppRole.SUPER_ADMIN
      ? (req.body.collegeId || req.collegeId)
      : req.user.collegeId;

    if (!collegeId) throw ApiError.badRequest('collegeId is required');

    const validatedData = createSubjectSchema.parse(req.body);
    const subject = await AcademicService.createSubject(collegeId, validatedData, req.user);
    return ApiResponse.created(res, subject, 'Subject created successfully');
  });

  static listSubjects = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) throw ApiError.unauthorized('User not authenticated');
    const query = subjectQuerySchema.parse(req.query);
    const result = await AcademicService.listSubjects(req.user, query);
    return ApiResponse.success(res, result);
  });

  static getSubjectById = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) throw ApiError.unauthorized('User not authenticated');
    const subject = await AcademicService.getSubjectById(req.params.id, req.user);
    return ApiResponse.success(res, subject);
  });

  static updateSubject = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) throw ApiError.unauthorized('User not authenticated');
    const validatedData = updateSubjectSchema.parse(req.body);
    const subject = await AcademicService.updateSubject(req.params.id, validatedData, req.user);
    return ApiResponse.success(res, subject, 'Subject updated successfully');
  });

  // =========================================================================
  // 6. STUDENT ENROLLMENT ENDPOINTS
  // =========================================================================

  static enrollStudent = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) throw ApiError.unauthorized('User not authenticated');

    const collegeId = req.user.role === AppRole.SUPER_ADMIN
      ? (req.body.collegeId || req.collegeId)
      : req.user.collegeId;

    if (!collegeId) throw ApiError.badRequest('collegeId is required');

    const validatedData = enrollStudentSchema.parse(req.body);
    const enrollment = await AcademicService.enrollStudent(collegeId, validatedData, req.user);
    return ApiResponse.created(res, enrollment, 'Student enrolled successfully');
  });

  static listEnrollments = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) throw ApiError.unauthorized('User not authenticated');
    const query = enrollmentQuerySchema.parse(req.query);
    const result = await AcademicService.listEnrollments(req.user, query);
    return ApiResponse.success(res, result);
  });

  static getEnrollmentById = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) throw ApiError.unauthorized('User not authenticated');
    const enrollment = await AcademicService.getEnrollmentById(req.params.id, req.user);
    return ApiResponse.success(res, enrollment);
  });

  static updateEnrollment = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) throw ApiError.unauthorized('User not authenticated');
    const validatedData = updateEnrollmentSchema.parse(req.body);
    const enrollment = await AcademicService.updateEnrollment(req.params.id, validatedData, req.user);
    return ApiResponse.success(res, enrollment, 'Enrollment updated successfully');
  });

  static deleteEnrollment = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) throw ApiError.unauthorized('User not authenticated');
    await AcademicService.deleteEnrollment(req.params.id, req.user);
    return ApiResponse.success(res, null, 'Student enrollment withdrawn successfully');
  });

  // =========================================================================
  // 7. ACADEMIC TREE & LOOKUPS
  // =========================================================================

  static getAcademicTree = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) throw ApiError.unauthorized('User not authenticated');
    const tree = await AcademicService.getAcademicTree(req.user);
    return ApiResponse.success(res, tree);
  });

  // =========================================================================
  // 8. FACULTY ASSIGNMENTS & WORKLOAD (MODULE 5B)
  // =========================================================================

  static createFacultyAssignment = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) throw ApiError.unauthorized('User not authenticated');

    const collegeId = req.user.role === AppRole.SUPER_ADMIN
      ? (req.body.collegeId || req.collegeId)
      : req.user.collegeId;

    if (!collegeId) throw ApiError.badRequest('collegeId is required');

    const validatedData = createFacultyAssignmentSchema.parse(req.body);
    const assignment = await AcademicService.createFacultyAssignment(collegeId, validatedData, req.user);
    return ApiResponse.created(res, assignment, 'Faculty assigned successfully');
  });

  static listFacultyAssignments = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) throw ApiError.unauthorized('User not authenticated');
    const query = facultyAssignmentQuerySchema.parse(req.query);
    const result = await AcademicService.listFacultyAssignments(req.user, query);
    return ApiResponse.success(res, result);
  });

  static getFacultyAssignmentById = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) throw ApiError.unauthorized('User not authenticated');
    const assignment = await AcademicService.getFacultyAssignmentById(req.params.id, req.user);
    return ApiResponse.success(res, assignment);
  });

  static updateFacultyAssignment = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) throw ApiError.unauthorized('User not authenticated');
    const validatedData = updateFacultyAssignmentSchema.parse(req.body);
    const assignment = await AcademicService.updateFacultyAssignment(req.params.id, validatedData, req.user);
    return ApiResponse.success(res, assignment, 'Faculty assignment updated successfully');
  });

  static deleteFacultyAssignment = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) throw ApiError.unauthorized('User not authenticated');
    await AcademicService.deleteFacultyAssignment(req.params.id, req.user);
    return ApiResponse.success(res, null, 'Faculty assignment deleted successfully');
  });

  static getFacultyWorkload = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) throw ApiError.unauthorized('User not authenticated');
    const departmentId = req.query.departmentId as string | undefined;
    const workloads = await AcademicService.getFacultyWorkload(req.user, departmentId);
    return ApiResponse.success(res, workloads);
  });

  static getMyFacultyAssignments = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) throw ApiError.unauthorized('User not authenticated');
    const result = await AcademicService.listFacultyAssignments(req.user, { page: 1, limit: 100 });
    return ApiResponse.success(res, result.items);
  });

  static assignFaculty = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) throw ApiError.unauthorized('User not authenticated');
    const collegeId = req.user.role === AppRole.SUPER_ADMIN
      ? (req.body.collegeId || req.collegeId)
      : req.user.collegeId;
    if (!collegeId) throw ApiError.badRequest('collegeId is required');
    const validatedData = createFacultyAssignmentSchema.parse(req.body);
    const assignment = await AcademicService.createFacultyAssignment(collegeId, validatedData, req.user);
    return ApiResponse.created(res, assignment, 'Faculty assigned successfully');
  });
}
