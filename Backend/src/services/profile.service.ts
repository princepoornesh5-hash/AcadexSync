import mongoose from 'mongoose';
import {
  User,
  IUser,
  Student,
  Faculty,
  StudentEnrollment,
  FacultyAssignment,
  Department,
  College,
  Course,
} from '../models';
import { ApiError } from '../utils/apiError';
import { AppRole } from '../constants/roles';
import { AuthenticatedUser } from '../types/auth.types';
import { ImageKitService } from '../storage/imagekit.service';
import { AuditService } from './audit.service';
import { realtimeEventBus } from '../realtime';
import { AcadexEventType } from '../realtime/contracts/eventRegistry';
import { env } from '../config/env';

export interface ComposedProfile {
  user: {
    id: string;
    instituteId: string;
    name: string;
    email: string;
    phone: string;
    role: AppRole;
    profilePictureUrl?: string | null;
    bio?: string;
    collegeId?: string;
    collegeName?: string;
    departmentId?: string;
    departmentName?: string;
  };
  roleProfile: {
    student?: {
      studentId: string;
      rollNumber?: string;
      admissionNumber?: string;
      academicStage?: string;
      cohort?: string;
      isEnrollmentAvailable: boolean;
      currentEnrollment?: {
        enrollmentId: string;
        courseId: string;
        courseName: string;
        courseCode: string;
        semesterId: string;
        semesterName: string;
        semesterNumber?: number;
        academicYearId: string;
        academicYearName: string;
        sectionId?: string;
        sectionName?: string;
        academicStage?: string;
        cohort?: string;
        status: string;
      } | null;
    };
    faculty?: {
      facultyId: string;
      employeeId?: string;
      designation?: string;
      qualification?: string;
      specialization?: string;
      joiningDate?: Date;
      activeAssignments: Array<{
        assignmentId: string;
        subjectId: string;
        subjectName: string;
        subjectCode: string;
        courseId: string;
        courseName: string;
        semesterId: string;
        semesterName: string;
        sectionId?: string;
        sectionName?: string;
        assignmentType?: string;
      }>;
    };
    hod?: {
      facultyId?: string;
      departmentId: string;
      departmentName: string;
      departmentCode: string;
      designation?: string;
      managedScope: {
        programsCount: number;
        facultyCount: number;
        studentsCount: number;
      };
    };
    collegeAdmin?: {
      collegeId: string;
      collegeName: string;
      collegeCode: string;
      administrativeScope: {
        departmentsCount: number;
        facultyCount: number;
        studentsCount: number;
      };
    };
    superAdmin?: {
      scope: 'GLOBAL';
    };
  };
  completion: {
    percentage: number;
    completedFields: string[];
    missingFields: string[];
  };
  editableFields: string[];
}

