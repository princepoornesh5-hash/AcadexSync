import { Request, Response } from 'express';
import { NoteService } from '../services/note.service';
import { ApiResponse } from '../utils/apiResponse';
import { ApiError } from '../utils/apiError';
import { AuthenticatedUser } from '../types/auth.types';
import { AppRole } from '../constants/roles';

export class NoteController {
  static async requestUploadUrl(req: Request, res: Response): Promise<void> {
    const user = req.user as AuthenticatedUser;
    const collegeId = user.role === AppRole.SUPER_ADMIN ? (req.body.collegeId || req.collegeId) : req.collegeId;
    if (!collegeId) {
      throw ApiError.badRequest('collegeId is required for note upload');
    }

    const result = await NoteService.requestUploadUrl(collegeId, req.body, user);
    ApiResponse.created(res, result, 'Upload URL generated successfully');
  }

  static async completeUpload(req: Request, res: Response): Promise<void> {
    const user = req.user as AuthenticatedUser;
    const note = await NoteService.completeUpload(req.params.id as string, user, req.body);
    ApiResponse.success(res, note, 'Note upload completed and published successfully');
  }

  static async getDownloadUrl(req: Request, res: Response): Promise<void> {
    const user = req.user as AuthenticatedUser;
    const result = await NoteService.getDownloadUrl(req.params.id as string, user);
    ApiResponse.success(res, result, 'Download URL generated successfully');
  }

  static async requestReplaceUrl(req: Request, res: Response): Promise<void> {
    const user = req.user as AuthenticatedUser;
    const result = await NoteService.requestReplaceUrl(req.params.id as string, req.body, user);
    ApiResponse.success(res, result, 'Replacement upload URL generated successfully');
  }

  static async completeReplace(req: Request, res: Response): Promise<void> {
    const user = req.user as AuthenticatedUser;
    const note = await NoteService.completeReplace(req.params.id as string, req.body, user);
    ApiResponse.success(res, note, 'Note replaced and updated successfully');
  }

  static async listNotes(req: Request, res: Response): Promise<void> {
    const user = req.user as AuthenticatedUser;
    const result = await NoteService.listNotes(user, req.query as any);
    ApiResponse.success(res, result);
  }

  static async getNoteById(req: Request, res: Response): Promise<void> {
    const user = req.user as AuthenticatedUser;
    const note = await NoteService.getNoteById(req.params.id as string, user);
    ApiResponse.success(res, note);
  }

  static async updateNote(req: Request, res: Response): Promise<void> {
    const user = req.user as AuthenticatedUser;
    const note = await NoteService.updateNote(req.params.id as string, req.body, user);
    ApiResponse.success(res, note, 'Note updated successfully');
  }

  static async deleteNote(req: Request, res: Response): Promise<void> {
    const user = req.user as AuthenticatedUser;
    await NoteService.deleteNote(req.params.id as string, user);
    ApiResponse.success(res, null, 'Note deleted successfully');
  }

  static async getStudentNotes(req: Request, res: Response): Promise<void> {
    const user = req.user as AuthenticatedUser;
    const result = await NoteService.getStudentNotes(user, req.query as any);
    ApiResponse.success(res, result);
  }

  static async getSubjectNotes(req: Request, res: Response): Promise<void> {
    const user = req.user as AuthenticatedUser;
    const result = await NoteService.getSubjectNotes(req.params.subjectId as string, user, req.query as any);
    ApiResponse.success(res, result);
  }
}
