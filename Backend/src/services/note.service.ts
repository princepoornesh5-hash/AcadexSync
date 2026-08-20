import mongoose from 'mongoose';
import { Note, INote } from '../models/note.model';
import { Subject } from '../models/subject.model';
import { Faculty } from '../models/faculty.model';
import { Student } from '../models/student.model';
import { AuditLog } from '../models/auditLog.model';
import { ImageKitService } from '../storage/imagekit.service';
import { ImageKitAuthParams } from '../storage/imagekit.types';
import { AppRole } from '../constants/roles';
import {
  NoteStatus,
  NoteType,
  NoteLifecycleState,
  NoteVisibility,
  ResourceType,
} from '../constants/status';
import { StudentEnrollment } from '../models/studentEnrollment.model';
import { NotificationService } from './notification.service';
import { NotificationType, NotificationCategory } from '../constants/notification.constants';
import { logger } from '../utils/logger';
import { ApiError } from '../utils/apiError';
import { AuthenticatedUser } from '../types/auth.types';

export class NoteService {
  // =========================================================================
  // 1. REQUEST UPLOAD URL / AUTHENTICATION (INITIALIZE NOTE)
  // =========================================================================

  static async requestUploadUrl(
    collegeId: string,
    data: {
      departmentId?: string;
      courseId?: string;
      academicYearId?: string;
      semesterId?: string;
      sectionId?: string;
      subjectId: string;
      title: string;
      description?: string;
      noteType?: NoteType;
      visibility?: NoteVisibility;
      fileName: string;
      mimeType: string;
      fileSize: number;
      chapter?: string;
    },
    requester: AuthenticatedUser
  ): Promise<{
    note: INote;
    uploadAuth: ImageKitAuthParams;
    uploadUrl: string;
    storageKey: string;
    fileId: string;
    expiresInSeconds: number;
  }> {
    if (![AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN, AppRole.HOD, AppRole.FACULTY].includes(requester.role)) {
      throw ApiError.forbidden('Students do not have permission to upload academic notes');
    }

    if (requester.role === AppRole.COLLEGE_ADMIN && requester.collegeId !== collegeId) {
      throw ApiError.forbidden('Cross-college upload request is strictly prohibited');
    }

    // Validate MIME and Extension
    const { valid, normalizedExtension, error } = ImageKitService.validateMimeAndExtension(data.mimeType, data.fileName);
    if (!valid) {
      throw ApiError.badRequest(error || 'Invalid file type');
    }

    // Validate Subject & Academic Hierarchy
    if (!mongoose.Types.ObjectId.isValid(data.subjectId)) throw ApiError.badRequest('Invalid subjectId');
    const subject = await Subject.findById(data.subjectId);
    if (!subject) throw ApiError.notFound('Subject not found');

    if (subject.collegeId.toString() !== collegeId) {
      throw ApiError.forbidden('Subject belongs to another college');
    }
    if (!subject.isActive || (subject as any).status === 'inactive') {
      throw ApiError.forbidden('Cannot upload notes for an inactive subject');
    }

    // Check Department scope for HOD / Faculty
    if (requester.role === AppRole.HOD && requester.departmentId && subject.departmentId.toString() !== requester.departmentId) {
      throw ApiError.forbidden('HOD can only upload notes within their assigned department');
    }

    let facultyDoc: InstanceType<typeof Faculty> | null = null;
    if (requester.role === AppRole.FACULTY) {
      facultyDoc = await Faculty.findOne({ userId: requester.id });
      if (facultyDoc && facultyDoc.departmentId.toString() !== subject.departmentId.toString()) {
        throw ApiError.forbidden('Faculty cannot upload notes for subjects in another department');
      }
    }

    const noteId = new mongoose.Types.ObjectId();
    const courseId = subject.courseId ? subject.courseId.toString() : data.courseId || '';
    const semesterId = subject.semesterId.toString();
    const departmentId = subject.departmentId.toString();

    const folder = ImageKitService.buildNoteFolder(
      collegeId,
      courseId,
      semesterId,
      subject.id,
      noteId.toString()
    );

    const authParams = ImageKitService.getAuthenticationParameters(folder, data.fileName, data.fileSize);
    const storageKey = `${folder}/${data.fileName.trim()}`;

    const note = await Note.create({
      _id: noteId,
      collegeId: new mongoose.Types.ObjectId(collegeId),
      departmentId: new mongoose.Types.ObjectId(departmentId),
      courseId: courseId ? new mongoose.Types.ObjectId(courseId) : null,
      academicYearId: data.academicYearId ? new mongoose.Types.ObjectId(data.academicYearId) : null,
      semesterId: new mongoose.Types.ObjectId(semesterId),
      sectionId: data.sectionId ? new mongoose.Types.ObjectId(data.sectionId) : null,
      subjectId: subject._id,
      facultyId: facultyDoc ? facultyDoc._id : null,
      authorUserId: new mongoose.Types.ObjectId(requester.id),
      title: data.title.trim(),
      description: (data.description || '').trim(),
      noteType: data.noteType || NoteType.STUDY_MATERIAL,
      visibility: data.visibility || NoteVisibility.PUBLIC,
      lifecycleState: NoteLifecycleState.PENDING_UPLOAD,
      status: NoteStatus.DRAFT,
      resourceType: ResourceType.FILE_ATTACHMENT,
      storageProvider: 'imagekit',
      originalFileName: data.fileName.trim(),
      storageKey,
      fileId: authParams.fileId,
      mimeType: data.mimeType.toLowerCase(),
      fileExtension: normalizedExtension,
      fileSize: data.fileSize,
      chapter: data.chapter?.trim() || null,
      version: 1,
      previousVersions: [],
    });

    await AuditLog.create({
      collegeId,
      actorUserId: requester.id,
      action: 'NOTE_UPLOAD_REQUESTED',
      entityType: 'Note',
      entityId: note.id,
      newValue: {
        title: note.title,
        subjectId: note.subjectId.toString(),
        storageKey,
        storageProvider: 'imagekit',
      },
    });

    return {
      note,
      uploadAuth: authParams,
      uploadUrl: authParams.urlEndpoint,
      storageKey,
      fileId: authParams.fileId,
      expiresInSeconds: authParams.expiresInSeconds,
    };
  }

