import mongoose from 'mongoose';
import { User, IUser } from '../models/user.model';
import { College } from '../models/college.model';
import { Department } from '../models/department.model';
import { Course } from '../models/course.model';
import { Faculty } from '../models/faculty.model';
import { AuditLog } from '../models/auditLog.model';
import { AppRole } from '../constants/roles';
import { AccountStatus, CollegeStatus, DepartmentStatus } from '../constants/status';
import { ApiError } from '../utils/apiError';
import { AuthenticatedUser } from '../types/auth.types';
import { InvitationService, CreateInvitationResult } from './invitation.service';
import { normalizeEmail, normalizePhone } from '../utils/identifier';
import { UserService } from './user.service';

export interface ProvisionHodInput {
  departmentId: string;
  name: string;
  instituteId: string;
  email: string;
  phone?: string;
}

export interface UpdateHodProfileInput {
  name?: string;
  email?: string;
  phone?: string;
  profilePictureUrl?: string;
}

export interface ListHodsQuery {
  page?: number;
  limit?: number;
  search?: string;
  collegeId?: string;
  departmentId?: string;
  status?: AccountStatus;
  sortBy?: 'name' | 'instituteId' | 'createdAt';
  sortOrder?: 'asc' | 'desc';
}

export interface PaginatedResult<T> {
  items: T[];
  page: number;
  limit: number;
  total: number;
  totalPages: number;
}

export class HodService {
  /**
   * Provision HOD Account using Phase 9C Invitation Engine
   */
  static async provisionHod(
    input: ProvisionHodInput,
    requester: AuthenticatedUser
  ): Promise<CreateInvitationResult> {
    if (![AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN].includes(requester.role)) {
      throw ApiError.forbidden('Only administrators have permission to provision HOD accounts');
    }

    if (!mongoose.Types.ObjectId.isValid(input.departmentId)) {
      throw ApiError.badRequest(`Invalid Department ID format: "${input.departmentId}"`);
    }

    const result = await InvitationService.createInvitation(requester, {
      name: input.name,
      instituteId: input.instituteId,
      email: input.email,
      phone: input.phone,
      role: AppRole.HOD,
      departmentId: input.departmentId,
    });

    return result;
  }

  /**
   * Get HOD by ID
   */
  static async getHodById(id: string, requester: AuthenticatedUser): Promise<IUser> {
    if (!mongoose.Types.ObjectId.isValid(id)) {
      throw ApiError.badRequest(`Invalid HOD ID format: "${id}"`);
    }

    const hod = await User.findOne({ _id: id, role: AppRole.HOD });
    if (!hod) {
      throw ApiError.notFound(`HOD with ID "${id}" not found`);
    }

    // Tenant Scoping
    if (requester.role === AppRole.SUPER_ADMIN) {
      return hod;
    }

    if (requester.role === AppRole.COLLEGE_ADMIN) {
      if (!requester.collegeId || hod.collegeId?.toString() !== requester.collegeId.toString()) {
        throw ApiError.forbidden('Cross-college tenant access is strictly prohibited');
      }
      return hod;
    }

    if (requester.role === AppRole.HOD) {
      if (hod._id.toString() !== requester.id) {
        throw ApiError.forbidden('HOD can only view their own record');
      }
      return hod;
    }

    throw ApiError.forbidden('Access denied to HOD administration');
  }

