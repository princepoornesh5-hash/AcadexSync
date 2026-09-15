import mongoose from 'mongoose';
import { College, ICollege } from '../models/college.model';
import { User, IUser } from '../models/user.model';
import { Department } from '../models/department.model';
import { Course } from '../models/course.model';
import { AcademicYear } from '../models/academicYear.model';
import { Semester } from '../models/semester.model';
import { Section } from '../models/section.model';
import { Subject } from '../models/subject.model';
import { Room } from '../models/room.model';
import { Timetable } from '../models/timetable.model';
import { AttendanceSession } from '../models/attendanceSession.model';
import { AttendanceRecord } from '../models/attendanceRecord.model';
import { FacultyAssignment } from '../models/facultyAssignment.model';
import { Note } from '../models/note.model';
import { Notification } from '../models/notification.model';
import { StudentEnrollment } from '../models/studentEnrollment.model';
import { Student } from '../models/student.model';
import { Faculty } from '../models/faculty.model';
import { Invitation } from '../models/invitation.model';
import { AuthSession } from '../models/authSession.model';
import { AuditLog } from '../models/auditLog.model';
import { AppRole } from '../constants/roles';
import { CollegeStatus, AccountStatus, InvitationStatus } from '../constants/status';
import { ApiError } from '../utils/apiError';
import { AuthenticatedUser } from '../types/auth.types';

export interface CreateCollegeInput {
  name: string;
  code: string;
  address: string;
  email: string;
  phone: string;
  principal: string;
  status?: CollegeStatus;
  logoUrl?: string | null;
  metadata?: Record<string, unknown>;
}

export interface UpdateCollegeInput {
  name?: string;
  code?: string;
  address?: string;
  email?: string;
  phone?: string;
  principal?: string;
  logoUrl?: string | null;
  metadata?: Record<string, unknown>;
}

export interface ListCollegesQuery {
  page?: number;
  limit?: number;
  search?: string;
  status?: CollegeStatus;
  sortBy?: 'name' | 'code' | 'status' | 'createdAt' | 'updatedAt';
  sortOrder?: 'asc' | 'desc';
}

export interface PaginatedResult<T> {
  items: T[];
  page: number;
  limit: number;
  total: number;
  totalPages: number;
}

export class CollegeService {
  /**
   * Super Admin College Creation
   */
  static async createCollege(data: CreateCollegeInput, actorUserId: string): Promise<ICollege> {
    const normalizedCode = data.code.trim().toUpperCase();

    // Check duplicate code
    const existing = await College.findOne({ code: normalizedCode });
    if (existing) {
      throw ApiError.conflict(`College with code "${normalizedCode}" already exists`);
    }

    const college = await College.create({
      name: data.name.trim(),
      code: normalizedCode,
      address: data.address.trim(),
      email: data.email.trim().toLowerCase(),
      phone: data.phone.trim(),
      principal: data.principal.trim(),
      status: data.status || CollegeStatus.ACTIVE,
      isActive: (data.status || CollegeStatus.ACTIVE) === CollegeStatus.ACTIVE,
      logoUrl: data.logoUrl || null,
      metadata: data.metadata || null,
      createdBy: actorUserId,
      updatedBy: actorUserId,
    });

    await AuditLog.create({
      actorUserId,
      collegeId: college.id,
      action: 'COLLEGE_CREATED',
      entityType: 'College',
      entityId: college.id,
      newValue: {
        name: college.name,
        code: college.code,
        status: college.status,
      },
    });

    return college;
  }

  /**
   * Get Single College by ID with Tenant Scoping
   */
  static async getCollegeById(id: string, requester: AuthenticatedUser): Promise<ICollege> {
    if (!mongoose.Types.ObjectId.isValid(id)) {
      throw ApiError.badRequest(`Invalid College ID format: "${id}"`);
    }

    // Tenant Isolation
    if (requester.role !== AppRole.SUPER_ADMIN) {
      if (!requester.collegeId || requester.collegeId.toString() !== id.toString()) {
        throw ApiError.forbidden('Cross-college access is strictly prohibited');
      }
    }

    const college = await College.findById(id);
    if (!college) {
      throw ApiError.notFound(`College with ID "${id}" not found`);
    }

    return college;
  }