  // =========================================================================
  // 2. COMPLETE UPLOAD (VERIFY IMAGEKIT OBJECT)
  // =========================================================================

  static async completeUpload(
    noteId: string,
    requester: AuthenticatedUser,
    clientData?: { fileId?: string; fileUrl?: string; thumbnailUrl?: string }
  ): Promise<INote> {
    if (!mongoose.Types.ObjectId.isValid(noteId)) throw ApiError.badRequest('Invalid noteId');
    const note = await Note.findById(noteId);
    if (!note) throw ApiError.notFound('Note not found');

    if (requester.role !== AppRole.SUPER_ADMIN && note.collegeId.toString() !== requester.collegeId) {
      throw ApiError.forbidden('Cross-college access is strictly prohibited');
    }

    if (
      requester.role === AppRole.FACULTY &&
      note.authorUserId.toString() !== requester.id
    ) {
      throw ApiError.forbidden('Unauthorized to complete upload for this note');
    }

    // Verify object exists in ImageKit
    const fileIdToVerify = clientData?.fileId || note.fileId;
    const fileMeta = await ImageKitService.getFileDetails(fileIdToVerify);
    if (!fileMeta) {
      note.lifecycleState = NoteLifecycleState.FAILED;
      await note.save();
      throw ApiError.badRequest('Uploaded file was not found in storage. Please upload the file first.');
    }

    note.fileId = fileMeta.fileId;
    note.fileUrl = fileMeta.url || clientData?.fileUrl || note.fileUrl;
    note.thumbnailUrl = fileMeta.thumbnailUrl || clientData?.thumbnailUrl || note.thumbnailUrl;
    note.lifecycleState = NoteLifecycleState.READY;
    note.status = NoteStatus.PUBLISHED;
    note.publishedAt = new Date();
    if (fileMeta.size > 0) {
      note.fileSize = fileMeta.size;
    }
    await note.save();

    await AuditLog.create({
      collegeId: note.collegeId.toString(),
      actorUserId: requester.id,
      action: 'NOTE_UPLOAD_COMPLETED',
      entityType: 'Note',
      entityId: note.id,
      newValue: {
        status: NoteStatus.PUBLISHED,
        fileSize: note.fileSize,
        storageProvider: 'imagekit',
      },
    });

    // Notify enrolled students asynchronously
    await this.notifyEnrolledStudents(note, NotificationType.NOTE_PUBLISHED).catch((err) =>
      logger.warn(`Failed to notify students of note publication: ${err.message}`)
    );

    return note;
  }

