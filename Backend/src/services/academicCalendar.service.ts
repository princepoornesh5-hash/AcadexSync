import mongoose from 'mongoose';
import {
  CalendarEvent,
  ICalendarEvent,
} from '../models/calendarEvent.model';
import {
  AcademicCalendar,
  IAcademicCalendar,
  ICalendarHolidayItem,
} from '../models/academicCalendar.model';
import {
  ICalendarOverride,
  CalendarOverrideType,
  CalendarOverrideScope,
} from '../models/calendarOverride.model';
import { CalendarOverrideService } from './calendarOverride.service';
import { TimetableDay } from '../constants/status';
import { PracticalSession } from '../models/practicalSession.model';
import { InternalAssessment, AssessmentStatus } from '../models/internalAssessment.model';
import { AcademicResult } from '../models/academicResult.model';
import { Assignment } from '../models/assignment.model';
import { AssignmentStatus } from '../constants/assignment.constants';
import { Department } from '../models/department.model';
import { Subject } from '../models/subject.model';
import { Section } from '../models/section.model';
import { Semester } from '../models/semester.model';
import { AcademicYear } from '../models/academicYear.model';
import { Student } from '../models/student.model';
import { StudentEnrollment } from '../models/studentEnrollment.model';
import { FacultyAssignment } from '../models/facultyAssignment.model';
import { User } from '../models/user.model';
import { institutionConfigService } from './institutionConfig.service';
import { NotificationService } from './notification.service';
import { realtimeEventBus } from '../realtime/realtimeEventBus';
import { AcadexEventType } from '../realtime/contracts/eventRegistry';
import {
  CalendarSourceType,
  CalendarEventType,
  CalendarEventScope,
  CalendarEventStatus,
  CalendarRecurrence,
  AcademicCalendarStatus,
} from '../constants/calendar.constants';
import {
  NotificationType,
  NotificationCategory,
  NotificationPriority,
} from '../constants/notification.constants';
import { ApiError } from '../utils/apiError';
import { AuthenticatedUser } from '../types/auth.types';
import { AppRole } from '../constants/roles';
import { logger } from '../utils/logger';

export interface CreateCalendarEventDTO {
  title: string;
  description?: string;
  eventType: CalendarEventType;
  scope?: CalendarEventScope;
  startDate: string;
  endDate?: string;
  startTime?: string | null;
  endTime?: string | null;
  allDay?: boolean;
  academicCalendarId?: string | null;
  departmentId?: string | null;
  courseId?: string | null;
  academicYearId?: string | null;
  semesterId?: string | null;
  sectionId?: string | null;
  subjectId?: string | null;
  facultyAssignmentId?: string | null;
  location?: string | null;
  isRecurring?: boolean;
  recurrence?: CalendarRecurrence;
  status?: CalendarEventStatus;
}

export interface UpdateCalendarEventDTO {
  title?: string;
  description?: string;
  eventType?: CalendarEventType;
  scope?: CalendarEventScope;
  startDate?: string;
  endDate?: string;
  startTime?: string | null;
  endTime?: string | null;
  allDay?: boolean;
  academicCalendarId?: string | null;
  departmentId?: string | null;
  courseId?: string | null;
  academicYearId?: string | null;
  semesterId?: string | null;
  sectionId?: string | null;
  subjectId?: string | null;
  facultyAssignmentId?: string | null;
  location?: string | null;
  isRecurring?: boolean;
  recurrence?: CalendarRecurrence;
  status?: CalendarEventStatus;
}

export interface CreateAcademicCalendarDTO {
  academicYearId: string;
  courseId?: string | null;
  departmentId?: string | null;
  semesterId?: string | null;
  title: string;
  description?: string;
  startDate: string;
  endDate: string;
  status?: AcademicCalendarStatus;
  workingDays?: number[];
  holidays?: ICalendarHolidayItem[];
}

export interface UpdateAcademicCalendarDTO {
  title?: string;
  description?: string;
  startDate?: string;
  endDate?: string;
  status?: AcademicCalendarStatus;
  workingDays?: number[];
  holidays?: ICalendarHolidayItem[];
}

export interface NormalizedCalendarEvent {
  id: string;
  title: string;
  description: string;
  sourceType: CalendarSourceType;
  sourceId?: string | null;
  eventType: CalendarEventType;
  scope: CalendarEventScope;
  startDate: string;
  endDate: string;
  startTime?: string | null;
  endTime?: string | null;
  allDay: boolean;
  departmentId?: string | null;
  courseId?: string | null;
  academicYearId?: string | null;
  semesterId?: string | null;
  sectionId?: string | null;
  subjectId?: string | null;
  academicContext?: string | null;
  location?: string | null;
  isRecurring: boolean;
  recurrence: CalendarRecurrence;
  status: CalendarEventStatus;
  createdBy: string;
  creatorRole: string;
  creatorName: string;
  navigationTarget?: string | null;
  canEdit: boolean;
  canCancel: boolean;
}

function getDayOfWeek(dateStr: string): TimetableDay {
  const [y, m, d] = dateStr.split('-').map(Number);
  const dateObj = new Date(Date.UTC(y, m - 1, d, 12, 0, 0));
  const day = dateObj.getUTCDay();
  const map: Record<number, TimetableDay> = {
    0: TimetableDay.SUNDAY,
    1: TimetableDay.MONDAY,
    2: TimetableDay.TUESDAY,
    3: TimetableDay.WEDNESDAY,
    4: TimetableDay.THURSDAY,
    5: TimetableDay.FRIDAY,
    6: TimetableDay.SATURDAY,
  };
  return map[day] || TimetableDay.MONDAY;
}



export class AcademicCalendarService {
  /**
   * Helper to resolve HOD department ID reliably
   */
  private static async resolveHodDepartmentId(
    requester: AuthenticatedUser,
    collegeId: string
  ): Promise<string> {
    if (requester.departmentId) {
      return requester.departmentId.toString();
    }
    const dept = await Department.findOne({
      collegeId: new mongoose.Types.ObjectId(collegeId),
      hodId: new mongoose.Types.ObjectId(requester.id),
    });
    if (dept) {
      return dept._id.toString();
    }
    throw ApiError.forbidden('HOD is not assigned to a department');
  }

  // ══════════════════════════════════════════════════════════
  // ACADEMIC CALENDAR LIFECYCLE (Prompt 45 Section D)
  // ══════════════════════════════════════════════════════════

