import { Request, Response, NextFunction } from 'express';
import { DashboardService } from '../services/dashboard.service';
import { AuthenticatedUser } from '../types/auth.types';

export class DashboardController {
  /**
   * GET /api/v1/dashboard/home
   * Canonical role-aware operational home aggregation endpoint.
   */
  static async getHomeDashboard(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const user = req.user as AuthenticatedUser;
      const date = req.query.date as string | undefined;

      const dashboard = await DashboardService.getHomeDashboard(user, { date });

      res.status(200).json({
        success: true,
        data: dashboard,
      });
    } catch (error) {
      next(error);
    }
  }
}
