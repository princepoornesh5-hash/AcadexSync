import { Request, Response } from 'express';
import { NotificationService } from '../services/notification.service';
import { ApiResponse } from '../utils/apiResponse';

export class NotificationController {
  static listNotifications = async (req: Request, res: Response): Promise<void> => {
    const result = await NotificationService.listNotifications(
      req.user!.id,
      req.collegeId || 'global',
      req.query as any
    );
    ApiResponse.success(res, result, 'Notifications retrieved successfully');
  };

  static getUnreadCount = async (req: Request, res: Response): Promise<void> => {
    const count = await NotificationService.getUnreadCount(
      req.user!.id,
      req.collegeId || 'global'
    );
    ApiResponse.success(res, { unreadCount: count }, 'Unread count retrieved');
  };

  static getById = async (req: Request, res: Response): Promise<void> => {
    const notification = await NotificationService.getNotificationById(
      req.params.id,
      req.user!.id,
      req.collegeId || 'global'
    );
    ApiResponse.success(res, notification, 'Notification retrieved');
  };

  static markAsRead = async (req: Request, res: Response): Promise<void> => {
    const notification = await NotificationService.markAsRead(
      req.params.id,
      req.user!.id,
      req.collegeId || 'global'
    );
    ApiResponse.success(res, notification, 'Notification marked as read');
  };

  static markAllAsRead = async (req: Request, res: Response): Promise<void> => {
    const result = await NotificationService.markAllAsRead(
      req.user!.id,
      req.collegeId || 'global'
    );
    ApiResponse.success(res, result, 'All notifications marked as read');
  };

  static registerDeviceToken = async (req: Request, res: Response): Promise<void> => {
    const deviceToken = await NotificationService.registerDeviceToken(req.user!.id, {
      ...req.body,
      collegeId: req.collegeId,
    });
    ApiResponse.created(res, deviceToken, 'Device token registered successfully');
  };

  static removeDeviceToken = async (req: Request, res: Response): Promise<void> => {
    await NotificationService.removeDeviceToken(req.user!.id, req.params.token);
    ApiResponse.success(res, null, 'Device token removed successfully');
  };

  static getPreferences = async (req: Request, res: Response): Promise<void> => {
    const preferences = await NotificationService.getPreferences(
      req.user!.id,
      req.collegeId
    );
    ApiResponse.success(res, preferences, 'Notification preferences retrieved');
  };

  static updatePreferences = async (req: Request, res: Response): Promise<void> => {
    const preferences = await NotificationService.updatePreferences(
      req.user!.id,
      req.body,
      req.collegeId
    );
    ApiResponse.success(res, preferences, 'Notification preferences updated');
  };
}