  static async createAcademicCalendar(
    data: CreateAcademicCalendarDTO,
    requester: AuthenticatedUser
  ): Promise<IAcademicCalendar> {
    if (requester.role === AppRole.STUDENT || requester.role === AppRole.FACULTY) {
      throw ApiError.forbidden('Only administrators and HODs may create academic calendars');
    }

    const collegeId = requester.collegeId ? requester.collegeId.toString() : '';
    if (!collegeId) {
      throw ApiError.badRequest('collegeId is required');
    }

    if (data.startDate > data.endDate) {
      throw ApiError.badRequest('startDate must be before or equal to endDate');
    }

    // Verify academic year exists in this college
    const ay = await AcademicYear.findOne({
      _id: new mongoose.Types.ObjectId(data.academicYearId),
      collegeId: new mongoose.Types.ObjectId(collegeId),
    });
    if (!ay) {
      throw ApiError.notFound('Academic Year not found in this institution');
    }

    let departmentId: mongoose.Types.ObjectId | null = null;
    if (requester.role === AppRole.HOD) {
      const hodDept = await this.resolveHodDepartmentId(requester, collegeId);
      departmentId = new mongoose.Types.ObjectId(hodDept);
    } else if (data.departmentId) {
      departmentId = new mongoose.Types.ObjectId(data.departmentId);
    }

    const calendar = await AcademicCalendar.create({
      collegeId: new mongoose.Types.ObjectId(collegeId),
      academicYearId: new mongoose.Types.ObjectId(data.academicYearId),
      courseId: data.courseId ? new mongoose.Types.ObjectId(data.courseId) : null,
      departmentId,
      semesterId: data.semesterId ? new mongoose.Types.ObjectId(data.semesterId) : null,
      title: data.title,
      description: data.description || '',
      startDate: data.startDate,
      endDate: data.endDate,
      status: data.status || AcademicCalendarStatus.DRAFT,
      workingDays: data.workingDays || [1, 2, 3, 4, 5],
      holidays: data.holidays || [],
      createdBy: new mongoose.Types.ObjectId(requester.id),
    });

    realtimeEventBus.publish({
      eventType: AcadexEventType.CALENDAR_CREATED,
      aggregateType: 'AcademicCalendar',
      aggregateId: calendar._id.toString(),
      action: 'CREATED',
      collegeId: collegeId.toString(),
      scope: { type: 'college', collegeId: collegeId.toString() },
      payload: {
        calendarId: calendar._id.toString(),
        academicYearId: data.academicYearId,
        title: calendar.title,
      },
      occurredAt: new Date().toISOString(),
    });

    return calendar;
  }

  static async listAcademicCalendars(
    requester: AuthenticatedUser,
    query: {
      academicYearId?: string;
      status?: AcademicCalendarStatus;
      page?: number;
      limit?: number;
    }
  ): Promise<{ calendars: IAcademicCalendar[]; total: number; page: number; pages: number }> {
    const collegeId = requester.collegeId ? requester.collegeId.toString() : '';
    const page = Math.max(1, query.page || 1);
    const limit = Math.min(50, Math.max(1, query.limit || 20));
    const skip = (page - 1) * limit;

    const filter: any = { collegeId: new mongoose.Types.ObjectId(collegeId) };
    if (query.academicYearId) {
      filter.academicYearId = new mongoose.Types.ObjectId(query.academicYearId);
    }
    if (query.status) {
      filter.status = query.status;
    }

    if (requester.role === AppRole.HOD) {
      try {
        const hodDept = await this.resolveHodDepartmentId(requester, collegeId);
        filter.$or = [{ departmentId: null }, { departmentId: new mongoose.Types.ObjectId(hodDept) }];
      } catch {
        filter.departmentId = null;
      }
    }

    const [calendars, total] = await Promise.all([
      AcademicCalendar.find(filter).sort({ startDate: -1, createdAt: -1 }).skip(skip).limit(limit),
      AcademicCalendar.countDocuments(filter),
    ]);

    return {
      calendars,
      total,
      page,
      pages: Math.ceil(total / limit) || 1,
    };
  }

  static async getAcademicCalendarById(
    id: string,
    requester: AuthenticatedUser
  ): Promise<IAcademicCalendar> {
    const collegeId = requester.collegeId ? requester.collegeId.toString() : '';
    const calendar = await AcademicCalendar.findById(id);
    if (!calendar || calendar.collegeId.toString() !== collegeId) {
      throw ApiError.notFound('Academic calendar not found');
    }
    return calendar;
  }

  static async updateAcademicCalendar(
    id: string,
    data: UpdateAcademicCalendarDTO,
    requester: AuthenticatedUser
  ): Promise<IAcademicCalendar> {
    if (requester.role === AppRole.STUDENT || requester.role === AppRole.FACULTY) {
      throw ApiError.forbidden('Only administrators and HODs may modify academic calendars');
    }

    const calendar = await this.getAcademicCalendarById(id, requester);

    if (data.startDate && data.endDate && data.startDate > data.endDate) {
      throw ApiError.badRequest('startDate must be before or equal to endDate');
    }

    if (data.title !== undefined) calendar.title = data.title;
    if (data.description !== undefined) calendar.description = data.description;
    if (data.startDate !== undefined) calendar.startDate = data.startDate;
    if (data.endDate !== undefined) calendar.endDate = data.endDate;
    if (data.status !== undefined) calendar.status = data.status;
    if (data.workingDays !== undefined) calendar.workingDays = data.workingDays;
    if (data.holidays !== undefined) calendar.holidays = data.holidays;
    calendar.updatedBy = new mongoose.Types.ObjectId(requester.id);

    await calendar.save();

    realtimeEventBus.publish({
      eventType: AcadexEventType.CALENDAR_UPDATED,
      aggregateType: 'AcademicCalendar',
      aggregateId: calendar._id.toString(),
      action: 'UPDATED',
      collegeId: calendar.collegeId.toString(),
      scope: { type: 'college', collegeId: calendar.collegeId.toString() },
      payload: { calendarId: calendar._id.toString(), status: calendar.status },
      occurredAt: new Date().toISOString(),
    });

    return calendar;
  }

  static async activateAcademicCalendar(
    id: string,
    requester: AuthenticatedUser
  ): Promise<IAcademicCalendar> {
    return this.updateAcademicCalendar(id, { status: AcademicCalendarStatus.ACTIVE }, requester);
  }

  static async closeAcademicCalendar(
    id: string,
    requester: AuthenticatedUser
  ): Promise<IAcademicCalendar> {
    return this.updateAcademicCalendar(id, { status: AcademicCalendarStatus.CLOSED }, requester);
  }

  // ══════════════════════════════════════════════════════════
  // HOLIDAY & WORKING-DAY RESOLUTION (Prompt 45 Sections H & I)
  // ══════════════════════════════════════════════════════════

  static async declareHoliday(
    data: {
      date: string;
      name: string;
      description?: string;
      scope?: CalendarEventScope;
      departmentId?: string | null;
    },
    requester: AuthenticatedUser
  ): Promise<{ override: ICalendarOverride; event: ICalendarEvent }> {
    if (requester.role === AppRole.STUDENT || requester.role === AppRole.FACULTY) {
      throw ApiError.forbidden('Only administrators and HODs may declare holidays');
    }

    const collegeId = requester.collegeId ? requester.collegeId.toString() : '';
    let scope = data.scope || CalendarEventScope.COLLEGE;
    let deptId = data.departmentId || null;

    if (requester.role === AppRole.HOD) {
      const hodDept = await this.resolveHodDepartmentId(requester, collegeId);
      deptId = hodDept;
      scope = CalendarEventScope.DEPARTMENT;
    }

    // 1. Create canonical CalendarOverride
    const override = await CalendarOverrideService.createOverride(
      {
        collegeId,
        departmentId: deptId,
        date: data.date,
        type: CalendarOverrideType.HOLIDAY,
        scope: scope === CalendarEventScope.DEPARTMENT ? CalendarOverrideScope.DEPARTMENT : CalendarOverrideScope.COLLEGE,
        reason: data.name,
      },
      requester
    );

    // 2. Create matching CalendarEvent for calendar visualization
    const event = await this.createEvent(
      {
        title: `Holiday: ${data.name}`,
        description: data.description || 'Institutional Holiday',
        eventType: CalendarEventType.HOLIDAY,
        scope,
        startDate: data.date,
        endDate: data.date,
        allDay: true,
        departmentId: deptId,
        status: CalendarEventStatus.PUBLISHED,
      },
      requester
    );

    realtimeEventBus.publish({
      eventType: AcadexEventType.CALENDAR_OVERRIDE_UPDATED,
      aggregateType: 'CalendarOverride',
      aggregateId: override._id.toString(),
      action: 'CREATED',
      collegeId: collegeId.toString(),
      scope: { type: 'college', collegeId: collegeId.toString() },
      payload: { overrideId: override._id.toString(), date: data.date, type: 'HOLIDAY' },
      occurredAt: new Date().toISOString(),
    });

    return { override, event };
  }