  /**
   * List Colleges with Search, Filter, Pagination, and Sorting
   */
  static async listColleges(
    requester: AuthenticatedUser,
    query: ListCollegesQuery = {}
  ): Promise<PaginatedResult<ICollege>> {
    // Non-SuperAdmins can only see their own college
    if (requester.role !== AppRole.SUPER_ADMIN) {
      if (!requester.collegeId) {
        return { items: [], page: 1, limit: 1, total: 0, totalPages: 0 };
      }
      const college = await College.findById(requester.collegeId);
      const items = college ? [college] : [];
      return {
        items,
        page: 1,
        limit: 1,
        total: items.length,
        totalPages: items.length > 0 ? 1 : 0,
      };
    }

    const page = Math.max(1, query.page || 1);
    const limit = Math.min(100, Math.max(1, query.limit || 20));
    const skip = (page - 1) * limit;

    const mongoQuery: Record<string, unknown> = {};

    // Filter by status
    if (query.status) {
      mongoQuery.status = query.status;
    }

    // Search by name or code (case-insensitive)
    if (query.search && query.search.trim() !== '') {
      const searchRegex = new RegExp(query.search.trim(), 'i');
      mongoQuery.$or = [{ name: searchRegex }, { code: searchRegex }];
    }

    // Whitelisted sorting
    const allowedSortFields = ['name', 'code', 'status', 'createdAt', 'updatedAt'];
    const sortField = allowedSortFields.includes(query.sortBy || '') ? query.sortBy! : 'name';
    const sortOrder = query.sortOrder === 'desc' ? -1 : 1;
    const sortOptions: Record<string, 1 | -1> = { [sortField]: sortOrder };

    const [items, total] = await Promise.all([
      College.find(mongoQuery).sort(sortOptions).skip(skip).limit(limit),
      College.countDocuments(mongoQuery),
    ]);

    const totalPages = Math.ceil(total / limit);

    return {
      items,
      page,
      limit,
      total,
      totalPages,
    };
  }

  /**
   * Super Admin Global College Update
   */
  static async updateCollege(
    id: string,
    update: UpdateCollegeInput,
    actorUserId: string
  ): Promise<ICollege> {
    if (!mongoose.Types.ObjectId.isValid(id)) {
      throw ApiError.badRequest(`Invalid College ID format: "${id}"`);
    }

    const college = await College.findById(id);
    if (!college) {
      throw ApiError.notFound(`College with ID "${id}" not found`);
    }

    const previousValue = college.toJSON();

    // Check code uniqueness if code is updated
    if (update.code) {
      const normalizedNewCode = update.code.trim().toUpperCase();
      if (normalizedNewCode !== college.code) {
        const existing = await College.findOne({
          code: normalizedNewCode,
          _id: { $ne: college._id },
        });
        if (existing) {
          throw ApiError.conflict(`College with code "${normalizedNewCode}" already exists`);
        }

        await AuditLog.create({
          actorUserId,
          collegeId: college.id,
          action: 'COLLEGE_CODE_CHANGED',
          entityType: 'College',
          entityId: college.id,
          previousValue: { code: college.code },
          newValue: { code: normalizedNewCode },
        });

        college.code = normalizedNewCode;
      }
    }

    if (update.name) college.name = update.name.trim();
    if (update.address) college.address = update.address.trim();
    if (update.email) college.email = update.email.trim().toLowerCase();
    if (update.phone) college.phone = update.phone.trim();
    if (update.principal) college.principal = update.principal.trim();
    if (update.logoUrl !== undefined) college.logoUrl = update.logoUrl || undefined;
    if (update.metadata) college.metadata = update.metadata;

    college.updatedBy = actorUserId;
    await college.save();

    await AuditLog.create({
      actorUserId,
      collegeId: college.id,
      action: 'COLLEGE_UPDATED',
      entityType: 'College',
      entityId: college.id,
      previousValue,
      newValue: college.toJSON(),
    });

    return college;
  }

  /**
   * Super Admin Status Change (Deactivation / Reactivation)
   */
  static async updateCollegeStatus(
    id: string,
    newStatus: CollegeStatus,
    actorUserId: string
  ): Promise<ICollege> {
    if (!mongoose.Types.ObjectId.isValid(id)) {
      throw ApiError.badRequest(`Invalid College ID format: "${id}"`);
    }

    const college = await College.findById(id);
    if (!college) {
      throw ApiError.notFound(`College with ID "${id}" not found`);
    }

    const previousStatus = college.status;
    college.status = newStatus;
    college.isActive = newStatus === CollegeStatus.ACTIVE;
    college.updatedBy = actorUserId;
    await college.save();

    // If deactivated, revoke all active sessions for users belonging to this college
    if (newStatus === CollegeStatus.INACTIVE) {
      const collegeUsers = await User.find({
        collegeId: college._id,
        role: { $ne: AppRole.SUPER_ADMIN },
      }).select('_id');

      const userIds = collegeUsers.map((u) => u._id);
      if (userIds.length > 0) {
        await AuthSession.updateMany(
          { userId: { $in: userIds }, revokedAt: null },
          { $set: { revokedAt: new Date() } }
        );
      }
    }

    await AuditLog.create({
      actorUserId,
      collegeId: college.id,
      action: 'COLLEGE_STATUS_CHANGED',
      entityType: 'College',
      entityId: college.id,
      previousValue: { status: previousStatus },
      newValue: { status: newStatus },
    });

    return college;
  }

