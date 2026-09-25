import mongoose from 'mongoose';
import {
  Announcement,
  IAnnouncement,
  User,
  Student,
  StudentEnrollment,
  Faculty,
  FacultyAssignment,
  Department,
  Course,
  Section,
} from '../models';
import {
  AudienceScope,
  AnnouncementStatus,
  NotificationType,
  NotificationCategory,
  NotificationPriority,
} from '../constants/notification.constants';
import { AppRole } from '../constants/roles';
import { AccountStatus } from '../constants/status';
import { NotificationService, CreateNotificationInput } from './notification.service';
import { AuditService } from './audit.service';
import { ApiError } from '../utils/apiError';
import { AuthenticatedUser } from '../types/auth.types';
import { logger } from '../utils/logger';

export interface CreateAnnouncementInput {
  title: string;
  body: string;
  category?: NotificationCategory;
  audienceScope: AudienceScope;
  departmentId?: string | null;
  targetRole?: AppRole | null;
  targetCourseId?: string | null;
  targetSemesterId?: string | null;
  targetSectionId?: string | null;
  targetUserId?: string | null;
  targetUserIds?: string[] | null;
  status?: string;
  publishAt?: Date | string | null;
  expiresAt?: Date | string | null;
  priority?: NotificationPriority;
  isPinned?: boolean;
  publishNow?: boolean;
}

export class AnnouncementService {
  /**
   * Validates author authority and audience parameters
   */
  private static async validateAuthorAndAudience(
    data: CreateAnnouncementInput,
    requester: AuthenticatedUser
  ): Promise<{ collegeId: string; departmentId?: string | null }> {
    // 1. Role enforcement: Faculty and Students cannot create announcements
    if (requester.role === AppRole.FACULTY || requester.role === AppRole.STUDENT) {
      throw ApiError.forbidden('Only administrators and HODs are authorized to create announcements');
    }

    // 2. Tenant scoping
    const collegeId = requester.collegeId;
    if (!collegeId || collegeId === 'global') {
      if (requester.role !== AppRole.SUPER_ADMIN) {
        throw ApiError.badRequest('Tenant context (collegeId) is missing');
      }
    }

    let departmentId = data.departmentId ? data.departmentId : null;

    // 3. HOD Scope Enforcement
    if (requester.role === AppRole.HOD) {
      if (!requester.departmentId) {
        throw ApiError.forbidden('HOD is not assigned to a department');
      }
      if (data.audienceScope === AudienceScope.COLLEGE) {
        throw ApiError.forbidden('HOD is not authorized to publish college-wide announcements');
      }
      if (data.departmentId && data.departmentId !== requester.departmentId) {
        throw ApiError.forbidden('HOD can only target announcements within their assigned department');
      }
      departmentId = requester.departmentId;
    }

    // 4. Verify department belongs to college
    if (departmentId && collegeId && collegeId !== 'global') {
      const deptDoc = await Department.findById(departmentId);
      if (!deptDoc) {
        throw ApiError.notFound('Department not found');
      }
      if (deptDoc.collegeId.toString() !== collegeId) {
        throw ApiError.forbidden('Department does not belong to the authorized college');
      }
    }

    // 5. Audience-specific validations
    if (data.audienceScope === AudienceScope.DEPARTMENT && !departmentId) {
      throw ApiError.badRequest('departmentId is required when audienceScope is DEPARTMENT');
    }

    if (data.audienceScope === AudienceScope.COURSE) {
      if (!data.targetCourseId) {
        throw ApiError.badRequest('targetCourseId is required when audienceScope is COURSE');
      }
      const course = await Course.findById(data.targetCourseId);
      if (!course || course.collegeId.toString() !== collegeId) {
        throw ApiError.notFound('Target course not found in this college');
      }
      if (requester.role === AppRole.HOD && course.departmentId.toString() !== requester.departmentId) {
        throw ApiError.forbidden('HOD cannot target courses outside their department');
      }
    }

    if (data.audienceScope === AudienceScope.SECTION) {
      if (!data.targetSectionId) {
        throw ApiError.badRequest('targetSectionId is required when audienceScope is SECTION');
      }
      const section = await Section.findById(data.targetSectionId);
      if (!section || section.collegeId.toString() !== collegeId) {
        throw ApiError.notFound('Target section not found in this college');
      }
      if (requester.role === AppRole.HOD && section.departmentId.toString() !== requester.departmentId) {
        throw ApiError.forbidden('HOD cannot target sections outside their department');
      }
    }

    if (data.audienceScope === AudienceScope.ROLE && !data.targetRole) {
      throw ApiError.badRequest('targetRole is required when audienceScope is ROLE');
    }

    if (data.audienceScope === AudienceScope.INDIVIDUAL) {
      const singleTargetId = data.targetUserId || (Array.isArray(data.targetUserIds) && data.targetUserIds.length > 0 ? data.targetUserIds[0] : null);
      if (!singleTargetId) {
        throw ApiError.badRequest('targetUserId is required when audienceScope is INDIVIDUAL');
      }
      data.targetUserId = singleTargetId;
      const user = await User.findById(data.targetUserId);
      if (!user || user.collegeId?.toString() !== collegeId) {
        throw ApiError.notFound('Target user not found in this college');
      }
      if (requester.role === AppRole.HOD && user.departmentId?.toString() !== requester.departmentId) {
        throw ApiError.forbidden('HOD cannot target users outside their department');
      }
    }

    // 6. Dates check
    if (data.publishAt && data.expiresAt) {
      const pub = new Date(data.publishAt).getTime();
      const exp = new Date(data.expiresAt).getTime();
      if (exp <= pub) {
        throw ApiError.badRequest('Expiry date must be after publish date');
      }
    }

    return { collegeId: collegeId!, departmentId };
  }