export class ProfileService {
  /**
   * Resolves the canonical, composed profile for the given user, bounded by the requester's scope.
   */
  static async getComposedProfile(
    userId: string,
    requester: AuthenticatedUser
  ): Promise<ComposedProfile> {
    if (!mongoose.Types.ObjectId.isValid(userId)) {
      throw ApiError.badRequest(`Invalid user ID format: "${userId}"`);
    }

    const user = await User.findById(userId);
    if (!user) {
      throw ApiError.notFound(`User with ID "${userId}" not found`);
    }

    const isSelf = requester.id === userId;
    const isSuperAdmin = requester.role === AppRole.SUPER_ADMIN;

    // Cross-tenant boundary check
    if (!isSuperAdmin && requester.collegeId && user.collegeId) {
      if (requester.collegeId.toString() !== user.collegeId.toString()) {
        throw ApiError.forbidden('Cross-college tenant profile access is strictly prohibited');
      }
    }

    // Role-based visibility and relationship scoping when viewing another user
    if (!isSelf && !isSuperAdmin) {
      await this.verifyProfileReadPermission(requester, user);
    }

    // Resolve College and Department presentation names
    let collegeName = '—';
    if (user.collegeId) {
      const college = await College.findById(user.collegeId).select('name code');
      if (college) collegeName = college.name;
    }

    let departmentName = '—';
    let departmentCode = '—';
    if (user.departmentId) {
      const department = await Department.findById(user.departmentId).select('name code');
      if (department) {
        departmentName = department.name;
        departmentCode = department.code;
      }
    }

    const roleProfile: ComposedProfile['roleProfile'] = {};

    // 1. STUDENT Composed Profile: User -> Student -> current StudentEnrollment
    if (user.role === AppRole.STUDENT) {
      const student = await Student.findOne({
        $or: [{ userId: user._id }, { instituteId: user.instituteId }],
      });

      if (student) {
        // Authoritative current academic context MUST come from active StudentEnrollment
        const activeEnrollment = await StudentEnrollment.findOne({
          studentId: student._id,
          status: 'active',
        })
          .populate<{ courseId: any }>('courseId', 'name code')
          .populate<{ semesterId: any }>('semesterId', 'name semesterNumber')
          .populate<{ academicYearId: any }>('academicYearId', 'name')
          .populate<{ sectionId: any }>('sectionId', 'name');

        let currentEnrollment = null;
        if (activeEnrollment) {
          const course = activeEnrollment.courseId;
          const semester = activeEnrollment.semesterId;
          const academicYear = activeEnrollment.academicYearId;
          const section = activeEnrollment.sectionId;

          currentEnrollment = {
            enrollmentId: activeEnrollment._id.toString(),
            courseId: course?._id?.toString() || activeEnrollment.courseId?.toString() || '',
            courseName: course?.name || '—',
            courseCode: course?.code || '—',
            semesterId: semester?._id?.toString() || activeEnrollment.semesterId?.toString() || '',
            semesterName: semester?.name || '—',
            semesterNumber: semester?.semesterNumber,
            academicYearId: academicYear?._id?.toString() || activeEnrollment.academicYearId?.toString() || '',
            academicYearName: academicYear?.name || '—',
            sectionId: section?._id?.toString() || (activeEnrollment.sectionId ? activeEnrollment.sectionId.toString() : undefined),
            sectionName: section?.name || undefined,
            academicStage: activeEnrollment.academicStage || student.academicStage,
            cohort: activeEnrollment.cohort || student.cohort,
            status: activeEnrollment.status,
          };
        }

        roleProfile.student = {
          studentId: student._id.toString(),
          rollNumber: student.rollNumber || undefined,
          admissionNumber: student.admissionNumber || undefined,
          academicStage: student.academicStage || undefined,
          cohort: student.cohort || undefined,
          isEnrollmentAvailable: activeEnrollment !== null,
          currentEnrollment,
        };
      } else {
        roleProfile.student = {
          studentId: '',
          isEnrollmentAvailable: false,
          currentEnrollment: null,
        };
      }
    }

    // 2. FACULTY Composed Profile: User -> Faculty -> active FacultyAssignment
    if (user.role === AppRole.FACULTY || user.role === AppRole.HOD) {
      const faculty = await Faculty.findOne({
        $or: [{ userId: user._id }, { instituteId: user.instituteId }],
      });

      if (faculty) {
        // Active teaching assignments come strictly from FacultyAssignment (status active and isActive true)
        const assignments = await FacultyAssignment.find({
          facultyId: faculty._id,
          status: 'active',
          isActive: true,
        })
          .populate<{ subjectId: any }>('subjectId', 'name code')
          .populate<{ courseId: any }>('courseId', 'name code')
          .populate<{ semesterId: any }>('semesterId', 'name')
          .populate<{ sectionId: any }>('sectionId', 'name');

        const activeAssignments = assignments.map((a) => {
          const subject = a.subjectId;
          const course = a.courseId;
          const semester = a.semesterId;
          const section = a.sectionId;

          return {
            assignmentId: a._id.toString(),
            subjectId: subject?._id?.toString() || a.subjectId?.toString() || '',
            subjectName: subject?.name || '—',
            subjectCode: subject?.code || '—',
            courseId: course?._id?.toString() || a.courseId?.toString() || '',
            courseName: course?.name || '—',
            semesterId: semester?._id?.toString() || a.semesterId?.toString() || '',
            semesterName: semester?.name || '—',
            sectionId: section?._id?.toString() || (a.sectionId ? a.sectionId.toString() : undefined),
            sectionName: section?.name || undefined,
            assignmentType: a.assignmentType,
          };
        });

        roleProfile.faculty = {
          facultyId: faculty._id.toString(),
          employeeId: faculty.employeeId || undefined,
          designation: faculty.designation || 'Faculty Member',
          qualification: faculty.qualification || undefined,
          specialization: faculty.specialization || undefined,
          joiningDate: faculty.joiningDate || undefined,
          activeAssignments,
        };
      }
    }

    // 3. HOD Composed Profile: Department scope and management summary
    if (user.role === AppRole.HOD) {
      const deptId = user.departmentId;
      let facultyCount = 0;
      let studentsCount = 0;
      let programsCount = 0;

      if (deptId) {
        [facultyCount, studentsCount, programsCount] = await Promise.all([
          Faculty.countDocuments({ departmentId: deptId, isActive: true }),
          Student.countDocuments({ departmentId: deptId, isActive: true }),
          Course.countDocuments({ departmentId: deptId }),
        ]);
      }

      roleProfile.hod = {
        facultyId: roleProfile.faculty?.facultyId,
        departmentId: deptId ? deptId.toString() : '',
        departmentName,
        departmentCode,
        designation: roleProfile.faculty?.designation || 'Head of Department',
        managedScope: {
          programsCount,
          facultyCount,
          studentsCount,
        },
      };
    }

    // 4. COLLEGE ADMIN Composed Profile: College scope summary
    if (user.role === AppRole.COLLEGE_ADMIN) {
      const colId = user.collegeId;
      let departmentsCount = 0;
      let facultyCount = 0;
      let studentsCount = 0;

      if (colId) {
        [departmentsCount, facultyCount, studentsCount] = await Promise.all([
          Department.countDocuments({ collegeId: colId, isActive: true }),
          Faculty.countDocuments({ collegeId: colId, isActive: true }),
          Student.countDocuments({ collegeId: colId, isActive: true }),
        ]);
      }

      roleProfile.collegeAdmin = {
        collegeId: colId ? colId.toString() : '',
        collegeName,
        collegeCode: user.collegeId ? 'COLLEGE' : '—',
        administrativeScope: {
          departmentsCount,
          facultyCount,
          studentsCount,
        },
      };
    }

    // 5. SUPER ADMIN Composed Profile: Platform scope
    if (user.role === AppRole.SUPER_ADMIN) {
      roleProfile.superAdmin = { scope: 'GLOBAL' };
    }

    // Privacy Masking: Private phone is masked if viewed by unrelated peers
    let phoneValue = user.phone || '';
    if (!isSelf && requester.role === AppRole.STUDENT) {
      phoneValue = ''; // Students cannot see private phone numbers of faculty or peers
    }

    // Profile completion indicator (server-calculated, deterministic)
    const completedFields: string[] = [];
    const missingFields: string[] = [];

    if (user.name && user.name.trim().length >= 2) completedFields.push('name');
    else missingFields.push('name');

    if (user.phone && user.phone.trim().length >= 5) completedFields.push('phone');
    else missingFields.push('phone');

    if (user.profilePictureUrl && user.profilePictureUrl.trim().length > 0) completedFields.push('avatar');
    else missingFields.push('avatar');

    if (user.role === AppRole.STUDENT) {
      if (roleProfile.student?.rollNumber) completedFields.push('rollNumber');
      else missingFields.push('rollNumber');
    } else if (user.role === AppRole.FACULTY || user.role === AppRole.HOD) {
      if (roleProfile.faculty?.designation) completedFields.push('designation');
      else missingFields.push('designation');
    } else {
      completedFields.push('institution');
    }

    const totalWeight = completedFields.length + missingFields.length;
    const percentage = totalWeight > 0 ? Math.round((completedFields.length / totalWeight) * 100) : 100;

    const editableFields = isSelf
      ? ['name', 'phone', 'bio', 'avatar', ...(user.role === AppRole.FACULTY || user.role === AppRole.HOD ? ['specialization', 'qualification'] : [])]
      : [];

    return {
      user: {
        id: user._id.toString(),
        instituteId: user.instituteId,
        name: user.name,
        email: user.email || '',
        phone: phoneValue,
        role: user.role,
        profilePictureUrl: user.profilePictureUrl || null,
        bio: user.bio || '',
        collegeId: user.collegeId?.toString(),
        collegeName,
        departmentId: user.departmentId?.toString(),
        departmentName,
      },
      roleProfile,
      completion: {
        percentage,
        completedFields,
        missingFields,
      },
      editableFields,
    };
  }