  static async resolveWorkingDay(
    collegeId: string,
    date: string,
    context?: { departmentId?: string; courseId?: string }
  ): Promise<{
    date: string;
    isWorkingDay: boolean;
    reason: string;
    type: 'WORKING_DAY' | 'HOLIDAY' | 'SPECIAL_WORKING_DAY' | 'WEEKLY_OFF';
  }> {
    // 1. Check CalendarOverride (hierarchical: department -> college)
    const override = await CalendarOverrideService.resolveActiveOverride({
      collegeId,
      date,
      departmentId: context?.departmentId || null,
    });

    if (override) {
      if (override.type === CalendarOverrideType.HOLIDAY) {
        return {
          date,
          isWorkingDay: false,
          reason: override.reason || 'Declared Holiday',
          type: 'HOLIDAY',
        };
      }
      if (override.type === CalendarOverrideType.SPECIAL_WORKING_DAY) {
        return {
          date,
          isWorkingDay: true,
          reason: override.reason || 'Compensatory Working Day',
          type: 'SPECIAL_WORKING_DAY',
        };
      }
    }

    // 2. Check active AcademicCalendar for this college
    const activeCalendar = await AcademicCalendar.findOne({
      collegeId: new mongoose.Types.ObjectId(collegeId),
      status: AcademicCalendarStatus.ACTIVE,
      startDate: { $lte: date },
      endDate: { $gte: date },
    });

    if (activeCalendar) {
      // Check embedded holidays
      const calHoliday = activeCalendar.holidays.find((h) => h.date === date);
      if (calHoliday) {
        return {
          date,
          isWorkingDay: false,
          reason: calHoliday.name,
          type: 'HOLIDAY',
        };
      }

      // Check working days array (1=Mon ... 7=Sun)
      const dayOfWeek = getDayOfWeek(date);
      const dayNumMap: Record<TimetableDay, number> = {
        [TimetableDay.MONDAY]: 1,
        [TimetableDay.TUESDAY]: 2,
        [TimetableDay.WEDNESDAY]: 3,
        [TimetableDay.THURSDAY]: 4,
        [TimetableDay.FRIDAY]: 5,
        [TimetableDay.SATURDAY]: 6,
        [TimetableDay.SUNDAY]: 7,
      };
      const dayNum = dayNumMap[dayOfWeek];
      const isConfiguredWorkingDay = activeCalendar.workingDays.includes(dayNum);

      return {
        date,
        isWorkingDay: isConfiguredWorkingDay,
        reason: isConfiguredWorkingDay ? 'Regular Working Day' : 'Weekly Off',
        type: isConfiguredWorkingDay ? 'WORKING_DAY' : 'WEEKLY_OFF',
      };
    }

    // Default fallback: Mon-Fri working, Sat-Sun off
    const dow = getDayOfWeek(date);
    const isWeekend = dow === TimetableDay.SATURDAY || dow === TimetableDay.SUNDAY;
    return {
      date,
      isWorkingDay: !isWeekend,
      reason: !isWeekend ? 'Regular Working Day' : 'Weekend',
      type: !isWeekend ? 'WORKING_DAY' : 'WEEKLY_OFF',
    };
  }

  // ══════════════════════════════════════════════════════════
  // EVENT CRUD (Prompt 45 Section E)
  // ══════════════════════════════════════════════════════════