  /**
   * Resolves all recipient user IDs based on authoritative server queries
   */
  static async resolveRecipientUserIds(announcement: IAnnouncement): Promise<string[]> {
    const recipientUserIds = new Set<string>();
    const collegeObjId = new mongoose.Types.ObjectId(announcement.collegeId.toString());

    switch (announcement.audienceScope) {
      case AudienceScope.COLLEGE: {
        const users = await User.find({
          collegeId: collegeObjId,
          accountStatus: { $ne: AccountStatus.DEACTIVATED },
        }).select('_id');
        users.forEach((u) => recipientUserIds.add(u._id.toString()));
        break;
      }

      case AudienceScope.DEPARTMENT: {
        if (!announcement.departmentId) break;
        const users = await User.find({
          collegeId: collegeObjId,
          departmentId: new mongoose.Types.ObjectId(announcement.departmentId.toString()),
          accountStatus: { $ne: AccountStatus.DEACTIVATED },
        }).select('_id');
        users.forEach((u) => recipientUserIds.add(u._id.toString()));
        break;
      }

      case AudienceScope.COURSE: {
        if (!announcement.targetCourseId) break;
        // 1. Enrolled students
        const enrollments = await StudentEnrollment.find({
          collegeId: collegeObjId,
          courseId: announcement.targetCourseId,
          status: 'active',
        }).select('studentId');
        const studentIds = enrollments.map((e) => e.studentId);
        if (studentIds.length > 0) {
          const students = await Student.find({ _id: { $in: studentIds } }).select('userId');
          students.forEach((s) => recipientUserIds.add(s.userId.toString()));
        }
        // 2. Faculty teaching this course
        const assignments = await FacultyAssignment.find({
          collegeId: collegeObjId,
          courseId: announcement.targetCourseId,
          status: 'active',
        }).select('facultyId');
        const facultyIds = assignments.map((a) => a.facultyId);
        if (facultyIds.length > 0) {
          const faculties = await Faculty.find({ _id: { $in: facultyIds } }).select('userId');
          faculties.forEach((f) => recipientUserIds.add(f.userId.toString()));
        }
        break;
      }

      case AudienceScope.SEMESTER: {
        if (!announcement.targetSemesterId) break;
        const enrollments = await StudentEnrollment.find({
          collegeId: collegeObjId,
          semesterId: announcement.targetSemesterId,
          status: 'active',
        }).select('studentId');
        const studentIds = enrollments.map((e) => e.studentId);
        if (studentIds.length > 0) {
          const students = await Student.find({ _id: { $in: studentIds } }).select('userId');
          students.forEach((s) => recipientUserIds.add(s.userId.toString()));
        }
        const assignments = await FacultyAssignment.find({
          collegeId: collegeObjId,
          semesterId: announcement.targetSemesterId,
          status: 'active',
        }).select('facultyId');
        const facultyIds = assignments.map((a) => a.facultyId);
        if (facultyIds.length > 0) {
          const faculties = await Faculty.find({ _id: { $in: facultyIds } }).select('userId');
          faculties.forEach((f) => recipientUserIds.add(f.userId.toString()));
        }
        break;
      }

      case AudienceScope.SECTION: {
        if (!announcement.targetSectionId) break;
        const enrollments = await StudentEnrollment.find({
          collegeId: collegeObjId,
          sectionId: announcement.targetSectionId,
          status: 'active',
        }).select('studentId');
        const studentIds = enrollments.map((e) => e.studentId);
        if (studentIds.length > 0) {
          const students = await Student.find({ _id: { $in: studentIds } }).select('userId');
          students.forEach((s) => recipientUserIds.add(s.userId.toString()));
        }
        const assignments = await FacultyAssignment.find({
          collegeId: collegeObjId,
          sectionId: announcement.targetSectionId,
          status: 'active',
        }).select('facultyId');
        const facultyIds = assignments.map((a) => a.facultyId);
        if (facultyIds.length > 0) {
          const faculties = await Faculty.find({ _id: { $in: facultyIds } }).select('userId');
          faculties.forEach((f) => recipientUserIds.add(f.userId.toString()));
        }
        break;
      }

      case AudienceScope.ROLE: {
        if (!announcement.targetRole) break;
        const filter: Record<string, unknown> = {
          collegeId: collegeObjId,
          role: announcement.targetRole,
          accountStatus: { $ne: AccountStatus.DEACTIVATED },
        };
        if (announcement.departmentId) {
          filter.departmentId = new mongoose.Types.ObjectId(announcement.departmentId.toString());
        }
        const users = await User.find(filter).select('_id');
        users.forEach((u) => recipientUserIds.add(u._id.toString()));
        break;
      }

      case AudienceScope.INDIVIDUAL: {
        if (announcement.targetUserId) {
          recipientUserIds.add(announcement.targetUserId.toString());
        }
        break;
      }
    }

    return Array.from(recipientUserIds);
  }

