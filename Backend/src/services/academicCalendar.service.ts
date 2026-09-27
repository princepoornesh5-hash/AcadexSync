import mongoose from 'mongoose';
import {
  CalendarEvent,
  ICalendarEvent,
} from '../models/calendarEvent.model';
import { Assignment } from '../models/assignment.model';
import { AssignmentStatus } from '../constants/assignment.constants';
import { Department } from '../models/department.model';
import { Subject } from '../models/subject.model';
import { Section } from '../models/section.model';
import { Semester } from '../models/semester.model';
import { Student } from '../models/student.model';
import { StudentEnrollment } from '../models/studentEnrollment.model';
import { FacultyAssignment } from '../models/facultyAssignment.model';
import { User } from '../models/user.model';
import { institutionConfigService } from './institutionConfig.service';
import { NotificationService } from './notification.service';
import {
  CalendarSourceType,
  CalendarEventType,
  CalendarEventScope,
  CalendarEventStatus,
  CalendarRecurrence,
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

  /**
   * Helper to format academic context respecting Prompt 21 configuration
   */
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
        if (sectionDoc) {
          return `${subjectName} • ${sectionDoc.name}`;
        }
      }
      if (params.semesterId) {
        const semesterDoc = await Semester.findById(params.semesterId);
        if (semesterDoc) {
          return `${subjectName} • ${semesterDoc.name}`;
        }
      }
      return subjectName;
    }

    if (params.departmentId) {
      const deptDoc = await Department.findById(params.departmentId);
      return deptDoc?.name || 'Department';
    }

    return '';
  }

  /**
   * Create a new manual or institution calendar event with authoritative role checks.
   */
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

    // ── ROLE SCOPE AUTHORIZATION ────────────────────────────
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

      // Authoritative teaching context resolution
      let assignment = null;
      if (data.facultyAssignmentId) {
        assignment = await FacultyAssignment.findOne({
          _id: new mongoose.Types.ObjectId(data.facultyAssignmentId),
          facultyId: new mongoose.Types.ObjectId(requester.id),
          collegeId: new mongoose.Types.ObjectId(collegeId),
          isActive: true,
        });
      } else if (data.subjectId) {
        const query: any = {
          facultyId: new mongoose.Types.ObjectId(requester.id),
          collegeId: new mongoose.Types.ObjectId(collegeId),
          subjectId: new mongoose.Types.ObjectId(data.subjectId),
          isActive: true,
        };
        if (data.sectionId) query.sectionId = new mongoose.Types.ObjectId(data.sectionId);
        if (data.semesterId) query.semesterId = new mongoose.Types.ObjectId(data.semesterId);
        assignment = await FacultyAssignment.findOne(query);
      }

      if (!assignment) {
        throw ApiError.forbidden('You can only create events for teaching contexts assigned to you');
      }

      facultyAssignmentId = assignment._id as mongoose.Types.ObjectId;
      departmentId = assignment.departmentId;
      courseId = assignment.courseId;
      academicYearId = assignment.academicYearId;
      semesterId = assignment.semesterId;
      sectionId = assignment.sectionId;
      subjectId = assignment.subjectId;
    }

    const startDate = data.startDate;
    const endDate = data.endDate || startDate;
    const status = data.status || CalendarEventStatus.PUBLISHED;

    // Resolve human-friendly academic context
    const academicContext = await this.formatContext(collegeId, {
      scope: scope || CalendarEventScope.COLLEGE,
      departmentId: departmentId ? departmentId.toString() : null,
      subjectId: subjectId ? subjectId.toString() : null,
      sectionId: sectionId ? sectionId.toString() : null,
      semesterId: semesterId ? semesterId.toString() : null,
    });

    const isHoliday =
      data.eventType === CalendarEventType.HOLIDAY ||
      data.eventType === CalendarEventType.PUBLIC_HOLIDAY ||
      data.eventType === CalendarEventType.INSTITUTION_HOLIDAY;

    const event = await CalendarEvent.create({
      collegeId: new mongoose.Types.ObjectId(collegeId),
      title: data.title,
      description: data.description || '',
      sourceType: isHoliday ? CalendarSourceType.SYSTEM : CalendarSourceType.MANUAL,
      eventType: data.eventType,
      scope,
      startDate,
      endDate,
      startTime: data.startTime || null,
      endTime: data.endTime || null,
      allDay: isHoliday ? true : (data.allDay ?? false),
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
      status,
      createdBy: new mongoose.Types.ObjectId(requester.id),
      creatorRole: requester.role,
      creatorName: requester.name || 'Staff Member',
      academicContext,
      navigationTarget: null,
    });

    // Dispatch notification safely if published
    if (status === CalendarEventStatus.PUBLISHED) {
      this.dispatchCalendarNotification(event, requester).catch((err) => {
        logger.warn('Failed to dispatch calendar event notification:', err);
      });
    }

    return event;
  }

  /**
   * Update an existing manual calendar event.
   */
  static async updateEvent(
    eventId: string,
    data: UpdateCalendarEventDTO,
    requester: AuthenticatedUser
  ): Promise<ICalendarEvent> {
    if (requester.role === AppRole.STUDENT) {
      throw ApiError.forbidden('Students cannot modify calendar events');
    }

    const collegeId = requester.collegeId ? requester.collegeId.toString() : '';
    const event = await CalendarEvent.findById(eventId);
    if (!event) {
      throw ApiError.notFound('Calendar event not found');
    }
    if (event.collegeId.toString() !== collegeId) {
      throw ApiError.forbidden('Cross-college modification is prohibited');
    }
    if (event.sourceType === CalendarSourceType.DERIVED) {
      throw ApiError.badRequest('Derived events cannot be modified through the calendar endpoint');
    }

    // Authorization check
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

    // Apply allowed updates
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
    return event;
  }

  /**
   * Cancel a calendar event (sets status to CANCELLED without hard-deleting).
   */
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
    if (event.sourceType === CalendarSourceType.DERIVED) {
      throw ApiError.badRequest('Derived events cannot be cancelled through the calendar endpoint');
    }

    // Authorization check
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
    return event;
  }

  /**
   * Publish a draft event.
   */
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

  /**
   * Central unified calendar query for the authenticated user.
   * Merges:
   * 1. Manual published Calendar Events
   * 2. Annual recurring events projected onto target year
   * 3. Derived Assignment Deadlines (from Assignment collection)
   */
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

    // Default to a 3-month window around current date if not provided
    const now = new Date();
    const defaultStart = new Date(now.getFullYear(), now.getMonth() - 1, 1).toISOString().split('T')[0];
    const defaultEnd = new Date(now.getFullYear(), now.getMonth() + 2, 0).toISOString().split('T')[0];

    const startDate = query.startDate || defaultStart;
    const endDate = query.endDate || defaultEnd;

    // Load institution config for concept visibility and terminology
    const config = await institutionConfigService.getEffectiveConfiguration(collegeId);
    const isSectionEnabled = config.academicStructure?.section ?? true;

    // ── GATHER USER CONTEXT ─────────────────────────────────
    let studentEnrollments: any[] = [];
    let facultyAssignments: any[] = [];
    let hodDeptId: string | null = null;

    if (requester.role === AppRole.STUDENT) {
      let student = await Student.findOne({ userId: requester.id, collegeId });
      if (!student) {
        student = await Student.findById(requester.id);
      }
      if (student) {
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
    const enrolledSectionIds = new Set(studentEnrollments.map((e) => e.sectionId.toString()));
    const enrolledSemesterIds = new Set(studentEnrollments.map((e) => e.semesterId.toString()));
    const facultySubjectIds = new Set(facultyAssignments.map((a) => a.subjectId.toString()));
    const facultySectionIds = new Set(facultyAssignments.map((a) => a.sectionId.toString()));

    // ── 1. QUERY MANUAL CALENDAR EVENTS ──────────────────────
    // Normal query covers standard events where date range overlaps
    const manualEventFilter: any = {
      collegeId: new mongoose.Types.ObjectId(collegeId),
      startDate: { $lte: endDate },
      endDate: { $gte: startDate },
      isRecurring: false,
    };

    // Role-based visibility
    if (requester.role === AppRole.STUDENT) {
      manualEventFilter.status = CalendarEventStatus.PUBLISHED;
    } else if (requester.role === AppRole.FACULTY || requester.role === AppRole.HOD) {
      // Can see PUBLISHED, plus their own DRAFT/CANCELLED
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

    // Filter manual & recurring events by audience visibility
    const visibleManualEvents: ICalendarEvent[] = [];

    const isVisibleToUser = (ev: ICalendarEvent): boolean => {
      if (requester.role === AppRole.SUPER_ADMIN || requester.role === AppRole.COLLEGE_ADMIN) {
        return true;
      }
      if (ev.createdBy.toString() === requester.id) {
        return true;
      }
      if (ev.scope === CalendarEventScope.COLLEGE) {
        return true;
      }

      if (requester.role === AppRole.HOD) {
        if (!hodDeptId) return false;
        return ev.departmentId ? ev.departmentId.toString() === hodDeptId : false;
      }

      if (requester.role === AppRole.FACULTY) {
        if (ev.scope === CalendarEventScope.DEPARTMENT) {
          return requester.departmentId ? ev.departmentId?.toString() === requester.departmentId : true;
        }
        if (ev.subjectId && facultySubjectIds.has(ev.subjectId.toString())) {
          return true;
        }
        if (ev.sectionId && facultySectionIds.has(ev.sectionId.toString())) {
          return true;
        }
        return false;
      }

      if (requester.role === AppRole.STUDENT) {
        if (ev.scope === CalendarEventScope.DEPARTMENT) {
          return ev.departmentId ? enrolledDeptIds.has(ev.departmentId.toString()) : false;
        }
        if (ev.scope === CalendarEventScope.SECTION || ev.scope === CalendarEventScope.CLASS) {
          if (ev.sectionId && !enrolledSectionIds.has(ev.sectionId.toString())) {
            return false;
          }
          if (ev.semesterId && !enrolledSemesterIds.has(ev.semesterId.toString())) {
            return false;
          }
          return true;
        }
      }

      return false;
    };

    for (const ev of manualEvents) {
      if (isVisibleToUser(ev)) {
        visibleManualEvents.push(ev);
      }
    }

    // Project recurring events onto current query range
    const startYear = parseInt(startDate.slice(0, 4), 10);
    const endYear = parseInt(endDate.slice(0, 4), 10);

    for (const recEv of recurringEvents) {
      if (!isVisibleToUser(recEv)) continue;

      const origStartMonthDay = recEv.startDate.slice(5); // MM-DD
      const origEndMonthDay = recEv.endDate.slice(5);

      for (let y = startYear; y <= endYear; y++) {
        const projectedStart = `${y}-${origStartMonthDay}`;
        const projectedEnd = `${y}-${origEndMonthDay}`;

        if (projectedStart <= endDate && projectedEnd >= startDate) {
          // Clone event with projected dates
          const projectedDoc = new CalendarEvent(recEv.toObject());
          projectedDoc._id = recEv._id;
          projectedDoc.startDate = projectedStart;
          projectedDoc.endDate = projectedEnd;
          visibleManualEvents.push(projectedDoc);
        }
      }
    }

    // ── 3. QUERY DERIVED ASSIGNMENT DEADLINES ────────────────
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
    } else if (requester.role === AppRole.HOD) {
      if (hodDeptId) {
        assignmentFilter.departmentId = new mongoose.Types.ObjectId(hodDeptId);
      }
    }

    const assignments = await Assignment.find(assignmentFilter);

    // ── 4. NORMALIZE & MERGE ─────────────────────────────────
    const results: NormalizedCalendarEvent[] = [];

    // Map manual events
    for (const ev of visibleManualEvents) {
      const isCreator = ev.createdBy.toString() === requester.id;
      const isAdmin = requester.role === AppRole.SUPER_ADMIN || requester.role === AppRole.COLLEGE_ADMIN;
      const isHodForDept = requester.role === AppRole.HOD && hodDeptId && ev.departmentId?.toString() === hodDeptId;

      const canEdit = isAdmin || (isHodForDept && ev.scope !== CalendarEventScope.COLLEGE) || (isCreator && requester.role === AppRole.FACULTY);
      const canCancel = canEdit && ev.status !== CalendarEventStatus.CANCELLED;

      // Adjust academic context if section is disabled
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
        canCancel,
      });
    }

    // Map derived assignment deadlines
    for (const a of assignments) {
      // Format assignment academic context
      let aContext = a.title;
      try {
        const sub = await Subject.findById(a.subjectId);
        if (sub) {
          if (isSectionEnabled && a.sectionId) {
            const sec = await Section.findById(a.sectionId);
            aContext = sec ? `${sub.name} • ${sec.name}` : sub.name;
          } else {
            aContext = sub.name;
          }
        }
      } catch {
        aContext = a.title;
      }

      results.push({
        id: `derived_assignment_${a._id.toString()}`,
        title: a.title,
        description: a.description || `Due at ${a.dueTime}`,
        sourceType: CalendarSourceType.DERIVED,
        sourceId: a._id.toString(),
        eventType: CalendarEventType.DEADLINE,
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
        academicContext: aContext,
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

    // ── 5. FILTER BY EVENT TYPE & SORT ──────────────────────
    let filtered = results;
    if (query.eventType) {
      filtered = results.filter((e) => e.eventType === query.eventType);
    }

    // Sort chronologically: startDate ASC, startTime ASC (allDay first)
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

  /**
   * Retrieve single event detail (manual or derived).
   */
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
        sourceType: CalendarSourceType.DERIVED,
        sourceId: assignment._id.toString(),
        eventType: CalendarEventType.DEADLINE,
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

  /**
   * Helper to dispatch persistent notifications for important calendar events.
   * Completely fault tolerant — will never bubble an exception or fail the event.
   */
  private static async dispatchCalendarNotification(
    event: ICalendarEvent,
    requester: AuthenticatedUser
  ): Promise<void> {
    try {
      const collegeId = event.collegeId;
      let targetUserIds: string[] = [];

      if (event.scope === CalendarEventScope.COLLEGE) {
        // Send to users in college
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
        if (uid === requester.id) continue; // Don't notify creator

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
