import { Request, Response } from 'express';
import { InternalAssessmentService } from '../services/internalAssessment.service';
import { LabExperimentService } from '../services/labExperiment.service';
import { ApiError } from '../utils/apiError';
import { ApiResponse } from '../utils/apiResponse';
import { asyncHandler } from '../utils/asyncHandler';

export class InternalAssessmentController {
  /**
   * Retrieves or initializes assessment context for a subject and section, or by assessmentId.
   */
  static getContext = asyncHandler(async (req: Request, res: Response) => {
    const collegeId = (req as any).collegeId || (req as any).user?.collegeId;
    if (!collegeId) throw ApiError.unauthorized('College context missing');

    const { sectionId, subjectId, academicYearId, assessmentId, facultyAssignmentId } = req.query;
    if (!assessmentId && !facultyAssignmentId && (!sectionId || !subjectId)) {
      throw ApiError.badRequest('Either assessmentId, facultyAssignmentId, or both sectionId and subjectId are required');
    }

    const context = await InternalAssessmentService.getAssessmentContext(
      collegeId.toString(),
      (req as any).user,
      {
        sectionId: sectionId ? sectionId.toString() : undefined,
        subjectId: subjectId ? subjectId.toString() : undefined,
        academicYearId: academicYearId ? academicYearId.toString() : undefined,
        assessmentId: assessmentId ? assessmentId.toString() : undefined,
        facultyAssignmentId: facultyAssignmentId ? facultyAssignmentId.toString() : undefined,
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
   * Retrieves comprehensive student assessment history for an authorized user/staff.
   */
  static getStudentAssessmentHistory = asyncHandler(async (req: Request, res: Response) => {
    const collegeId = (req as any).collegeId || (req as any).user?.collegeId;
    if (!collegeId) throw ApiError.unauthorized('College context missing');

    const { semesterId, subjectId } = req.query;
    const targetStudentId = req.params.studentId || (req as any).user?.id;

    const result = await InternalAssessmentService.getStudentAssessmentHistory(
      collegeId.toString(),
      (req as any).user,
      targetStudentId,
      {
        semesterId: semesterId ? semesterId.toString() : undefined,
        subjectId: subjectId ? subjectId.toString() : undefined,
      }
    );

    return ApiResponse.success(res, result, 'Student assessment history retrieved successfully');
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

  /**
   * Lists accessible assessments matching filters for the college.
   */
  static listAssessments = asyncHandler(async (req: Request, res: Response) => {
    const collegeId = (req as any).collegeId || (req as any).user?.collegeId;
    if (!collegeId) throw ApiError.unauthorized('College context missing');

    const {
      facultyAssignmentId,
      sectionId,
      subjectId,
      semesterId,
      academicYearId,
      status,
      assessmentType,
    } = req.query;

    const items = await InternalAssessmentService.listAssessments(
      collegeId.toString(),
      (req as any).user,
      {
        facultyAssignmentId: facultyAssignmentId ? facultyAssignmentId.toString() : undefined,
        sectionId: sectionId ? sectionId.toString() : undefined,
        subjectId: subjectId ? subjectId.toString() : undefined,
        semesterId: semesterId ? semesterId.toString() : undefined,
        academicYearId: academicYearId ? academicYearId.toString() : undefined,
        status: status as any,
        assessmentType: assessmentType as any,
      }
    );

    return ApiResponse.success(res, items, 'Assessments retrieved successfully');
  });

  /**
   * Retrieves an Assessment by ID, including its schedule.
   */
  static getAssessmentById = asyncHandler(async (req: Request, res: Response) => {
    const collegeId = (req as any).collegeId || (req as any).user?.collegeId;
    if (!collegeId) throw ApiError.unauthorized('College context missing');

    const result = await InternalAssessmentService.getAssessmentById(
      collegeId.toString(),
      (req as any).user,
      req.params.id
    );

    return ApiResponse.success(res, result, 'Assessment details retrieved successfully');
  });

  /**
   * Updates an existing assessment's metadata.
   */
  static updateAssessment = asyncHandler(async (req: Request, res: Response) => {
    const collegeId = (req as any).collegeId || (req as any).user?.collegeId;
    if (!collegeId) throw ApiError.unauthorized('College context missing');

    const result = await InternalAssessmentService.updateAssessment(
      collegeId.toString(),
      (req as any).user,
      req.params.id,
      req.body
    );

    return ApiResponse.success(res, result, 'Assessment updated successfully');
  });

  /**
   * Schedules a date-specific assessment occurrence.
   */
  static scheduleAssessment = asyncHandler(async (req: Request, res: Response) => {
    const collegeId = (req as any).collegeId || (req as any).user?.collegeId;
    if (!collegeId) throw ApiError.unauthorized('College context missing');

    const assessmentId = req.params.id || req.body.assessmentId;
    if (!assessmentId) throw ApiError.badRequest('assessmentId is required');

    const result = await InternalAssessmentService.scheduleAssessment(
      collegeId.toString(),
      (req as any).user,
      {
        ...req.body,
        assessmentId,
      }
    );

    return ApiResponse.success(res, result, 'Assessment scheduled successfully');
  });

  /**
   * Retrieves an assessment's date-specific schedule.
   */
  static getAssessmentSchedule = asyncHandler(async (req: Request, res: Response) => {
    const collegeId = (req as any).collegeId || (req as any).user?.collegeId;
    if (!collegeId) throw ApiError.unauthorized('College context missing');

    const result = await InternalAssessmentService.getAssessmentSchedule(
      collegeId.toString(),
      req.params.id
    );

    return ApiResponse.success(res, result, 'Assessment schedule retrieved successfully');
  });

  /**
   * Cancels an assessment schedule.
   */
  static cancelAssessmentSchedule = asyncHandler(async (req: Request, res: Response) => {
    const collegeId = (req as any).collegeId || (req as any).user?.collegeId;
    if (!collegeId) throw ApiError.unauthorized('College context missing');

    const result = await InternalAssessmentService.cancelAssessmentSchedule(
      collegeId.toString(),
      (req as any).user,
      req.params.id
    );

    return ApiResponse.success(res, result, 'Assessment schedule cancelled successfully');
  });

  /**
   * Retrieves date-specific exam timetable across sections/semesters.
   */
  static getExamTimetable = asyncHandler(async (req: Request, res: Response) => {
    const collegeId = (req as any).collegeId || (req as any).user?.collegeId;
    if (!collegeId) throw ApiError.unauthorized('College context missing');

    const { sectionId, semesterId, dateFrom, dateTo } = req.query;

    const result = await InternalAssessmentService.getExamTimetable(
      collegeId.toString(),
      {
        sectionId: sectionId ? sectionId.toString() : undefined,
        semesterId: semesterId ? semesterId.toString() : undefined,
        dateFrom: dateFrom ? dateFrom.toString() : undefined,
        dateTo: dateTo ? dateTo.toString() : undefined,
      }
    );

    return ApiResponse.success(res, result, 'Exam timetable retrieved successfully');
  });

  /**
   * Executes idempotent canonical migration from embedded marks to AssessmentMark.
   */
  static runMigration = asyncHandler(async (req: Request, res: Response) => {
    const collegeId = (req as any).collegeId || (req as any).user?.collegeId;
    if (!collegeId) throw ApiError.unauthorized('College context missing');

    const dryRun = req.query.dryRun !== 'false' && req.body.dryRun !== false;

    const result = await InternalAssessmentService.runMigration(
      collegeId.toString(),
      dryRun
    );

    return ApiResponse.success(
      res,
      result,
      `Assessment migration ${dryRun ? 'preview (dry-run)' : 'completed'} successfully`
    );
  });

  /**
   * Retrieves the authoritative marks roster for an assessment.
   */
  static getRoster = asyncHandler(async (req: Request, res: Response) => {
    const collegeId = (req as any).collegeId || (req as any).user?.collegeId;
    if (!collegeId) throw ApiError.unauthorized('College context missing');

    const assessmentId = req.params.id || req.query.assessmentId;
    if (!assessmentId) throw ApiError.badRequest('assessmentId is required');

    const result = await InternalAssessmentService.getMarksRoster(
      collegeId.toString(),
      (req as any).user,
      assessmentId.toString()
    );

    return ApiResponse.success(res, result, 'Marks roster retrieved successfully');
  });

  /**
   * Explicitly completes an assessment when the scheduled exam finishes.
   */
  static complete = asyncHandler(async (req: Request, res: Response) => {
    const collegeId = (req as any).collegeId || (req as any).user?.collegeId;
    if (!collegeId) throw ApiError.unauthorized('College context missing');

    const assessmentId = req.params.id || req.body.assessmentId;
    if (!assessmentId) throw ApiError.badRequest('assessmentId is required');

    const result = await InternalAssessmentService.completeAssessment(
      collegeId.toString(),
      (req as any).user,
      assessmentId.toString()
    );

    return ApiResponse.success(res, result, 'Assessment marked as completed. Marks entry opened.');
  });

  /**
   * Submits marks and transitions assessment to SUBMITTED.
   */
  static submit = asyncHandler(async (req: Request, res: Response) => {
    const collegeId = (req as any).collegeId || (req as any).user?.collegeId;
    if (!collegeId) throw ApiError.unauthorized('College context missing');

    const assessmentId = req.params.id || req.body.assessmentId;
    if (!assessmentId) throw ApiError.badRequest('assessmentId is required');

    const result = await InternalAssessmentService.submitMarks(
      collegeId.toString(),
      (req as any).user,
      assessmentId.toString(),
      req.body
    );

    return ApiResponse.success(res, result, result.message || 'Assessment marks submitted successfully');
  });

  /**
   * Locks an assessment and all underlying marks against direct edits.
   */
  static lock = asyncHandler(async (req: Request, res: Response) => {
    const collegeId = (req as any).collegeId || (req as any).user?.collegeId;
    if (!collegeId) throw ApiError.unauthorized('College context missing');

    const assessmentId = req.params.id || req.body.assessmentId;
    if (!assessmentId) throw ApiError.badRequest('assessmentId is required');

    const result = await InternalAssessmentService.lockAssessment(
      collegeId.toString(),
      (req as any).user,
      assessmentId.toString()
    );

    return ApiResponse.success(res, result, 'Assessment finalized and locked successfully');
  });

  /**
   * Retrieves summary submission and lock state of an assessment.
   */
  static getSubmissionState = asyncHandler(async (req: Request, res: Response) => {
    const collegeId = (req as any).collegeId || (req as any).user?.collegeId;
    if (!collegeId) throw ApiError.unauthorized('College context missing');

    const assessmentId = req.params.id || req.query.assessmentId;
    if (!assessmentId) throw ApiError.badRequest('assessmentId is required');

    const result = await InternalAssessmentService.getAssessmentSubmissionState(
      collegeId.toString(),
      (req as any).user,
      assessmentId.toString()
    );

    return ApiResponse.success(res, result, 'Assessment submission state retrieved successfully');
  });

  /**
   * Requests a mark correction via the canonical Request architecture.
   */
  static requestCorrection = asyncHandler(async (req: Request, res: Response) => {
    const collegeId = (req as any).collegeId || (req as any).user?.collegeId;
    if (!collegeId) throw ApiError.unauthorized('College context missing');

    const assessmentId = req.params.id || req.body.assessmentId;
    if (!assessmentId) throw ApiError.badRequest('assessmentId is required');

    const result = await InternalAssessmentService.requestAssessmentCorrection(
      collegeId.toString(),
      (req as any).user,
      {
        ...req.body,
        assessmentId: assessmentId.toString(),
      }
    );

    return ApiResponse.created(res, result, 'Mark correction request submitted successfully');
  });

  /**
   * Responds to a mark correction request (Approve/Reject).
   */
  static respondCorrection = asyncHandler(async (req: Request, res: Response) => {
    const collegeId = (req as any).collegeId || (req as any).user?.collegeId;
    if (!collegeId) throw ApiError.unauthorized('College context missing');

    const requestId = req.params.requestId || req.body.requestId;
    if (!requestId) throw ApiError.badRequest('requestId is required');

    const rawAction = ((req.body.action || '') as string).trim().toUpperCase();
    if (!rawAction.startsWith('APPROV') && !rawAction.startsWith('REJECT')) {
      throw ApiError.badRequest("action must be either 'APPROVED' or 'REJECTED'");
    }
    const action: 'APPROVED' | 'REJECTED' = rawAction.startsWith('APPROV') ? 'APPROVED' : 'REJECTED';

    const result = await InternalAssessmentService.respondAssessmentCorrection(
      collegeId.toString(),
      (req as any).user,
      requestId.toString(),
      action,
      req.body.message
    );

    return ApiResponse.success(
      res,
      result,
      `Correction request ${action === 'APPROVED' ? 'approved and assessment unlocked for correction' : 'rejected'}`
    );
  });

  /**
   * Previews eligible students and detects duplicate students across multi-department scopes.
   */
  static previewScope = asyncHandler(async (req: Request, res: Response) => {
    const collegeId = (req as any).collegeId || (req as any).user?.collegeId;
    if (!collegeId) throw ApiError.unauthorized('College context missing');

    const result = await InternalAssessmentService.previewScope(
      collegeId.toString(),
      (req as any).user,
      req.body
    );

    return ApiResponse.success(res, result, 'Assessment scope preview generated successfully');
  });

  /**
   * Real-time schedule conflict check for rooms, invigilators, and academic sections.
   */
  static checkScheduleConflicts = asyncHandler(async (req: Request, res: Response) => {
    const collegeId = (req as any).collegeId || (req as any).user?.collegeId;
    if (!collegeId) throw ApiError.unauthorized('College context missing');

    const result = await InternalAssessmentService.checkScheduleConflicts(
      collegeId.toString(),
      (req as any).user,
      req.body
    );

    return ApiResponse.success(res, result, 'Schedule conflicts analyzed successfully');
  });

  /**
   * Publishes an assessment schedule to students and emits targeted notifications.
   */
  static publishAssessment = asyncHandler(async (req: Request, res: Response) => {
    const collegeId = (req as any).collegeId || (req as any).user?.collegeId;
    if (!collegeId) throw ApiError.unauthorized('College context missing');

    const assessmentId = req.params.id || req.body.assessmentId;
    if (!assessmentId) throw ApiError.badRequest('Assessment ID is required');

    const result = await InternalAssessmentService.publishAssessment(
      collegeId.toString(),
      (req as any).user,
      assessmentId.toString()
    );

    return ApiResponse.success(res, result, 'Assessment published to students successfully');
  });
}