  /**
   * Internal helper to dispatch notification records to all resolved recipients
   */
  private static async dispatchAnnouncementNotifications(announcement: IAnnouncement): Promise<number> {
    const recipients = await this.resolveRecipientUserIds(announcement);
    if (recipients.length === 0) return 0;

    const notifInputs: CreateNotificationInput[] = recipients.map((userId) => ({
      collegeId: announcement.collegeId.toString(),
      departmentId: announcement.departmentId?.toString(),
      recipientUserId: userId,
      title: announcement.title,
      body: announcement.body,
      notificationType: NotificationType.ANNOUNCEMENT,
      category: announcement.category || NotificationCategory.ANNOUNCEMENT,
      priority: announcement.priority,
      entityType: 'Announcement',
      entityId: announcement.id,
      deepLink: `/announcements/${announcement.id}`,
      idempotencyKey: `ann_${announcement.id}_${userId}`,
    }));

    const created = await NotificationService.createBatchNotifications(notifInputs);
    return created.length;
  }

  /**
   * Creates a new Announcement (Draft or Published immediately)
   */
  static async createAnnouncement(
    data: CreateAnnouncementInput,
    requester: AuthenticatedUser
  ): Promise<IAnnouncement> {
    const { collegeId, departmentId } = await this.validateAuthorAndAudience(data, requester);

    const isPublishNow = !!data.publishNow || (data.status as any) === AnnouncementStatus.PUBLISHED;
    const finalTargetUserId = data.targetUserId || (Array.isArray(data.targetUserIds) && data.targetUserIds.length > 0 ? data.targetUserIds[0] : null);
    const now = new Date();

    const announcement = await Announcement.create({
      collegeId: new mongoose.Types.ObjectId(collegeId),
      departmentId: departmentId ? new mongoose.Types.ObjectId(departmentId) : null,
      title: data.title.trim(),
      body: data.body.trim(),
      category: data.category || NotificationCategory.ANNOUNCEMENT,
      audienceScope: data.audienceScope,
      targetRole: data.targetRole || null,
      targetCourseId: data.targetCourseId ? new mongoose.Types.ObjectId(data.targetCourseId) : null,
      targetSemesterId: data.targetSemesterId ? new mongoose.Types.ObjectId(data.targetSemesterId) : null,
      targetSectionId: data.targetSectionId ? new mongoose.Types.ObjectId(data.targetSectionId) : null,
      targetUserId: finalTargetUserId ? new mongoose.Types.ObjectId(finalTargetUserId) : null,
      publishAt: data.publishAt ? new Date(data.publishAt) : now,
      expiresAt: data.expiresAt ? new Date(data.expiresAt) : null,
      priority: data.priority || NotificationPriority.NORMAL,
      isPinned: !!data.isPinned,
      status: isPublishNow ? AnnouncementStatus.PUBLISHED : AnnouncementStatus.DRAFT,
      publishedAt: isPublishNow ? now : null,
      createdBy: new mongoose.Types.ObjectId(requester.id),
      recipientCount: 0,
    });

    if (isPublishNow) {
      try {
        const count = await this.dispatchAnnouncementNotifications(announcement);
        announcement.recipientCount = count;
        await announcement.save();
      } catch (err) {
        logger.error(`Error dispatching notifications for announcement ${announcement.id}:`, err as Error);
      }
    }

    await AuditService.log({
      collegeId,
      actorUserId: requester.id,
      action: isPublishNow ? 'ANNOUNCEMENT_PUBLISHED' : 'ANNOUNCEMENT_CREATED',
      entityType: 'Announcement',
      entityId: announcement.id,
      newValue: { title: announcement.title, audienceScope: announcement.audienceScope, status: announcement.status },
    }).catch((e: Error) => logger.warn(`Audit log failed: ${e.message}`));

    return announcement;
  }

