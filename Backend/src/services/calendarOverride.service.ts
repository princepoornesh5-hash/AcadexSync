import mongoose from 'mongoose';
import {
  CalendarOverride,
  ICalendarOverride,
  CalendarOverrideType,
  CalendarOverrideScope,
} from '../models/calendarOverride.model';
import { Department } from '../models/department.model';
import { User } from '../models/user.model';
import { Student } from '../models/student.model';
import { StudentEnrollment } from '../models/studentEnrollment.model';
import { NotificationService, CreateNotificationInput } from './notification.service';
import {
  NotificationType,
  NotificationCategory,
  NotificationPriority,
} from '../constants/notification.constants';
import { ApiError } from '../utils/apiError';
import { AuthenticatedUser } from '../types/auth.types';
import { AppRole } from '../constants/roles';
import { AccountStatus } from '../constants/status';
import { logger } from '../utils/logger';

export class CalendarOverrideService {
  /**
   * Creates a new calendar override with authoritative role scoping and duplicate prevention.
   */
  static async createOverride(
    data: {
      collegeId?: string;
      departmentId?: string | null;
      sectionId?: string | null;
      timetableId?: string | null;
      timetableEntryId?: string | null;
      date: string;
      type: CalendarOverrideType;
      scope?: CalendarOverrideScope;
      reason: string;
    },
    requester: AuthenticatedUser
  ): Promise<ICalendarOverride> {
    if (requester.role === AppRole.FACULTY || requester.role === AppRole.STUDENT) {
      throw ApiError.forbidden('You are not authorized to create calendar overrides');
    }

    // 1. Authoritative College ID resolution
    let collegeId = requester.collegeId ? requester.collegeId.toString() : '';
    if (requester.role === AppRole.SUPER_ADMIN) {
      collegeId = data.collegeId || collegeId;
    } else if (data.collegeId && collegeId && data.collegeId.toString() !== collegeId) {
      throw ApiError.forbidden('Cross-college access is strictly prohibited');
    }

    if (!collegeId) {
      throw ApiError.badRequest('collegeId is required');
    }

    // 2. Role-based Department scope validation
    let departmentId: mongoose.Types.ObjectId | null = null;

    if (requester.role === AppRole.HOD) {
      if (!requester.departmentId) {
        throw ApiError.forbidden('HOD is not assigned to a department');
      }
      if (data.departmentId && data.departmentId !== requester.departmentId) {
        throw ApiError.forbidden('HOD can only create calendar overrides for their own department');
      }
      if (data.scope === CalendarOverrideScope.COLLEGE) {
        throw ApiError.forbidden('HOD is not permitted to declare college-wide overrides');
      }
      departmentId = new mongoose.Types.ObjectId(requester.departmentId);
    } else if (data.departmentId) {
      const deptDoc = await Department.findById(data.departmentId);
      if (!deptDoc) {
        throw ApiError.notFound('Department not found');
      }
      if (deptDoc.collegeId.toString() !== collegeId) {
        throw ApiError.forbidden('Department does not belong to this college');
      }
      departmentId = deptDoc._id as mongoose.Types.ObjectId;
    }

    // 3. Determine scope
    let scope = data.scope;
    if (!scope) {
      if (data.timetableEntryId) {
        scope = CalendarOverrideScope.ENTRY;
      } else if (data.sectionId) {
        scope = CalendarOverrideScope.SECTION;
      } else if (departmentId) {
        scope = CalendarOverrideScope.DEPARTMENT;
      } else {
        scope = CalendarOverrideScope.COLLEGE;
      }
    }

    // 4. Check for duplicate or conflicting overrides
    const collegeObjId = new mongoose.Types.ObjectId(collegeId);
    const sectionObjId = data.sectionId ? new mongoose.Types.ObjectId(data.sectionId) : null;
    const entryObjId = data.timetableEntryId ? new mongoose.Types.ObjectId(data.timetableEntryId) : null;
    const timetableObjId = data.timetableId ? new mongoose.Types.ObjectId(data.timetableId) : null;

    // Exact scope duplicate check
    const existing = await CalendarOverride.findOne({
      collegeId: collegeObjId,
      departmentId,
      sectionId: sectionObjId,
      timetableEntryId: entryObjId,
      date: data.date,
    });

    if (existing) {
      throw ApiError.conflict(
        `A calendar override (${existing.type}) already exists for this date and scope`
      );
    }

    // If attempting department/section override on a date that already has a college-wide holiday
    if (departmentId || sectionObjId || entryObjId) {
      const collegeHoliday = await CalendarOverride.findOne({
        collegeId: collegeObjId,
        departmentId: null,
        date: data.date,
        type: CalendarOverrideType.HOLIDAY,
      });
      if (collegeHoliday) {
        throw ApiError.conflict(
          `A college-wide holiday (${collegeHoliday.reason}) is already declared for ${data.date}`
        );
      }
    }

    // 5. Create authoritative record
    const override = await CalendarOverride.create({
      collegeId: collegeObjId,
      departmentId,
      sectionId: sectionObjId,
      timetableId: timetableObjId,
      timetableEntryId: entryObjId,
      date: data.date,
      type: data.type,
      scope,
      reason: data.reason.trim(),
      createdBy: new mongoose.Types.ObjectId(requester.id),
    });

    try {
      await this.dispatchOverrideNotifications(override);
    } catch (err) {
      logger.warn(`Failed to dispatch calendar override notifications: ${(err as Error).message}`);
    }

    return override;
  }