  static async createEvent(
    data: CreateCalendarEventDTO,
    requester: AuthenticatedUser
  ): Promise<ICalendarEvent> {
    if (requester.role === AppRole.STUDENT) {
      throw ApiError.forbidden('Students are not authorized to create calendar events');
    }

    const collegeId = requester.collegeId ? requester.collegeId.toString() : '';
    if (!collegeId) {
      throw ApiError.badRequest('collegeId is required');
    }

    let scope = data.scope;
    let departmentId: mongoose.Types.ObjectId | null = null;
    let courseId: mongoose.Types.ObjectId | null = null;
    let academicYearId: mongoose.Types.ObjectId | null = null;
    let semesterId: mongoose.Types.ObjectId | null = null;
    let sectionId: mongoose.Types.ObjectId | null = null;
    let subjectId: mongoose.Types.ObjectId | null = null;
    let facultyAssignmentId: mongoose.Types.ObjectId | null = null;

    if (requester.role === AppRole.SUPER_ADMIN || requester.role === AppRole.COLLEGE_ADMIN) {
      scope = scope || CalendarEventScope.COLLEGE;
      if (data.departmentId) {
        const dept = await Department.findById(data.departmentId);
        if (!dept || dept.collegeId.toString() !== collegeId) {
          throw ApiError.notFound('Department not found in this college');
        }
        departmentId = dept._id as mongoose.Types.ObjectId;
      }
      if (data.courseId) courseId = new mongoose.Types.ObjectId(data.courseId);
      if (data.academicYearId) academicYearId = new mongoose.Types.ObjectId(data.academicYearId);
      if (data.semesterId) semesterId = new mongoose.Types.ObjectId(data.semesterId);
      if (data.sectionId) sectionId = new mongoose.Types.ObjectId(data.sectionId);
      if (data.subjectId) subjectId = new mongoose.Types.ObjectId(data.subjectId);
    } else if (requester.role === AppRole.HOD) {
      const hodDeptId = await this.resolveHodDepartmentId(requester, collegeId);
      if (data.departmentId && data.departmentId !== hodDeptId) {
        throw ApiError.forbidden('HOD can only create events for their own department');
      }
      if (scope === CalendarEventScope.COLLEGE) {
        throw ApiError.forbidden('HOD is not permitted to create college-wide events');
      }
      scope = scope || CalendarEventScope.DEPARTMENT;
      departmentId = new mongoose.Types.ObjectId(hodDeptId);

      if (data.courseId) courseId = new mongoose.Types.ObjectId(data.courseId);
      if (data.academicYearId) academicYearId = new mongoose.Types.ObjectId(data.academicYearId);
      if (data.semesterId) semesterId = new mongoose.Types.ObjectId(data.semesterId);
      if (data.sectionId) sectionId = new mongoose.Types.ObjectId(data.sectionId);
      if (data.subjectId) subjectId = new mongoose.Types.ObjectId(data.subjectId);
    } else if (requester.role === AppRole.FACULTY) {
      if (scope === CalendarEventScope.COLLEGE || scope === CalendarEventScope.DEPARTMENT) {
        throw ApiError.forbidden('Faculty cannot create college or department wide events');
      }
      scope = scope || CalendarEventScope.CLASS;

      let assignment = null;
      if (data.facultyAssignmentId) {
        assignment = await FacultyAssignment.findOne({
          _id: new mongoose.Types.ObjectId(data.facultyAssignmentId),
          facultyId: new mongoose.Types.ObjectId(requester.id),
          collegeId: new mongoose.Types.ObjectId(collegeId),
          isActive: true,
        });
        if (!assignment) {
          throw ApiError.forbidden('Invalid or inactive faculty assignment');
        }
      } else if (data.subjectId) {
        assignment = await FacultyAssignment.findOne({
          facultyId: new mongoose.Types.ObjectId(requester.id),
          subjectId: new mongoose.Types.ObjectId(data.subjectId),
          collegeId: new mongoose.Types.ObjectId(collegeId),
          isActive: true,
        });
      }

      if (assignment) {
        facultyAssignmentId = assignment._id as mongoose.Types.ObjectId;
        subjectId = assignment.subjectId;
        courseId = assignment.courseId;
        academicYearId = assignment.academicYearId;
        semesterId = assignment.semesterId;
        sectionId = assignment.sectionId || null;
        departmentId = assignment.departmentId;
      } else {
        if (data.subjectId) subjectId = new mongoose.Types.ObjectId(data.subjectId);
        if (data.sectionId) sectionId = new mongoose.Types.ObjectId(data.sectionId);
      }
    }

    const academicContext = await this.formatContext(collegeId, {
      scope: scope || CalendarEventScope.COLLEGE,
      departmentId: departmentId?.toString(),
      subjectId: subjectId?.toString(),
      sectionId: sectionId?.toString(),
      semesterId: semesterId?.toString(),
    });

    const event = await CalendarEvent.create({
      collegeId: new mongoose.Types.ObjectId(collegeId),
      academicCalendarId: data.academicCalendarId ? new mongoose.Types.ObjectId(data.academicCalendarId) : null,
      title: data.title,
      description: data.description || '',
      sourceType: CalendarSourceType.MANUAL,
      eventType: data.eventType,
      scope: scope || CalendarEventScope.COLLEGE,
      startDate: data.startDate,
      endDate: data.endDate || data.startDate,
      startTime: data.startTime || null,
      endTime: data.endTime || null,
      allDay: data.allDay ?? false,
      departmentId,
      courseId,
      academicYearId,
      semesterId,
      sectionId,
      subjectId,
      facultyAssignmentId,
      location: data.location || null,
      isRecurring: data.isRecurring ?? false,
      recurrence: data.recurrence || CalendarRecurrence.NONE,
      status: data.status || CalendarEventStatus.PUBLISHED,
      createdBy: new mongoose.Types.ObjectId(requester.id),
      creatorRole: requester.role,
      creatorName: requester.name || 'User',
      academicContext,
    });

    if (event.status === CalendarEventStatus.PUBLISHED) {
      this.dispatchCalendarNotification(event, requester).catch((err) => {
        logger.warn('Failed to dispatch notification on event creation:', err);
      });
    }

    realtimeEventBus.publish({
      eventType: AcadexEventType.CALENDAR_EVENT_CREATED,
      aggregateType: 'CalendarEvent',
      aggregateId: event._id.toString(),
      action: 'CREATED',
      collegeId: collegeId.toString(),
      scope: { type: 'college', collegeId: collegeId.toString() },
      payload: { eventId: event._id.toString(), startDate: event.startDate, title: event.title },
      occurredAt: new Date().toISOString(),
    });

    return event;
  }

  static async updateEvent(
    eventId: string,
    data: UpdateCalendarEventDTO,
    requester: AuthenticatedUser
  ): Promise<ICalendarEvent> {
    const collegeId = requester.collegeId ? requester.collegeId.toString() : '';
    const event = await CalendarEvent.findById(eventId);
    if (!event) {
      throw ApiError.notFound('Calendar event not found');
    }
    if (event.collegeId.toString() !== collegeId) {
      throw ApiError.forbidden('Cross-college modification is prohibited');
    }
    if (event.sourceType !== CalendarSourceType.MANUAL) {
      throw ApiError.badRequest('Derived operational events cannot be modified through the calendar endpoint');
    }

    if (requester.role === AppRole.SUPER_ADMIN || requester.role === AppRole.COLLEGE_ADMIN) {
      // Allowed full edit
    } else if (requester.role === AppRole.HOD) {
      const hodDeptId = await this.resolveHodDepartmentId(requester, collegeId);
      if (event.scope === CalendarEventScope.COLLEGE) {
        throw ApiError.forbidden('HOD cannot edit college-wide events');
      }
      if (event.departmentId && event.departmentId.toString() !== hodDeptId) {
        throw ApiError.forbidden('HOD cannot edit events belonging to another department');
      }
    } else if (requester.role === AppRole.FACULTY) {
      if (event.createdBy.toString() !== requester.id) {
        throw ApiError.forbidden('Faculty can only edit events they created');
      }
    }

    if (data.title !== undefined) event.title = data.title;
    if (data.description !== undefined) event.description = data.description;
    if (data.eventType !== undefined) event.eventType = data.eventType;
    if (data.startDate !== undefined) event.startDate = data.startDate;
    if (data.endDate !== undefined) event.endDate = data.endDate;
    if (data.startTime !== undefined) event.startTime = data.startTime;
    if (data.endTime !== undefined) event.endTime = data.endTime;
    if (data.allDay !== undefined) event.allDay = data.allDay;
    if (data.location !== undefined) event.location = data.location;
    if (data.isRecurring !== undefined) event.isRecurring = data.isRecurring;
    if (data.recurrence !== undefined) event.recurrence = data.recurrence;
    if (data.status !== undefined) event.status = data.status;

    await event.save();

    realtimeEventBus.publish({
      eventType: AcadexEventType.CALENDAR_EVENT_UPDATED,
      aggregateType: 'CalendarEvent',
      aggregateId: event._id.toString(),
      action: 'UPDATED',
      collegeId: collegeId.toString(),
      scope: { type: 'college', collegeId: collegeId.toString() },
      payload: { eventId: event._id.toString(), startDate: event.startDate },
      occurredAt: new Date().toISOString(),
    });

    return event;
  }