  // =========================================================================
  // 3. SECURE DOWNLOAD URL GENERATION
  // =========================================================================

  static async getDownloadUrl(
    noteId: string,
    requester: AuthenticatedUser
  ): Promise<{ downloadUrl: string; expiresInSeconds: number; fileName: string; mimeType: string; fileSize: number }> {
    if (!mongoose.Types.ObjectId.isValid(noteId)) throw ApiError.badRequest('Invalid noteId');
    const note = await Note.findById(noteId);
    if (!note || note.lifecycleState === NoteLifecycleState.DELETED) {
      throw ApiError.notFound('Note not found or has been deleted');
    }

    if (requester.role !== AppRole.SUPER_ADMIN && note.collegeId.toString() !== requester.collegeId) {
      throw ApiError.forbidden('Cross-college access is strictly prohibited');
    }

    // Student Access Verification
    if (requester.role === AppRole.STUDENT) {
      if (note.lifecycleState !== NoteLifecycleState.READY) {
        throw ApiError.notFound('Note is not available for download');
      }
      if (note.visibility === NoteVisibility.FACULTY_ONLY) {
        throw ApiError.forbidden('This note is restricted to faculty members');
      }

      const studentProfile = await Student.findOne({ userId: requester.id });
      if (!studentProfile) throw ApiError.notFound('Student profile not found');

      // Verify matching semester / course
      if (studentProfile.semesterId && studentProfile.semesterId.toString() !== note.semesterId.toString()) {
        throw ApiError.forbidden('Note belongs to a different academic semester');
      }
      if (note.visibility === NoteVisibility.SECTION_ONLY && note.sectionId) {
        if (studentProfile.sectionId?.toString() !== note.sectionId.toString()) {
          throw ApiError.forbidden('This note is restricted to a different section');
        }
      }
    }

    // Generate signed download URL via ImageKit with 5 minute expiry
    const targetPathOrUrl = note.fileUrl || note.storageKey;
    const downloadUrl = ImageKitService.generateSignedUrl(targetPathOrUrl, 300);

    await AuditLog.create({
      collegeId: note.collegeId.toString(),
      actorUserId: requester.id,
      action: 'NOTE_DOWNLOADED',
      entityType: 'Note',
      entityId: note.id,
      newValue: {
        fileName: note.originalFileName,
        storageProvider: 'imagekit',
      },
    });

    return {
      downloadUrl,
      expiresInSeconds: 300,
      fileName: note.originalFileName,
      mimeType: note.mimeType,
      fileSize: note.fileSize,
    };
  }

  // =========================================================================
  // 4. NOTE REPLACEMENT & VERSIONING
  // =========================================================================

