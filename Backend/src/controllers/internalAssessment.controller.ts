import { Request, Response } from 'express';
import { InternalAssessmentService } from '../services/internalAssessment.service';
import { LabExperimentService } from '../services/labExperiment.service';
import { ApiError } from '../utils/apiError';
import { ApiResponse } from '../utils/apiResponse';
import { asyncHandler } from '../utils/asyncHandler';

export class InternalAssessmentController {
  /**
   * Retrieves or initializes assessment context for a subject and section.
   */
  static getContext = asyncHandler(async (req: Request, res: Response) => {
    const collegeId = (req as any).collegeId || (req as any).user?.collegeId;
    if (!collegeId) throw ApiError.unauthorized('College context missing');

    const { sectionId, subjectId, academicYearId } = req.query;
    if (!sectionId || !subjectId) {
      throw ApiError.badRequest('sectionId and subjectId are required query parameters');
    }

    const context = await InternalAssessmentService.getAssessmentContext(
      collegeId.toString(),
      (req as any).user,
      {
        sectionId: sectionId.toString(),
        subjectId: subjectId.toString(),
        academicYearId: academicYearId ? academicYearId.toString() : undefined,
      }
    );

    return ApiResponse.success(res, context, 'Assessment context retrieved successfully');
  });

  /**
   * Explicitly creates a new Internal Assessment document.
   */
  static createAssessment = asyncHandler(async (req: Request, res: Response) => {
    const collegeId = (req as any).collegeId || (req as any).user?.collegeId;
    if (!collegeId) throw ApiError.unauthorized('College context missing');

    const result = await InternalAssessmentService.createAssessment(
      collegeId.toString(),
      (req as any).user,
      req.body
    );

    return ApiResponse.created(res, result, 'Internal assessment created successfully');
  });

  /**
   * Opens an assessment for marks entry (DRAFT -> OPEN).
   */
  static open = asyncHandler(async (req: Request, res: Response) => {
    const collegeId = (req as any).collegeId || (req as any).user?.collegeId;
    if (!collegeId) throw ApiError.unauthorized('College context missing');

    const assessmentId = req.params.id || req.body.assessmentId;
    const { sectionId, subjectId } = req.body;

    const result = await InternalAssessmentService.openAssessment(
      collegeId.toString(),
      (req as any).user,
      { assessmentId, sectionId, subjectId }
    );

    return ApiResponse.success(res, result, 'Assessment opened for marks entry');
  });

  /**
   * Saves or updates draft marks for a class section and subject.
   */
  static saveDraft = asyncHandler(async (req: Request, res: Response) => {
    const collegeId = (req as any).collegeId || (req as any).user?.collegeId;
    if (!collegeId) throw ApiError.unauthorized('College context missing');

    const { sectionId, subjectId, entries, title, academicYearId } = req.body;
    const assessmentId = req.params.id || req.body.assessmentId;

    if ((!sectionId || !subjectId) && !assessmentId) {
      throw ApiError.badRequest('Either assessmentId or both sectionId and subjectId are required');
    }
    if (!Array.isArray(entries)) {
      throw ApiError.badRequest('entries array is required');
    }

    const result = await InternalAssessmentService.saveDraftMarks(
      collegeId.toString(),
      (req as any).user,
      {
        assessmentId,
        sectionId,
        subjectId,
        entries,
        title,
        academicYearId,
      }
    );

    return ApiResponse.success(res, result, 'Assessment draft marks saved successfully');
  });

  /**
   * Bulk marks save operation with identical integrity.
   */
  static bulkSaveMarks = asyncHandler(async (req: Request, res: Response) => {
    const collegeId = (req as any).collegeId || (req as any).user?.collegeId;
    if (!collegeId) throw ApiError.unauthorized('College context missing');

    const { sectionId, subjectId, entries, title, academicYearId } = req.body;
    const assessmentId = req.params.id || req.body.assessmentId;

    if ((!sectionId || !subjectId) && !assessmentId) {
      throw ApiError.badRequest('Either assessmentId or both sectionId and subjectId are required');
    }
    if (!Array.isArray(entries)) {
      throw ApiError.badRequest('entries array is required');
    }

    const result = await InternalAssessmentService.bulkSaveMarks(
      collegeId.toString(),
      (req as any).user,
      {
        assessmentId,
        sectionId,
        subjectId,
        entries,
        title,
        academicYearId,
      }
    );

    return ApiResponse.success(res, result, 'Bulk assessment marks saved successfully');
  });