  private static async dispatchOverrideNotifications(override: ICalendarOverride): Promise<void> {
    try {
      const recipientUserIds = new Set<string>();

      if (override.scope === CalendarOverrideScope.COLLEGE) {
        const users = await User.find({
          collegeId: override.collegeId,
          accountStatus: { $ne: AccountStatus.DEACTIVATED },
        }).select('_id');
        users.forEach((u) => recipientUserIds.add(u._id.toString()));
      } else if (override.scope === CalendarOverrideScope.DEPARTMENT && override.departmentId) {
        const users = await User.find({
          collegeId: override.collegeId,
          departmentId: override.departmentId,
          accountStatus: { $ne: AccountStatus.DEACTIVATED },
        }).select('_id');
        users.forEach((u) => recipientUserIds.add(u._id.toString()));
      } else if (override.sectionId) {
        const enrollments = await StudentEnrollment.find({
          sectionId: override.sectionId,
          status: 'active',
        }).select('studentId');
        const studentIds = enrollments.map((e) => e.studentId);
        if (studentIds.length > 0) {
          const students = await Student.find({ _id: { $in: studentIds } }).select('userId');
          students.forEach((s) => recipientUserIds.add(s.userId.toString()));
        }
      }

      if (recipientUserIds.size === 0) return;

      const title =
        override.type === CalendarOverrideType.HOLIDAY ? 'Holiday Declared' : 'Calendar / Schedule Update';
      const body = `${override.reason} on ${override.date}`;

      const notifInputs: CreateNotificationInput[] = Array.from(recipientUserIds).map((userId) => ({
        collegeId: override.collegeId.toString(),
        departmentId: override.departmentId?.toString(),
        recipientUserId: userId,
        title,
        body,
        notificationType: NotificationType.CALENDAR_OVERRIDE,
        category: NotificationCategory.SYSTEM,
        priority: NotificationPriority.NORMAL,
        entityType: 'CalendarOverride',
        entityId: override.id,
        deepLink: '/timetable',
        idempotencyKey: `co_${override.id}_${userId}`,
      }));

      await NotificationService.createBatchNotifications(notifInputs);
    } catch (err) {
      logger.warn(`Failed to dispatch calendar override notifications: ${(err as Error).message}`);
    }
  }

  /**
   * Lists calendar overrides with role scoping and filters.
   */
  static async listOverrides(
    query: {
      page?: number;
      limit?: number;
      collegeId?: string;
      departmentId?: string;
      date?: string;
      from?: string;
      to?: string;
      type?: CalendarOverrideType;
    },
    requester?: AuthenticatedUser
  ): Promise<{ items: ICalendarOverride[]; total: number; page: number; limit: number }> {
    const filter: Record<string, any> = {};

    let targetCollegeId = query.collegeId;
    if (requester && requester.role !== AppRole.SUPER_ADMIN && requester.collegeId) {
      targetCollegeId = requester.collegeId;
    }

    if (targetCollegeId) {
      filter.collegeId = new mongoose.Types.ObjectId(targetCollegeId);
    }

    if (requester && requester.role === AppRole.HOD && requester.departmentId) {
      // HOD sees college-wide overrides plus their own department overrides
      filter.$or = [
        { departmentId: null },
        { departmentId: new mongoose.Types.ObjectId(requester.departmentId) },
      ];
    } else if (query.departmentId) {
      filter.departmentId = new mongoose.Types.ObjectId(query.departmentId);
    }

    if (query.date) {
      filter.date = query.date;
    } else if (query.from || query.to) {
      filter.date = {};
      if (query.from) filter.date.$gte = query.from;
      if (query.to) filter.date.$lte = query.to;
    }

    if (query.type) {
      filter.type = query.type;
    }

    const page = query.page || 1;
    const limit = query.limit || 20;
    const skip = (page - 1) * limit;

    const [items, total] = await Promise.all([
      CalendarOverride.find(filter).sort({ date: 1, createdAt: -1 }).skip(skip).limit(limit),
      CalendarOverride.countDocuments(filter),
    ]);

    return { items, total, page, limit };
  }