  static async requestReplaceUrl(
    noteId: string,
    data: { fileName: string; mimeType: string; fileSize: number },
    requester: AuthenticatedUser
  ): Promise<{
    uploadAuth: ImageKitAuthParams;
    uploadUrl: string;
    storageKey: string;
    fileId: string;
    expiresInSeconds: number;
  }> {
    if (!mongoose.Types.ObjectId.isValid(noteId)) throw ApiError.badRequest('Invalid noteId');
    const note = await Note.findById(noteId);
    if (!note || note.lifecycleState === NoteLifecycleState.DELETED) {
      throw ApiError.notFound('Note not found');
    }

    if (requester.role !== AppRole.SUPER_ADMIN && note.collegeId.toString() !== requester.collegeId) {
      throw ApiError.forbidden('Cross-college access is strictly prohibited');
    }

    if (
      requester.role === AppRole.FACULTY &&
      note.authorUserId.toString() !== requester.id
    ) {
      throw ApiError.forbidden('Unauthorized to replace this note');
    }

    const { valid, error } = ImageKitService.validateMimeAndExtension(data.mimeType, data.fileName);
    if (!valid) {
      throw ApiError.badRequest(error || 'Invalid file type');
    }

    const folder = ImageKitService.buildNoteFolder(
      note.collegeId.toString(),
      note.courseId.toString(),
      note.semesterId.toString(),
      note.subjectId.toString(),
      note.id
    );

    const versionFileName = `v${note.version + 1}_${data.fileName.trim()}`;
    const authParams = ImageKitService.getAuthenticationParameters(folder, versionFileName, data.fileSize);
    authParams.fileId = `v${note.version + 1}-${authParams.fileId}`;
    const newStorageKey = `${folder}/${versionFileName}`;

    return {
      uploadAuth: authParams,
      uploadUrl: authParams.urlEndpoint,
      storageKey: newStorageKey,
      fileId: authParams.fileId,
      expiresInSeconds: authParams.expiresInSeconds,
    };
  }

  static async completeReplace(
    noteId: string,
    data: { storageKey: string; fileId: string; fileName: string; mimeType: string; fileSize: number; fileUrl?: string },
    requester: AuthenticatedUser
  ): Promise<INote> {
    if (!mongoose.Types.ObjectId.isValid(noteId)) throw ApiError.badRequest('Invalid noteId');
    const note = await Note.findById(noteId);
    if (!note || note.lifecycleState === NoteLifecycleState.DELETED) {
      throw ApiError.notFound('Note not found');
    }

    // Verify new file exists in ImageKit
    const fileMeta = await ImageKitService.getFileDetails(data.fileId);
    if (!fileMeta) {
      throw ApiError.badRequest('Replacement file was not found in storage.');
    }

    // Save previous version metadata
    note.previousVersions.push({
      version: note.version,
      storageKey: note.storageKey,
      fileId: note.fileId,
      fileName: note.originalFileName,
      fileSize: note.fileSize,
      mimeType: note.mimeType,
      fileUrl: note.fileUrl,
      uploadedAt: note.updatedAt || new Date(),
    });

    note.version += 1;
    note.storageKey = data.storageKey;
    note.fileId = fileMeta.fileId || data.fileId;
    note.fileUrl = fileMeta.url || data.fileUrl || note.fileUrl;
    note.thumbnailUrl = fileMeta.thumbnailUrl || note.thumbnailUrl;
    note.originalFileName = data.fileName.trim();
    note.mimeType = data.mimeType.toLowerCase();
    note.fileExtension = data.fileName.split('.').pop()!.toLowerCase();
    note.fileSize = fileMeta.size || data.fileSize;
    note.lifecycleState = NoteLifecycleState.READY;
    await note.save();

    await AuditLog.create({
      collegeId: note.collegeId.toString(),
      actorUserId: requester.id,
      action: 'NOTE_REPLACED',
      entityType: 'Note',
      entityId: note.id,
      newValue: {
        version: note.version,
        storageKey: note.storageKey,
        storageProvider: 'imagekit',
      },
    });

    await this.notifyEnrolledStudents(note, NotificationType.NOTE_UPDATED).catch((err) =>
      logger.warn(`Failed to notify students of note update: ${err.message}`)
    );

    return note;
  }

  // =========================================================================
  // 5. SAFE DELETION
  // =========================================================================