  /**
   * Publishes an existing Draft Announcement
   */
  static async publishAnnouncement(id: string, requester: AuthenticatedUser): Promise<IAnnouncement> {
    if (!mongoose.Types.ObjectId.isValid(id)) {
      throw ApiError.notFound('Announcement not found');
    }

    const announcement = await Announcement.findById(id);
    if (!announcement) {
      throw ApiError.notFound('Announcement not found');
    }

    // Role & Tenant verification
    if (requester.role === AppRole.FACULTY || requester.role === AppRole.STUDENT) {
      throw ApiError.forbidden('You are not authorized to publish announcements');
    }
    if (requester.role !== AppRole.SUPER_ADMIN && announcement.collegeId.toString() !== requester.collegeId) {
      throw ApiError.forbidden('Access denied');
    }
    if (requester.role === AppRole.HOD && announcement.departmentId?.toString() !== requester.departmentId) {
      throw ApiError.forbidden('HOD can only manage announcements in their department');
    }

    if (announcement.status === AnnouncementStatus.PUBLISHED) {
      return announcement; // Idempotent
    }

    announcement.status = AnnouncementStatus.PUBLISHED;
    announcement.publishedAt = new Date();

    const count = await this.dispatchAnnouncementNotifications(announcement);
    announcement.recipientCount = count;
    await announcement.save();

    await AuditService.log({
      collegeId: announcement.collegeId.toString(),
      actorUserId: requester.id,
      action: 'ANNOUNCEMENT_PUBLISHED',
      entityType: 'Announcement',
      entityId: announcement.id,
      newValue: { status: announcement.status, recipientCount: count },
    }).catch((e: Error) => logger.warn(`Audit log failed: ${e.message}`));

    return announcement;
  }