  static async cancelEvent(
    eventId: string,
    reason: string | undefined,
    requester: AuthenticatedUser
  ): Promise<ICalendarEvent> {
    if (requester.role === AppRole.STUDENT) {
      throw ApiError.forbidden('Students cannot cancel calendar events');
    }

    const collegeId = requester.collegeId ? requester.collegeId.toString() : '';
    const event = await CalendarEvent.findById(eventId);
    if (!event) {
      throw ApiError.notFound('Calendar event not found');
    }
    if (event.collegeId.toString() !== collegeId) {
      throw ApiError.forbidden('Cross-college modification is prohibited');
    }
    if (event.sourceType !== CalendarSourceType.MANUAL) {
      throw ApiError.badRequest('Derived events cannot be cancelled through the calendar endpoint');
    }

    if (requester.role === AppRole.SUPER_ADMIN || requester.role === AppRole.COLLEGE_ADMIN) {
      // Allowed
    } else if (requester.role === AppRole.HOD) {
      const hodDeptId = await this.resolveHodDepartmentId(requester, collegeId);
      if (event.scope === CalendarEventScope.COLLEGE) {
        throw ApiError.forbidden('HOD cannot cancel college-wide events');
      }
      if (event.departmentId && event.departmentId.toString() !== hodDeptId) {
        throw ApiError.forbidden('HOD cannot cancel events belonging to another department');
      }
    } else if (requester.role === AppRole.FACULTY) {
      if (event.createdBy.toString() !== requester.id) {
        throw ApiError.forbidden('Faculty can only cancel events they created');
      }
    }

    event.status = CalendarEventStatus.CANCELLED;
    if (reason) {
      event.metadata = { ...(event.metadata || {}), cancellationReason: reason };
    }
    await event.save();

    realtimeEventBus.publish({
      eventType: AcadexEventType.CALENDAR_EVENT_CANCELLED,
      aggregateType: 'CalendarEvent',
      aggregateId: event._id.toString(),
      action: 'CLOSED',
      collegeId: collegeId.toString(),
      scope: { type: 'college', collegeId: collegeId.toString() },
      payload: { eventId: event._id.toString() },
      occurredAt: new Date().toISOString(),
    });

    return event;
  }

  static async publishEvent(
    eventId: string,
    requester: AuthenticatedUser
  ): Promise<ICalendarEvent> {
    const event = await this.updateEvent(eventId, { status: CalendarEventStatus.PUBLISHED }, requester);
    this.dispatchCalendarNotification(event, requester).catch((err) => {
      logger.warn('Failed to dispatch notification on publish:', err);
    });
    return event;
  }

  // ══════════════════════════════════════════════════════════
  // UNIFIED MULTI-SOURCE CALENDAR AGGREGATION (Prompt 45 Sections F-Q)
  // ══════════════════════════════════════════════════════════