  /**
   * Closes an assessment to lock mark entry before publication.
   */
  static close = asyncHandler(async (req: Request, res: Response) => {
    const collegeId = (req as any).collegeId || (req as any).user?.collegeId;
    if (!collegeId) throw ApiError.unauthorized('College context missing');

    const assessmentId = req.params.id || req.body.assessmentId;
    const { sectionId, subjectId } = req.body;

    const result = await InternalAssessmentService.closeAssessment(
      collegeId.toString(),
      (req as any).user,
      { assessmentId, sectionId, subjectId }
    );

    return ApiResponse.success(res, result, 'Assessment closed successfully');
  });

  /**
   * Reviews assessment marks.
   */
  static review = asyncHandler(async (req: Request, res: Response) => {
    const collegeId = (req as any).collegeId || (req as any).user?.collegeId;
    if (!collegeId) throw ApiError.unauthorized('College context missing');

    const assessmentId = req.params.id || req.body.assessmentId;
    const { sectionId, subjectId, comments } = req.body;
    if ((!sectionId || !subjectId) && !assessmentId) {
      throw ApiError.badRequest('sectionId and subjectId or assessmentId are required');
    }

    const result = await InternalAssessmentService.reviewMarks(
      collegeId.toString(),
      (req as any).user,
      { sectionId, subjectId, comments, assessmentId }
    );

    return ApiResponse.success(res, result, 'Assessment marked as reviewed successfully');
  });

  /**
   * Finalizes, locks, and publishes internal assessment marks.
   */
  static publish = asyncHandler(async (req: Request, res: Response) => {
    const collegeId = (req as any).collegeId || (req as any).user?.collegeId;
    if (!collegeId) throw ApiError.unauthorized('College context missing');

    const assessmentId = req.params.id || req.body.assessmentId;
    const { sectionId, subjectId } = req.body;
    if ((!sectionId || !subjectId) && !assessmentId) {
      throw ApiError.badRequest('sectionId and subjectId or assessmentId are required');
    }

    const result = await InternalAssessmentService.publishMarks(
      collegeId.toString(),
      (req as any).user,
      { sectionId, subjectId, assessmentId }
    );

    return ApiResponse.success(res, result, 'Assessment marks published and locked successfully');
  });

  /**
   * Archives an assessment.
   */
  static archive = asyncHandler(async (req: Request, res: Response) => {
    const collegeId = (req as any).collegeId || (req as any).user?.collegeId;
    if (!collegeId) throw ApiError.unauthorized('College context missing');

    const assessmentId = req.params.id || req.body.assessmentId;
    const { sectionId, subjectId } = req.body;

    const result = await InternalAssessmentService.archiveAssessment(
      collegeId.toString(),
      (req as any).user,
      { assessmentId, sectionId, subjectId }
    );

    return ApiResponse.success(res, result, 'Assessment archived successfully');
  });

  /**
   * Unlocks a published assessment for edits (Admin/HOD only).
   */
  static unlock = asyncHandler(async (req: Request, res: Response) => {
    const collegeId = (req as any).collegeId || (req as any).user?.collegeId;
    if (!collegeId) throw ApiError.unauthorized('College context missing');

    const assessmentId = req.params.id || req.body.assessmentId;
    const { sectionId, subjectId, reason } = req.body;
    if ((!sectionId || !subjectId) && !assessmentId) {
      throw ApiError.badRequest('sectionId and subjectId or assessmentId are required');
    }
    if (!reason) {
      throw ApiError.badRequest('reason is required to unlock published marks');
    }

    const result = await InternalAssessmentService.unlockMarks(
      collegeId.toString(),
      (req as any).user,
      { sectionId, subjectId, assessmentId, reason }
    );

    return ApiResponse.success(res, result, 'Assessment unlocked for editing');
  });

  /**
   * Controlled Mark Correction Workflow.
   */
  static correctMark = asyncHandler(async (req: Request, res: Response) => {
    const collegeId = (req as any).collegeId || (req as any).user?.collegeId;
    if (!collegeId) throw ApiError.unauthorized('College context missing');

    const assessmentId = req.params.id || req.body.assessmentId;
    const { sectionId, subjectId, studentId, componentKey, newMark, status, reason } = req.body;

    if (!studentId || newMark === undefined || !reason) {
      throw ApiError.badRequest('studentId, newMark, and reason are required for mark correction');
    }

    const result = await InternalAssessmentService.correctStudentMark(
      collegeId.toString(),
      (req as any).user,
      {
        assessmentId,
        sectionId,
        subjectId,
        studentId,
        componentKey,
        newMark: Number(newMark),
        status,
        reason,
      }
    );

    return ApiResponse.success(res, result, 'Student mark corrected and audited successfully');
  });