  /**
   * Updates an existing announcement (only allowed in DRAFT status)
   */
  static async updateAnnouncement(
    id: string,
    update: Partial<CreateAnnouncementInput>,
    requester: AuthenticatedUser
  ): Promise<IAnnouncement> {
    if (!mongoose.Types.ObjectId.isValid(id)) {
      throw ApiError.notFound('Announcement not found');
    }

    const announcement = await Announcement.findById(id);
    if (!announcement) {
      throw ApiError.notFound('Announcement not found');
    }

    if (requester.role !== AppRole.SUPER_ADMIN && announcement.collegeId.toString() !== requester.collegeId) {
      throw ApiError.forbidden('Access denied');
    }
    if (requester.role === AppRole.HOD && announcement.departmentId?.toString() !== requester.departmentId) {
      throw ApiError.forbidden('HOD can only manage announcements in their department');
    }

    if (announcement.status !== AnnouncementStatus.DRAFT) {
      throw ApiError.badRequest('Published or Archived announcements cannot be edited to maintain notification integrity');
    }

    if (update.title) announcement.title = update.title.trim();
    if (update.body) announcement.body = update.body.trim();
    if (update.category) announcement.category = update.category;
    if (update.priority) announcement.priority = update.priority;
    if (update.isPinned !== undefined) announcement.isPinned = update.isPinned;
    if (update.expiresAt !== undefined) {
      announcement.expiresAt = update.expiresAt ? new Date(update.expiresAt) : null;
    }

    await announcement.save();
    return announcement;
  }

  /**
   * Archives a published announcement
   */
  static async archiveAnnouncement(id: string, requester: AuthenticatedUser): Promise<IAnnouncement> {
    if (!mongoose.Types.ObjectId.isValid(id)) {
      throw ApiError.notFound('Announcement not found');
    }

    const announcement = await Announcement.findById(id);
    if (!announcement) {
      throw ApiError.notFound('Announcement not found');
    }

    if (requester.role !== AppRole.SUPER_ADMIN && announcement.collegeId.toString() !== requester.collegeId) {
      throw ApiError.forbidden('Access denied');
    }
    if (requester.role === AppRole.HOD && announcement.departmentId?.toString() !== requester.departmentId) {
      throw ApiError.forbidden('HOD can only manage announcements in their department');
    }

    announcement.status = AnnouncementStatus.ARCHIVED;
    await announcement.save();

    await AuditService.log({
      collegeId: announcement.collegeId.toString(),
      actorUserId: requester.id,
      action: 'ANNOUNCEMENT_ARCHIVED',
      entityType: 'Announcement',
      entityId: announcement.id,
    }).catch((e: Error) => logger.warn(`Audit log failed: ${e.message}`));

    return announcement;
  }