  static async deleteNote(noteId: string, requester: AuthenticatedUser): Promise<void> {
    if (!mongoose.Types.ObjectId.isValid(noteId)) throw ApiError.badRequest('Invalid noteId');
    const note = await Note.findById(noteId);
    if (!note || note.lifecycleState === NoteLifecycleState.DELETED) {
      throw ApiError.notFound('Note not found');
    }

    if (requester.role !== AppRole.SUPER_ADMIN && note.collegeId.toString() !== requester.collegeId) {
      throw ApiError.forbidden('Cross-college access is strictly prohibited');
    }

    if (
      requester.role === AppRole.FACULTY &&
      note.authorUserId.toString() !== requester.id
    ) {
      throw ApiError.forbidden('Unauthorized to delete this note');
    }

    // Mark as DELETING
    note.lifecycleState = NoteLifecycleState.DELETING;
    await note.save();

    // Delete current file from ImageKit
    if (note.fileId) {
      await ImageKitService.deleteFile(note.fileId);
    }

    // Delete any previous version files from ImageKit
    for (const prev of note.previousVersions) {
      if (prev.fileId) {
        await ImageKitService.deleteFile(prev.fileId);
      }
    }

    note.lifecycleState = NoteLifecycleState.DELETED;
    note.status = NoteStatus.ARCHIVED;
    await note.save();

    await AuditLog.create({
      collegeId: note.collegeId.toString(),
      actorUserId: requester.id,
      action: 'NOTE_DELETED',
      entityType: 'Note',
      entityId: note.id,
      newValue: {
        storageProvider: 'imagekit',
      },
    });
  }

  // =========================================================================
  // 6. STUDENT PERSONAL NOTES & SUBJECT NOTES VIEWS
  // =========================================================================

  static async getStudentNotes(
    requester: AuthenticatedUser,
    query: { subjectId?: string; noteType?: NoteType; search?: string; page?: number; limit?: number } = {}
  ): Promise<{ items: INote[]; page: number; limit: number; total: number; totalPages: number }> {
    if (requester.role !== AppRole.STUDENT) {
      throw ApiError.forbidden('Only students can access their personal notes feed');
    }

    const studentProfile = await Student.findOne({ userId: requester.id });
    if (!studentProfile) throw ApiError.notFound('Student profile not found');

    const filter: Record<string, unknown> = {
      collegeId: studentProfile.collegeId,
      lifecycleState: NoteLifecycleState.READY,
      visibility: { $ne: NoteVisibility.FACULTY_ONLY },
    };

    if (studentProfile.semesterId) {
      filter.semesterId = studentProfile.semesterId;
    }
    if (query.subjectId) {
      if (!mongoose.Types.ObjectId.isValid(query.subjectId)) throw ApiError.badRequest('Invalid subjectId');
      filter.subjectId = new mongoose.Types.ObjectId(query.subjectId);
    }
    if (query.noteType) filter.noteType = query.noteType;

    if (query.search && query.search.trim() !== '') {
      const searchRegex = new RegExp(query.search.trim(), 'i');
      filter.$or = [{ title: searchRegex }, { description: searchRegex }, { chapter: searchRegex }];
    }

    const page = Math.max(1, query.page || 1);
    const limit = Math.min(100, Math.max(1, query.limit || 20));
    const skip = (page - 1) * limit;

    const [items, total] = await Promise.all([
      Note.find(filter).sort({ createdAt: -1 }).skip(skip).limit(limit),
      Note.countDocuments(filter),
    ]);

    return { items, page, limit, total, totalPages: Math.ceil(total / limit) };
  }

