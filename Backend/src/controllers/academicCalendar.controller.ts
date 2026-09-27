import { Request, Response, NextFunction } from 'express';
import { AcademicCalendarService } from '../services/academicCalendar.service';
import { AuthenticatedUser } from '../types/auth.types';

export class AcademicCalendarController {
  static async getCalendar(req: Request, res: Response, Next: NextFunction): Promise<void> {
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
      Next(error);
    }
  }

  static async getEventById(req: Request, res: Response, Next: NextFunction): Promise<void> {
    try {
      const user = req.user as AuthenticatedUser;
      const { id } = req.params;

      const event = await AcademicCalendarService.getEventById(id, user);

      res.status(200).json({
        success: true,
        data: event,
      });
    } catch (error) {
      Next(error);
    }
  }

  static async createEvent(req: Request, res: Response, Next: NextFunction): Promise<void> {
    try {
      const user = req.user as AuthenticatedUser;
      const event = await AcademicCalendarService.createEvent(req.body, user);

      res.status(201).json({
        success: true,
        message: 'Calendar event created successfully',
        data: event,
      });
    } catch (error) {
      Next(error);
    }
  }

  static async updateEvent(req: Request, res: Response, Next: NextFunction): Promise<void> {
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
      Next(error);
    }
  }

  static async cancelEvent(req: Request, res: Response, Next: NextFunction): Promise<void> {
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
      Next(error);
    }
  }

  static async publishEvent(req: Request, res: Response, Next: NextFunction): Promise<void> {
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
      Next(error);
    }
  }
}
