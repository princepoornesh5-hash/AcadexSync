import mongoose from 'mongoose';
import { User, IUser } from '../models/user.model';
import { AuthSession } from '../models/authSession.model';
import { FacultyAssignment } from '../models/facultyAssignment.model';
import { Faculty } from '../models/faculty.model';
import { Student } from '../models/student.model';
import { StudentEnrollment } from '../models/studentEnrollment.model';
import { Note } from '../models/note.model';
import { AuditLog } from '../models/auditLog.model';
import { Timetable } from '../models/timetable.model';
import { TeacherSubstitution, TeacherSubstitutionStatus } from '../models/teacherSubstitution.model';
import { AttendanceSession } from '../models/attendanceSession.model';
import { AttendanceRecord } from '../models/attendanceRecord.model';
import { DeviceToken } from '../models/deviceToken.model';
import { Department } from '../models/department.model';
import { ApiError } from '../utils/apiError';
import { AppRole } from '../constants/roles';
import { AccountStatus } from '../constants/status';
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
   * Safe User Deactivation
   * Preferred lifecycle: ACTIVE -> DEACTIVATED
   * Cascades invalidation across operational entities while preserving historical academic records.
   */
  static async deactivateUserSafely(
    userId: string,
    actor: AuthenticatedUser,
    reason?: string
  ): Promise<IUser> {
    if (!mongoose.Types.ObjectId.isValid(userId)) {
      throw ApiError.badRequest(`Invalid User ID format: "${userId}"`);
    }

    if (actor.id === userId) {
      throw ApiError.badRequest('Administrators cannot deactivate their own account');
    }

    const user = await User.findById(userId);
    if (!user) {
      throw ApiError.notFound(`User with ID "${userId}" not found`);
    }

    // Tenant check
    if (actor.role === AppRole.COLLEGE_ADMIN) {
      if (!actor.collegeId || user.collegeId?.toString() !== actor.collegeId.toString()) {
        throw ApiError.forbidden('Cross-college tenant access is strictly prohibited');
      }
    } else if (actor.role !== AppRole.SUPER_ADMIN) {
      throw ApiError.forbidden('Only administrators have permission to deactivate users');
    }

    const previousValue = user.toJSON();
    const targetObjectId = new mongoose.Types.ObjectId(userId);
    const todayStr = new Date().toISOString().slice(0, 10);

    // 1. Mark user as deactivated
    user.accountStatus = AccountStatus.DEACTIVATED;
    await user.save();

    // 2. Invalidate active authentication sessions & push tokens
    await Promise.all([
      AuthSession.updateMany(
        { userId: targetObjectId, revokedAt: null },
        { revokedAt: new Date() }
      ),
      DeviceToken.updateMany(
        { userId: targetObjectId, isActive: true },
        { isActive: false }
      ),
    ]);

    // 3. Cascade Faculty profile & active assignments if applicable
    const facultyDoc = await Faculty.findOne({ userId: targetObjectId });
    if (facultyDoc) {
      facultyDoc.isActive = false;
      facultyDoc.status = 'inactive';
      await facultyDoc.save();

      // Deactivate all active faculty assignments (MOHAN fix)
      await FacultyAssignment.updateMany(
        { facultyId: facultyDoc._id, isActive: true },
        { isActive: false }
      );

      // Vacate / unassign from timetable entries
      await Timetable.updateMany(
        {},
        { $pull: { entries: { facultyId: facultyDoc._id } } }
      );

      // Cancel future teacher substitutions
      await TeacherSubstitution.updateMany(
        {
          $or: [
            { originalFacultyId: facultyDoc._id },
            { substituteFacultyId: facultyDoc._id },
          ],
          date: { $gte: todayStr },
          status: TeacherSubstitutionStatus.ACTIVE,
        },
        {
          status: TeacherSubstitutionStatus.CANCELLED,
          reason: reason || 'Faculty member deactivated',
        }
      );
    }

    // 4. Cascade Student profile & enrollments if applicable
    const studentDoc = await Student.findOne({ userId: targetObjectId });
    if (studentDoc) {
      studentDoc.isActive = false;
      studentDoc.status = 'inactive';
      await studentDoc.save();

      await StudentEnrollment.updateMany(
        { studentId: studentDoc._id, status: 'ACTIVE' },
        { status: 'INACTIVE' }
      );
    }

    // 5. If user is HOD, clear department leadership pointer
    if (user.role === AppRole.HOD) {
      await Department.updateMany(
        { hodId: user.id },
        { hodId: null }
      );
    }

    // 6. Record audit log
    await AuditLog.create({
      collegeId: user.collegeId ? user.collegeId.toString() : 'GLOBAL',
      actorUserId: actor.id,
      action: 'USER_DEACTIVATED',
      entityType: 'User',
      entityId: user.id,
      previousValue,
      newValue: {
        accountStatus: AccountStatus.DEACTIVATED,
        reason: reason || 'Administrative deactivation',
      },
      metadata: { reason },
    });

    return user;
  }

  /**
   * Safe User Reactivation
   */
  static async reactivateUserSafely(
    userId: string,
    actor: AuthenticatedUser
  ): Promise<IUser> {
    if (!mongoose.Types.ObjectId.isValid(userId)) {
      throw ApiError.badRequest(`Invalid User ID format: "${userId}"`);
    }

    const user = await User.findById(userId);
    if (!user) {
      throw ApiError.notFound(`User with ID "${userId}" not found`);
    }

    // Tenant check
    if (actor.role === AppRole.COLLEGE_ADMIN) {
      if (!actor.collegeId || user.collegeId?.toString() !== actor.collegeId.toString()) {
        throw ApiError.forbidden('Cross-college tenant access is strictly prohibited');
      }
    } else if (actor.role !== AppRole.SUPER_ADMIN) {
      throw ApiError.forbidden('Only administrators have permission to reactivate users');
    }

    const previousValue = user.toJSON();
    const targetObjectId = new mongoose.Types.ObjectId(userId);

    user.accountStatus = AccountStatus.ACTIVE;
    await user.save();

    await Promise.all([
      Faculty.updateOne({ userId: targetObjectId }, { isActive: true, status: 'active' }),
      Student.updateOne({ userId: targetObjectId }, { isActive: true, status: 'active' }),
    ]);

    await AuditLog.create({
      collegeId: user.collegeId ? user.collegeId.toString() : 'GLOBAL',
      actorUserId: actor.id,
      action: 'USER_REACTIVATED',
      entityType: 'User',
      entityId: user.id,
      previousValue,
      newValue: { accountStatus: AccountStatus.ACTIVE },
    });

    return user;
  }

  /**
   * Super Admin Permanent User Deletion (Overhauled with Historical Integrity Guards & Cascade Fixes)
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

    const [facultyDoc, studentDoc] = await Promise.all([
      Faculty.findOne({ userId: targetObjectId }),
      Student.findOne({ userId: targetObjectId }),
    ]);

    // Historical Academic Guard: Reject hard delete if historical attendance exists
    if (facultyDoc) {
      const hasAttendanceSession = await AttendanceSession.exists({ facultyId: facultyDoc._id });
      if (hasAttendanceSession) {
        throw ApiError.badRequest(
          'You cannot delete this faculty because historical attendance exists. The account can be deactivated instead.'
        );
      }
    }

    if (studentDoc) {
      const hasAttendanceRecord = await AttendanceRecord.exists({ studentId: studentDoc._id });
      if (hasAttendanceRecord) {
        throw ApiError.badRequest(
          'You cannot delete this student because historical attendance exists. The account can be deactivated instead.'
        );
      }
    }

    // Safe Cascade Cleanup (using correct IDs)
    const cleanupPromises: Promise<any>[] = [
      User.findByIdAndDelete(targetObjectId),
      AuthSession.deleteMany({ userId: targetObjectId }),
      DeviceToken.deleteMany({ userId: targetObjectId }),
      Note.deleteMany({ authorUserId: targetObjectId }),
    ];

    if (facultyDoc) {
      cleanupPromises.push(
        Faculty.findByIdAndDelete(facultyDoc._id),
        FacultyAssignment.deleteMany({ facultyId: facultyDoc._id }),
        Timetable.updateMany({}, { $pull: { entries: { facultyId: facultyDoc._id } } }),
        TeacherSubstitution.deleteMany({
          $or: [{ originalFacultyId: facultyDoc._id }, { substituteFacultyId: facultyDoc._id }],
        })
      );
    }

    if (studentDoc) {
      cleanupPromises.push(
        Student.findByIdAndDelete(studentDoc._id),
        StudentEnrollment.deleteMany({ studentId: studentDoc._id })
      );
    }

    if (user.role === AppRole.HOD) {
      cleanupPromises.push(
        Department.updateMany({ hodId: user.id }, { hodId: null })
      );
    }

    await Promise.all(cleanupPromises);

    await AuditLog.create({
      actorUserId: actor.id,
      collegeId: user.collegeId ? user.collegeId.toString() : 'GLOBAL',
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