  static async getSubjectNotes(
    subjectId: string,
    requester: AuthenticatedUser,
    query: { page?: number; limit?: number } = {}
  ): Promise<{ items: INote[]; page: number; limit: number; total: number; totalPages: number }> {
    if (!mongoose.Types.ObjectId.isValid(subjectId)) throw ApiError.badRequest('Invalid subjectId');
    const subject = await Subject.findById(subjectId);
    if (!subject) throw ApiError.notFound('Subject not found');

    if (requester.role !== AppRole.SUPER_ADMIN && subject.collegeId.toString() !== requester.collegeId) {
      throw ApiError.forbidden('Cross-college access is strictly prohibited');
    }

    const filter: Record<string, unknown> = {
      subjectId: subject._id,
      lifecycleState: NoteLifecycleState.READY,
    };

    if (requester.role === AppRole.STUDENT) {
      filter.visibility = { $ne: NoteVisibility.FACULTY_ONLY };
    }

    const page = Math.max(1, query.page || 1);
    const limit = Math.min(100, Math.max(1, query.limit || 20));
    const skip = (page - 1) * limit;

    const [items, total] = await Promise.all([
      Note.find(filter).sort({ createdAt: -1 }).skip(skip).limit(limit),
      Note.countDocuments(filter),
    ]);

    return { items, page, limit, total, totalPages: Math.ceil(total / limit) };
  }

  static async getNoteById(id: string, requester: AuthenticatedUser): Promise<INote> {
    if (!mongoose.Types.ObjectId.isValid(id)) throw ApiError.badRequest('Invalid Note ID');
    const note = await Note.findById(id);
    if (!note || note.lifecycleState === NoteLifecycleState.DELETED) {
      throw ApiError.notFound('Note not found');
    }

    if (requester.role !== AppRole.SUPER_ADMIN && note.collegeId.toString() !== requester.collegeId) {
      throw ApiError.forbidden('Cross-college access is strictly prohibited');
    }

    if (requester.role === AppRole.STUDENT && note.lifecycleState !== NoteLifecycleState.READY) {
      throw ApiError.notFound('Note not available');
    }

    return note;
  }

  static async listNotes(
    requester: AuthenticatedUser,
    query: {
      collegeId?: string;
      departmentId?: string;
      courseId?: string;
      semesterId?: string;
      sectionId?: string;
      subjectId?: string;
      facultyId?: string;
      noteType?: NoteType;
      search?: string;
      status?: NoteStatus;
      page?: number;
      limit?: number;
    } = {}
  ): Promise<{ items: INote[]; page: number; limit: number; total: number; totalPages: number }> {
    const filter: Record<string, unknown> = {
      lifecycleState: { $ne: NoteLifecycleState.DELETED },
    };

    if (requester.role !== AppRole.SUPER_ADMIN) {
      if (!requester.collegeId) return { items: [], page: 1, limit: 1, total: 0, totalPages: 0 };
      filter.collegeId = new mongoose.Types.ObjectId(requester.collegeId);
      if (requester.role === AppRole.HOD && requester.departmentId) {
        filter.departmentId = new mongoose.Types.ObjectId(requester.departmentId);
      }
    } else if (query.collegeId) {
      if (!mongoose.Types.ObjectId.isValid(query.collegeId)) throw ApiError.badRequest('Invalid collegeId');
      filter.collegeId = new mongoose.Types.ObjectId(query.collegeId);
    }

    if (query.departmentId) filter.departmentId = new mongoose.Types.ObjectId(query.departmentId);
    if (query.courseId) filter.courseId = new mongoose.Types.ObjectId(query.courseId);
    if (query.semesterId) filter.semesterId = new mongoose.Types.ObjectId(query.semesterId);
    if (query.sectionId) filter.sectionId = new mongoose.Types.ObjectId(query.sectionId);
    if (query.subjectId) filter.subjectId = new mongoose.Types.ObjectId(query.subjectId);
    if (query.facultyId) filter.facultyId = new mongoose.Types.ObjectId(query.facultyId);
    if (query.noteType) filter.noteType = query.noteType;
    if (query.status) filter.status = query.status;

    if (requester.role === AppRole.STUDENT) {
      filter.lifecycleState = NoteLifecycleState.READY;
      filter.visibility = { $ne: NoteVisibility.FACULTY_ONLY };
    }

    if (query.search && query.search.trim() !== '') {
      const searchRegex = new RegExp(query.search.trim(), 'i');
      filter.$or = [{ title: searchRegex }, { description: searchRegex }, { chapter: searchRegex }];
    }

    const page = Math.max(1, query.page || 1);
    const limit = Math.min(100, Math.max(1, query.limit || 20));
    const skip = (page - 1) * limit;

    const [items, total] = await Promise.all([
      Note.find(filter).sort({ createdAt: -1 }).skip(skip).limit(limit),
      Note.countDocuments(filter),
    ]);

    return { items, page, limit, total, totalPages: Math.ceil(total / limit) };
  }