  /**
   * Get Administrators belonging to a College
   */
  static async getCollegeAdmins(
    collegeId: string,
    requester: AuthenticatedUser
  ): Promise<IUser[]> {
    if (!mongoose.Types.ObjectId.isValid(collegeId)) {
      throw ApiError.badRequest(`Invalid College ID format: "${collegeId}"`);
    }

    if (requester.role !== AppRole.SUPER_ADMIN) {
      if (!requester.collegeId || requester.collegeId.toString() !== collegeId.toString()) {
        throw ApiError.forbidden('Cross-college access is strictly prohibited');
      }
    }

    const admins = await User.find({
      collegeId: new mongoose.Types.ObjectId(collegeId),
      role: AppRole.COLLEGE_ADMIN,
    }).sort({ createdAt: -1 });

    return admins;
  }

  /**
   * Get Real Aggregated Database Summary for a College
   */
  static async getCollegeSummary(
    collegeId: string,
    requester: AuthenticatedUser
  ): Promise<Record<string, unknown>> {
    if (!mongoose.Types.ObjectId.isValid(collegeId)) {
      throw ApiError.badRequest(`Invalid College ID format: "${collegeId}"`);
    }

    if (requester.role !== AppRole.SUPER_ADMIN) {
      if (!requester.collegeId || requester.collegeId.toString() !== collegeId.toString()) {
        throw ApiError.forbidden('Cross-college access is strictly prohibited');
      }
    }

    const college = await College.findById(collegeId);
    if (!college) {
      throw ApiError.notFound(`College with ID "${collegeId}" not found`);
    }

    const targetObjectId = new mongoose.Types.ObjectId(collegeId);

    const [
      departmentCount,
      collegeAdminCount,
      hodCount,
      facultyCount,
      studentCount,
      activeUserCount,
      pendingInvitationCount,
    ] = await Promise.all([
      Department.countDocuments({ collegeId: targetObjectId }),
      User.countDocuments({ collegeId: targetObjectId, role: AppRole.COLLEGE_ADMIN }),
      User.countDocuments({ collegeId: targetObjectId, role: AppRole.HOD }),
      User.countDocuments({ collegeId: targetObjectId, role: AppRole.FACULTY }),
      User.countDocuments({ collegeId: targetObjectId, role: AppRole.STUDENT }),
      User.countDocuments({ collegeId: targetObjectId, accountStatus: AccountStatus.ACTIVE }),
      Invitation.countDocuments({ collegeId: targetObjectId, status: InvitationStatus.PENDING }),
    ]);

    return {
      college: college.toJSON(),
      status: college.status,
      isActive: college.isActive,
      departmentCount,
      collegeAdminCount,
      hodCount,
      facultyCount,
      studentCount,
      activeUserCount,
      pendingInvitationCount,
    };
  }

  /**
   * Super Admin Permanent College Deletion with Cascading Entity Cleanup
   */
  static async deleteCollegePermanently(collegeId: string, actorUserId: string): Promise<void> {
    if (!mongoose.Types.ObjectId.isValid(collegeId)) {
      throw ApiError.badRequest(`Invalid College ID format: "${collegeId}"`);
    }

    const college = await College.findById(collegeId);
    if (!college) {
      throw ApiError.notFound(`College with ID "${collegeId}" not found`);
    }

    const targetObjectId = new mongoose.Types.ObjectId(collegeId);

    // Find all user IDs belonging to this college to clean up their sessions
    const collegeUsers = await User.find({ collegeId: targetObjectId }).select('_id');
    const userIds = collegeUsers.map((u) => u._id);

    await Promise.all([
      // Direct college entities
      College.findByIdAndDelete(targetObjectId),
      Department.deleteMany({ collegeId: targetObjectId }),
      Course.deleteMany({ collegeId: targetObjectId }),
      AcademicYear.deleteMany({ collegeId: targetObjectId }),
      Semester.deleteMany({ collegeId: targetObjectId }),
      Section.deleteMany({ collegeId: targetObjectId }),
      Subject.deleteMany({ collegeId: targetObjectId }),
      Room.deleteMany({ collegeId: targetObjectId }),
      Timetable.deleteMany({ collegeId: targetObjectId }),
      AttendanceSession.deleteMany({ collegeId: targetObjectId }),
      AttendanceRecord.deleteMany({ collegeId: targetObjectId }),
      FacultyAssignment.deleteMany({ collegeId: targetObjectId }),
      Invitation.deleteMany({ collegeId: targetObjectId }),
      Note.deleteMany({ collegeId: targetObjectId }),
      Notification.deleteMany({ collegeId: targetObjectId }),
      StudentEnrollment.deleteMany({ collegeId: targetObjectId }),
      Student.deleteMany({ collegeId: targetObjectId }),
      Faculty.deleteMany({ collegeId: targetObjectId }),
      // Users and their sessions
      User.deleteMany({ collegeId: targetObjectId }),
      AuthSession.deleteMany({ userId: { $in: userIds } }),
    ]);

    await AuditLog.create({
      actorUserId,
      collegeId: targetObjectId,
      action: 'COLLEGE_PERMANENTLY_DELETED',
      entityType: 'College',
      entityId: college.id,
      oldValue: {
        name: college.name,
        code: college.code,
        status: college.status,
      },
    });
  }
}

