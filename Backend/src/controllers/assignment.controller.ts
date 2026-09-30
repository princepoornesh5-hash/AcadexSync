import { Request, Response } from 'express';
import { AssignmentService } from '../services/assignment.service';
import {
  createAssignmentSchema,
  updateAssignmentSchema,
  recordMarksSchema,
  submissionUploadAuthSchema,
  submitAssignmentSchema,
  singleReviewSchema,
} from '../validations/assignment.validation';
import { ApiError } from '../utils/apiError';
import { ApiResponse } from '../utils/apiResponse';
import { asyncHandler } from '../utils/asyncHandler';

export class AssignmentController {
  static createAssignment = asyncHandler(async (req: Request, res: Response) => {
    const collegeId = (req as any).collegeId || (req as any).user?.collegeId;
    if (!collegeId) {
      throw ApiError.unauthorized('College context missing');
    }

    const validated = createAssignmentSchema.parse(req.body);
    const assignment = await AssignmentService.createAssignment(
      collegeId.toString(),
      (req as any).user,
      validated as any
    );

    return ApiResponse.created(res, assignment, 'Assignment created successfully');
  });

  static publishAssignment = asyncHandler(async (req: Request, res: Response) => {
    const collegeId = (req as any).collegeId || (req as any).user?.collegeId;
    if (!collegeId) {
      throw ApiError.unauthorized('College context missing');
    }

    const { id } = req.params;
    const assignment = await AssignmentService.publishAssignment(
      collegeId.toString(),
      (req as any).user,
      id
    );

    return ApiResponse.success(res, assignment, 'Assignment published successfully');
  });

  static closeAssignment = asyncHandler(async (req: Request, res: Response) => {
    const collegeId = (req as any).collegeId || (req as any).user?.collegeId;
    if (!collegeId) {
      throw ApiError.unauthorized('College context missing');
    }

    const { id } = req.params;
    const assignment = await AssignmentService.closeAssignment(
      collegeId.toString(),
      (req as any).user,
      id
    );

    return ApiResponse.success(res, assignment, 'Assignment closed successfully');
  });

  static getFacultyAssignments = asyncHandler(async (req: Request, res: Response) => {
    const collegeId = (req as any).collegeId || (req as any).user?.collegeId;
    if (!collegeId) {
      throw ApiError.unauthorized('College context missing');
    }

    const query = {
      status: req.query.status as string,
      sectionId: req.query.sectionId as string,
      subjectId: req.query.subjectId as string,
    };

    const assignments = await AssignmentService.getFacultyAssignments(
      collegeId.toString(),
      (req as any).user,
      query
    );

    return ApiResponse.success(res, assignments, 'Assignments retrieved successfully');
  });

  static getStudentAssignments = asyncHandler(async (req: Request, res: Response) => {
    const collegeId = (req as any).collegeId || (req as any).user?.collegeId;
    if (!collegeId) {
      throw ApiError.unauthorized('College context missing');
    }

    const assignments = await AssignmentService.getStudentAssignments(
      collegeId.toString(),
      (req as any).user
    );

    return ApiResponse.success(res, assignments, 'Student assignments retrieved successfully');
  });

  static getAssignmentDetail = asyncHandler(async (req: Request, res: Response) => {
    const collegeId = (req as any).collegeId || (req as any).user?.collegeId;
    if (!collegeId) {
      throw ApiError.unauthorized('College context missing');
    }

    const { id } = req.params;
    const detail = await AssignmentService.getAssignmentDetail(
      collegeId.toString(),
      (req as any).user,
      id
    );

    return ApiResponse.success(res, detail, 'Assignment detail retrieved successfully');
  });

  static completeAssignment = asyncHandler(async (req: Request, res: Response) => {
    const collegeId = (req as any).collegeId || (req as any).user?.collegeId;
    if (!collegeId) {
      throw ApiError.unauthorized('College context missing');
    }

    const { id } = req.params;
    const submission = await AssignmentService.completeAssignment(
      collegeId.toString(),
      (req as any).user,
      id
    );

    return ApiResponse.success(res, submission, 'Assignment marked as completed');
  });

  static getSubmissionUploadAuth = asyncHandler(async (req: Request, res: Response) => {
    const collegeId = (req as any).collegeId || (req as any).user?.collegeId;
    if (!collegeId) {
      throw ApiError.unauthorized('College context missing');
    }

    const { id } = req.params;
    const validated = submissionUploadAuthSchema.parse(req.body);
    const authParams = await AssignmentService.getSubmissionUploadAuth(
      collegeId.toString(),
      (req as any).user,
      id,
      validated
    );

    return ApiResponse.success(res, authParams, 'Upload authorization granted');
  });

  static getStudentSubmission = asyncHandler(async (req: Request, res: Response) => {
    const collegeId = (req as any).collegeId || (req as any).user?.collegeId;
    if (!collegeId) {
      throw ApiError.unauthorized('College context missing');
    }

    const { id } = req.params;
    const submission = await AssignmentService.getStudentSubmission(
      collegeId.toString(),
      (req as any).user,
      id
    );

    return ApiResponse.success(res, submission, 'Student submission retrieved');
  });

