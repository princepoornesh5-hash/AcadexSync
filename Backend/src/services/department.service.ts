import mongoose from 'mongoose';
import { Department, IDepartment } from '../models/department.model';
import { College } from '../models/college.model';
import { User } from '../models/user.model';
import { Course } from '../models/course.model';
import { AuditLog } from '../models/auditLog.model';
import { AppRole } from '../constants/roles';
import { CollegeStatus, DepartmentStatus, AccountStatus } from '../constants/status';
import { ApiError } from '../utils/apiError';
import { AuthenticatedUser } from '../types/auth.types';

export interface CreateDepartmentInput {
  collegeId?: string;
  name: string;
  code: string;
  description?: string;
  status?: DepartmentStatus;
  metadata?: Record<string, unknown>;
}

export interface UpdateDepartmentInput {
  name?: string;
  code?: string;
  description?: string;
  metadata?: Record<string, unknown>;
}

export interface ListDepartmentsQuery {
  page?: number;
  limit?: number;
  search?: string;
  collegeId?: string;
  status?: DepartmentStatus;
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

export class DepartmentService {
  /**
   * Create Department
   * SUPER_ADMIN can create for any active college.
   * COLLEGE_ADMIN can create only for their own active college.
   */
  static async createDepartment(
    input: CreateDepartmentInput,
    requester: AuthenticatedUser
  ): Promise<IDepartment> {
    let targetCollegeId: string | undefined;

    if (requester.role === AppRole.SUPER_ADMIN) {
      targetCollegeId = input.collegeId;
      if (!targetCollegeId) {
        throw ApiError.badRequest('collegeId is required for Super Admin to create a department');
      }
    } else if (requester.role === AppRole.COLLEGE_ADMIN) {
      if (!requester.collegeId) {
        throw ApiError.forbidden('College Admin has no assigned college');
      }
      if (input.collegeId && input.collegeId.toString() !== requester.collegeId.toString()) {
        throw ApiError.forbidden('Cross-college tenant access is strictly prohibited');
      }
      targetCollegeId = requester.collegeId;
    } else {
      throw ApiError.forbidden('Only administrators have permission to create departments');
    }

    if (!mongoose.Types.ObjectId.isValid(targetCollegeId)) {
      throw ApiError.badRequest(`Invalid College ID format: "${targetCollegeId}"`);
    }

    // Verify target College exists and is ACTIVE
    const college = await College.findById(targetCollegeId);
    if (!college) {
      throw ApiError.notFound(`College with ID "${targetCollegeId}" not found`);
    }

    if (college.status === CollegeStatus.INACTIVE || !college.isActive) {
      throw ApiError.forbidden('Cannot perform department operations on an inactive college');
    }

    const normalizedCode = input.code.trim().toUpperCase();
    const collegeObjectId = new mongoose.Types.ObjectId(targetCollegeId);

    // Check duplicate code within the same college
    const existing = await Department.findOne({
      collegeId: collegeObjectId,
      code: normalizedCode,
    });

    if (existing) {
      throw ApiError.conflict(`Department with code "${normalizedCode}" already exists in this college`);
    }

    const department = await Department.create({
      collegeId: collegeObjectId,
      name: input.name.trim(),
      code: normalizedCode,
      description: input.description?.trim() || '',
      status: input.status || DepartmentStatus.ACTIVE,
      isActive: (input.status || DepartmentStatus.ACTIVE) === DepartmentStatus.ACTIVE,
      createdBy: requester.id,
      updatedBy: requester.id,
      metadata: input.metadata || null,
    });

    await AuditLog.create({
      actorUserId: requester.id,
      collegeId: collegeObjectId.toString(),
      action: 'DEPARTMENT_CREATED',
      entityType: 'Department',
      entityId: department.id,
      newValue: {
        name: department.name,
        code: department.code,
        collegeId: collegeObjectId.toString(),
        status: department.status,
      },
    });

    return department;
  }

