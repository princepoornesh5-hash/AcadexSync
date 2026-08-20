import mongoose from 'mongoose';
import { User, IUser } from '../models/user.model';
import { Student, IStudent } from '../models/student.model';
import { StudentEnrollment } from '../models/studentEnrollment.model';
import { College } from '../models/college.model';
import { Department } from '../models/department.model';
import { Invitation } from '../models/invitation.model';
import { AuditLog } from '../models/auditLog.model';
import { StudentContactRequest, IStudentContactRequest, ContactRequestStatus } from '../models/studentContactRequest.model';
import { AppRole } from '../constants/roles';
import { AccountStatus, CollegeStatus, DepartmentStatus, StudentLifecycleState } from '../constants/status';
import { ApiError } from '../utils/apiError';
import { AuthenticatedUser } from '../types/auth.types';
import { InvitationService, CreateInvitationResult } from './invitation.service';
import { normalizeEmail, normalizePhone } from '../utils/identifier';

export interface ProvisionStudentInput {
  departmentId: string;
  name: string;
  instituteId: string;
  email?: string;
  phone?: string;
  rollNumber?: string;
  admissionNumber?: string;
  parentName?: string;
  parentPhone?: string;
  bloodGroup?: string;
  address?: string;
  dateOfBirth?: string;
  admissionDate?: string;
  metadata?: Record<string, unknown>;
}

export interface UpdateStudentProfileInput {
  name?: string;
  email?: string;
  phone?: string;
  rollNumber?: string;
  admissionNumber?: string;
  parentName?: string;
  parentPhone?: string;
  bloodGroup?: string;
  address?: string;
  dateOfBirth?: string;
  admissionDate?: string;
  profilePictureUrl?: string;
  metadata?: Record<string, unknown>;
}

export interface ListStudentQuery {
  page?: number;
  limit?: number;
  search?: string;
  collegeId?: string;
  departmentId?: string;
  status?: AccountStatus;
  sortBy?: 'name' | 'instituteId' | 'rollNumber' | 'createdAt';
  sortOrder?: 'asc' | 'desc';
}

export interface ListContactRequestQuery {
  page?: number;
  limit?: number;
  departmentId?: string;
  status?: ContactRequestStatus;
}

export interface PaginatedResult<T> {
  items: T[];
  page: number;
  limit: number;
  total: number;
  totalPages: number;
}

