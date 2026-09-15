import mongoose from 'mongoose';
import { User, IUser } from '../models/user.model';
import { AuthSession } from '../models/authSession.model';
import { FacultyAssignment } from '../models/facultyAssignment.model';
import { Faculty } from '../models/faculty.model';
import { Student } from '../models/student.model';
import { StudentEnrollment } from '../models/studentEnrollment.model';
import { Note } from '../models/note.model';
import { AuditLog } from '../models/auditLog.model';
import { ApiError } from '../utils/apiError';
import { AppRole } from '../constants/roles';
import { ImageKitService } from '../storage/imagekit.service';
import { env } from '../config/env';
import { AuthenticatedUser } from '../types/auth.types';

export class UserService {
  static async createUser(data: Partial<IUser>): Promise<IUser> {
    if (!data.instituteId || data.instituteId.trim() === '') {
      throw ApiError.badRequest('instituteId is required for user registration');
    }

    const normalizedInstituteId = data.instituteId.trim().toUpperCase();

    const existingInstituteId = await User.findOne({ instituteId: normalizedInstituteId });
    if (existingInstituteId) {
      throw ApiError.conflict(`User with instituteId "${normalizedInstituteId}" already exists`);
    }

    if (data.email) {
      const existingEmail = await User.findOne({ email: data.email.toLowerCase().trim() });
      if (existingEmail) {
        throw ApiError.conflict(`User with email "${data.email}" already exists`);
      }
    }

    return User.create({
      ...data,
      instituteId: normalizedInstituteId,
      email: data.email ? data.email.toLowerCase().trim() : undefined,
    });
  }

  static async getUserById(id: string, requesterCollegeId?: string, isSuperAdmin = false): Promise<IUser> {
    const query: Record<string, unknown> = { _id: id };
    if (!isSuperAdmin && requesterCollegeId) {
      query.collegeId = requesterCollegeId;
    }

    const user = await User.findOne(query);
    if (!user) {
      throw ApiError.notFound(`User with ID "${id}" not found`);
    }
    return user;
  }

  static async getUserByInstituteId(
    instituteId: string,
    requesterCollegeId?: string,
    isSuperAdmin = false
  ): Promise<IUser> {
    const query: Record<string, unknown> = { instituteId: instituteId.trim().toUpperCase() };
    if (!isSuperAdmin && requesterCollegeId) {
      query.collegeId = requesterCollegeId;
    }

    const user = await User.findOne(query);
    if (!user) {
      throw ApiError.notFound(`User with instituteId "${instituteId}" not found`);
    }
    return user;
  }

  static async listUsers(
    collegeId?: string,
    role?: AppRole,
    isSuperAdmin = false
  ): Promise<IUser[]> {
    const filter: Record<string, unknown> = {};
    if (!isSuperAdmin && collegeId) {
      filter.collegeId = collegeId;
    } else if (isSuperAdmin && collegeId) {
      filter.collegeId = collegeId;
    }
    if (role) {
      filter.role = role;
    }

    return User.find(filter).sort({ name: 1 });
  }

  static async updateUser(
    id: string,
    update: Partial<IUser>,
    requesterCollegeId?: string,
    isSuperAdmin = false
  ): Promise<IUser> {
    const query: Record<string, unknown> = { _id: id };
    if (!isSuperAdmin && requesterCollegeId) {
      query.collegeId = requesterCollegeId;
    }

    const user = await User.findOne(query);
    if (!user) {
      throw ApiError.notFound(`User with ID "${id}" not found`);
    }

    // If instituteId is changing, ensure uniqueness
    if (update.instituteId && update.instituteId.trim().toUpperCase() !== user.instituteId) {
      const normalizedInstituteId = update.instituteId.trim().toUpperCase();
      const existing = await User.findOne({
        instituteId: normalizedInstituteId,
        _id: { $ne: user._id },
      });
      if (existing) {
        throw ApiError.conflict(`User with instituteId "${normalizedInstituteId}" already exists`);
      }
      user.instituteId = normalizedInstituteId;
    }

    // If email is changing, ensure uniqueness
    if (update.email && update.email.toLowerCase().trim() !== user.email) {
      const normalizedEmail = update.email.toLowerCase().trim();
      const existingEmail = await User.findOne({
        email: normalizedEmail,
        _id: { $ne: user._id },
      });
      if (existingEmail) {
        throw ApiError.conflict(`User with email "${normalizedEmail}" already exists`);
      }
      user.email = normalizedEmail;
    }

    if (update.name !== undefined) user.name = update.name;
    if (update.phone !== undefined) user.phone = update.phone;
    if (update.role !== undefined) user.role = update.role;
    if (update.accountStatus !== undefined) user.accountStatus = update.accountStatus;
    if (update.activationStatus !== undefined) user.activationStatus = update.activationStatus;
    if (update.departmentId !== undefined) user.departmentId = update.departmentId;
    if (update.courseId !== undefined) user.courseId = update.courseId;
    if (update.sectionId !== undefined) user.sectionId = update.sectionId;
    if (update.semesterId !== undefined) user.semesterId = update.semesterId;
    if (update.profilePictureUrl !== undefined) user.profilePictureUrl = update.profilePictureUrl;

    await user.save();
    return user;
  }