  /**
   * Retrieves an override by ID ensuring college/department permissions.
   */
  static async getOverrideById(
    id: string,
    requester?: AuthenticatedUser
  ): Promise<ICalendarOverride> {
    const override = await CalendarOverride.findById(id);
    if (!override) {
      throw ApiError.notFound('Calendar override not found');
    }

    if (requester && requester.role !== AppRole.SUPER_ADMIN) {
      if (override.collegeId.toString() !== requester.collegeId) {
        throw ApiError.forbidden('Cross-college access is strictly prohibited');
      }
      if (
        requester.role === AppRole.HOD &&
        override.departmentId &&
        override.departmentId.toString() !== requester.departmentId
      ) {
        throw ApiError.forbidden('Cross-department access is strictly prohibited');
      }
    }

    return override;
  }

  /**
   * Deletes an override by ID ensuring role and ownership.
   */
  static async deleteOverride(
    id: string,
    requester: AuthenticatedUser
  ): Promise<void> {
    if (requester.role === AppRole.FACULTY || requester.role === AppRole.STUDENT) {
      throw ApiError.forbidden('You are not authorized to delete calendar overrides');
    }

    const override = await CalendarOverride.findById(id);
    if (!override) {
      throw ApiError.notFound('Calendar override not found');
    }

    if (requester.role !== AppRole.SUPER_ADMIN) {
      if (override.collegeId.toString() !== requester.collegeId) {
        throw ApiError.forbidden('Cross-college access is strictly prohibited');
      }
      if (requester.role === AppRole.HOD) {
        if (!override.departmentId || override.departmentId.toString() !== requester.departmentId) {
          throw ApiError.forbidden('HOD can only delete overrides for their own department');
        }
      }
    }

    await override.deleteOne();
  }

  /**
   * Resolves whether an active calendar override applies to a class on a specific date.
   * Checks hierarchically: Entry -> Section -> Department -> College.
   */
  static async resolveActiveOverride(params: {
    collegeId: string | mongoose.Types.ObjectId;
    departmentId?: string | mongoose.Types.ObjectId | null;
    sectionId?: string | mongoose.Types.ObjectId | null;
    timetableEntryId?: string | mongoose.Types.ObjectId | null;
    date: string;
  }): Promise<ICalendarOverride | null> {
    const collegeObjId =
      typeof params.collegeId === 'string'
        ? new mongoose.Types.ObjectId(params.collegeId)
        : params.collegeId;

    // 1. Entry-specific override
    if (params.timetableEntryId) {
      const entryObjId =
        typeof params.timetableEntryId === 'string'
          ? new mongoose.Types.ObjectId(params.timetableEntryId)
          : params.timetableEntryId;
      const entryOverride = await CalendarOverride.findOne({
        collegeId: collegeObjId,
        timetableEntryId: entryObjId,
        date: params.date,
      });
      if (entryOverride) return entryOverride;
    }

    // 2. Section-specific override
    if (params.sectionId) {
      const sectionObjId =
        typeof params.sectionId === 'string'
          ? new mongoose.Types.ObjectId(params.sectionId)
          : params.sectionId;
      const sectionOverride = await CalendarOverride.findOne({
        collegeId: collegeObjId,
        sectionId: sectionObjId,
        date: params.date,
      });
      if (sectionOverride) return sectionOverride;
    }

    // 3. Department-specific override
    if (params.departmentId) {
      const deptObjId =
        typeof params.departmentId === 'string'
          ? new mongoose.Types.ObjectId(params.departmentId)
          : params.departmentId;
      const deptOverride = await CalendarOverride.findOne({
        collegeId: collegeObjId,
        departmentId: deptObjId,
        date: params.date,
      });
      if (deptOverride) return deptOverride;
    }

    // 4. College-wide override (departmentId is null)
    const collegeOverride = await CalendarOverride.findOne({
      collegeId: collegeObjId,
      departmentId: null,
      date: params.date,
    });

    return collegeOverride;
  }
}