  /**
   * List HODs (Admin only)
   */
  static async listHods(
    requester: AuthenticatedUser,
    query: ListHodsQuery = {}
  ): Promise<PaginatedResult<IUser>> {
    if (![AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN].includes(requester.role)) {
      throw ApiError.forbidden('Only administrators have permission to access HOD administration');
    }

    const mongoQuery: Record<string, unknown> = {
      role: AppRole.HOD,
    };

    // Tenant Isolation
    if (requester.role === AppRole.COLLEGE_ADMIN) {
      if (!requester.collegeId) {
        return { items: [], page: 1, limit: 1, total: 0, totalPages: 0 };
      }
      if (query.collegeId && query.collegeId.toString() !== requester.collegeId.toString()) {
        throw ApiError.forbidden('Cross-college tenant access is strictly prohibited');
      }
      mongoQuery.collegeId = new mongoose.Types.ObjectId(requester.collegeId);
    } else if (query.collegeId) {
      if (!mongoose.Types.ObjectId.isValid(query.collegeId)) {
        throw ApiError.badRequest(`Invalid College ID format: "${query.collegeId}"`);
      }
      mongoQuery.collegeId = new mongoose.Types.ObjectId(query.collegeId);
    }

    if (query.departmentId) {
      if (!mongoose.Types.ObjectId.isValid(query.departmentId)) {
        throw ApiError.badRequest(`Invalid Department ID format: "${query.departmentId}"`);
      }
      mongoQuery.departmentId = new mongoose.Types.ObjectId(query.departmentId);
    }

    if (query.status) {
      mongoQuery.accountStatus = query.status;
    }

    // Search by name, instituteId, email
    if (query.search && query.search.trim() !== '') {
      const searchRegex = new RegExp(query.search.trim(), 'i');
      mongoQuery.$or = [
        { name: searchRegex },
        { instituteId: searchRegex },
        { email: searchRegex },
      ];
    }

    const page = Math.max(1, query.page || 1);
    const limit = Math.min(100, Math.max(1, query.limit || 20));
    const skip = (page - 1) * limit;

    const allowedSortFields = ['name', 'instituteId', 'createdAt'];
    const sortField = allowedSortFields.includes(query.sortBy || '') ? query.sortBy! : 'name';
    const sortOrder = query.sortOrder === 'desc' ? -1 : 1;
    const sortOptions: Record<string, 1 | -1> = { [sortField]: sortOrder };

    const [items, total] = await Promise.all([
      User.find(mongoQuery).sort(sortOptions).skip(skip).limit(limit),
      User.countDocuments(mongoQuery),
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
   * Update HOD Profile (Safely updates name, email, phone without changing role/department/instituteId)
   */
  static async updateHodProfile(
    id: string,
    update: UpdateHodProfileInput,
    requester: AuthenticatedUser
  ): Promise<IUser> {
    if (!mongoose.Types.ObjectId.isValid(id)) {
      throw ApiError.badRequest(`Invalid HOD ID format: "${id}"`);
    }

    const hod = await User.findOne({ _id: id, role: AppRole.HOD });
    if (!hod) {
      throw ApiError.notFound(`HOD with ID "${id}" not found`);
    }

    // Tenant & Actor authorization
    if (requester.role === AppRole.COLLEGE_ADMIN) {
      if (!requester.collegeId || hod.collegeId?.toString() !== requester.collegeId.toString()) {
        throw ApiError.forbidden('Cross-college tenant access is strictly prohibited');
      }
    } else if (requester.role === AppRole.HOD) {
      if (hod._id.toString() !== requester.id) {
        throw ApiError.forbidden('HOD can only update their own profile');
      }
    } else if (requester.role !== AppRole.SUPER_ADMIN) {
      throw ApiError.forbidden('Access denied to update HOD');
    }

    const previousValue = hod.toJSON();

    if (update.name) {
      hod.name = update.name.trim();
    }

    if (update.email) {
      const normalizedEmail = normalizeEmail(update.email);
      if (normalizedEmail !== hod.email) {
        const existing = await User.findOne({ email: normalizedEmail, _id: { $ne: hod._id } });
        if (existing) {
          throw ApiError.conflict(`Email "${normalizedEmail}" is already registered`);
        }
        hod.email = normalizedEmail;
      }
    }

    if (update.phone !== undefined) {
      if (update.phone === '' || update.phone === null) {
        hod.phone = undefined;
      } else {
        const normalizedPhone = normalizePhone(update.phone);
        if (normalizedPhone !== hod.phone) {
          const existing = await User.findOne({ phone: normalizedPhone, _id: { $ne: hod._id } });
          if (existing) {
            throw ApiError.conflict(`Phone number "${normalizedPhone}" is already registered`);
          }
          hod.phone = normalizedPhone;
        }
      }
    }

    if (update.profilePictureUrl !== undefined) {
      hod.profilePictureUrl = update.profilePictureUrl;
    }

    await hod.save();

    await AuditLog.create({
      collegeId: hod.collegeId ? hod.collegeId.toString() : 'GLOBAL',
      actorUserId: requester.id,
      action: 'HOD_UPDATED',
      entityType: 'User',
      entityId: hod.id,
      previousValue,
      newValue: hod.toJSON(),
    });

    return hod;
  }

  /**
   * Safe Transfer of HOD to another Department
   */
  static async transferHodDepartment(
    id: string,
    targetDepartmentId: string,
    requester: AuthenticatedUser
  ): Promise<IUser> {
    if (![AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN].includes(requester.role)) {
      throw ApiError.forbidden('Only administrators have permission to transfer HODs');
    }

    if (!mongoose.Types.ObjectId.isValid(id)) {
      throw ApiError.badRequest(`Invalid HOD ID format: "${id}"`);
    }

    if (!mongoose.Types.ObjectId.isValid(targetDepartmentId)) {
      throw ApiError.badRequest(`Invalid Department ID format: "${targetDepartmentId}"`);
    }

    const hod = await User.findOne({ _id: id, role: AppRole.HOD });
    if (!hod) {
      throw ApiError.notFound(`HOD with ID "${id}" not found`);
    }

    // Check college admin tenant boundary on source HOD
    if (requester.role === AppRole.COLLEGE_ADMIN) {
      if (!requester.collegeId || hod.collegeId?.toString() !== requester.collegeId.toString()) {
        throw ApiError.forbidden('Cross-college tenant access is strictly prohibited');
      }
    }

    const targetDept = await Department.findById(targetDepartmentId);
    if (!targetDept) {
      throw ApiError.notFound(`Target Department with ID "${targetDepartmentId}" not found`);
    }

    if (targetDept.status === DepartmentStatus.INACTIVE || !targetDept.isActive) {
      throw ApiError.forbidden('Cannot transfer HOD to an inactive department');
    }

    // Check college admin tenant boundary on destination department
    if (requester.role === AppRole.COLLEGE_ADMIN) {
      if (targetDept.collegeId.toString() !== requester.collegeId?.toString()) {
        throw ApiError.forbidden('Cannot transfer HOD to a department belonging to another college');
      }
    }

    const targetCollege = await College.findById(targetDept.collegeId);
    if (!targetCollege || targetCollege.status === CollegeStatus.INACTIVE || !targetCollege.isActive) {
      throw ApiError.forbidden('Cannot transfer HOD to a department in an inactive college');
    }

    // Check if target department already has an active HOD
    const existingHod = await User.findOne({
      departmentId: targetDept._id,
      role: AppRole.HOD,
      _id: { $ne: hod._id },
      accountStatus: { $in: [AccountStatus.ACTIVE, AccountStatus.PENDING_ACTIVATION] },
    });

    if (existingHod) {
      throw ApiError.conflict('Target department already has an active or pending HOD');
    }

    const oldDepartmentId = hod.departmentId?.toString();
    const oldCollegeId = hod.collegeId?.toString();

    // Clear old department hod pointer
    if (oldDepartmentId) {
      await Department.findByIdAndUpdate(oldDepartmentId, { hodId: null });
    }

    // Update target department hod pointer
    targetDept.hodId = hod._id.toString();
    await targetDept.save();

    // Update HOD
    hod.departmentId = targetDept._id;
    hod.collegeId = targetDept.collegeId;
    await hod.save();

    await AuditLog.create({
      collegeId: targetDept.collegeId.toString(),
      actorUserId: requester.id,
      action: 'HOD_DEPARTMENT_TRANSFERRED',
      entityType: 'User',
      entityId: hod.id,
      previousValue: {
        departmentId: oldDepartmentId,
        collegeId: oldCollegeId,
      },
      newValue: {
        departmentId: targetDept._id.toString(),
        collegeId: targetDept.collegeId.toString(),
      },
    });

    return hod;
  }

  /**
   * Get HOD by Department ID lookup
   */
  static async getDepartmentHod(
    departmentId: string,
    requester: AuthenticatedUser
  ): Promise<IUser | null> {
    if (!mongoose.Types.ObjectId.isValid(departmentId)) {
      throw ApiError.badRequest(`Invalid Department ID format: "${departmentId}"`);
    }

    const department = await Department.findById(departmentId);
    if (!department) {
      throw ApiError.notFound(`Department with ID "${departmentId}" not found`);
    }

    // Scoping
    if (requester.role === AppRole.COLLEGE_ADMIN) {
      if (!requester.collegeId || department.collegeId.toString() !== requester.collegeId.toString()) {
        throw ApiError.forbidden('Cross-college tenant access is strictly prohibited');
      }
    } else if (requester.role === AppRole.HOD) {
      if (requester.departmentId?.toString() !== department._id.toString()) {
        throw ApiError.forbidden('HOD can only lookup their own department HOD');
      }
    } else if (requester.role !== AppRole.SUPER_ADMIN) {
      throw ApiError.forbidden('Access denied');
    }

    const hod = await User.findOne({
      departmentId: department._id,
      role: AppRole.HOD,
      accountStatus: { $in: [AccountStatus.ACTIVE, AccountStatus.PENDING_ACTIVATION] },
    });

    return hod;
  }

  /**
   * Get HOD Summary Metrics
   */
  static async getHodSummary(
    id: string,
    requester: AuthenticatedUser
  ): Promise<Record<string, unknown>> {
    const hod = await this.getHodById(id, requester);

    const [college, department, facultyCount, studentCount, subjectCount] = await Promise.all([
      hod.collegeId ? College.findById(hod.collegeId) : null,
      hod.departmentId ? Department.findById(hod.departmentId) : null,
      hod.departmentId ? User.countDocuments({ departmentId: hod.departmentId, role: AppRole.FACULTY }) : 0,
      hod.departmentId ? User.countDocuments({ departmentId: hod.departmentId, role: AppRole.STUDENT }) : 0,
      hod.departmentId ? Course.countDocuments({ departmentId: hod.departmentId }) : 0,
    ]);

    return {
      hod: hod.toJSON(),
      college: college ? college.toJSON() : null,
      department: department ? department.toJSON() : null,
      facultyCount,
      studentCount,
      subjectCount,
    };
  }

  /**
   * Assign Existing User to HOD Role & Department
   */
  static async assignExistingUserToHod(
    input: { userId: string; departmentId: string },
    requester: AuthenticatedUser
  ): Promise<{ user: IUser; department: InstanceType<typeof Department> }> {
    if (![AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN].includes(requester.role)) {
      throw ApiError.forbidden('Only administrators have permission to assign HOD roles');
    }

    if (!mongoose.Types.ObjectId.isValid(input.userId)) {
      throw ApiError.badRequest(`Invalid User ID format: "${input.userId}"`);
    }

    if (!mongoose.Types.ObjectId.isValid(input.departmentId)) {
      throw ApiError.badRequest(`Invalid Department ID format: "${input.departmentId}"`);
    }

    let user = await User.findById(input.userId);
    if (!user) {
      const faculty = await Faculty.findById(input.userId);
      if (faculty && faculty.userId) {
        user = await User.findById(faculty.userId);
      }
    }
    const targetDept = await Department.findById(input.departmentId);

    if (!user) {
      throw ApiError.notFound(`User with ID "${input.userId}" not found`);
    }

    if (!targetDept) {
      throw ApiError.notFound(`Department with ID "${input.departmentId}" not found`);
    }

    if (targetDept.status === DepartmentStatus.INACTIVE || !targetDept.isActive) {
      throw ApiError.forbidden('Cannot assign HOD to an inactive department');
    }

    // Tenant Scoping
    if (requester.role === AppRole.COLLEGE_ADMIN) {
      if (!requester.collegeId || user.collegeId?.toString() !== requester.collegeId.toString()) {
        throw ApiError.forbidden('Cross-college tenant access is strictly prohibited for user');
      }
      if (targetDept.collegeId.toString() !== requester.collegeId.toString()) {
        throw ApiError.forbidden('Cross-college tenant access is strictly prohibited for department');
      }
    }

    if (user.collegeId && targetDept.collegeId.toString() !== user.collegeId.toString()) {
      throw ApiError.badRequest('User and Department must belong to the same college');
    }

    // Check if target department already has an active HOD
    const existingHod = await User.findOne({
      departmentId: targetDept._id,
      role: AppRole.HOD,
      _id: { $ne: user._id },
      accountStatus: { $in: [AccountStatus.ACTIVE, AccountStatus.PENDING_ACTIVATION] },
    });

    if (existingHod) {
      throw ApiError.conflict('Target department already has an active or pending HOD');
    }

    const previousRole = user.role;
    const oldDepartmentId = user.departmentId?.toString();

    // If user was previously HOD of another department, clear that department's hodId
    if (oldDepartmentId && oldDepartmentId !== targetDept._id.toString() && previousRole === AppRole.HOD) {
      await Department.findByIdAndUpdate(oldDepartmentId, { hodId: null });
    }

    // Authoritative assignment
    user.role = AppRole.HOD;
    user.departmentId = targetDept._id;
    user.collegeId = targetDept.collegeId;
    await user.save();

    targetDept.hodId = user._id.toString();
    await targetDept.save();

    await AuditLog.create({
      collegeId: targetDept.collegeId.toString(),
      actorUserId: requester.id,
      action: 'HOD_ASSIGNED_FROM_EXISTING_USER',
      entityType: 'User',
      entityId: user.id,
      previousValue: {
        role: previousRole,
        departmentId: oldDepartmentId,
      },
      newValue: {
        role: AppRole.HOD,
        departmentId: targetDept._id.toString(),
        collegeId: targetDept.collegeId.toString(),
      },
    });

    return { user, department: targetDept };
  }

  /**
   * Unassign / Remove HOD Assignment
   * Clears department hodId and demotes user role to FACULTY (or specified newRole)
   */
  static async unassignHod(
    id: string,
    options: { newRole?: AppRole } = {},
    requester: AuthenticatedUser
  ): Promise<IUser> {
    if (![AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN].includes(requester.role)) {
      throw ApiError.forbidden('Only administrators have permission to unassign HODs');
    }

    if (!mongoose.Types.ObjectId.isValid(id)) {
      throw ApiError.badRequest(`Invalid HOD ID format: "${id}"`);
    }

    const hod = await User.findOne({ _id: id, role: AppRole.HOD });
    if (!hod) {
      throw ApiError.notFound(`HOD with ID "${id}" not found`);
    }

    // Tenant check
    if (requester.role === AppRole.COLLEGE_ADMIN) {
      if (!requester.collegeId || hod.collegeId?.toString() !== requester.collegeId.toString()) {
        throw ApiError.forbidden('Cross-college tenant access is strictly prohibited');
      }
    }

    const oldDeptId = hod.departmentId?.toString();
    if (oldDeptId) {
      await Department.findByIdAndUpdate(oldDeptId, { hodId: null });
    }

    const previousRole = hod.role;
    const demotedRole = options.newRole || AppRole.FACULTY;

    hod.role = demotedRole;
    await hod.save();

    await AuditLog.create({
      collegeId: hod.collegeId ? hod.collegeId.toString() : 'GLOBAL',
      actorUserId: requester.id,
      action: 'HOD_UNASSIGNED',
      entityType: 'User',
      entityId: hod.id,
      previousValue: {
        role: previousRole,
        departmentId: oldDeptId,
      },
      newValue: {
        role: demotedRole,
        departmentId: hod.departmentId?.toString(),
      },
    });

    return hod;
  }

  /**
   * Update HOD Status (Activate / Deactivate)
   */
  static async updateHodStatus(
    id: string,
    status: AccountStatus,
    requester: AuthenticatedUser,
    reason?: string
  ): Promise<IUser> {
    if (![AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN].includes(requester.role)) {
      throw ApiError.forbidden('Only administrators have permission to update HOD status');
    }

    if (status === AccountStatus.DEACTIVATED) {
      return UserService.deactivateUserSafely(id, requester, reason || 'HOD deactivated by administrator');
    } else if (status === AccountStatus.ACTIVE) {
      return UserService.reactivateUserSafely(id, requester);
    } else {
      throw ApiError.badRequest(`Unsupported status transition: ${status}`);
    }
  }
}
