import { Request, Response, NextFunction } from 'express';
import { AcademicCalendarService } from '../services/academicCalendar.service';
import { AuthenticatedUser } from '../types/auth.types';

export class AcademicCalendarController {
  static async getCalendar(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const user = req.user as AuthenticatedUser;
      const { startDate, endDate, eventType } = req.query;

      const events = await AcademicCalendarService.getCalendarForUser(user, {
        startDate: startDate as string | undefined,
        endDate: endDate as string | undefined,
        eventType: eventType as string | undefined,
      });

      res.status(200).json({
        success: true,
        data: events,
      });
    } catch (error) {
      next(error);
    }
  }

  static async getEventById(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const user = req.user as AuthenticatedUser;
      const { id } = req.params;

      const event = await AcademicCalendarService.getEventById(id, user);

      res.status(200).json({
        success: true,
        data: event,
      });
    } catch (error) {
      next(error);
    }
  }

  static async createEvent(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const user = req.user as AuthenticatedUser;
      const event = await AcademicCalendarService.createEvent(req.body, user);

      res.status(201).json({
        success: true,
        message: 'Calendar event created successfully',
        data: event,
      });
    } catch (error) {
      next(error);
    }
  }

  static async updateEvent(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const user = req.user as AuthenticatedUser;
      const { id } = req.params;

      const event = await AcademicCalendarService.updateEvent(id, req.body, user);

      res.status(200).json({
        success: true,
        message: 'Calendar event updated successfully',
        data: event,
      });
    } catch (error) {
      next(error);
    }
  }

  static async cancelEvent(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const user = req.user as AuthenticatedUser;
      const { id } = req.params;
      const { reason } = req.body || {};

      const event = await AcademicCalendarService.cancelEvent(id, reason, user);

      res.status(200).json({
        success: true,
        message: 'Calendar event cancelled successfully',
        data: event,
      });
    } catch (error) {
      next(error);
    }
  }

  static async publishEvent(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const user = req.user as AuthenticatedUser;
      const { id } = req.params;

      const event = await AcademicCalendarService.publishEvent(id, user);

      res.status(200).json({
        success: true,
        message: 'Calendar event published successfully',
        data: event,
      });
    } catch (error) {
      next(error);
    }
  }

  // ══════════════════════════════════════════════════════════
  // ACADEMIC CALENDAR CONTROLLER ENDPOINTS (Prompt 45)
  // ══════════════════════════════════════════════════════════

  static async createAcademicCalendar(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const user = req.user as AuthenticatedUser;
      const calendar = await AcademicCalendarService.createAcademicCalendar(req.body, user);

      res.status(201).json({
        success: true,
        message: 'Academic calendar created successfully',
        data: calendar,
      });
    } catch (error) {
      next(error);
    }
  }

  static async listAcademicCalendars(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const user = req.user as AuthenticatedUser;
      const { academicYearId, status, page, limit } = req.query;

      const result = await AcademicCalendarService.listAcademicCalendars(user, {
        academicYearId: academicYearId as string | undefined,
        status: status as any,
        page: page ? parseInt(page as string, 10) : undefined,
        limit: limit ? parseInt(limit as string, 10) : undefined,
      });

      res.status(200).json({
        success: true,
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  static async getAcademicCalendarById(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const user = req.user as AuthenticatedUser;
      const { id } = req.params;

      const calendar = await AcademicCalendarService.getAcademicCalendarById(id, user);

      res.status(200).json({
        success: true,
        data: calendar,
      });
    } catch (error) {
      next(error);
    }
  }

  static async updateAcademicCalendar(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const user = req.user as AuthenticatedUser;
      const { id } = req.params;

      const calendar = await AcademicCalendarService.updateAcademicCalendar(id, req.body, user);

      res.status(200).json({
        success: true,
        message: 'Academic calendar updated successfully',
        data: calendar,
      });
    } catch (error) {
      next(error);
    }
  }

  static async activateAcademicCalendar(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const user = req.user as AuthenticatedUser;
      const { id } = req.params;

      const calendar = await AcademicCalendarService.activateAcademicCalendar(id, user);

      res.status(200).json({
        success: true,
        message: 'Academic calendar activated successfully',
        data: calendar,
      });
    } catch (error) {
      next(error);
    }
  }

  static async closeAcademicCalendar(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const user = req.user as AuthenticatedUser;
      const { id } = req.params;

      const calendar = await AcademicCalendarService.closeAcademicCalendar(id, user);

      res.status(200).json({
        success: true,
        message: 'Academic calendar closed successfully',
        data: calendar,
      });
    } catch (error) {
      next(error);
    }
  }

  static async declareHoliday(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const user = req.user as AuthenticatedUser;
      const result = await AcademicCalendarService.declareHoliday(req.body, user);

      res.status(201).json({
        success: true,
        message: 'Holiday declared successfully',
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  static async resolveWorkingDay(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const user = req.user as AuthenticatedUser;
      const collegeId = user.collegeId ? user.collegeId.toString() : '';
      const { date, departmentId, courseId } = req.query;

      if (!date || typeof date !== 'string') {
        res.status(400).json({ success: false, message: 'date query parameter is required (YYYY-MM-DD)' });
        return;
      }

      const status = await AcademicCalendarService.resolveWorkingDay(collegeId, date, {
        departmentId: departmentId as string | undefined,
        courseId: courseId as string | undefined,
      });

      res.status(200).json({
        success: true,
        data: status,
      });
    } catch (error) {
      next(error);
    }
  }
}