  static async getCalendarForUser(
    requester: AuthenticatedUser,
    query: {
      startDate?: string;
      endDate?: string;
      eventType?: string;
    }
  ): Promise<NormalizedCalendarEvent[]> {
    const collegeId = requester.collegeId ? requester.collegeId.toString() : '';
    if (!collegeId) {
      throw ApiError.badRequest('collegeId is required');
    }

    const now = new Date();
    const defaultStart = new Date(now.getFullYear(), now.getMonth() - 1, 1).toISOString().split('T')[0];
    const defaultEnd = new Date(now.getFullYear(), now.getMonth() + 2, 0).toISOString().split('T')[0];

    const startDate = query.startDate || defaultStart;
    const endDate = query.endDate || defaultEnd;

    const startDateTime = new Date(`${startDate}T00:00:00.000Z`);
    const endDateTime = new Date(`${endDate}T23:59:59.999Z`);

    const config = await institutionConfigService.getEffectiveConfiguration(collegeId);
    const isSectionEnabled = config.academicStructure?.section ?? true;

    // ── GATHER USER CONTEXT ─────────────────────────────────
    let studentEnrollments: any[] = [];
    let facultyAssignments: any[] = [];
    let hodDeptId: string | null = null;
    let studentId: string | null = null;

    if (requester.role === AppRole.STUDENT) {
      let student = await Student.findOne({ userId: requester.id, collegeId });
      if (!student) {
        student = await Student.findById(requester.id);
      }
      if (student) {
        studentId = student._id.toString();
        studentEnrollments = await StudentEnrollment.find({
          studentId: student._id,
          collegeId,
          status: 'active',
        });
      }
    } else if (requester.role === AppRole.FACULTY) {
      facultyAssignments = await FacultyAssignment.find({
        facultyId: requester.id,
        collegeId,
        isActive: true,
      });
    } else if (requester.role === AppRole.HOD) {
      try {
        hodDeptId = await this.resolveHodDepartmentId(requester, collegeId);
      } catch {
        hodDeptId = null;
      }
    }

    const enrolledDeptIds = new Set(studentEnrollments.map((e) => e.departmentId.toString()));
    const enrolledSectionIds = new Set(
      studentEnrollments.filter((e) => e.sectionId).map((e) => e.sectionId.toString())
    );
    const enrolledSemesterIds = new Set(studentEnrollments.map((e) => e.semesterId.toString()));
    const facultySubjectIds = new Set(facultyAssignments.map((a) => a.subjectId.toString()));
    const facultySectionIds = new Set(
      facultyAssignments.filter((a) => a.sectionId).map((a) => a.sectionId.toString())
    );

    const results: NormalizedCalendarEvent[] = [];

    // ── 1. QUERY MANUAL CALENDAR EVENTS ──────────────────────
    const manualEventFilter: any = {
      collegeId: new mongoose.Types.ObjectId(collegeId),
      startDate: { $lte: endDate },
      endDate: { $gte: startDate },
      isRecurring: false,
    };

    if (requester.role === AppRole.STUDENT) {
      manualEventFilter.status = CalendarEventStatus.PUBLISHED;
    } else if (requester.role === AppRole.FACULTY || requester.role === AppRole.HOD) {
      manualEventFilter.$or = [
        { status: CalendarEventStatus.PUBLISHED },
        { createdBy: new mongoose.Types.ObjectId(requester.id) },
      ];
    }

    const manualEvents = await CalendarEvent.find(manualEventFilter);

    // ── 2. QUERY ANNUAL RECURRING EVENTS ────────────────────
    const recurringFilter: any = {
      collegeId: new mongoose.Types.ObjectId(collegeId),
      isRecurring: true,
      recurrence: CalendarRecurrence.ANNUAL,
    };
    if (requester.role === AppRole.STUDENT) {
      recurringFilter.status = CalendarEventStatus.PUBLISHED;
    }
    const recurringEvents = await CalendarEvent.find(recurringFilter);

    const visibleManualEvents: ICalendarEvent[] = [];

    const isVisibleToUser = (ev: ICalendarEvent): boolean => {
      if (requester.role === AppRole.SUPER_ADMIN || requester.role === AppRole.COLLEGE_ADMIN) return true;
      if (ev.createdBy.toString() === requester.id) return true;
      if (ev.scope === CalendarEventScope.COLLEGE) return true;

      if (requester.role === AppRole.HOD) {
        if (!hodDeptId) return false;
        return ev.departmentId ? ev.departmentId.toString() === hodDeptId : false;
      }

      if (requester.role === AppRole.FACULTY) {
        if (ev.scope === CalendarEventScope.DEPARTMENT) {
          return requester.departmentId ? ev.departmentId?.toString() === requester.departmentId : true;
        }
        if (ev.subjectId && facultySubjectIds.has(ev.subjectId.toString())) return true;
        if (ev.sectionId && facultySectionIds.has(ev.sectionId.toString())) return true;
        return false;
      }

      if (requester.role === AppRole.STUDENT) {
        if (ev.scope === CalendarEventScope.DEPARTMENT) {
          return ev.departmentId ? enrolledDeptIds.has(ev.departmentId.toString()) : false;
        }
        if (ev.scope === CalendarEventScope.SECTION || ev.scope === CalendarEventScope.CLASS) {
          if (ev.sectionId && !enrolledSectionIds.has(ev.sectionId.toString())) return false;
          if (ev.semesterId && !enrolledSemesterIds.has(ev.semesterId.toString())) return false;
          return true;
        }
      }
      return false;
    };

    for (const ev of manualEvents) {
      if (isVisibleToUser(ev)) visibleManualEvents.push(ev);
    }

    const startYear = parseInt(startDate.slice(0, 4), 10);
    const endYear = parseInt(endDate.slice(0, 4), 10);

    for (const recEv of recurringEvents) {
      if (!isVisibleToUser(recEv)) continue;
      const origStartMonthDay = recEv.startDate.slice(5);
      const origEndMonthDay = recEv.endDate.slice(5);

      for (let y = startYear; y <= endYear; y++) {
        const projectedStart = `${y}-${origStartMonthDay}`;
        const projectedEnd = `${y}-${origEndMonthDay}`;
        if (projectedStart <= endDate && projectedEnd >= startDate) {
          const projectedDoc = new CalendarEvent(recEv.toObject());
          projectedDoc._id = recEv._id;
          projectedDoc.startDate = projectedStart;
          projectedDoc.endDate = projectedEnd;
          visibleManualEvents.push(projectedDoc);
        }
      }
    }

    for (const ev of visibleManualEvents) {
      const isCreator = ev.createdBy.toString() === requester.id;
      const isAdmin = requester.role === AppRole.SUPER_ADMIN || requester.role === AppRole.COLLEGE_ADMIN;
      const isHodForDept = requester.role === AppRole.HOD && hodDeptId && ev.departmentId?.toString() === hodDeptId;
      const canEdit = isAdmin || (isHodForDept && ev.scope !== CalendarEventScope.COLLEGE) || (isCreator && requester.role === AppRole.FACULTY);

      let context = ev.academicContext || '';
      if (!isSectionEnabled && context.includes('•')) {
        context = context.split('•')[0].trim();
      }

      results.push({
        id: ev._id.toString(),
        title: ev.title,
        description: ev.description || '',
        sourceType: ev.sourceType,
        sourceId: ev.sourceId || null,
        eventType: ev.eventType,
        scope: ev.scope,
        startDate: ev.startDate,
        endDate: ev.endDate,
        startTime: ev.startTime || null,
        endTime: ev.endTime || null,
        allDay: ev.allDay,
        departmentId: ev.departmentId ? ev.departmentId.toString() : null,
        courseId: ev.courseId ? ev.courseId.toString() : null,
        academicYearId: ev.academicYearId ? ev.academicYearId.toString() : null,
        semesterId: ev.semesterId ? ev.semesterId.toString() : null,
        sectionId: isSectionEnabled && ev.sectionId ? ev.sectionId.toString() : null,
        subjectId: ev.subjectId ? ev.subjectId.toString() : null,
        academicContext: context || null,
        location: ev.location || null,
        isRecurring: ev.isRecurring,
        recurrence: ev.recurrence,
        status: ev.status,
        createdBy: ev.createdBy.toString(),
        creatorRole: ev.creatorRole,
        creatorName: ev.creatorName,
        navigationTarget: `/calendar/event/${ev._id.toString()}`,
        canEdit,
        canCancel: canEdit && ev.status !== CalendarEventStatus.CANCELLED,
      });
    }

    // ── 3. QUERY DERIVED ASSIGNMENT DEADLINES (Prompt 39) ─────
    const assignmentFilter: any = {
      collegeId: new mongoose.Types.ObjectId(collegeId),
      status: AssignmentStatus.PUBLISHED,
      dueDate: { $gte: startDate, $lte: endDate },
    };

    if (requester.role === AppRole.STUDENT) {
      assignmentFilter.sectionId = { $in: Array.from(enrolledSectionIds).map((id) => new mongoose.Types.ObjectId(id)) };
    } else if (requester.role === AppRole.FACULTY) {
      assignmentFilter.$or = [
        { facultyId: new mongoose.Types.ObjectId(requester.id) },
        { sectionId: { $in: Array.from(facultySectionIds).map((id) => new mongoose.Types.ObjectId(id)) } },
      ];
    } else if (requester.role === AppRole.HOD && hodDeptId) {
      assignmentFilter.departmentId = new mongoose.Types.ObjectId(hodDeptId);
    }

    const assignments = await Assignment.find(assignmentFilter);
    for (const a of assignments) {
      results.push({
        id: `derived_assignment_${a._id.toString()}`,
        title: a.title,
        description: a.description || `Due at ${a.dueTime}`,
        sourceType: CalendarSourceType.ASSIGNMENT,
        sourceId: a._id.toString(),
        eventType: CalendarEventType.ASSIGNMENT_DEADLINE,
        scope: CalendarEventScope.CLASS,
        startDate: a.dueDate,
        endDate: a.dueDate,
        startTime: a.dueTime || null,
        endTime: a.dueTime || null,
        allDay: false,
        departmentId: a.departmentId ? a.departmentId.toString() : null,
        courseId: a.courseId ? a.courseId.toString() : null,
        academicYearId: a.academicYearId ? a.academicYearId.toString() : null,
        semesterId: a.semesterId ? a.semesterId.toString() : null,
        sectionId: isSectionEnabled && a.sectionId ? a.sectionId.toString() : null,
        subjectId: a.subjectId ? a.subjectId.toString() : null,
        academicContext: a.title,
        location: null,
        isRecurring: false,
        recurrence: CalendarRecurrence.NONE,
        status: CalendarEventStatus.PUBLISHED,
        createdBy: a.facultyId.toString(),
        creatorRole: AppRole.FACULTY,
        creatorName: a.facultyName,
        navigationTarget: `/assignments/${a._id.toString()}`,
        canEdit: false,
        canCancel: false,
      });
    }

    // ── 4. TIMETABLE CANONICAL SEPARATION ─────────────────────────────────────
    // Note: Routine timetable classes are owned strictly by Timetable, not Calendar.
    // Timetable-derived classes are excluded here to maintain strict separation of concerns.

    // ── 5. QUERY PRACTICAL SESSIONS (Prompt 41) ──────────────
    const practicalFilter: any = {
      collegeId: new mongoose.Types.ObjectId(collegeId),
      scheduledDate: { $gte: startDateTime, $lte: endDateTime },
    };

    if (requester.role === AppRole.STUDENT) {
      practicalFilter.sectionId = { $in: Array.from(enrolledSectionIds).map((id) => new mongoose.Types.ObjectId(id)) };
    } else if (requester.role === AppRole.FACULTY) {
      practicalFilter.facultyId = new mongoose.Types.ObjectId(requester.id);
    } else if (requester.role === AppRole.HOD && hodDeptId) {
      practicalFilter.departmentId = new mongoose.Types.ObjectId(hodDeptId);
    }

    const practicalSessions = await PracticalSession.find(practicalFilter).populate('subjectId');
    for (const ps of practicalSessions) {
      const scheduledDateStr = ps.scheduledDate.toISOString().split('T')[0];
      const subDoc: any = ps.subjectId;
      results.push({
        id: `derived_practical_${ps._id.toString()}`,
        title: `Practical: ${ps.topic}`,
        description: ps.instructions || `Session #${ps.sessionNumber}`,
        sourceType: CalendarSourceType.PRACTICAL,
        sourceId: ps._id.toString(),
        eventType: CalendarEventType.PRACTICAL,
        scope: CalendarEventScope.CLASS,
        startDate: scheduledDateStr,
        endDate: scheduledDateStr,
        startTime: ps.startTime || null,
        endTime: ps.endTime || null,
        allDay: false,
        departmentId: ps.departmentId?.toString(),
        courseId: ps.courseId?.toString(),
        academicYearId: ps.academicYearId?.toString(),
        semesterId: ps.semesterId?.toString(),
        sectionId: ps.sectionId?.toString() || null,
        subjectId: subDoc?._id?.toString() || ps.subjectId?.toString() || null,
        academicContext: subDoc?.name || ps.topic,
        location: ps.roomNumber || null,
        isRecurring: false,
        recurrence: CalendarRecurrence.NONE,
        status: ps.status === 'CANCELLED' ? CalendarEventStatus.CANCELLED : CalendarEventStatus.PUBLISHED,
        createdBy: ps.facultyId?.toString() || requester.id,
        creatorRole: AppRole.FACULTY,
        creatorName: 'Faculty Instructor',
        navigationTarget: `/practicals/${ps._id.toString()}`,
        canEdit: false,
        canCancel: false,
      });
    }

    // ── 6. QUERY INTERNAL ASSESSMENTS (Prompt 43) ────────────
    const assessmentFilter: any = {
      collegeId: new mongoose.Types.ObjectId(collegeId),
      assessmentDate: { $gte: startDateTime, $lte: endDateTime },
      status: { $in: [AssessmentStatus.OPEN, AssessmentStatus.CLOSED, AssessmentStatus.REVIEWED, AssessmentStatus.PUBLISHED] },
    };

    if (requester.role === AppRole.STUDENT) {
      assessmentFilter.sectionId = { $in: Array.from(enrolledSectionIds).map((id) => new mongoose.Types.ObjectId(id)) };
    } else if (requester.role === AppRole.FACULTY) {
      assessmentFilter.facultyId = new mongoose.Types.ObjectId(requester.id);
    } else if (requester.role === AppRole.HOD && hodDeptId) {
      assessmentFilter.departmentId = new mongoose.Types.ObjectId(hodDeptId);
    }

    const assessments = await InternalAssessment.find(assessmentFilter).populate('subjectId');
    for (const ia of assessments) {
      const aDateStr = ia.assessmentDate ? ia.assessmentDate.toISOString().split('T')[0] : startDate;
      const subDoc: any = ia.subjectId;
      results.push({
        id: `derived_assessment_${ia._id.toString()}`,
        title: `Assessment: ${ia.title}`,
        description: `Max Marks: ${ia.maximumMarks} • Type: ${ia.assessmentType}`,
        sourceType: CalendarSourceType.ASSESSMENT,
        sourceId: ia._id.toString(),
        eventType: CalendarEventType.INTERNAL_ASSESSMENT,
        scope: CalendarEventScope.CLASS,
        startDate: aDateStr,
        endDate: aDateStr,
        startTime: null,
        endTime: null,
        allDay: true,
        departmentId: ia.departmentId?.toString(),
        courseId: ia.courseId?.toString(),
        academicYearId: ia.academicYearId?.toString(),
        semesterId: ia.semesterId?.toString(),
        sectionId: ia.sectionId?.toString() || null,
        subjectId: subDoc?._id?.toString() || ia.subjectId?.toString() || null,
        academicContext: subDoc?.name || ia.title,
        location: null,
        isRecurring: false,
        recurrence: CalendarRecurrence.NONE,
        status: CalendarEventStatus.PUBLISHED,
        createdBy: ia.facultyId?.toString() || requester.id,
        creatorRole: AppRole.FACULTY,
        creatorName: ia.facultyName || 'Faculty',
        navigationTarget: `/assessments`,
        canEdit: false,
        canCancel: false,
      });
    }

    // ── 7. QUERY ACADEMIC RESULTS PUBLICATIONS (Prompt 44) ───
    const resultFilter: any = {
      collegeId: new mongoose.Types.ObjectId(collegeId),
      status: 'PUBLISHED',
      publishedAt: { $gte: startDateTime, $lte: endDateTime },
    };

    if (requester.role === AppRole.STUDENT && studentId) {
      resultFilter.studentId = new mongoose.Types.ObjectId(studentId);
    } else if (requester.role === AppRole.HOD && hodDeptId) {
      // HOD scope
    }

    const publishedResults = await AcademicResult.find(resultFilter).limit(20);
    for (const r of publishedResults) {
      const pubDateStr = r.publishedAt ? r.publishedAt.toISOString().split('T')[0] : startDate;
      results.push({
        id: `derived_result_${r._id.toString()}`,
        title: `Official Result Published (v${r.version})`,
        description: `Overall: ${r.summary.overallResult} • Percentage: ${r.summary.percentage != null ? r.summary.percentage.toFixed(1) + '%' : 'N/A'}`,
        sourceType: CalendarSourceType.ACADEMIC_RESULT,
        sourceId: r._id.toString(),
        eventType: CalendarEventType.RESULT_PUBLICATION,
        scope: CalendarEventScope.COLLEGE,
        startDate: pubDateStr,
        endDate: pubDateStr,
        startTime: null,
        endTime: null,
        allDay: true,
        departmentId: r.departmentId?.toString(),
        courseId: r.courseId?.toString(),
        academicYearId: r.academicYearId?.toString(),
        semesterId: r.semesterId?.toString(),
        sectionId: r.sectionId?.toString() || null,
        subjectId: null,
        academicContext: `Semester ${r.semesterId}`,
        location: null,
        isRecurring: false,
        recurrence: CalendarRecurrence.NONE,
        status: CalendarEventStatus.PUBLISHED,
        createdBy: r.publishedBy ? r.publishedBy.toString() : requester.id,
        creatorRole: AppRole.COLLEGE_ADMIN,
        creatorName: 'Controller of Examinations',
        navigationTarget: `/my-results`,
        canEdit: false,
        canCancel: false,
      });
    }

    // ── 8. FILTER & SORT ─────────────────────────────────────
    let filtered = results;
    if (query.eventType) {
      filtered = results.filter((e) => e.eventType === query.eventType);
    }

    filtered.sort((a, b) => {
      const dateCmp = a.startDate.localeCompare(b.startDate);
      if (dateCmp !== 0) return dateCmp;
      if (a.allDay && !b.allDay) return -1;
      if (!a.allDay && b.allDay) return 1;
      const timeA = a.startTime || '00:00';
      const timeB = b.startTime || '00:00';
      return timeA.localeCompare(timeB);
    });

    return filtered;
  }

