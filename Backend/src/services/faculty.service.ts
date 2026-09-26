import mongoose from 'mongoose';
import { User, IUser } from '../models/user.model';
import { Faculty, IFaculty } from '../models/faculty.model';
import { College } from '../models/college.model';
import { Department } from '../models/department.model';
import { Invitation } from '../models/invitation.model';
import { AuditLog } from '../models/auditLog.model';
import { AppRole } from '../constants/roles';
import { AccountStatus, CollegeStatus, DepartmentStatus } from '../constants/status';
import { ApiError } from '../utils/apiError';
import { AuthenticatedUser } from '../types/auth.types';
import { InvitationService, CreateInvitationResult } from './invitation.service';
import { normalizeEmail, normalizePhone } from '../utils/identifier';

export interface ProvisionFacultyInput {
  departmentId: string;
  name: string;
  instituteId: string;
  email: string;
  phone?: string;
  employeeId?: string;
  designation?: string;
  qualification?: string;
  specialization?: string;
  joiningDate?: string;
  metadata?: Record<string, unknown>;
}

export interface UpdateFacultyProfileInput {
  name?: string;
  email?: string;
  phone?: string;
  employeeId?: string;
  designation?: string;
  qualification?: string;
  specialization?: string;
  profilePictureUrl?: string;
  metadata?: Record<string, unknown>;
}

export interface ListFacultyQuery {
  page?: number;
  limit?: number;
  search?: string;
  collegeId?: string;
  departmentId?: string;
  status?: AccountStatus | string;
  sortBy?: 'name' | 'instituteId' | 'employeeId' | 'createdAt';
  sortOrder?: 'asc' | 'desc';
}

export interface PaginatedResult<T> {
  items: T[];
  page: number;
  limit: number;
  total: number;
  totalPages: number;
}

export class FacultyService {
  /**
   * Provision Faculty Account & Profile using Phase 9C Invitation Engine
   */
  static async provisionFaculty(
    input: ProvisionFacultyInput,
    requester: AuthenticatedUser
  ): Promise<{
    user: IUser;
    faculty: IFaculty;
    invitation: CreateInvitationResult['invitation'];
    activationCode: string;
  }> {
    if (![AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN, AppRole.HOD].includes(requester.role)) {
      throw ApiError.forbidden('Only administrators and HODs have permission to provision faculty accounts');
    }

    if (!mongoose.Types.ObjectId.isValid(input.departmentId)) {
      throw ApiError.badRequest(`Invalid Department ID format: "${input.departmentId}"`);
    }

    const dept = await Department.findById(input.departmentId);
    if (!dept) {
      throw ApiError.notFound(`Department with ID "${input.departmentId}" not found`);
    }

    if (dept.status === DepartmentStatus.INACTIVE || !dept.isActive) {
      throw ApiError.forbidden('Cannot provision faculty for an inactive department');
    }

    const college = await College.findById(dept.collegeId);
    if (!college || college.status === CollegeStatus.INACTIVE || !college.isActive) {
      throw ApiError.forbidden('Cannot provision faculty for an inactive college');
    }

    // Role-specific scoping
    if (requester.role === AppRole.COLLEGE_ADMIN) {
      if (!requester.collegeId || dept.collegeId.toString() !== requester.collegeId.toString()) {
        throw ApiError.forbidden('College Admin cannot provision faculty for another college');
      }
    } else if (requester.role === AppRole.HOD) {
      if (!requester.departmentId || dept._id.toString() !== requester.departmentId.toString()) {
        throw ApiError.forbidden('HOD cannot provision faculty outside their assigned department');
      }
    }

    // Check employeeId uniqueness within college if provided
    if (input.employeeId && input.employeeId.trim() !== '') {
      const existingEmployee = await Faculty.findOne({
        collegeId: dept.collegeId,
        employeeId: input.employeeId.trim(),
      });
      if (existingEmployee) {
        throw ApiError.conflict(`Faculty with employee ID "${input.employeeId.trim()}" already exists in this college`);
      }
    }

    // 1. Create User & Invitation via Phase 9C
    const invitationResult = await InvitationService.createInvitation(requester, {
      name: input.name,
      instituteId: input.instituteId,
      email: input.email,
      phone: input.phone,
      role: AppRole.FACULTY,
      departmentId: input.departmentId,
    });

    const user = invitationResult.user;

    // 2. Create Faculty Profile
    let faculty: IFaculty;
    try {
      faculty = await Faculty.create({
        collegeId: dept.collegeId,
        departmentId: dept._id,
        userId: user._id,
        instituteId: user.instituteId,
        name: user.name,
        employeeId: input.employeeId?.trim() || undefined,
        email: user.email,
        phone: user.phone || null,
        designation: input.designation?.trim() || 'Assistant Professor',
        qualification: input.qualification?.trim() || '',
        specialization: input.specialization?.trim() || '',
        joiningDate: input.joiningDate ? new Date(input.joiningDate) : null,
        status: 'active',
        isActive: true,
        metadata: input.metadata || null,
      });
    } catch (err: any) {
      // Compensating Rollback: Remove User and Invitation to prevent orphan states
      await Promise.all([
        User.findByIdAndDelete(user._id),
        Invitation.findByIdAndDelete(invitationResult.invitation.id),
      ]);
      if (err.code === 11000) {
        throw ApiError.conflict('Faculty profile with this userId or employeeId already exists');
      }
      throw err;
    }

    // 3. Audit Log
    await AuditLog.create({
      collegeId: dept.collegeId.toString(),
      actorUserId: requester.id,
      action: 'FACULTY_PROVISIONED',
      entityType: 'Faculty',
      entityId: faculty.id,
      newValue: {
        userId: user.id,
        instituteId: user.instituteId,
        departmentId: dept.id,
        collegeId: dept.collegeId.toString(),
        employeeId: faculty.employeeId,
      },
    });

    return {
      user,
      faculty,
      invitation: invitationResult.invitation,
      activationCode: invitationResult.activationCode,
    };
  }