  /**
   * Updates only explicitly editable fields for the user's profile.
   * Strictly rejects protected academic or authorization fields.
   */
  static async updateProfile(
    userId: string,
    body: Record<string, any>,
    requester: AuthenticatedUser
  ): Promise<ComposedProfile> {
    if (!mongoose.Types.ObjectId.isValid(userId)) {
      throw ApiError.badRequest(`Invalid user ID format: "${userId}"`);
    }

    const isSelf = requester.id === userId;
    const isSuperAdmin = requester.role === AppRole.SUPER_ADMIN;
    const isCollegeAdmin = requester.role === AppRole.COLLEGE_ADMIN;

    if (!isSelf && !isSuperAdmin && !isCollegeAdmin) {
      throw ApiError.forbidden('You are not authorized to edit this profile');
    }

    const user = await User.findById(userId);
    if (!user) {
      throw ApiError.notFound(`User with ID "${userId}" not found`);
    }

    // Explicit rejection of protected fields
    const protectedFields = [
      'role',
      'collegeId',
      'studentId',
      'facultyId',
      'departmentId',
      'courseId',
      'semesterId',
      'sectionId',
      'academicYearId',
      'rollNumber',
      'employeeId',
      'email',
      'accountStatus',
      'activationStatus',
      'passwordHash',
      'permissions',
      'isSuperAdmin',
      'currentEnrollment',
      'assignments',
      'subjectIds',
      'sectionIds',
    ];

    for (const key of Object.keys(body)) {
      if (protectedFields.includes(key)) {
        throw ApiError.badRequest(
          `Protected field '${key}' cannot be modified through the profile endpoint. Academic and identity fields remain authoritative in their respective source modules.`
        );
      }
    }

    const previousSnapshot = {
      name: user.name,
      phone: user.phone,
      bio: user.bio,
    };

    // Apply allowed updates to User
    if (typeof body.name === 'string' && body.name.trim().length >= 2) {
      user.name = body.name.trim();
    }
    if (body.phone !== undefined) {
      user.phone = body.phone ? body.phone.trim() : undefined;
    }
    if (body.bio !== undefined) {
      user.bio = body.bio ? body.bio.trim() : '';
    }

    await user.save();

    // Synchronize display name and contact on linked role entity
    if (user.role === AppRole.STUDENT) {
      await Student.updateOne(
        { userId: user._id },
        { $set: { name: user.name, phone: user.phone } }
      );
    } else if (user.role === AppRole.FACULTY || user.role === AppRole.HOD) {
      const facultyUpdate: Record<string, any> = {
        name: user.name,
        phone: user.phone,
      };
      if (typeof body.specialization === 'string') {
        facultyUpdate.specialization = body.specialization.trim();
      }
      if (typeof body.qualification === 'string') {
        facultyUpdate.qualification = body.qualification.trim();
      }
      await Faculty.updateOne({ userId: user._id }, { $set: facultyUpdate });
    }

    // Audit meaningful profile mutation
    await AuditService.logAction({
      collegeId: user.collegeId?.toString(),
      actorUserId: requester.id,
      entityType: 'UserProfile',
      entityId: user._id.toString(),
      action: 'PROFILE_UPDATED',
      previousValue: previousSnapshot,
      newValue: {
        name: user.name,
        phone: user.phone,
        bio: user.bio,
      },
      timestamp: new Date(),
    });

    // Realtime event emission (Prompt 38 bus)
    realtimeEventBus.publish({
      eventType: AcadexEventType.PROFILE_UPDATED,
      aggregateType: 'UserProfile',
      aggregateId: user._id.toString(),
      action: 'UPDATED',
      collegeId: user.collegeId ? user.collegeId.toString() : 'global',
      scope: {
        type: 'user',
        collegeId: user.collegeId ? user.collegeId.toString() : 'global',
        userId: user._id.toString(),
      },
      payload: {
        userId: user._id.toString(),
        role: user.role,
        name: user.name,
      },
    });

    return this.getComposedProfile(userId, requester);
  }

