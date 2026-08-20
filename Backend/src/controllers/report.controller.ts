import { Request, Response } from 'express';
import { ReportService } from '../services/report.service';
import { ApiResponse } from '../utils/apiResponse';
import { AuthenticatedUser } from '../types/auth.types';

export class ReportController {
  static getDashboard = async (req: Request, res: Response): Promise<void> => {
    const requester = req.user as AuthenticatedUser;
    const report = await ReportService.getDashboard(requester, req.query as any);
    ApiResponse.success(res, report, 'Dashboard report retrieved successfully');
  };

  static getMyAttendanceReport = async (req: Request, res: Response): Promise<void> => {
    const requester = req.user as AuthenticatedUser;
    const report = await ReportService.getStudentAttendanceReport('me', requester, req.query as any);
    ApiResponse.success(res, report, 'Student personal attendance report retrieved successfully');
  };

  static getStudentAttendanceReport = async (req: Request, res: Response): Promise<void> => {
    const requester = req.user as AuthenticatedUser;
    const report = await ReportService.getStudentAttendanceReport(req.params.studentId, requester, req.query as any);
    ApiResponse.success(res, report, 'Student attendance report retrieved successfully');
  };

  static getSectionAttendanceReport = async (req: Request, res: Response): Promise<void> => {
    const requester = req.user as AuthenticatedUser;
    const report = await ReportService.getSectionAttendanceReport(req.params.sectionId, requester, req.query as any);
    ApiResponse.success(res, report, 'Section attendance report retrieved successfully');
  };

  static getDepartmentAttendanceReport = async (req: Request, res: Response): Promise<void> => {
    const requester = req.user as AuthenticatedUser;
    const report = await ReportService.getDepartmentAttendanceReport(req.params.departmentId, requester, req.query as any);
    ApiResponse.success(res, report, 'Department attendance report retrieved successfully');
  };

  static getCollegeAttendanceReport = async (req: Request, res: Response): Promise<void> => {
    const requester = req.user as AuthenticatedUser;
    const report = await ReportService.getCollegeAttendanceReport(req.params.collegeId, requester, req.query as any);
    ApiResponse.success(res, report, 'College attendance report retrieved successfully');
  };

  static getSubjectAttendanceReport = async (req: Request, res: Response): Promise<void> => {
    const requester = req.user as AuthenticatedUser;
    const report = await ReportService.getSubjectAttendanceReport(req.params.subjectId, requester, req.query as any);
    ApiResponse.success(res, report, 'Subject attendance report retrieved successfully');
  };

  static getFacultyReport = async (req: Request, res: Response): Promise<void> => {
    const requester = req.user as AuthenticatedUser;
    const report = await ReportService.getFacultyReport(req.params.facultyId, requester, req.query as any);
    ApiResponse.success(res, report, 'Faculty activity report retrieved successfully');
  };

  static getAcademicReport = async (req: Request, res: Response): Promise<void> => {
    const requester = req.user as AuthenticatedUser;
    const report = await ReportService.getAcademicReport(requester, req.query as any);
    ApiResponse.success(res, report, 'Academic hierarchy report retrieved successfully');
  };

  static getNotesReport = async (req: Request, res: Response): Promise<void> => {
    const requester = req.user as AuthenticatedUser;
    const report = await ReportService.getNotesReport(requester, req.query as any);
    ApiResponse.success(res, report, 'Notes analytics report retrieved successfully');
  };
}
