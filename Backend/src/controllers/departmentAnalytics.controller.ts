import { Request, Response } from 'express';
import { DepartmentAnalyticsService } from '../services/departmentAnalytics.service';
import { ApiResponse } from '../utils/apiResponse';
import { ApiError } from '../utils/apiError';
import { departmentAnalyticsQuerySchema } from '../validations/departmentAnalytics.validation';

export class DepartmentAnalyticsController {
  static getOverview = async (req: Request, res: Response): Promise<Response> => {
    if (!req.user) throw ApiError.unauthorized('Authentication required');
    const query = departmentAnalyticsQuerySchema.parse(req.query);
    const result = await DepartmentAnalyticsService.getDepartmentOverview(req.user, query);
    return ApiResponse.success(res, result);
  };

  static getCourses = async (req: Request, res: Response): Promise<Response> => {
    if (!req.user) throw ApiError.unauthorized('Authentication required');
    const query = departmentAnalyticsQuerySchema.parse(req.query);
    const result = await DepartmentAnalyticsService.getCourseAnalytics(req.user, query);
    return ApiResponse.success(res, result);
  };

  static getSections = async (req: Request, res: Response): Promise<Response> => {
    if (!req.user) throw ApiError.unauthorized('Authentication required');
    const query = departmentAnalyticsQuerySchema.parse(req.query);
    const result = await DepartmentAnalyticsService.getSectionAnalytics(req.user, query);
    return ApiResponse.success(res, result);
  };

  static getSubjects = async (req: Request, res: Response): Promise<Response> => {
    if (!req.user) throw ApiError.unauthorized('Authentication required');
    const query = departmentAnalyticsQuerySchema.parse(req.query);
    const result = await DepartmentAnalyticsService.getSubjectAnalytics(req.user, query);
    return ApiResponse.success(res, result);
  };

  static getStudents = async (req: Request, res: Response): Promise<Response> => {
    if (!req.user) throw ApiError.unauthorized('Authentication required');
    const query = departmentAnalyticsQuerySchema.parse(req.query);
    const result = await DepartmentAnalyticsService.getStudentAnalytics(req.user, query);
    return ApiResponse.success(res, result);
  };

  static getTrends = async (req: Request, res: Response): Promise<Response> => {
    if (!req.user) throw ApiError.unauthorized('Authentication required');
    const query = departmentAnalyticsQuerySchema.parse(req.query);
    const result = await DepartmentAnalyticsService.getTrendAnalytics(req.user, query);
    return ApiResponse.success(res, result);
  };
}