  static async requestProfileImageUploadUrl(
    userId: string,
    data: { fileName: string; mimeType: string; fileSize: number },
    requester: { id: string; role: string; collegeId?: string }
  ): Promise<{
    uploadAuth: any;
    uploadUrl: string;
    folder: string;
    fileName: string;
    fileId: string;
    expiresInSeconds: number;
  }> {
    if (requester.id !== userId && requester.role !== AppRole.SUPER_ADMIN && requester.role !== AppRole.COLLEGE_ADMIN) {
      throw ApiError.forbidden('Unauthorized to update profile image for another user');
    }

    const user = await User.findById(userId);
    if (!user) throw ApiError.notFound('User not found');

    const cleanMime = data.mimeType.trim().toLowerCase();
    const { valid, error } = ImageKitService.validateMimeAndExtension(cleanMime, data.fileName);
    if (!valid || !['image/jpeg', 'image/png', 'image/webp'].includes(cleanMime)) {
      throw ApiError.badRequest(error || 'Only JPEG, PNG, and WebP images are allowed for profile pictures');
    }

    const maxProfileSizeBytes = env.PROFILE_IMAGE_MAX_FILE_SIZE_MB * 1024 * 1024;
    if (data.fileSize > maxProfileSizeBytes) {
      throw ApiError.badRequest(`File size exceeds maximum limit of ${env.PROFILE_IMAGE_MAX_FILE_SIZE_MB}MB`);
    }

    const collegeId = user.collegeId ? user.collegeId.toString() : 'global';
    const folder = ImageKitService.buildProfileFolder(collegeId, user.role, user.id);
    const authParams = ImageKitService.getAuthenticationParameters(
      folder,
      data.fileName,
      data.fileSize,
      env.SIGNED_URL_EXPIRY_SECONDS
    );

    return {
      uploadAuth: authParams,
      uploadUrl: authParams.urlEndpoint,
      folder,
      fileName: data.fileName,
      fileId: authParams.fileId,
      expiresInSeconds: authParams.expiresInSeconds,
    };
  }

  static async completeProfileImageUpload(
    userId: string,
    data: { fileId: string; fileUrl?: string },
    requester: { id: string; role: string; collegeId?: string }
  ): Promise<IUser> {
    if (requester.id !== userId && requester.role !== AppRole.SUPER_ADMIN && requester.role !== AppRole.COLLEGE_ADMIN) {
      throw ApiError.forbidden('Unauthorized to update profile image for another user');
    }

    const user = await User.findById(userId);
    if (!user) throw ApiError.notFound('User not found');

    const fileMeta = await ImageKitService.getFileDetails(data.fileId);
    if (!fileMeta) {
      throw ApiError.badRequest('Uploaded image file was not found in storage. Please upload the file first.');
    }

    user.profilePictureUrl = fileMeta.url || data.fileUrl || user.profilePictureUrl;
    await user.save();

    return user;
  }

  /**
   * Super Admin Permanent User Deletion
   */
  static async deleteUserPermanently(userId: string, actor: AuthenticatedUser): Promise<void> {
    if (!mongoose.Types.ObjectId.isValid(userId)) {
      throw ApiError.badRequest(`Invalid User ID format: "${userId}"`);
    }

    if (actor.id === userId) {
      throw ApiError.badRequest('Super Admin cannot delete their own account');
    }

    const user = await User.findById(userId);
    if (!user) {
      throw ApiError.notFound(`User with ID "${userId}" not found`);
    }

    const targetObjectId = new mongoose.Types.ObjectId(userId);

    await Promise.all([
      User.findByIdAndDelete(targetObjectId),
      AuthSession.deleteMany({ userId: targetObjectId }),
      FacultyAssignment.deleteMany({ facultyUserId: targetObjectId }),
      Student.deleteMany({ userId: targetObjectId }),
      Faculty.deleteMany({ userId: targetObjectId }),
      StudentEnrollment.deleteMany({ studentUserId: targetObjectId }),
      Note.deleteMany({ authorUserId: targetObjectId }),
    ]);

    await AuditLog.create({
      actorUserId: actor.id,
      collegeId: user.collegeId || null,
      action: 'USER_PERMANENTLY_DELETED',
      entityType: 'User',
      entityId: user.id,
      oldValue: {
        instituteId: user.instituteId,
        name: user.name,
        email: user.email,
        role: user.role,
      },
    });
  }
}