  /**
   * Initiates avatar image upload session with ImageKit storage signed parameters.
   */
  static async requestAvatarUploadAuth(
    userId: string,
    data: { fileName: string; mimeType: string; fileSize: number },
    requester: AuthenticatedUser
  ) {
    if (!mongoose.Types.ObjectId.isValid(userId)) {
      throw ApiError.badRequest(`Invalid user ID format: "${userId}"`);
    }

    const isSelf = requester.id === userId;
    const isSuperAdmin = requester.role === AppRole.SUPER_ADMIN;
    const isCollegeAdmin = requester.role === AppRole.COLLEGE_ADMIN;

    if (!isSelf && !isSuperAdmin && !isCollegeAdmin) {
      throw ApiError.forbidden('You are not authorized to upload an avatar for this profile');
    }

    const user = await User.findById(userId);
    if (!user) {
      throw ApiError.notFound(`User with ID "${userId}" not found`);
    }

    const cleanMime = data.mimeType.trim().toLowerCase();
    const { valid, error } = ImageKitService.validateMimeAndExtension(cleanMime, data.fileName);
    if (!valid || !['image/jpeg', 'image/png', 'image/webp'].includes(cleanMime)) {
      throw ApiError.badRequest(error || 'Only JPEG, PNG, and WebP images are allowed for profile avatars');
    }

    const maxProfileSizeBytes = env.PROFILE_IMAGE_MAX_FILE_SIZE_MB * 1024 * 1024;
    if (data.fileSize > maxProfileSizeBytes) {
      throw ApiError.badRequest(`File size exceeds maximum limit of ${env.PROFILE_IMAGE_MAX_FILE_SIZE_MB}MB`);
    }

    const collegeId = user.collegeId ? user.collegeId.toString() : 'global';
    const folder = ImageKitService.buildProfileFolder(collegeId, user.role, user._id.toString());
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

  /**
   * Finalizes avatar upload, verifies storage persistence, and updates canonical profilePictureUrl.
   */
  static async completeAvatarUpload(
    userId: string,
    data: { fileId: string; fileUrl?: string },
    requester: AuthenticatedUser
  ): Promise<ComposedProfile> {
    if (!mongoose.Types.ObjectId.isValid(userId)) {
      throw ApiError.badRequest(`Invalid user ID format: "${userId}"`);
    }

    const isSelf = requester.id === userId;
    const isSuperAdmin = requester.role === AppRole.SUPER_ADMIN;
    const isCollegeAdmin = requester.role === AppRole.COLLEGE_ADMIN;

    if (!isSelf && !isSuperAdmin && !isCollegeAdmin) {
      throw ApiError.forbidden('You are not authorized to update the avatar for this profile');
    }

    const user = await User.findById(userId);
    if (!user) {
      throw ApiError.notFound(`User with ID "${userId}" not found`);
    }

    const fileMeta = await ImageKitService.getFileDetails(data.fileId);
    if (!fileMeta) {
      throw ApiError.badRequest('Uploaded avatar file was not found in storage. Please upload the file first.');
    }

    const previousAvatar = user.profilePictureUrl;
    user.profilePictureUrl = fileMeta.url || data.fileUrl || user.profilePictureUrl;
    await user.save();

    // Audit avatar change
    await AuditService.logAction({
      collegeId: user.collegeId?.toString(),
      actorUserId: requester.id,
      entityType: 'UserProfile',
      entityId: user._id.toString(),
      action: 'PROFILE_AVATAR_UPDATED',
      previousValue: { avatarUrl: previousAvatar },
      newValue: { avatarUrl: user.profilePictureUrl },
      timestamp: new Date(),
    });

    // Realtime event emission
    realtimeEventBus.publish({
      eventType: AcadexEventType.PROFILE_AVATAR_UPDATED,
      aggregateType: 'UserProfile',
      aggregateId: user._id.toString(),
      action: 'UPDATED',
      collegeId: user.collegeId ? user.collegeId.toString() : 'global',
      scope: {
        type: 'user',
        collegeId: user.collegeId ? user.collegeId.toString() : 'global',
        userId: user._id.toString(),
      },
      payload: {
        userId: user._id.toString(),
        role: user.role,
        avatarUrl: user.profilePictureUrl,
      },
    });

    return this.getComposedProfile(userId, requester);
  }

  /**
   * Scoped directory lookup bounded by tenant and academic relationship.
   */
  static async getDirectory(
    query: { search?: string; role?: AppRole; departmentId?: string; page?: number; limit?: number },
    requester: AuthenticatedUser
  ) {
    const page = Math.max(1, query.page || 1);
    const limit = Math.min(100, Math.max(1, query.limit || 20));
    const skip = (page - 1) * limit;

    const filter: Record<string, any> = {};

    // Tenant isolation
    if (requester.role !== AppRole.SUPER_ADMIN && requester.collegeId) {
      filter.collegeId = requester.collegeId;
    }

    if (query.role) {
      filter.role = query.role;
    }

    // Role-specific scoping
    if (requester.role === AppRole.STUDENT) {
      // Students can only see faculty in their directory
      filter.role = AppRole.FACULTY;
      if (requester.departmentId) {
        filter.departmentId = requester.departmentId;
      }
    } else if (requester.role === AppRole.HOD && requester.departmentId) {
      filter.departmentId = requester.departmentId;
    } else if (query.departmentId) {
      filter.departmentId = query.departmentId;
    }

    if (query.search && query.search.trim().length > 0) {
      const searchRegex = new RegExp(query.search.trim(), 'i');
      filter.$or = [{ name: searchRegex }, { instituteId: searchRegex }];
    }

    const [users, total] = await Promise.all([
      User.find(filter)
        .select('name role profilePictureUrl departmentId instituteId')
        .populate('departmentId', 'name code')
        .sort({ name: 1 })
        .skip(skip)
        .limit(limit),
      User.countDocuments(filter),
    ]);

    const items = users.map((u) => {
      const dept: any = u.departmentId;
      return {
        id: u._id.toString(),
        name: u.name,
        role: u.role,
        instituteId: u.instituteId,
        profilePictureUrl: u.profilePictureUrl || null,
        departmentName: dept?.name || undefined,
        departmentCode: dept?.code || undefined,
      };
    });

    return {
      items,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  /**
   * Validates relationship permissions for cross-user profile reads.
   */
  private static async verifyProfileReadPermission(
    requester: AuthenticatedUser,
    targetUser: IUser
  ): Promise<void> {
    if (requester.role === AppRole.STUDENT) {
      if (targetUser.role === AppRole.STUDENT) {
        throw ApiError.forbidden('Students cannot access other student profiles');
      }
      // Student viewing faculty: allowed if in same college
      return;
    }

    if (requester.role === AppRole.FACULTY) {
      if (targetUser.role === AppRole.STUDENT) {
        // Verify student is enrolled in a section/semester taught by this faculty
        const faculty = await Faculty.findOne({ userId: requester.id });
        if (!faculty) {
          throw ApiError.forbidden('Faculty profile not linked to user account');
        }

        const assignments = await FacultyAssignment.find({
          facultyId: faculty._id,
          status: 'active',
          isActive: true,
        });

        const assignedSectionIds = assignments.map((a) => a.sectionId?.toString()).filter(Boolean);
        const assignedSemesterIds = assignments.map((a) => a.semesterId?.toString()).filter(Boolean);

        const student = await Student.findOne({ userId: targetUser._id });
        if (!student) {
          throw ApiError.forbidden('Student profile not found');
        }

        const activeEnrollment = await StudentEnrollment.findOne({
          studentId: student._id,
          status: 'active',
        });

        const hasTeachingContext =
          activeEnrollment &&
          ((activeEnrollment.sectionId && assignedSectionIds.includes(activeEnrollment.sectionId.toString())) ||
            (!activeEnrollment.sectionId && assignedSemesterIds.includes(activeEnrollment.semesterId.toString())));

        if (!hasTeachingContext) {
          throw ApiError.forbidden(
            'Faculty access to student profiles is strictly limited to active teaching contexts'
          );
        }
      }
      return;
    }

    if (requester.role === AppRole.HOD) {
      if (
        requester.departmentId &&
        targetUser.departmentId &&
        requester.departmentId.toString() !== targetUser.departmentId.toString()
      ) {
        throw ApiError.forbidden('HOD profile access is strictly scoped to their department');
      }
      return;
    }
  }
}