  /**
   * Deletes a draft announcement
   */
  static async deleteAnnouncement(id: string, requester: AuthenticatedUser): Promise<void> {
    if (!mongoose.Types.ObjectId.isValid(id)) {
      throw ApiError.notFound('Announcement not found');
    }

    const announcement = await Announcement.findById(id);
    if (!announcement) {
      throw ApiError.notFound('Announcement not found');
    }

    if (requester.role !== AppRole.SUPER_ADMIN && announcement.collegeId.toString() !== requester.collegeId) {
      throw ApiError.forbidden('Access denied');
    }
    if (requester.role === AppRole.HOD && announcement.departmentId?.toString() !== requester.departmentId) {
      throw ApiError.forbidden('HOD can only manage announcements in their department');
    }

    if (announcement.status === AnnouncementStatus.PUBLISHED) {
      throw ApiError.badRequest('Published announcements cannot be deleted to preserve audit integrity. Archive it instead.');
    }

    await Announcement.deleteOne({ _id: announcement._id });
  }

  /**
   * Lists announcements with authoritative scoping:
   * - If manage === true: Admin management list for the author's tenant scope
   * - If manage === false: Target recipient feed for the current user (Student, Faculty, HOD, Admin)
   */
  static async listAnnouncements(
    query: {
      manage?: boolean;
      status?: AnnouncementStatus;
      audienceScope?: AudienceScope;
      departmentId?: string;
      page?: number;
      limit?: number;
    },
    requester: AuthenticatedUser
  ): Promise<{
    items: IAnnouncement[];
    total: number;
    page: number;
    limit: number;
    totalPages: number;
  }> {
    const page = Math.max(1, query.page || 1);
    const limit = Math.min(100, Math.max(1, query.limit || 20));
    const skip = (page - 1) * limit;

    // A. ADMIN MANAGEMENT VIEW
    if (query.manage) {
      if (requester.role === AppRole.STUDENT || requester.role === AppRole.FACULTY) {
        throw ApiError.forbidden('You are not authorized to view announcement management');
      }

      const filter: Record<string, unknown> = {};

      if (requester.role === AppRole.SUPER_ADMIN) {
        if (requester.collegeId && requester.collegeId !== 'global') {
          filter.collegeId = new mongoose.Types.ObjectId(requester.collegeId);
        }
      } else {
        filter.collegeId = new mongoose.Types.ObjectId(requester.collegeId);
      }

      if (requester.role === AppRole.HOD) {
        filter.departmentId = new mongoose.Types.ObjectId(requester.departmentId);
      } else if (query.departmentId && mongoose.Types.ObjectId.isValid(query.departmentId)) {
        filter.departmentId = new mongoose.Types.ObjectId(query.departmentId);
      }

      if (query.status) {
        filter.status = query.status;
      }
      if (query.audienceScope) {
        filter.audienceScope = query.audienceScope;
      }

      const [items, total] = await Promise.all([
        Announcement.find(filter).sort({ createdAt: -1 }).skip(skip).limit(limit),
        Announcement.countDocuments(filter),
      ]);

      return {
        items,
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit) || 1,
      };
    }

    // B. USER RECIPIENT FEED VIEW (Student, Faculty, HOD, Admin reading announcements)
    const collegeId = requester.collegeId;
    if (!collegeId || collegeId === 'global') {
      return { items: [], total: 0, page: 1, limit, totalPages: 1 };
    }

    const now = new Date();
    const collegeObjId = new mongoose.Types.ObjectId(collegeId);

    // Build audience clauses that match this user
    const audienceConditions: Record<string, unknown>[] = [
      { audienceScope: AudienceScope.COLLEGE },
      { audienceScope: AudienceScope.ROLE, targetRole: requester.role },
      { audienceScope: AudienceScope.INDIVIDUAL, targetUserId: new mongoose.Types.ObjectId(requester.id) },
    ];

    if (requester.departmentId && mongoose.Types.ObjectId.isValid(requester.departmentId)) {
      audienceConditions.push({
        audienceScope: AudienceScope.DEPARTMENT,
        departmentId: new mongoose.Types.ObjectId(requester.departmentId),
      });
      audienceConditions.push({
        audienceScope: AudienceScope.ROLE,
        targetRole: requester.role,
        departmentId: new mongoose.Types.ObjectId(requester.departmentId),
      });
    }