  /**
   * Get Department by ID
   */
  static async getDepartmentById(id: string, requester: AuthenticatedUser): Promise<IDepartment> {
    if (!mongoose.Types.ObjectId.isValid(id)) {
      throw ApiError.badRequest(`Invalid Department ID format: "${id}"`);
    }

    const department = await Department.findById(id);
    if (!department) {
      throw ApiError.notFound(`Department with ID "${id}" not found`);
    }

    // Tenant Scoping
    if (requester.role !== AppRole.SUPER_ADMIN) {
      if (!requester.collegeId || department.collegeId.toString() !== requester.collegeId.toString()) {
        throw ApiError.forbidden('Cross-college tenant access is strictly prohibited');
      }
    }

    return department;
  }

  /**
   * List Departments with Search, Filtering, Pagination, and Whitelisted Sorting
   */
  static async listDepartments(
    requester: AuthenticatedUser,
    query: ListDepartmentsQuery = {}
  ): Promise<PaginatedResult<IDepartment>> {
    const mongoQuery: Record<string, unknown> = {};

    // Tenant Isolation
    if (requester.role !== AppRole.SUPER_ADMIN) {
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

    // Filter by status
    if (query.status) {
      mongoQuery.status = query.status;
    }

    // Search by name or code (case-insensitive)
    if (query.search && query.search.trim() !== '') {
      const searchRegex = new RegExp(query.search.trim(), 'i');
      mongoQuery.$or = [{ name: searchRegex }, { code: searchRegex }];
    }

    const page = Math.max(1, query.page || 1);
    const limit = Math.min(100, Math.max(1, query.limit || 20));
    const skip = (page - 1) * limit;

    // Whitelisted sorting
    const allowedSortFields = ['name', 'code', 'status', 'createdAt', 'updatedAt'];
    const sortField = allowedSortFields.includes(query.sortBy || '') ? query.sortBy! : 'name';
    const sortOrder = query.sortOrder === 'desc' ? -1 : 1;
    const sortOptions: Record<string, 1 | -1> = { [sortField]: sortOrder };

    const [items, total] = await Promise.all([
      Department.find(mongoQuery).sort(sortOptions).skip(skip).limit(limit),
      Department.countDocuments(mongoQuery),
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
   * Update Department
   */
  static async updateDepartment(
    id: string,
    update: UpdateDepartmentInput,
    requester: AuthenticatedUser
  ): Promise<IDepartment> {
    if (!mongoose.Types.ObjectId.isValid(id)) {
      throw ApiError.badRequest(`Invalid Department ID format: "${id}"`);
    }

    const department = await Department.findById(id);
    if (!department) {
      throw ApiError.notFound(`Department with ID "${id}" not found`);
    }

    // Tenant Isolation
    if (requester.role !== AppRole.SUPER_ADMIN) {
      if (!requester.collegeId || department.collegeId.toString() !== requester.collegeId.toString()) {
        throw ApiError.forbidden('Cross-college tenant access is strictly prohibited');
      }
    }

    // Active College Check
    const college = await College.findById(department.collegeId);
    if (!college) {
      throw ApiError.notFound('Referenced college not found');
    }

    if (requester.role !== AppRole.SUPER_ADMIN && (college.status === CollegeStatus.INACTIVE || !college.isActive)) {
      throw ApiError.forbidden('Cannot modify departments in an inactive college');
    }

    const previousValue = department.toJSON();

    // Check code uniqueness if code is being modified
    if (update.code) {
      const normalizedNewCode = update.code.trim().toUpperCase();
      if (normalizedNewCode !== department.code) {
        const existing = await Department.findOne({
          collegeId: department.collegeId,
          code: normalizedNewCode,
          _id: { $ne: department._id },
        });

        if (existing) {
          throw ApiError.conflict(
            `Department with code "${normalizedNewCode}" already exists in this college`
          );
        }

        await AuditLog.create({
          actorUserId: requester.id,
          collegeId: department.collegeId.toString(),
          action: 'DEPARTMENT_CODE_CHANGED',
          entityType: 'Department',
          entityId: department.id,
          previousValue: { code: department.code },
          newValue: { code: normalizedNewCode },
        });

        department.code = normalizedNewCode;
      }
    }

    if (update.name) department.name = update.name.trim();
    if (update.description !== undefined) department.description = update.description.trim();
    if (update.metadata) department.metadata = update.metadata;

    department.updatedBy = requester.id;
    await department.save();

    await AuditLog.create({
      actorUserId: requester.id,
      collegeId: department.collegeId.toString(),
      action: 'DEPARTMENT_UPDATED',
      entityType: 'Department',
      entityId: department.id,
      previousValue,
      newValue: department.toJSON(),
    });

    return department;
  }

  /**
   * Update Department Status (Deactivate / Reactivate)
   */
  static async updateDepartmentStatus(
    id: string,
    newStatus: DepartmentStatus,
    requester: AuthenticatedUser
  ): Promise<IDepartment> {
    if (!mongoose.Types.ObjectId.isValid(id)) {
      throw ApiError.badRequest(`Invalid Department ID format: "${id}"`);
    }

    const department = await Department.findById(id);
    if (!department) {
      throw ApiError.notFound(`Department with ID "${id}" not found`);
    }

    // Tenant Isolation
    if (requester.role !== AppRole.SUPER_ADMIN) {
      if (!requester.collegeId || department.collegeId.toString() !== requester.collegeId.toString()) {
        throw ApiError.forbidden('Cross-college tenant access is strictly prohibited');
      }
    }

    // Active College Check
    const college = await College.findById(department.collegeId);
    if (!college) {
      throw ApiError.notFound('Referenced college not found');
    }

    if (requester.role !== AppRole.SUPER_ADMIN && (college.status === CollegeStatus.INACTIVE || !college.isActive)) {
      throw ApiError.forbidden('Cannot modify department status in an inactive college');
    }

    const previousStatus = department.status;
    department.status = newStatus;
    department.isActive = newStatus === DepartmentStatus.ACTIVE;
    department.updatedBy = requester.id;
    await department.save();

    await AuditLog.create({
      actorUserId: requester.id,
      collegeId: department.collegeId.toString(),
      action: 'DEPARTMENT_STATUS_CHANGED',
      entityType: 'Department',
      entityId: department.id,
      previousValue: { status: previousStatus },
      newValue: { status: newStatus },
    });

    return department;
  }

  /**
   * Get Department Summary Metrics
   */
  static async getDepartmentSummary(
    id: string,
    requester: AuthenticatedUser
  ): Promise<Record<string, unknown>> {
    if (!mongoose.Types.ObjectId.isValid(id)) {
      throw ApiError.badRequest(`Invalid Department ID format: "${id}"`);
    }

    const department = await Department.findById(id);
    if (!department) {
      throw ApiError.notFound(`Department with ID "${id}" not found`);
    }

    // Tenant Scoping
    if (requester.role !== AppRole.SUPER_ADMIN) {
      if (!requester.collegeId || department.collegeId.toString() !== requester.collegeId.toString()) {
        throw ApiError.forbidden('Cross-college tenant access is strictly prohibited');
      }
      if (requester.role === AppRole.HOD && requester.departmentId && department._id.toString() !== requester.departmentId.toString()) {
        throw ApiError.forbidden('HOD cannot access summary of another department');
      }
    }

    const college = await College.findById(department.collegeId);
    const departmentObjectId = department._id;

    const [
      facultyCount,
      studentCount,
      hodCount,
      activeUserCount,
      courseCount,
    ] = await Promise.all([
      User.countDocuments({ departmentId: departmentObjectId, role: AppRole.FACULTY, accountStatus: AccountStatus.ACTIVE }),
      User.countDocuments({ departmentId: departmentObjectId, role: AppRole.STUDENT, accountStatus: AccountStatus.ACTIVE }),
      User.countDocuments({ departmentId: departmentObjectId, role: AppRole.HOD, accountStatus: AccountStatus.ACTIVE }),
      User.countDocuments({ departmentId: departmentObjectId, accountStatus: AccountStatus.ACTIVE }),
      Course.countDocuments({ departmentId: departmentObjectId, isActive: true }),
    ]);

    return {
      department: department.toJSON(),
      college: college ? college.toJSON() : null,
      status: department.status,
      isActive: department.isActive,
      facultyCount,
      studentCount,
      hodCount,
      activeUserCount,
      courseCount,
    };
  }
}