  static async getEventById(
    eventId: string,
    requester: AuthenticatedUser
  ): Promise<NormalizedCalendarEvent> {
    const collegeId = requester.collegeId ? requester.collegeId.toString() : '';

    if (eventId.startsWith('derived_assignment_')) {
      const assignmentId = eventId.replace('derived_assignment_', '');
      const assignment = await Assignment.findById(assignmentId);
      if (!assignment || assignment.collegeId.toString() !== collegeId) {
        throw ApiError.notFound('Assignment event not found');
      }

      return {
        id: eventId,
        title: assignment.title,
        description: assignment.description || '',
        sourceType: CalendarSourceType.ASSIGNMENT,
        sourceId: assignment._id.toString(),
        eventType: CalendarEventType.ASSIGNMENT_DEADLINE,
        scope: CalendarEventScope.CLASS,
        startDate: assignment.dueDate,
        endDate: assignment.dueDate,
        startTime: assignment.dueTime || null,
        endTime: assignment.dueTime || null,
        allDay: false,
        departmentId: assignment.departmentId?.toString(),
        courseId: assignment.courseId?.toString(),
        academicYearId: assignment.academicYearId?.toString(),
        semesterId: assignment.semesterId?.toString(),
        sectionId: assignment.sectionId?.toString(),
        subjectId: assignment.subjectId?.toString(),
        academicContext: assignment.title,
        location: null,
        isRecurring: false,
        recurrence: CalendarRecurrence.NONE,
        status: CalendarEventStatus.PUBLISHED,
        createdBy: assignment.facultyId.toString(),
        creatorRole: AppRole.FACULTY,
        creatorName: assignment.facultyName,
        navigationTarget: `/assignments/${assignment._id.toString()}`,
        canEdit: false,
        canCancel: false,
      };
    }

    const event = await CalendarEvent.findById(eventId);
    if (!event || event.collegeId.toString() !== collegeId) {
      throw ApiError.notFound('Calendar event not found');
    }

    const isCreator = event.createdBy.toString() === requester.id;
    const isAdmin = requester.role === AppRole.SUPER_ADMIN || requester.role === AppRole.COLLEGE_ADMIN;
    let isHodForDept = false;
    if (requester.role === AppRole.HOD) {
      try {
        const hDept = await this.resolveHodDepartmentId(requester, collegeId);
        isHodForDept = event.departmentId?.toString() === hDept;
      } catch {
        isHodForDept = false;
      }
    }

    const canEdit = isAdmin || (isHodForDept && event.scope !== CalendarEventScope.COLLEGE) || (isCreator && requester.role === AppRole.FACULTY);

    return {
      id: event._id.toString(),
      title: event.title,
      description: event.description || '',
      sourceType: event.sourceType,
      sourceId: event.sourceId || null,
      eventType: event.eventType,
      scope: event.scope,
      startDate: event.startDate,
      endDate: event.endDate,
      startTime: event.startTime || null,
      endTime: event.endTime || null,
      allDay: event.allDay,
      departmentId: event.departmentId ? event.departmentId.toString() : null,
      courseId: event.courseId ? event.courseId.toString() : null,
      academicYearId: event.academicYearId ? event.academicYearId.toString() : null,
      semesterId: event.semesterId ? event.semesterId.toString() : null,
      sectionId: event.sectionId ? event.sectionId.toString() : null,
      subjectId: event.subjectId ? event.subjectId.toString() : null,
      academicContext: event.academicContext || null,
      location: event.location || null,
      isRecurring: event.isRecurring,
      recurrence: event.recurrence,
      status: event.status,
      createdBy: event.createdBy.toString(),
      creatorRole: event.creatorRole,
      creatorName: event.creatorName,
      navigationTarget: `/calendar/event/${event._id.toString()}`,
      canEdit,
      canCancel: canEdit && event.status !== CalendarEventStatus.CANCELLED,
    };
  }