export class StudentService {
  /**
   * Provision Student Account & Profile using Phase 9C Invitation Engine
   */
  static async provisionStudent(
    input: ProvisionStudentInput,
    requester: AuthenticatedUser
  ): Promise<{
    user: IUser;
    student: IStudent;
    invitation: CreateInvitationResult['invitation'];
    activationCode: string;
  }> {
    if (![AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN, AppRole.HOD, AppRole.FACULTY].includes(requester.role)) {
      throw ApiError.forbidden('Only administrators, HODs, and faculty have permission to provision students');
    }

    if (!mongoose.Types.ObjectId.isValid(input.departmentId)) {
      throw ApiError.badRequest(`Invalid Department ID format: "${input.departmentId}"`);
    }

    const dept = await Department.findById(input.departmentId);
    if (!dept) {
      throw ApiError.notFound(`Department with ID "${input.departmentId}" not found`);
    }

    if (dept.status === DepartmentStatus.INACTIVE || !dept.isActive) {
      throw ApiError.forbidden('Cannot provision student for an inactive department');
    }

    const college = await College.findById(dept.collegeId);
    if (!college || college.status === CollegeStatus.INACTIVE || !college.isActive) {
      throw ApiError.forbidden('Cannot provision student for an inactive college');
    }

    // Role-specific scoping
    if (requester.role === AppRole.COLLEGE_ADMIN) {
      if (!requester.collegeId || dept.collegeId.toString() !== requester.collegeId.toString()) {
        throw ApiError.forbidden('College Admin cannot provision students for another college');
      }
    } else if (requester.role === AppRole.HOD || requester.role === AppRole.FACULTY) {
      if (!requester.departmentId || dept._id.toString() !== requester.departmentId.toString()) {
        throw ApiError.forbidden('Staff cannot provision students outside their assigned department');
      }
    }

    // Check rollNumber uniqueness within college if provided
    if (input.rollNumber && input.rollNumber.trim() !== '') {
      const existingRoll = await Student.findOne({
        collegeId: dept.collegeId,
        rollNumber: input.rollNumber.trim(),
      });
      if (existingRoll) {
        throw ApiError.conflict(`Student with roll number "${input.rollNumber.trim()}" already exists in this college`);
      }
    }

    // Check admissionNumber uniqueness within college if provided
    if (input.admissionNumber && input.admissionNumber.trim() !== '') {
      const existingAdm = await Student.findOne({
        collegeId: dept.collegeId,
        admissionNumber: input.admissionNumber.trim(),
      });
      if (existingAdm) {
        throw ApiError.conflict(`Student with admission number "${input.admissionNumber.trim()}" already exists in this college`);
      }
    }

    // 1. Create User & Invitation via Phase 9C
    const invitationResult = await InvitationService.createInvitation(requester, {
      name: input.name,
      instituteId: input.instituteId,
      email: input.email || undefined,
      phone: input.phone || undefined,
      role: AppRole.STUDENT,
      departmentId: input.departmentId,
    });

    const user = invitationResult.user;

    // 2. Create Student Profile
    let student: IStudent;
    try {
      student = await Student.create({
        collegeId: dept.collegeId,
        departmentId: dept._id,
        userId: user._id,
        instituteId: user.instituteId,
        name: user.name,
        email: user.email || undefined,
        phone: user.phone || undefined,
        rollNumber: input.rollNumber?.trim() || undefined,
        admissionNumber: input.admissionNumber?.trim() || undefined,
        parentName: input.parentName?.trim() || undefined,
        parentPhone: input.parentPhone?.trim() || undefined,
        bloodGroup: input.bloodGroup?.trim() || undefined,
        address: input.address?.trim() || undefined,
        dateOfBirth: input.dateOfBirth ? new Date(input.dateOfBirth) : undefined,
        admissionDate: input.admissionDate ? new Date(input.admissionDate) : undefined,
        lifecycleState: StudentLifecycleState.ACTIVE,
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
        throw ApiError.conflict('Student profile with this userId, rollNumber, or admissionNumber already exists');
      }
      throw err;
    }

    // 3. Audit Log
    await AuditLog.create({
      collegeId: dept.collegeId.toString(),
      actorUserId: requester.id,
      action: 'STUDENT_PROVISIONED',
      entityType: 'Student',
      entityId: student.id,
      newValue: {
        userId: user.id,
        instituteId: user.instituteId,
        departmentId: dept.id,
        collegeId: dept.collegeId.toString(),
        rollNumber: student.rollNumber,
        admissionNumber: student.admissionNumber,
      },
    });

    return {
      user,
      student,
      invitation: invitationResult.invitation,
      activationCode: invitationResult.activationCode,
    };
  }

  /**
   * Get Student by User/Student ID
   */
  static async getStudentById(
    id: string,
    requester: AuthenticatedUser
  ): Promise<{ user: IUser; student: IStudent | null }> {
    if (!mongoose.Types.ObjectId.isValid(id)) {
      throw ApiError.badRequest(`Invalid Student ID format: "${id}"`);
    }

    let user = await User.findOne({ _id: id, role: AppRole.STUDENT });
    let student: IStudent | null = null;

    if (user) {
      student = await Student.findOne({ userId: user._id });
    } else {
      student = await Student.findById(id);
      if (student && student.userId) {
        user = await User.findById(student.userId);
      }
    }

    if (!user) {
      throw ApiError.notFound(`Student with ID "${id}" not found`);
    }

    // Scoping
    if (requester.role === AppRole.SUPER_ADMIN) {
      return { user, student };
    }

    if (requester.role === AppRole.COLLEGE_ADMIN) {
      if (!requester.collegeId || user.collegeId?.toString() !== requester.collegeId.toString()) {
        throw ApiError.forbidden('Cross-college tenant access is strictly prohibited');
      }
      return { user, student };
    }

    if (requester.role === AppRole.HOD || requester.role === AppRole.FACULTY) {
      if (!requester.departmentId || user.departmentId?.toString() !== requester.departmentId.toString()) {
        throw ApiError.forbidden('Cross-department access is strictly prohibited for staff');
      }
      return { user, student };
    }

    if (requester.role === AppRole.STUDENT) {
      if (user._id.toString() !== requester.id) {
        throw ApiError.forbidden('Students can only view their own profile');
      }
      return { user, student };
    }

    throw ApiError.forbidden('Access denied to student administration');
  }

  /**
   * List Students (Admin, College Admin, HOD, Faculty)
   */
  static async listStudents(
    requester: AuthenticatedUser,
    query: ListStudentQuery = {}
  ): Promise<PaginatedResult<{ user: IUser; student: IStudent | null }>> {
    if (![AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN, AppRole.HOD, AppRole.FACULTY].includes(requester.role)) {
      throw ApiError.forbidden('Only administrators, HODs, and faculty have permission to access student administration');
    }

    const mongoQuery: Record<string, unknown> = {
      role: AppRole.STUDENT,
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
    } else if (requester.role === AppRole.HOD || requester.role === AppRole.FACULTY) {
      if (!requester.collegeId || !requester.departmentId) {
        return { items: [], page: 1, limit: 1, total: 0, totalPages: 0 };
      }
      if (query.collegeId && query.collegeId.toString() !== requester.collegeId.toString()) {
        throw ApiError.forbidden('Cross-college tenant access is strictly prohibited');
      }
      if (query.departmentId && query.departmentId.toString() !== requester.departmentId.toString()) {
        throw ApiError.forbidden('Staff cannot access students outside their assigned department');
      }
      mongoQuery.collegeId = new mongoose.Types.ObjectId(requester.collegeId);
      mongoQuery.departmentId = new mongoose.Types.ObjectId(requester.departmentId);
    } else if (query.collegeId) {
      if (!mongoose.Types.ObjectId.isValid(query.collegeId)) {
        throw ApiError.badRequest(`Invalid College ID format: "${query.collegeId}"`);
      }
      mongoQuery.collegeId = new mongoose.Types.ObjectId(query.collegeId);
    }

    if (query.departmentId && ![AppRole.HOD, AppRole.FACULTY].includes(requester.role)) {
      if (!mongoose.Types.ObjectId.isValid(query.departmentId)) {
        throw ApiError.badRequest(`Invalid Department ID format: "${query.departmentId}"`);
      }
      mongoQuery.departmentId = new mongoose.Types.ObjectId(query.departmentId);
    }

    if (query.status) {
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
    const studentProfiles = await Student.find({ userId: { $in: userIds } });
    const profileMap = new Map(studentProfiles.map((s) => [s.userId.toString(), s]));

    const items = users.map((u) => ({
      user: u,
      student: profileMap.get(u._id.toString()) || null,
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
   * Update Student Profile
   */
  static async updateStudentProfile(
    id: string,
    update: UpdateStudentProfileInput,
    requester: AuthenticatedUser
  ): Promise<{ user: IUser; student: IStudent | null }> {
    const { user, student } = await this.getStudentById(id, requester);

    const previousUser = user.toJSON();

    if (update.name) {
      user.name = update.name.trim();
      if (student) student.name = update.name.trim();
    }

    if (update.email !== undefined) {
      if (update.email === '' || update.email === null) {
        user.email = undefined;
        if (student) student.email = undefined;
      } else {
        const normalizedEmail = normalizeEmail(update.email);
        if (normalizedEmail !== user.email) {
          const existing = await User.findOne({ email: normalizedEmail, _id: { $ne: user._id } });
          if (existing) {
            throw ApiError.conflict(`Email "${normalizedEmail}" is already registered`);
          }
          user.email = normalizedEmail;
          if (student) student.email = normalizedEmail;
        }
      }
    }

    if (update.phone !== undefined) {
      if (update.phone === '' || update.phone === null) {
        user.phone = undefined;
        if (student) student.phone = undefined;
      } else {
        const normalizedPhone = normalizePhone(update.phone);
        if (normalizedPhone !== user.phone) {
          const existing = await User.findOne({ phone: normalizedPhone, _id: { $ne: user._id } });
          if (existing) {
            throw ApiError.conflict(`Phone number "${normalizedPhone}" is already registered`);
          }
          user.phone = normalizedPhone;
          if (student) student.phone = normalizedPhone;
        }
      }
    }

    if (update.profilePictureUrl !== undefined) {
      user.profilePictureUrl = update.profilePictureUrl;
    }

    if (student) {
      if (update.rollNumber !== undefined) {
        if (update.rollNumber && update.rollNumber.trim() !== '') {
          const rollTrimmed = update.rollNumber.trim();
          if (rollTrimmed !== student.rollNumber) {
            const existingRoll = await Student.findOne({
              collegeId: student.collegeId,
              rollNumber: rollTrimmed,
              _id: { $ne: student._id },
            });
            if (existingRoll) {
              throw ApiError.conflict(`Roll number "${rollTrimmed}" is already registered in this college`);
            }
            student.rollNumber = rollTrimmed;
          }
        } else {
          student.rollNumber = undefined;
        }
      }

      if (update.admissionNumber !== undefined) {
        if (update.admissionNumber && update.admissionNumber.trim() !== '') {
          const admTrimmed = update.admissionNumber.trim();
          if (admTrimmed !== student.admissionNumber) {
            const existingAdm = await Student.findOne({
              collegeId: student.collegeId,
              admissionNumber: admTrimmed,
              _id: { $ne: student._id },
            });
            if (existingAdm) {
              throw ApiError.conflict(`Admission number "${admTrimmed}" is already registered in this college`);
            }
            student.admissionNumber = admTrimmed;
          }
        } else {
          student.admissionNumber = undefined;
        }
      }

      if (update.parentName !== undefined) student.parentName = update.parentName.trim();
      if (update.parentPhone !== undefined) student.parentPhone = update.parentPhone.trim();
      if (update.bloodGroup !== undefined) student.bloodGroup = update.bloodGroup.trim();
      if (update.address !== undefined) student.address = update.address.trim();
      if (update.dateOfBirth) student.dateOfBirth = new Date(update.dateOfBirth);
      if (update.admissionDate) student.admissionDate = new Date(update.admissionDate);
      if (update.metadata) student.metadata = update.metadata;

      await student.save();
    }

    await user.save();

    await AuditLog.create({
      collegeId: user.collegeId ? user.collegeId.toString() : 'GLOBAL',
      actorUserId: requester.id,
      action: 'STUDENT_UPDATED',
      entityType: 'Student',
      entityId: student ? student.id : user.id,
      previousValue: previousUser,
      newValue: user.toJSON(),
    });

    return { user, student };
  }

  /**
   * Correct Student instituteId (Super Admin, College Admin, HOD)
   */
  static async correctInstituteId(
    id: string,
    newInstituteId: string,
    requester: AuthenticatedUser
  ): Promise<{ user: IUser; student: IStudent | null }> {
    if (![AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN, AppRole.HOD].includes(requester.role)) {
      throw ApiError.forbidden('Only administrators and HODs have permission to correct student institutional IDs');
    }

    const normalized = newInstituteId.trim().toUpperCase();
    if (!normalized || normalized.length < 2) {
      throw ApiError.badRequest('instituteId must be at least 2 characters');
    }

    const { user, student } = await this.getStudentById(id, requester);

    if (user.instituteId === normalized) {
      return { user, student };
    }

    const existingUser = await User.findOne({ instituteId: normalized, _id: { $ne: user._id } });
    if (existingUser) {
      throw ApiError.conflict(`instituteId "${normalized}" is already registered`);
    }

    const previousInstituteId = user.instituteId;

    // Update User & Student profile while preserving MongoDB _id and relational links
    user.instituteId = normalized;
    await user.save();

    if (student) {
      student.instituteId = normalized;
      await student.save();
    }

    await AuditLog.create({
      collegeId: user.collegeId ? user.collegeId.toString() : 'GLOBAL',
      actorUserId: requester.id,
      action: 'STUDENT_INSTITUTE_ID_CHANGED',
      entityType: 'Student',
      entityId: student ? student.id : user.id,
      previousValue: { instituteId: previousInstituteId },
      newValue: { instituteId: normalized },
    });

    return { user, student };
  }

  /**
   * Safe Administrative Department Transfer
   */
  static async transferStudentDepartment(
    id: string,
    targetDepartmentId: string,
    requester: AuthenticatedUser
  ): Promise<{ user: IUser; student: IStudent | null }> {
    if (![AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN].includes(requester.role)) {
      throw ApiError.forbidden('Only Super Admin and College Admin have permission to transfer students between departments');
    }

    if (!mongoose.Types.ObjectId.isValid(targetDepartmentId)) {
      throw ApiError.badRequest(`Invalid Department ID format: "${targetDepartmentId}"`);
    }

    const { user, student } = await this.getStudentById(id, requester);

    const targetDept = await Department.findById(targetDepartmentId);
    if (!targetDept) {
      throw ApiError.notFound(`Target Department with ID "${targetDepartmentId}" not found`);
    }

    if (targetDept.status === DepartmentStatus.INACTIVE || !targetDept.isActive) {
      throw ApiError.forbidden('Cannot transfer student to an inactive department');
    }

    if (requester.role === AppRole.COLLEGE_ADMIN) {
      if (targetDept.collegeId.toString() !== requester.collegeId?.toString()) {
        throw ApiError.forbidden('Cannot transfer student to a department belonging to another college');
      }
    }

    const targetCollege = await College.findById(targetDept.collegeId);
    if (!targetCollege || targetCollege.status === CollegeStatus.INACTIVE || !targetCollege.isActive) {
      throw ApiError.forbidden('Cannot transfer student to an inactive college');
    }

    const oldDepartmentId = user.departmentId?.toString();
    const oldCollegeId = user.collegeId?.toString();

    // Update User
    user.departmentId = targetDept._id;
    user.collegeId = targetDept.collegeId;
    await user.save();

    // Update Student Profile
    if (student) {
      student.departmentId = targetDept._id;
      student.collegeId = targetDept.collegeId;
      await student.save();
    }

    await AuditLog.create({
      collegeId: targetDept.collegeId.toString(),
      actorUserId: requester.id,
      action: 'STUDENT_DEPARTMENT_TRANSFERRED',
      entityType: 'Student',
      entityId: student ? student.id : user.id,
      previousValue: {
        departmentId: oldDepartmentId,
        collegeId: oldCollegeId,
      },
      newValue: {
        departmentId: targetDept._id.toString(),
        collegeId: targetDept.collegeId.toString(),
      },
    });

    return { user, student };
  }

  /**
   * Create Student Contact Request ("Request Teacher to Add Mobile Number")
   */
  static async createContactRequest(
    requestedPhone: string,
    notes: string | undefined,
    requester: AuthenticatedUser
  ): Promise<IStudentContactRequest> {
    if (requester.role !== AppRole.STUDENT) {
      throw ApiError.forbidden('Only students can create phone number addition requests for their own account');
    }

    const user = await User.findById(requester.id);
    if (!user || !user.collegeId || !user.departmentId) {
      throw ApiError.notFound('Student account details not found');
    }

    const studentProfile = await Student.findOne({ userId: user._id });

    const normalizedPhone = normalizePhone(requestedPhone);

    // Check if phone already registered to another user
    const existingPhoneUser = await User.findOne({ phone: normalizedPhone, _id: { $ne: user._id } });
    if (existingPhoneUser) {
      throw ApiError.conflict(`Phone number "${normalizedPhone}" is already registered to another user`);
    }

    const contactRequest = await StudentContactRequest.create({
      collegeId: user.collegeId,
      departmentId: user.departmentId,
      studentUserId: user._id,
      studentProfileId: studentProfile ? studentProfile._id : null,
      studentName: user.name,
      studentInstituteId: user.instituteId,
      currentPhone: user.phone || null,
      requestedPhone: normalizedPhone,
      status: 'PENDING',
      notes: notes?.trim() || null,
    });

    await AuditLog.create({
      collegeId: user.collegeId.toString(),
      actorUserId: requester.id,
      action: 'STUDENT_CONTACT_REQUEST_CREATED',
      entityType: 'StudentContactRequest',
      entityId: contactRequest.id,
      newValue: {
        studentUserId: user.id,
        requestedPhone: normalizedPhone,
      },
    });

    return contactRequest;
  }

  /**
   * List Contact Requests
   */
  static async listContactRequests(
    requester: AuthenticatedUser,
    query: ListContactRequestQuery = {}
  ): Promise<PaginatedResult<IStudentContactRequest>> {
    const mongoQuery: Record<string, unknown> = {};

    if (requester.role === AppRole.STUDENT) {
      mongoQuery.studentUserId = new mongoose.Types.ObjectId(requester.id);
    } else if (requester.role === AppRole.COLLEGE_ADMIN) {
      if (!requester.collegeId) return { items: [], page: 1, limit: 1, total: 0, totalPages: 0 };
      mongoQuery.collegeId = new mongoose.Types.ObjectId(requester.collegeId);
    } else if (requester.role === AppRole.HOD || requester.role === AppRole.FACULTY) {
      if (!requester.collegeId || !requester.departmentId) {
        return { items: [], page: 1, limit: 1, total: 0, totalPages: 0 };
      }
      mongoQuery.collegeId = new mongoose.Types.ObjectId(requester.collegeId);
      mongoQuery.departmentId = new mongoose.Types.ObjectId(requester.departmentId);
    }

    if (query.departmentId && [AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN].includes(requester.role)) {
      if (mongoose.Types.ObjectId.isValid(query.departmentId)) {
        mongoQuery.departmentId = new mongoose.Types.ObjectId(query.departmentId);
      }
    }

    if (query.status) {
      mongoQuery.status = query.status;
    }

    const page = Math.max(1, query.page || 1);
    const limit = Math.min(100, Math.max(1, query.limit || 20));
    const skip = (page - 1) * limit;

    const [items, total] = await Promise.all([
      StudentContactRequest.find(mongoQuery).sort({ createdAt: -1 }).skip(skip).limit(limit),
      StudentContactRequest.countDocuments(mongoQuery),
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
   * Resolve Contact Request (Approve or Reject)
   */
  static async resolveContactRequest(
    requestId: string,
    resolution: { status: 'APPROVED' | 'REJECTED'; rejectionReason?: string; notes?: string },
    requester: AuthenticatedUser
  ): Promise<IStudentContactRequest> {
    if (![AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN, AppRole.HOD, AppRole.FACULTY].includes(requester.role)) {
      throw ApiError.forbidden('Only staff and administrators can resolve contact number addition requests');
    }

    if (!mongoose.Types.ObjectId.isValid(requestId)) {
      throw ApiError.badRequest(`Invalid Contact Request ID format: "${requestId}"`);
    }

    const contactRequest = await StudentContactRequest.findById(requestId);
    if (!contactRequest) {
      throw ApiError.notFound(`Contact Request with ID "${requestId}" not found`);
    }

    // Scoping
    if (requester.role === AppRole.COLLEGE_ADMIN) {
      if (contactRequest.collegeId.toString() !== requester.collegeId?.toString()) {
        throw ApiError.forbidden('Cross-college contact request management is strictly prohibited');
      }
    } else if (requester.role === AppRole.HOD || requester.role === AppRole.FACULTY) {
      if (contactRequest.departmentId.toString() !== requester.departmentId?.toString()) {
        throw ApiError.forbidden('Staff can only resolve contact requests within their assigned department');
      }
    }

    if (contactRequest.status !== 'PENDING') {
      throw ApiError.badRequest(`Contact request is already "${contactRequest.status}"`);
    }

    if (resolution.status === 'APPROVED') {
      // Check phone duplicate before assigning
      const existing = await User.findOne({
        phone: contactRequest.requestedPhone,
        _id: { $ne: contactRequest.studentUserId },
      });
      if (existing) {
        throw ApiError.conflict(`Phone number "${contactRequest.requestedPhone}" is already registered`);
      }

      // Update Student User & Profile
      await Promise.all([
        User.findByIdAndUpdate(contactRequest.studentUserId, { phone: contactRequest.requestedPhone }),
        Student.findOneAndUpdate(
          { userId: contactRequest.studentUserId },
          { phone: contactRequest.requestedPhone }
        ),
      ]);

      contactRequest.status = 'APPROVED';
      contactRequest.resolvedBy = new mongoose.Types.ObjectId(requester.id);
      contactRequest.resolvedByName = requester.name;
      contactRequest.resolvedAt = new Date();
      if (resolution.notes) contactRequest.notes = resolution.notes;
      await contactRequest.save();

      await AuditLog.create({
        collegeId: contactRequest.collegeId.toString(),
        actorUserId: requester.id,
        action: 'STUDENT_CONTACT_REQUEST_APPROVED',
        entityType: 'StudentContactRequest',
        entityId: contactRequest.id,
        newValue: {
          studentUserId: contactRequest.studentUserId.toString(),
          assignedPhone: contactRequest.requestedPhone,
        },
      });
    } else {
      contactRequest.status = 'REJECTED';
      contactRequest.resolvedBy = new mongoose.Types.ObjectId(requester.id);
      contactRequest.resolvedByName = requester.name;
      contactRequest.resolvedAt = new Date();
      contactRequest.rejectionReason = resolution.rejectionReason || 'Request rejected by staff';
      if (resolution.notes) contactRequest.notes = resolution.notes;
      await contactRequest.save();

      await AuditLog.create({
        collegeId: contactRequest.collegeId.toString(),
        actorUserId: requester.id,
        action: 'STUDENT_CONTACT_REQUEST_REJECTED',
        entityType: 'StudentContactRequest',
        entityId: contactRequest.id,
        newValue: {
          studentUserId: contactRequest.studentUserId.toString(),
          rejectionReason: contactRequest.rejectionReason,
        },
      });
    }

    return contactRequest;
  }

  /**
   * Get Student Summary
   */
  static async getStudentSummary(
    id: string,
    requester: AuthenticatedUser
  ): Promise<Record<string, unknown>> {
    const { user, student } = await this.getStudentById(id, requester);

    const [college, department, enrollmentCount] = await Promise.all([
      user.collegeId ? College.findById(user.collegeId) : null,
      user.departmentId ? Department.findById(user.departmentId) : null,
      student ? StudentEnrollment.countDocuments({ studentId: student._id }) : 0,
    ]);

    return {
      user: user.toJSON(),
      student: student ? student.toJSON() : null,
      college: college ? college.toJSON() : null,
      department: department ? department.toJSON() : null,
      enrollmentCount,
    };
  }

  /**
   * Get Department Students Lookup
   */
  static async getDepartmentStudents(
    departmentId: string,
    requester: AuthenticatedUser
  ): Promise<{ user: IUser; student: IStudent | null }[]> {
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
    } else if (requester.role === AppRole.HOD || requester.role === AppRole.FACULTY) {
      if (requester.departmentId?.toString() !== department._id.toString()) {
        throw ApiError.forbidden('Staff can only lookup students within their assigned department');
      }
    } else if (requester.role !== AppRole.SUPER_ADMIN) {
      throw ApiError.forbidden('Access denied');
    }

    const users = await User.find({
      departmentId: department._id,
      role: AppRole.STUDENT,
    }).sort({ name: 1 });

    const userIds = users.map((u) => u._id);
    const studentProfiles = await Student.find({ userId: { $in: userIds } });
    const profileMap = new Map(studentProfiles.map((s) => [s.userId.toString(), s]));

    return users.map((u) => ({
      user: u,
      student: profileMap.get(u._id.toString()) || null,
    }));
  }
}