  /**
   * Get Faculty by User/Faculty ID
   */
  static async getFacultyById(id: string, requester: AuthenticatedUser): Promise<{ user: IUser; faculty: IFaculty | null }> {
    if (!mongoose.Types.ObjectId.isValid(id)) {
      throw ApiError.badRequest(`Invalid Faculty ID format: "${id}"`);
    }

    // Try finding by User._id or Faculty._id
    let user = await User.findOne({ _id: id, role: AppRole.FACULTY });
    let faculty: IFaculty | null = null;

    if (user) {
      faculty = await Faculty.findOne({ userId: user._id });
    } else {
      faculty = await Faculty.findById(id);
      if (faculty && faculty.userId) {
        user = await User.findById(faculty.userId);
      }
    }

    if (!user) {
      throw ApiError.notFound(`Faculty with ID "${id}" not found`);
    }

    // Scoping
    if (requester.role === AppRole.SUPER_ADMIN) {
      return { user, faculty };
    }

    if (requester.role === AppRole.COLLEGE_ADMIN) {
      if (!requester.collegeId || user.collegeId?.toString() !== requester.collegeId.toString()) {
        throw ApiError.forbidden('Cross-college tenant access is strictly prohibited');
      }
      return { user, faculty };
    }

    if (requester.role === AppRole.HOD) {
      if (!requester.departmentId || user.departmentId?.toString() !== requester.departmentId.toString()) {
        throw ApiError.forbidden('Cross-department access is strictly prohibited for HOD');
      }
      return { user, faculty };
    }

    if (requester.role === AppRole.FACULTY) {
      if (user._id.toString() !== requester.id) {
        throw ApiError.forbidden('Faculty can only view their own profile');
      }
      return { user, faculty };
    }

    throw ApiError.forbidden('Access denied to faculty administration');
  }

