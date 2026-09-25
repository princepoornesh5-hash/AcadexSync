import { Request, Response } from 'express';
import { AnnouncementService } from '../services/announcement.service';
import { ApiResponse } from '../utils/apiResponse';

export class AnnouncementController {
  static createAnnouncement = async (req: Request, res: Response): Promise<void> => {
    const announcement = await AnnouncementService.createAnnouncement(req.body, req.user!);
    ApiResponse.created(res, announcement, 'Announcement created successfully');
  };

  static listAnnouncements = async (req: Request, res: Response): Promise<void> => {
    const result = await AnnouncementService.listAnnouncements(req.query as any, req.user!);
    ApiResponse.success(res, result, 'Announcements retrieved successfully');
  };

  static getById = async (req: Request, res: Response): Promise<void> => {
    const announcement = await AnnouncementService.getAnnouncementById(req.params.id, req.user!);
    ApiResponse.success(res, announcement, 'Announcement retrieved successfully');
  };

  static updateAnnouncement = async (req: Request, res: Response): Promise<void> => {
    const announcement = await AnnouncementService.updateAnnouncement(req.params.id, req.body, req.user!);
    ApiResponse.success(res, announcement, 'Announcement updated successfully');
  };

  static publishAnnouncement = async (req: Request, res: Response): Promise<void> => {
    const announcement = await AnnouncementService.publishAnnouncement(req.params.id, req.user!);
    ApiResponse.success(res, announcement, 'Announcement published successfully');
  };

  static archiveAnnouncement = async (req: Request, res: Response): Promise<void> => {
    const announcement = await AnnouncementService.archiveAnnouncement(req.params.id, req.user!);
    ApiResponse.success(res, announcement, 'Announcement archived successfully');
  };

  static deleteAnnouncement = async (req: Request, res: Response): Promise<void> => {
    await AnnouncementService.deleteAnnouncement(req.params.id, req.user!);
    ApiResponse.success(res, null, 'Announcement deleted successfully');
  };
}
