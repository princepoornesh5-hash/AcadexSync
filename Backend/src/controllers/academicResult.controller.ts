import { Request, Response } from 'express';
import { AcademicResultService } from '../services/academicResult.service';
import { AcademicRuleConfiguration } from '../models';

export class AcademicResultController {
  /**
   * GET /api/v1/academic-results/rules
   */
  static async getRuleConfig(req: Request, res: Response): Promise<void> {
    try {
      const collegeId = (req as any).user.collegeId;
      const courseId = req.query.courseId as string;
      const rule = await AcademicResultService.getEffectiveRuleConfig(collegeId, courseId);
      res.status(200).json({
        success: true,
        data: rule,
      });
    } catch (err: any) {
      res.status(400).json({ success: false, message: err.message });
    }
  }

  /**
   * POST /api/v1/academic-results/rules
   */
  static async saveRuleConfig(req: Request, res: Response): Promise<void> {
    try {
      const collegeId = (req as any).user.collegeId;
      const userId = (req as any).user.id;
      const body = req.body;

      let rule = await AcademicRuleConfiguration.findOne({
        collegeId,
        courseId: body.courseId || null,
      });

      if (!rule) {
        rule = await AcademicRuleConfiguration.create({
          ...body,
          collegeId,
          createdBy: userId,
          updatedBy: userId,
        });
      } else {
        Object.assign(rule, body, { updatedBy: userId });
        await rule.save();
      }

      res.status(200).json({
        success: true,
        message: 'Academic rule configuration saved successfully.',
        data: rule,
      });
    } catch (err: any) {
      res.status(400).json({ success: false, message: err.message });
    }
  }

  /**
   * POST /api/v1/academic-results/calculate
   */
  static async calculateSemesterResult(req: Request, res: Response): Promise<void> {
    try {
      const collegeId = (req as any).user.collegeId;
      const user = (req as any).user;
      const { studentId, semesterId, academicYearId, courseId } = req.body;

      const { result, warnings } = await AcademicResultService.calculateSemesterResult({
        collegeId,
        studentId,
        semesterId,
        academicYearId,
        courseId,
        user,
      });

      res.status(200).json({
        success: true,
        message: 'Semester result calculated successfully.',
        data: result,
        warnings,
      });
    } catch (err: any) {
      res.status(400).json({ success: false, message: err.message });
    }
  }

  /**
   * POST /api/v1/academic-results/calculate/class
   */
  static async calculateClassResults(req: Request, res: Response): Promise<void> {
    try {
      const collegeId = (req as any).user.collegeId;
      const user = (req as any).user;
      const { courseId, semesterId, academicYearId, sectionId } = req.body;

      const batchSummary = await AcademicResultService.calculateClassResults({
        collegeId,
        courseId,
        semesterId,
        academicYearId,
        sectionId,
        user,
      });

      res.status(200).json({
        success: true,
        message: `Processed ${batchSummary.calculatedCount} student results for class.`,
        data: batchSummary,
      });
    } catch (err: any) {
      res.status(400).json({ success: false, message: err.message });
    }
  }

  /**
   * POST /api/v1/academic-results/:id/review
   */
  static async reviewResult(req: Request, res: Response): Promise<void> {
    try {
      const collegeId = (req as any).user.collegeId;
      const user = (req as any).user;
      const resultId = req.params.id;
      const { reviewNotes } = req.body;

      const updated = await AcademicResultService.reviewResult({
        collegeId,
        resultId,
        user,
        reviewNotes,
      });

      res.status(200).json({
        success: true,
        message: 'Result marked as under review.',
        data: updated,
      });
    } catch (err: any) {
      res.status(400).json({ success: false, message: err.message });
    }
  }

  /**
   * POST /api/v1/academic-results/:id/finalize
   */
  static async finalizeResult(req: Request, res: Response): Promise<void> {
    try {
      const collegeId = (req as any).user.collegeId;
      const user = (req as any).user;
      const resultId = req.params.id;
      const { reviewNotes } = req.body;

      const updated = await AcademicResultService.finalizeResult({
        collegeId,
        resultId,
        user,
        reviewNotes,
      });

      res.status(200).json({
        success: true,
        message: 'Academic result successfully finalized and locked.',
        data: updated,
      });
    } catch (err: any) {
      res.status(400).json({ success: false, message: err.message });
    }
  }

  /**
   * POST /api/v1/academic-results/:id/publish
   */
  static async publishResult(req: Request, res: Response): Promise<void> {
    try {
      const collegeId = (req as any).user.collegeId;
      const user = (req as any).user;
      const resultId = req.params.id;
      const { publicationNotes } = req.body;

      const updated = await AcademicResultService.publishResult({
        collegeId,
        resultId,
        user,
        publicationNotes,
      });

      res.status(200).json({
        success: true,
        message: 'Academic result officially published to student.',
        data: updated,
      });
    } catch (err: any) {
      res.status(400).json({ success: false, message: err.message });
    }
  }

  /**
   * POST /api/v1/academic-results/:id/reopen
   */
  static async reopenResult(req: Request, res: Response): Promise<void> {
    try {
      const collegeId = (req as any).user.collegeId;
      const user = (req as any).user;
      const resultId = req.params.id;
      const { reason } = req.body;

      const updated = await AcademicResultService.reopenResult({
        collegeId,
        resultId,
        user,
        reason,
      });

      res.status(200).json({
        success: true,
        message: 'Academic result reopened for authorized correction.',
        data: updated,
      });
    } catch (err: any) {
      res.status(400).json({ success: false, message: err.message });
    }
  }

  /**
   * GET /api/v1/academic-results/student/my-result
   */
  static async getStudentOfficialResult(req: Request, res: Response): Promise<void> {
    try {
      const collegeId = (req as any).user.collegeId;
      const studentUserId = (req as any).user.id;
      const semesterId = req.query.semesterId as string;
      const academicYearId = req.query.academicYearId as string;

      const data = await AcademicResultService.getStudentOfficialResult({
        collegeId,
        studentUserId,
        semesterId,
        academicYearId,
      });

      res.status(200).json({
        success: true,
        data,
      });
    } catch (err: any) {
      res.status(400).json({ success: false, message: err.message });
    }
  }

  /**
   * GET /api/v1/academic-results
   */
  static async queryAdminResults(req: Request, res: Response): Promise<void> {
    try {
      const collegeId = (req as any).user.collegeId;
      const user = (req as any).user;

      const data = await AcademicResultService.queryAdminResults({
        collegeId,
        user,
        courseId: req.query.courseId as string,
        semesterId: req.query.semesterId as string,
        academicYearId: req.query.academicYearId as string,
        departmentId: req.query.departmentId as string,
        sectionId: req.query.sectionId as string,
        status: req.query.status as any,
        studentId: req.query.studentId as string,
        page: req.query.page ? Number(req.query.page) : 1,
        limit: req.query.limit ? Number(req.query.limit) : 50,
      });

      res.status(200).json({
        success: true,
        data: data.results,
        pagination: data.pagination,
        metrics: data.metrics,
      });
    } catch (err: any) {
      res.status(400).json({ success: false, message: err.message });
    }
  }

  /**
   * GET /api/v1/academic-results/:id
   */
  static async getResultDetail(req: Request, res: Response): Promise<void> {
    try {
      const collegeId = (req as any).user.collegeId;
      const resultId = req.params.id;

      const result = await AcademicResultService.getResultDetail(collegeId, resultId);

      res.status(200).json({
        success: true,
        data: result,
      });
    } catch (err: any) {
      res.status(400).json({ success: false, message: err.message });
    }
  }
}