  /**
   * Subject Assessment Summary (for AcademicRecord / SubjectAcademicRecord).
   */
  static getSubjectSummary = asyncHandler(async (req: Request, res: Response) => {
    const collegeId = (req as any).collegeId || (req as any).user?.collegeId;
    if (!collegeId) throw ApiError.unauthorized('College context missing');

    const { subjectId, semesterId, studentId } = req.query;
    if (!subjectId || !semesterId) {
      throw ApiError.badRequest('subjectId and semesterId are required query parameters');
    }

    const summary = await InternalAssessmentService.getSubjectAssessmentSummary(
      collegeId.toString(),
      {
        subjectId: subjectId.toString(),
        semesterId: semesterId.toString(),
        studentId: studentId ? studentId.toString() : undefined,
      }
    );

    return ApiResponse.success(res, summary, 'Subject assessment summary retrieved successfully');
  });

  /**
   * Retrieves all published marks for the authenticated student.
   */
  static getStudentMarks = asyncHandler(async (req: Request, res: Response) => {
    const collegeId = (req as any).collegeId || (req as any).user?.collegeId;
    if (!collegeId) throw ApiError.unauthorized('College context missing');

    const { semesterId } = req.query;
    const result = await InternalAssessmentService.getStudentAllMarks(
      collegeId.toString(),
      (req as any).user,
      { semesterId: semesterId ? semesterId.toString() : undefined }
    );

    return ApiResponse.success(res, result, 'Student internal marks retrieved successfully');
  });

  /**
   * Synchronizes aggregated lab and record scores into the internal assessment.
   */
  static syncLab = asyncHandler(async (req: Request, res: Response) => {
    const collegeId = (req as any).collegeId || (req as any).user?.collegeId;
    if (!collegeId) throw ApiError.unauthorized('College context missing');

    const { sectionId, subjectId } = req.body;
    if (!sectionId || !subjectId) {
      throw ApiError.badRequest('sectionId and subjectId are required');
    }

    const result = await InternalAssessmentService.syncLabScoresToAssessment(
      collegeId.toString(),
      (req as any).user,
      { sectionId, subjectId }
    );

    return ApiResponse.success(res, result, 'Lab scores synced to internal assessment');
  });

  /**
   * Creates a lab experiment task.
   */
  static createExperiment = asyncHandler(async (req: Request, res: Response) => {
    const collegeId = (req as any).collegeId || (req as any).user?.collegeId;
    if (!collegeId) throw ApiError.unauthorized('College context missing');

    const experiment = await LabExperimentService.createExperiment(
      collegeId.toString(),
      (req as any).user,
      req.body
    );

    return ApiResponse.created(res, experiment, 'Lab experiment created successfully');
  });

  /**
   * Retrieves lab experiments for a subject and section.
   */
  static getExperiments = asyncHandler(async (req: Request, res: Response) => {
    const collegeId = (req as any).collegeId || (req as any).user?.collegeId;
    if (!collegeId) throw ApiError.unauthorized('College context missing');

    const { sectionId, subjectId } = req.query;
    if (!sectionId || !subjectId) {
      throw ApiError.badRequest('sectionId and subjectId are required');
    }

    const experiments = await LabExperimentService.getExperiments(
      collegeId.toString(),
      (req as any).user,
      { sectionId: sectionId.toString(), subjectId: subjectId.toString() }
    );

    return ApiResponse.success(res, experiments, 'Lab experiments retrieved successfully');
  });

  /**
   * Updates student submissions/verification/grading for a lab experiment.
   */
  static updateExperimentSubmissions = asyncHandler(async (req: Request, res: Response) => {
    const collegeId = (req as any).collegeId || (req as any).user?.collegeId;
    if (!collegeId) throw ApiError.unauthorized('College context missing');

    const { id } = req.params;
    const { updates } = req.body;
    if (!Array.isArray(updates)) {
      throw ApiError.badRequest('updates array is required');
    }

    const experiment = await LabExperimentService.updateSubmissions(
      collegeId.toString(),
      (req as any).user,
      id,
      updates
    );

    return ApiResponse.success(res, experiment, 'Lab submissions updated successfully');
  });
}