  static async updateNote(
    id: string,
    update: { title?: string; description?: string; noteType?: NoteType; visibility?: NoteVisibility; chapter?: string },
    requester: AuthenticatedUser
  ): Promise<INote> {
    const note = await this.getNoteById(id, requester);

    if (
      requester.role === AppRole.FACULTY &&
      note.authorUserId.toString() !== requester.id
    ) {
      throw ApiError.forbidden('Unauthorized to update this note');
    }

    const prev = note.toJSON();

    if (update.title) note.title = update.title.trim();
    if (update.description !== undefined) note.description = update.description.trim();
    if (update.noteType) note.noteType = update.noteType;
    if (update.visibility) note.visibility = update.visibility;
    if (update.chapter !== undefined) note.chapter = update.chapter ? update.chapter.trim() : undefined;

    await note.save();

    await AuditLog.create({
      collegeId: note.collegeId.toString(),
      actorUserId: requester.id,
      action: 'NOTE_UPDATED',
      entityType: 'Note',
      entityId: note.id,
      previousValue: prev,
      newValue: note.toJSON(),
    });

    await this.notifyEnrolledStudents(note, NotificationType.NOTE_UPDATED).catch((err) =>
      logger.warn(`Failed to notify students of note update: ${err.message}`)
    );

    return note;
  }

  private static async notifyEnrolledStudents(
    note: INote,
    notificationType: NotificationType
  ): Promise<void> {
    try {
      const query: Record<string, unknown> = {
        collegeId: note.collegeId,
        status: 'active',
      };

      const orConditions: any[] = [];
      if (note.sectionId) orConditions.push({ sectionId: note.sectionId });
      if (note.semesterId) orConditions.push({ semesterId: note.semesterId });
      if (note.courseId) orConditions.push({ courseId: note.courseId });

      if (orConditions.length > 0) {
        query.$or = orConditions;
      }

      const enrollments = await StudentEnrollment.find(query).select('studentId');
      const studentIds = enrollments.map((e) => e.studentId);
      const students = await Student.find({ _id: { $in: studentIds } }).select('userId');

      const uniqueUserIds = Array.from(
        new Set(students.map((s) => s.userId?.toString()).filter(Boolean))
      );
      if (uniqueUserIds.length === 0) return;

      const notifInputs = uniqueUserIds.map((userId) => ({
        collegeId: note.collegeId.toString(),
        departmentId: note.departmentId ? note.departmentId.toString() : undefined,
        recipientUserId: userId as string,
        recipientRole: AppRole.STUDENT,
        title:
          notificationType === NotificationType.NOTE_PUBLISHED
            ? `New Study Note: ${note.title}`
            : `Updated Note: ${note.title}`,
        body: note.chapter
          ? `${note.chapter}: ${note.title} is now available.`
          : `Note "${note.title}" has been published.`,
        notificationType,
        category: NotificationCategory.NOTES,
        entityType: 'Note',
        entityId: note.id,
        deepLink: `/notes/${note.id}`,
        idempotencyKey: `note_${notificationType}_${note.id}_v${note.version}_${userId}`,
      }));

      await NotificationService.createBatchNotifications(notifInputs);
    } catch (err) {
      logger.warn(`Failed to dispatch note notification: ${(err as Error).message}`);
    }
  }
}