  static saveDraftSubmission = asyncHandler(async (req: Request, res: Response) => {
    const collegeId = (req as any).collegeId || (req as any).user?.collegeId;
    if (!collegeId) {
      throw ApiError.unauthorized('College context missing');
    }

    const { id } = req.params;
    const validated = submitAssignmentSchema.parse(req.body);
    const draft = await AssignmentService.saveDraftSubmission(
      collegeId.toString(),
      (req as any).user,
      id,
      validated as any
    );

    return ApiResponse.success(res, draft, 'Draft submission saved successfully');
  });

  static submitAssignment = asyncHandler(async (req: Request, res: Response) => {
    const collegeId = (req as any).collegeId || (req as any).user?.collegeId;
    if (!collegeId) {
      throw ApiError.unauthorized('College context missing');
    }

    const { id } = req.params;
    const validated = submitAssignmentSchema.parse(req.body);
    const submission = await AssignmentService.submitAssignment(
      collegeId.toString(),
      (req as any).user,
      id,
      validated as any
    );

    return ApiResponse.success(res, submission, 'Assignment submitted successfully');
  });

  static getSubmissionFileDownloadUrl = asyncHandler(async (req: Request, res: Response) => {
    const collegeId = (req as any).collegeId || (req as any).user?.collegeId;
    if (!collegeId) {
      throw ApiError.unauthorized('College context missing');
    }

    const { id, fileId } = req.params;
    const downloadData = await AssignmentService.getSubmissionFileDownloadUrl(
      collegeId.toString(),
      (req as any).user,
      id,
      fileId
    );

    return ApiResponse.success(res, downloadData, 'File download link generated');
  });

  static reviewSingleSubmission = asyncHandler(async (req: Request, res: Response) => {
    const collegeId = (req as any).collegeId || (req as any).user?.collegeId;
    if (!collegeId) {
      throw ApiError.unauthorized('College context missing');
    }

    const { id, submissionId } = req.params;
    const validated = singleReviewSchema.parse(req.body);
    const submission = await AssignmentService.reviewSingleSubmission(
      collegeId.toString(),
      (req as any).user,
      id,
      submissionId,
      validated
    );

    return ApiResponse.success(res, submission, 'Submission reviewed and graded successfully');
  });

  static getAssignmentActivity = asyncHandler(async (req: Request, res: Response) => {
    const collegeId = (req as any).collegeId || (req as any).user?.collegeId;
    if (!collegeId) {
      throw ApiError.unauthorized('College context missing');
    }

    const { id } = req.params;
    const activity = await AssignmentService.getAssignmentActivity(
      collegeId.toString(),
      (req as any).user,
      id
    );

    return ApiResponse.success(res, activity, 'Assignment activity retrieved successfully');
  });

  static recordMarks = asyncHandler(async (req: Request, res: Response) => {
    const collegeId = (req as any).collegeId || (req as any).user?.collegeId;
    if (!collegeId) {
      throw ApiError.unauthorized('College context missing');
    }

    const { id } = req.params;
    const validated = recordMarksSchema.parse(req.body);
    const result = await AssignmentService.recordMarks(
      collegeId.toString(),
      (req as any).user,
      id,
      validated.marks
    );

    return ApiResponse.success(res, result, 'Marks saved successfully');
  });

  static updateAssignment = asyncHandler(async (req: Request, res: Response) => {
    const collegeId = (req as any).collegeId || (req as any).user?.collegeId;
    if (!collegeId) {
      throw ApiError.unauthorized('College context missing');
    }

    const { id } = req.params;
    const validated = updateAssignmentSchema.parse(req.body);
    const updated = await AssignmentService.updateAssignment(
      collegeId.toString(),
      (req as any).user,
      id,
      validated as any
    );

    return ApiResponse.success(res, updated, 'Assignment updated successfully');
  });

  static archiveAssignment = asyncHandler(async (req: Request, res: Response) => {
    const collegeId = (req as any).collegeId || (req as any).user?.collegeId;
    if (!collegeId) {
      throw ApiError.unauthorized('College context missing');
    }

    const { id } = req.params;
    const archived = await AssignmentService.archiveAssignment(
      collegeId.toString(),
      (req as any).user,
      id
    );

    return ApiResponse.success(res, archived, 'Assignment archived successfully');
  });

  static deleteAssignment = asyncHandler(async (req: Request, res: Response) => {
    const collegeId = (req as any).collegeId || (req as any).user?.collegeId;
    if (!collegeId) {
      throw ApiError.unauthorized('College context missing');
    }

    const { id } = req.params;
    const result = await AssignmentService.deleteAssignment(
      collegeId.toString(),
      (req as any).user,
      id
    );

    return ApiResponse.success(res, result, 'Draft assignment deleted successfully');
  });
}