  /**
   * List Faculty (Admin, College Admin, HOD)
   */
  static async listFaculty(
    requester: AuthenticatedUser,
    query: ListFacultyQuery = {}
  ): Promise<PaginatedResult<{ user: IUser; faculty: IFaculty | null }>> {
    if (![AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN, AppRole.HOD].includes(requester.role)) {
      throw ApiError.forbidden('Only administrators and HODs have permission to access faculty administration');
    }

    const mongoQuery: Record<string, unknown> = {
      role: AppRole.FACULTY,
    };

    // Scoping
    if (requester.role === AppRole.COLLEGE_ADMIN) {
      if (!requester.collegeId) {
        return { items: [], page: 1, limit: 1, total: 0, totalPages: 0 };
      }
      if (query.collegeId && query.collegeId.toString() !== requester.collegeId.toString()) {
        throw ApiError.forbidden('Cross-college tenant access is strictly prohibited');
      }
      mongoQuery.collegeId = new mongoose.Types.ObjectId(requester.collegeId);
    } else if (requester.role === AppRole.HOD) {
      if (!requester.collegeId || !requester.departmentId) {
        return { items: [], page: 1, limit: 1, total: 0, totalPages: 0 };
      }
      if (query.collegeId && query.collegeId.toString() !== requester.collegeId.toString()) {
        throw ApiError.forbidden('Cross-college tenant access is strictly prohibited');
      }
      if (query.departmentId && query.departmentId.toString() !== requester.departmentId.toString()) {
        throw ApiError.forbidden('HOD cannot access faculty outside their assigned department');
      }
      mongoQuery.collegeId = new mongoose.Types.ObjectId(requester.collegeId);
      mongoQuery.departmentId = new mongoose.Types.ObjectId(requester.departmentId);
    } else if (query.collegeId) {
      if (!mongoose.Types.ObjectId.isValid(query.collegeId)) {
        throw ApiError.badRequest(`Invalid College ID format: "${query.collegeId}"`);
      }
      mongoQuery.collegeId = new mongoose.Types.ObjectId(query.collegeId);
    }

    if (query.departmentId && requester.role !== AppRole.HOD) {
      if (!mongoose.Types.ObjectId.isValid(query.departmentId)) {
        throw ApiError.badRequest(`Invalid Department ID format: "${query.departmentId}"`);
      }
      mongoQuery.departmentId = new mongoose.Types.ObjectId(query.departmentId);
    }

    if (query.status && query.status.toString().toUpperCase() !== 'ALL') {
      mongoQuery.accountStatus = query.status;
    }

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

    const [users, total] = await Promise.all([
      User.find(mongoQuery).sort(sortOptions).skip(skip).limit(limit),
      User.countDocuments(mongoQuery),
    ]);

    const userIds = users.map((u) => u._id);
    const facultyProfiles = await Faculty.find({ userId: { $in: userIds } });
    const profileMap = new Map(facultyProfiles.map((f) => [f.userId.toString(), f]));

    const items = users.map((u) => ({
      user: u,
      faculty: profileMap.get(u._id.toString()) || null,
    }));

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
   * Update Faculty Profile
   */
  static async updateFacultyProfile(
    id: string,
    update: UpdateFacultyProfileInput,
    requester: AuthenticatedUser
  ): Promise<{ user: IUser; faculty: IFaculty | null }> {
    const { user, faculty } = await this.getFacultyById(id, requester);

    const previousUser = user.toJSON();

    if (update.name) {
      user.name = update.name.trim();
      if (faculty) faculty.name = update.name.trim();
    }

    if (update.email) {
      const normalizedEmail = normalizeEmail(update.email);
      if (normalizedEmail !== user.email) {
        const existing = await User.findOne({ email: normalizedEmail, _id: { $ne: user._id } });
        if (existing) {
          throw ApiError.conflict(`Email "${normalizedEmail}" is already registered`);
        }
        user.email = normalizedEmail;
        if (faculty) faculty.email = normalizedEmail;
      }
    }

    if (update.phone !== undefined) {
      if (update.phone === '' || update.phone === null) {
        user.phone = undefined;
        if (faculty) faculty.phone = undefined;
      } else {
        const normalizedPhone = normalizePhone(update.phone);
        if (normalizedPhone !== user.phone) {
          const existing = await User.findOne({ phone: normalizedPhone, _id: { $ne: user._id } });
          if (existing) {
            throw ApiError.conflict(`Phone number "${normalizedPhone}" is already registered`);
          }
          user.phone = normalizedPhone;
          if (faculty) faculty.phone = normalizedPhone;
        }
      }
    }

    if (update.profilePictureUrl !== undefined) {
      user.profilePictureUrl = update.profilePictureUrl;
    }

    if (faculty) {
      if (update.employeeId !== undefined) {
        if (update.employeeId && update.employeeId.trim() !== '') {
          const empTrimmed = update.employeeId.trim();
          if (empTrimmed !== faculty.employeeId) {
            const existingEmp = await Faculty.findOne({
              collegeId: faculty.collegeId,
              employeeId: empTrimmed,
              _id: { $ne: faculty._id },
            });
            if (existingEmp) {
              throw ApiError.conflict(`Employee ID "${empTrimmed}" is already registered in this college`);
            }
            faculty.employeeId = empTrimmed;
          }
        } else {
          faculty.employeeId = undefined;
        }
      }

      if (update.designation !== undefined) faculty.designation = update.designation.trim();
      if (update.qualification !== undefined) faculty.qualification = update.qualification.trim();
      if (update.specialization !== undefined) faculty.specialization = update.specialization.trim();
      if (update.metadata) faculty.metadata = update.metadata;

      await faculty.save();
    }

    await user.save();

    await AuditLog.create({
      collegeId: user.collegeId ? user.collegeId.toString() : 'GLOBAL',
      actorUserId: requester.id,
      action: 'FACULTY_UPDATED',
      entityType: 'Faculty',
      entityId: faculty ? faculty.id : user.id,
      previousValue: previousUser,
      newValue: user.toJSON(),
    });

    return { user, faculty };
  }

  /**
   * Safe Administrative Department Transfer
   */
  static async transferFacultyDepartment(
    id: string,
    targetDepartmentId: string,
    requester: AuthenticatedUser
  ): Promise<{ user: IUser; faculty: IFaculty | null }> {
    if (![AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN].includes(requester.role)) {
      throw ApiError.forbidden('Only Super Admin and College Admin have permission to transfer faculty');
    }

    if (!mongoose.Types.ObjectId.isValid(targetDepartmentId)) {
      throw ApiError.badRequest(`Invalid Department ID format: "${targetDepartmentId}"`);
    }

    const { user, faculty } = await this.getFacultyById(id, requester);

    const targetDept = await Department.findById(targetDepartmentId);
    if (!targetDept) {
      throw ApiError.notFound(`Target Department with ID "${targetDepartmentId}" not found`);
    }

    if (targetDept.status === DepartmentStatus.INACTIVE || !targetDept.isActive) {
      throw ApiError.forbidden('Cannot transfer faculty to an inactive department');
    }

    if (requester.role === AppRole.COLLEGE_ADMIN) {
      if (targetDept.collegeId.toString() !== requester.collegeId?.toString()) {
        throw ApiError.forbidden('Cannot transfer faculty to a department belonging to another college');
      }
    }

    const targetCollege = await College.findById(targetDept.collegeId);
    if (!targetCollege || targetCollege.status === CollegeStatus.INACTIVE || !targetCollege.isActive) {
      throw ApiError.forbidden('Cannot transfer faculty to an inactive college');
    }

    const oldDepartmentId = user.departmentId?.toString();
    const oldCollegeId = user.collegeId?.toString();

    // Update User
    user.departmentId = targetDept._id;
    user.collegeId = targetDept.collegeId;
    await user.save();

    // Update Faculty Profile
    if (faculty) {
      faculty.departmentId = targetDept._id;
      faculty.collegeId = targetDept.collegeId;
      await faculty.save();
    }

    await AuditLog.create({
      collegeId: targetDept.collegeId.toString(),
      actorUserId: requester.id,
      action: 'FACULTY_DEPARTMENT_TRANSFERRED',
      entityType: 'Faculty',
      entityId: faculty ? faculty.id : user.id,
      previousValue: {
        departmentId: oldDepartmentId,
        collegeId: oldCollegeId,
      },
      newValue: {
        departmentId: targetDept._id.toString(),
        collegeId: targetDept.collegeId.toString(),
      },
    });

    return { user, faculty };
  }

  /**
   * Get Faculty Summary Metrics
   */
  static async getFacultySummary(
    id: string,
    requester: AuthenticatedUser
  ): Promise<Record<string, unknown>> {
    const { user, faculty } = await this.getFacultyById(id, requester);

    const [college, department] = await Promise.all([
      user.collegeId ? College.findById(user.collegeId) : null,
      user.departmentId ? Department.findById(user.departmentId) : null,
    ]);

    return {
      user: user.toJSON(),
      faculty: faculty ? faculty.toJSON() : null,
      college: college ? college.toJSON() : null,
      department: department ? department.toJSON() : null,
      assignmentCount: 0,
      sectionCount: faculty?.sectionIds?.length || 0,
      subjectCount: faculty?.subjectIds?.length || 0,
    };
  }

  /**
   * Get Department Faculty Lookup
   */
  static async getDepartmentFaculty(
    departmentId: string,
    requester: AuthenticatedUser
  ): Promise<{ user: IUser; faculty: IFaculty | null }[]> {
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
        throw ApiError.forbidden('HOD can only lookup faculty within their assigned department');
      }
    } else if (requester.role !== AppRole.SUPER_ADMIN) {
      throw ApiError.forbidden('Access denied');
    }

    const users = await User.find({
      departmentId: department._id,
      role: AppRole.FACULTY,
    }).sort({ name: 1 });

    const userIds = users.map((u) => u._id);
    const facultyProfiles = await Faculty.find({ userId: { $in: userIds } });
    const profileMap = new Map(facultyProfiles.map((f) => [f.userId.toString(), f]));

    return users.map((u) => ({
      user: u,
      faculty: profileMap.get(u._id.toString()) || null,
    }));
  }
}