    // For students: check enrolled courses, semesters, and sections
    if (requester.role === AppRole.STUDENT) {
      const studentProfile = await Student.findOne({ userId: requester.id });
      if (studentProfile) {
        const enrollments = await StudentEnrollment.find({
          studentId: studentProfile._id,
          status: 'active',
        });
        const courseIds = enrollments.map((e) => e.courseId);
        const semesterIds = enrollments.map((e) => e.semesterId);
        const sectionIds = enrollments.map((e) => e.sectionId);

        if (courseIds.length > 0) {
          audienceConditions.push({
            audienceScope: AudienceScope.COURSE,
            targetCourseId: { $in: courseIds },
          });
        }
        if (semesterIds.length > 0) {
          audienceConditions.push({
            audienceScope: AudienceScope.SEMESTER,
            targetSemesterId: { $in: semesterIds },
          });
        }
        if (sectionIds.length > 0) {
          audienceConditions.push({
            audienceScope: AudienceScope.SECTION,
            targetSectionId: { $in: sectionIds },
          });
        }
      }
    }

    // For faculty: check assigned courses, semesters, and sections
    if (requester.role === AppRole.FACULTY) {
      const facultyProfile = await Faculty.findOne({ userId: requester.id });
      if (facultyProfile) {
        const assignments = await FacultyAssignment.find({
          facultyId: facultyProfile._id,
          status: 'active',
        });
        const courseIds = assignments.map((a) => a.courseId);
        const semesterIds = assignments.map((a) => a.semesterId);
        const sectionIds = assignments.map((a) => a.sectionId);

        if (courseIds.length > 0) {
          audienceConditions.push({
            audienceScope: AudienceScope.COURSE,
            targetCourseId: { $in: courseIds },
          });
        }
        if (semesterIds.length > 0) {
          audienceConditions.push({
            audienceScope: AudienceScope.SEMESTER,
            targetSemesterId: { $in: semesterIds },
          });
        }
        if (sectionIds.length > 0) {
          audienceConditions.push({
            audienceScope: AudienceScope.SECTION,
            targetSectionId: { $in: sectionIds },
          });
        }
      }
    }

    const feedFilter: Record<string, unknown> = {
      collegeId: collegeObjId,
      status: AnnouncementStatus.PUBLISHED,
      publishAt: { $lte: now },
      $and: [
        {
          $or: [{ expiresAt: null }, { expiresAt: { $gt: now } }],
        },
        {
          $or: audienceConditions,
        },
      ],
    };

    const [items, total] = await Promise.all([
      Announcement.find(feedFilter)
        .sort({ isPinned: -1, publishedAt: -1, createdAt: -1 })
        .skip(skip)
        .limit(limit),
      Announcement.countDocuments(feedFilter),
    ]);

    return {
      items,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit) || 1,
    };
  }

  /**
   * Retrieves single announcement by ID with audience / admin authorization
   */
  static async getAnnouncementById(id: string, requester: AuthenticatedUser): Promise<IAnnouncement> {
    if (!mongoose.Types.ObjectId.isValid(id)) {
      throw ApiError.notFound('Announcement not found');
    }

    const announcement = await Announcement.findById(id);
    if (!announcement) {
      throw ApiError.notFound('Announcement not found');
    }

    if (requester.role !== AppRole.SUPER_ADMIN && announcement.collegeId.toString() !== requester.collegeId) {
      throw ApiError.forbidden('Access denied');
    }

    // Admins and HODs can view any announcement in their college/dept
    if ([AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN].includes(requester.role)) {
      return announcement;
    }
    if (requester.role === AppRole.HOD && (!announcement.departmentId || announcement.departmentId.toString() === requester.departmentId)) {
      return announcement;
    }

    // Otherwise, must be PUBLISHED
    if (announcement.status !== AnnouncementStatus.PUBLISHED) {
      throw ApiError.notFound('Announcement not found or not published');
    }

    return announcement;
  }
}