  private static async formatContext(
    collegeId: string,
    params: {
      scope: CalendarEventScope;
      departmentId?: string | null;
      subjectId?: string | null;
      sectionId?: string | null;
      semesterId?: string | null;
    }
  ): Promise<string> {
    const config = await institutionConfigService.getEffectiveConfiguration(collegeId);
    const isSectionEnabled = config.academicStructure?.section ?? true;

    if (params.scope === CalendarEventScope.COLLEGE) {
      return 'Entire College';
    }

    if (params.subjectId) {
      const subjectDoc = await Subject.findById(params.subjectId);
      const subjectName = subjectDoc?.name || 'Subject';
      if (isSectionEnabled && params.sectionId) {
        const sectionDoc = await Section.findById(params.sectionId);
        if (sectionDoc) return `${subjectName} • ${sectionDoc.name}`;
      }
      if (params.semesterId) {
        const semesterDoc = await Semester.findById(params.semesterId);
        if (semesterDoc) return `${subjectName} • ${semesterDoc.name}`;
      }
      return subjectName;
    }

    if (params.departmentId) {
      const deptDoc = await Department.findById(params.departmentId);
      return deptDoc?.name || 'Department';
    }

    return '';
  }

  private static async dispatchCalendarNotification(
    event: ICalendarEvent,
    requester: AuthenticatedUser
  ): Promise<void> {
    try {
      const collegeId = event.collegeId;
      let targetUserIds: string[] = [];

      if (event.scope === CalendarEventScope.COLLEGE) {
        const users = await User.find({ collegeId, isActive: { $ne: false } }).select('_id');
        targetUserIds = users.map((u) => u._id.toString());
      } else if (event.scope === CalendarEventScope.DEPARTMENT && event.departmentId) {
        const users = await User.find({
          collegeId,
          departmentId: event.departmentId,
          isActive: { $ne: false },
        }).select('_id');
        targetUserIds = users.map((u) => u._id.toString());
      } else if (event.sectionId) {
        const enrollments = await StudentEnrollment.find({
          collegeId,
          sectionId: event.sectionId,
          status: 'active',
        }).populate('studentId');
        for (const enr of enrollments) {
          const studentDoc: any = enr.studentId;
          if (studentDoc && studentDoc.userId) {
            targetUserIds.push(studentDoc.userId.toString());
          }
        }
      }

      if (targetUserIds.length === 0) return;

      const priority =
        event.eventType === CalendarEventType.EXAM || event.eventType === CalendarEventType.HOLIDAY
          ? NotificationPriority.HIGH
          : NotificationPriority.NORMAL;

      const title = `${event.title}`;
      const body = event.description
        ? `${event.description} • ${event.startDate}`
        : `Scheduled for ${event.startDate}${event.startTime ? ' at ' + event.startTime : ''}`;

      for (const uid of targetUserIds) {
        if (uid === requester.id) continue;

        await NotificationService.createNotification({
          collegeId: collegeId.toString(),
          recipientUserId: uid,
          title,
          body,
          notificationType: NotificationType.CALENDAR_EVENT || ('CALENDAR_EVENT' as any),
          category: NotificationCategory.ACADEMIC || ('academic' as any),
          priority,
          relatedEntityId: event._id.toString(),
          relatedEntityType: 'CALENDAR_EVENT',
          metadata: {
            eventId: event._id.toString(),
            startDate: event.startDate,
            eventType: event.eventType,
          },
          idempotencyKey: `cal_event_${event._id.toString()}_${uid}`,
        });
      }
    } catch (err) {
      logger.warn('Failed to send calendar notifications:', err);
    }
  }
}
