import mongoose from 'mongoose';
import { FunctionDeclaration, Type } from '@google/genai';
import { AuthenticatedUser } from '../types/auth.types';
import { AppRole } from '../constants/roles';
import { TimetableService } from './timetable.service';
import { AssignmentService } from './assignment.service';
import { AcademicCalendarService } from './academicCalendar.service';
import { RequestService } from './request.service';
import { PendingActionService } from './pendingAction.service';
import { Faculty } from '../models/faculty.model';
import { FacultyAssignment } from '../models/facultyAssignment.model';
import { CalendarEvent } from '../models/calendarEvent.model';
import { CalendarEventScope, CalendarEventType } from '../constants/calendar.constants';
import { AssignmentStatus, AssignmentType } from '../constants/assignment.constants';
import { Logger } from '../utils/logger';

/**
 * Gemini Tool Declarations conforming to @google/genai FunctionDeclaration
 */
export const aiFunctionDeclarations: FunctionDeclaration[] = [
  // ── 1. READ TOOLS ──────────────────────────────────────────────────────────
  {
    name: 'get_my_timetable',
    description:
      "Retrieve the authenticated user's current class timetable/schedule. Use when the user asks about their schedule, next class, periods, or rooms. Can filter by relative day ('today', 'tomorrow', 'yesterday'), day of week ('monday', 'tuesday', etc.), specific date ('YYYY-MM-DD'), or period target ('all', 'next', 'first', 'last', 'morning', 'afternoon').",
    parameters: {
      type: Type.OBJECT,
      properties: {
        day: {
          type: Type.STRING,
          description: "Optional day: 'today', 'tomorrow', 'yesterday', or a weekday name (e.g. 'monday', 'friday').",
        },
        date: {
          type: Type.STRING,
          description: "Optional specific date in 'YYYY-MM-DD' format.",
        },
        periodTarget: {
          type: Type.STRING,
          description: "Optional period targeting: 'all' (default), 'next' (upcoming period today), 'first' (first period of day), 'last' (last period of day), 'morning' (classes before 12:00 PM), or 'afternoon' (classes 12:00 PM onwards).",
        },
      },
    },
  },
  {
    name: 'get_my_assignments',
    description:
      'Retrieve academic assignments for the authenticated user (coursework for students, or created assignments for faculty/HOD). Supports filtering by status, subject, section, or dueSoon (within next 7 days).',
    parameters: {
      type: Type.OBJECT,
      properties: {
        status: {
          type: Type.STRING,
          description: "Optional assignment status filter: 'published', 'draft', or 'closed'.",
        },
        subject: {
          type: Type.STRING,
          description: 'Optional subject name or code filter.',
        },
        section: {
          type: Type.STRING,
          description: 'Optional section name filter.',
        },
        dueSoon: {
          type: Type.BOOLEAN,
          description: 'Optional flag to only return assignments with deadlines in the next 7 days.',
        },
      },
    },
  },
  {
    name: 'get_calendar_events',
    description:
      'Retrieve upcoming academic calendar events, holidays, examinations, and institution activities for the authenticated user. Defaults to upcoming 30 days if range is not specified.',
    parameters: {
      type: Type.OBJECT,
      properties: {
        startDate: {
          type: Type.STRING,
          description: "Optional start date in 'YYYY-MM-DD' format (defaults to current date).",
        },
        endDate: {
          type: Type.STRING,
          description: "Optional end date in 'YYYY-MM-DD' format (defaults to 30 days from start date).",
        },
        eventType: {
          type: Type.STRING,
          description: "Optional event type filter (e.g. 'holiday', 'exam', 'meeting', 'academic').",
        },
      },
    },
  },
  {
    name: 'get_my_requests',
    description:
      'Retrieve status and history of requests submitted by the authenticated user (e.g. leave, hall booking, certificates).',
    parameters: {
      type: Type.OBJECT,
      properties: {
        status: {
          type: Type.STRING,
          description: "Optional status filter (e.g. 'SUBMITTED', 'APPROVED', 'REJECTED', 'DRAFT').",
        },
        requestType: {
          type: Type.STRING,
          description: 'Optional request type filter.',
        },
      },
    },
  },

  // ── 2. WRITE PROPOSAL TOOLS ────────────────────────────────────────────────
  {
    name: 'propose_create_assignment',
    description:
      'Propose an assignment creation draft for faculty/HOD review. Does NOT persist to database directly. Validates subject, section, and teaching scope, and generates a structured preview with an action ID requiring explicit confirmation.',
    parameters: {
      type: Type.OBJECT,
      properties: {
        title: {
          type: Type.STRING,
          description: 'Title of the assignment (required).',
        },
        subject: {
          type: Type.STRING,
          description: 'Name or code of the subject (required).',
        },
        section: {
          type: Type.STRING,
          description: 'Name or identifier of the section (e.g. "A", "Section A") (required).',
        },
        dueDate: {
          type: Type.STRING,
          description: "Due date in 'YYYY-MM-DD' format (must be in the future) (required).",
        },
        dueTime: {
          type: Type.STRING,
          description: "Due time (e.g. '11:59 PM', '05:00 PM'). Defaults to '11:59 PM'.",
        },
        description: {
          type: Type.STRING,
          description: 'Description or instructions for the assignment.',
        },
        maximumMarks: {
          type: Type.NUMBER,
          description: 'Maximum marks / total score (defaults to 100).',
        },
        assignmentType: {
          type: Type.STRING,
          description: "Assignment type ('homework', 'project', 'quiz', 'lab', defaults to 'homework').",
        },
      },
      required: ['title', 'subject', 'section', 'dueDate'],
    },
  },
  {
    name: 'propose_create_calendar_event',
    description:
      'Propose scheduling a calendar event, meeting, or activity for review. Does NOT persist to database directly. Validates dates in India Standard Time (UTC+05:30), role permissions, checks for room/time conflicts, and creates a structured preview with an action ID requiring confirmation.',
    parameters: {
      type: Type.OBJECT,
      properties: {
        title: {
          type: Type.STRING,
          description: 'Title of the event or meeting (required).',
        },
        startDate: {
          type: Type.STRING,
          description: "Event date in 'YYYY-MM-DD' format (required).",
        },
        endDate: {
          type: Type.STRING,
          description: "Optional end date in 'YYYY-MM-DD' format (defaults to startDate).",
        },
        startTime: {
          type: Type.STRING,
          description: "Start time (e.g. '10:00 AM' or '10:00').",
        },
        endTime: {
          type: Type.STRING,
          description: "End time (e.g. '11:00 AM' or '11:00').",
        },
        eventType: {
          type: Type.STRING,
          description: "Type of event ('meeting', 'academic', 'holiday', 'exam', 'seminar', defaults to 'meeting').",
        },
        description: {
          type: Type.STRING,
          description: 'Optional description of the event.',
        },
        location: {
          type: Type.STRING,
          description: 'Optional venue, room, or online meeting link.',
        },
      },
      required: ['title', 'startDate'],
    },
  },
];

export interface ToolExecutionContext {
  user: AuthenticatedUser;
  collegeId: string;
}

export interface ProposalResult {
  actionId: string;
  actionType: 'CREATE_ASSIGNMENT' | 'CREATE_CALENDAR_EVENT';
  summary: string;
  preview: Record<string, any>;
  expiresAt: string;
}

/**
 * Helper to parse time strings into minutes from midnight (0 to 1439)
 */
export function parseTimeToMinutes(t?: string | null): number | null {
  if (!t || typeof t !== 'string') return null;
  const trimmed = t.trim().toLowerCase();
  const match12 = trimmed.match(/^(\d{1,2}):(\d{2})\s*(am|pm)$/);
  if (match12) {
    let hours = parseInt(match12[1], 10);
    const minutes = parseInt(match12[2], 10);
    const meridian = match12[3];
    if (meridian === 'pm' && hours < 12) hours += 12;
    if (meridian === 'am' && hours === 12) hours = 0;
    return hours * 60 + minutes;
  }
  const match24 = trimmed.match(/^(\d{1,2}):(\d{2})$/);
  if (match24) {
    const hours = parseInt(match24[1], 10);
    const minutes = parseInt(match24[2], 10);
    return hours * 60 + minutes;
  }
  return null;
}

/**
 * Returns true if two time intervals overlap (adjacent intervals do not overlap)
 */
export function doTimeIntervalsOverlap(
  startA?: string | null,
  endA?: string | null,
  startB?: string | null,
  endB?: string | null
): boolean {
  const minStartA = parseTimeToMinutes(startA);
  const minStartB = parseTimeToMinutes(startB);
  if (minStartA === null || minStartB === null) {
    return Boolean(startA && startB && startA.trim().toLowerCase() === startB.trim().toLowerCase());
  }
  const minEndA = parseTimeToMinutes(endA) ?? minStartA + 60;
  const minEndB = parseTimeToMinutes(endB) ?? minStartB + 60;
  return minStartA < minEndB && minStartB < minEndA;
}

export class AiToolsRegistry {
  /**
   * Dispatches and securely executes a tool invocation derived strictly from verified session context
   */
  static async executeTool(
    name: string,
    args: Record<string, any>,
    context: ToolExecutionContext
  ): Promise<{ result: Record<string, any>; proposal?: ProposalResult }> {
    const { user, collegeId } = context;

    Logger.info('Executing AI tool', {
      toolName: name,
      userId: user.id,
      userRole: user.role,
      collegeId,
    });

    switch (name) {
      // ── 1. GET TIMETABLE ───────────────────────────────────────────────────
      case 'get_my_timetable': {
        const rawDay = typeof args.day === 'string' ? args.day.trim().toLowerCase() : undefined;
        let date = typeof args.date === 'string' ? args.date.trim() : undefined;
        const periodTarget = typeof args.periodTarget === 'string' ? args.periodTarget.trim().toLowerCase() : 'all';

        // Asia/Kolkata (IST) resolution for relative day expressions
        const now = new Date();
        const istDateStr = new Intl.DateTimeFormat('en-CA', { timeZone: 'Asia/Kolkata' }).format(now);
        const istWeekday = new Intl.DateTimeFormat('en-US', { timeZone: 'Asia/Kolkata', weekday: 'long' }).format(now).toLowerCase();
        const istTimeStr = new Intl.DateTimeFormat('en-US', { timeZone: 'Asia/Kolkata', hour: '2-digit', minute: '2-digit', hour12: false }).format(now);

        let day: string | undefined = rawDay;
        const validWeekdays = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];

        if (rawDay === 'today') {
          day = istWeekday;
          if (!date) date = istDateStr;
        } else if (rawDay === 'tomorrow') {
          const tomorrow = new Date(now.getTime() + 24 * 60 * 60 * 1000);
          day = new Intl.DateTimeFormat('en-US', { timeZone: 'Asia/Kolkata', weekday: 'long' }).format(tomorrow).toLowerCase();
          const tomorrowDateStr = new Intl.DateTimeFormat('en-CA', { timeZone: 'Asia/Kolkata' }).format(tomorrow);
          if (!date) date = tomorrowDateStr;
        } else if (rawDay === 'yesterday') {
          const yesterday = new Date(now.getTime() - 24 * 60 * 60 * 1000);
          day = new Intl.DateTimeFormat('en-US', { timeZone: 'Asia/Kolkata', weekday: 'long' }).format(yesterday).toLowerCase();
          const yesterdayDateStr = new Intl.DateTimeFormat('en-CA', { timeZone: 'Asia/Kolkata' }).format(yesterday);
          if (!date) date = yesterdayDateStr;
        } else if (rawDay && !validWeekdays.includes(rawDay)) {
          return {
            result: {
              error: `Unrecognized day expression "${rawDay}". Please specify 'today', 'tomorrow', 'yesterday', or a weekday (e.g. 'Monday', 'Friday').`,
              currentServerTimeIST: `${istDateStr} ${istTimeStr} IST`,
            },
          };
        }

        let entries: any[] = [];
        if (user.role === AppRole.STUDENT) {
          entries = await TimetableService.getStudentTimetable(user, day, date);
        } else if (user.role === AppRole.FACULTY) {
          entries = await TimetableService.getFacultyTimetable('me', day, user, date);
        } else if (user.role === AppRole.HOD && user.departmentId) {
          entries = await TimetableService.getDepartmentTimetable(user.departmentId, day, user, date);
        } else {
          const listRes = await TimetableService.listTimetables(user, { collegeId });
          const items = Array.isArray(listRes) ? listRes : listRes.items;
          entries = items.flatMap((t: any) => t.entries || []);
        }

        // Sort chronologically by startTime
        const sorted = entries.slice().sort((a: any, b: any) => {
          const tA = (a.startTime || '').toString();
          const tB = (b.startTime || '').toString();
          return tA.localeCompare(tB);
        });

        const simplified = sorted.map((e: any) => ({
          subject: e.subjectName || e.subjectCode || 'Class',
          code: e.subjectCode,
          section: e.sectionName,
          day: e.dayOfWeek,
          startTime: e.startTime,
          endTime: e.endTime,
          room: e.roomCode || e.roomName,
          faculty: e.facultyName,
        }));

        let targetedPeriod: any = undefined;
        let explanationMessage = '';

        if (periodTarget === 'first') {
          targetedPeriod = simplified.length > 0 ? simplified[0] : null;
          explanationMessage = targetedPeriod
            ? `First period: ${targetedPeriod.subject} (${targetedPeriod.startTime} - ${targetedPeriod.endTime || 'end'}).`
            : 'No scheduled classes found.';
        } else if (periodTarget === 'last') {
          targetedPeriod = simplified.length > 0 ? simplified[simplified.length - 1] : null;
          explanationMessage = targetedPeriod
            ? `Last period: ${targetedPeriod.subject} (${targetedPeriod.startTime} - ${targetedPeriod.endTime || 'end'}).`
            : 'No scheduled classes found.';
        } else if (periodTarget === 'morning') {
          const morningClasses = simplified.filter((e: any) => {
            const mins = parseTimeToMinutes(e.startTime);
            return mins !== null ? mins < 720 : (e.startTime || '').includes('AM');
          });
          targetedPeriod = morningClasses;
          explanationMessage = morningClasses.length > 0
            ? `Found ${morningClasses.length} morning period(s) before 12:00 PM.`
            : 'No morning classes found for the queried schedule.';
        } else if (periodTarget === 'afternoon') {
          const afternoonClasses = simplified.filter((e: any) => {
            const mins = parseTimeToMinutes(e.startTime);
            return mins !== null ? mins >= 720 : !(e.startTime || '').includes('AM');
          });
          targetedPeriod = afternoonClasses;
          explanationMessage = afternoonClasses.length > 0
            ? `Found ${afternoonClasses.length} afternoon period(s) starting from 12:00 PM onwards.`
            : 'No afternoon classes found for the queried schedule.';
        } else if (periodTarget === 'next') {
          const isToday = !rawDay || rawDay === 'today' || rawDay === istWeekday;
          if (isToday) {
            const currentMins = parseTimeToMinutes(istTimeStr) ?? 0;
            const next = simplified.find((e: any) => {
              const startMins = parseTimeToMinutes(e.startTime);
              const endMins = parseTimeToMinutes(e.endTime) ?? (startMins !== null ? startMins + 60 : null);
              if (startMins !== null && endMins !== null) {
                return startMins >= currentMins || endMins > currentMins;
              }
              const start = e.startTime || '';
              const end = e.endTime || '';
              return start >= istTimeStr || end > istTimeStr;
            });
            targetedPeriod = next || null;
            explanationMessage = next
              ? `Next class today: ${next.subject} in ${next.room || 'campus'} at ${next.startTime}.`
              : 'All scheduled classes for today have concluded.';
          } else {
            targetedPeriod = simplified.length > 0 ? simplified[0] : null;
            explanationMessage = targetedPeriod
              ? `First period for ${day}: ${targetedPeriod.subject} at ${targetedPeriod.startTime}.`
              : 'No scheduled classes found.';
          }
        }

        const message =
          explanationMessage ||
          (simplified.length === 0
            ? 'No timetable entries found for the requested criteria.'
            : `Found ${simplified.length} scheduled class(es).`);

        return {
          result: {
            dayQueried: day || 'All days',
            currentServerTimeIST: `${istDateStr} ${istTimeStr} IST`,
            totalEntries: simplified.length,
            timetable: simplified.slice(0, 15),
            periodTarget: periodTarget !== 'all' ? periodTarget : undefined,
            targetedPeriod,
            message,
          },
        };
      }

      // ── 2. GET ASSIGNMENTS ─────────────────────────────────────────────────
      case 'get_my_assignments': {
        const status = typeof args.status === 'string' ? args.status.toLowerCase().trim() : undefined;
        const subjectFilter = typeof args.subject === 'string' ? args.subject.toLowerCase().trim() : undefined;
        const sectionFilter = typeof args.section === 'string' ? args.section.toLowerCase().trim() : undefined;
        const dueSoon = Boolean(args.dueSoon);

        let assignments: any[] = [];
        if (user.role === AppRole.STUDENT) {
          assignments = await AssignmentService.getStudentAssignments(collegeId, user);
        } else {
          assignments = await AssignmentService.getFacultyAssignments(collegeId, user, { status });
        }

        if (status) {
          assignments = assignments.filter((a: any) => a.status?.toLowerCase() === status);
        }

        if (subjectFilter) {
          assignments = assignments.filter((a: any) => {
            const name = (a.subjectName || a.subjectId?.name || '').toLowerCase();
            const code = (a.subjectCode || a.subjectId?.code || '').toLowerCase();
            return name.includes(subjectFilter) || code.includes(subjectFilter);
          });
        }

        if (sectionFilter) {
          assignments = assignments.filter((a: any) => {
            const sec = (a.sectionName || a.sectionId?.name || '').toLowerCase();
            return sec.includes(sectionFilter);
          });
        }

        // Canonical India Standard Time (IST) date boundary calculation
        const now = new Date();
        const todayISTStr = new Intl.DateTimeFormat('en-CA', { timeZone: 'Asia/Kolkata' }).format(now);
        const [curY, curM, curD] = todayISTStr.split('-').map(Number);
        const curUtcMidnight = Date.UTC(curY, curM - 1, curD);

        let simplified = assignments.map((a: any) => {
          let daysRemaining: number | null = null;
          let isOverdue = false;
          if (a.dueDate) {
            const rawDue = typeof a.dueDate === 'string' ? a.dueDate : a.dueDate.toISOString?.() || '';
            const dueParts = rawDue.split('T')[0].split('-').map(Number);
            if (dueParts.length === 3 && !dueParts.some(isNaN)) {
              const dueUtcMidnight = Date.UTC(dueParts[0], dueParts[1] - 1, dueParts[2]);
              const diffDays = Math.round((dueUtcMidnight - curUtcMidnight) / (1000 * 60 * 60 * 24));
              daysRemaining = diffDays;
              isOverdue = diffDays < 0;
            }
          }

          return {
            id: a.id || a._id?.toString(),
            title: a.title,
            subject: a.subjectName || a.subjectId?.name || a.subjectCode,
            section: a.sectionName || a.sectionId?.name,
            dueDate: a.dueDate,
            dueTime: a.dueTime,
            maximumMarks: a.maximumMarks,
            status: a.status,
            daysRemaining,
            isOverdue,
          };
        });

        // Filter dueSoon: due within 7 days and not overdue (0 <= daysRemaining <= 7)
        if (dueSoon) {
          simplified = simplified.filter(
            (a: any) => a.daysRemaining !== null && a.daysRemaining >= 0 && a.daysRemaining <= 7
          );
        }

        // Sort by dueDate ascending
        simplified.sort((a: any, b: any) => {
          if (!a.dueDate) return 1;
          if (!b.dueDate) return -1;
          return new Date(a.dueDate).getTime() - new Date(b.dueDate).getTime();
        });

        return {
          result: {
            totalAssignments: simplified.length,
            assignments: simplified.slice(0, 15),
            filter: { status, subject: subjectFilter, section: sectionFilter, dueSoon },
            message:
              simplified.length === 0
                ? 'No assignments found matching the criteria.'
                : `Found ${simplified.length} assignment(s)${dueSoon ? ' due in the next 7 days' : ''}.`,
          },
        };
      }

      // ── 3. GET CALENDAR EVENTS ─────────────────────────────────────────────
      case 'get_calendar_events': {
        const now = new Date();
        const istTodayStr = new Intl.DateTimeFormat('en-CA', { timeZone: 'Asia/Kolkata' }).format(now);
        const in30Days = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000);
        const ist30DaysStr = new Intl.DateTimeFormat('en-CA', { timeZone: 'Asia/Kolkata' }).format(in30Days);

        const startDate = typeof args.startDate === 'string' ? args.startDate.trim() : istTodayStr;
        const endDate = typeof args.endDate === 'string' ? args.endDate.trim() : ist30DaysStr;
        const eventType = typeof args.eventType === 'string' ? args.eventType.trim() : undefined;

        const events = await AcademicCalendarService.getCalendarForUser(user, {
          startDate,
          endDate,
          eventType,
        });

        const simplified = events.slice(0, 20).map((ev: any) => ({
          id: ev.id,
          title: ev.title,
          eventType: ev.eventType,
          startDate: ev.startDate,
          endDate: ev.endDate,
          startTime: ev.startTime,
          endTime: ev.endTime,
          location: ev.location,
          description: ev.description,
        }));

        return {
          result: {
            timeframe: { startDate, endDate },
            totalEvents: events.length,
            events: simplified,
            message:
              simplified.length === 0
                ? 'No calendar events found for the requested timeframe.'
                : `Found ${simplified.length} calendar event(s).`,
          },
        };
      }

      // ── 4. GET REQUESTS ────────────────────────────────────────────────────
      case 'get_my_requests': {
        const status = typeof args.status === 'string' ? args.status.trim() : undefined;
        const requestType = typeof args.requestType === 'string' ? args.requestType.trim() : undefined;

        const res = await RequestService.listMyRequests(
          { status: status as any, requestType, limit: 10 },
          user
        );

        const simplified = res.items.map((r: any) => ({
          id: r.id,
          title: r.title,
          requestType: r.requestType,
          status: r.status,
          createdAt: r.createdAt,
          responseMessage: r.responseMessage,
        }));

        return {
          result: {
            totalRequests: res.total,
            requests: simplified,
            message:
              simplified.length === 0
                ? 'No requests found for your account.'
                : `Found ${simplified.length} request(s).`,
          },
        };
      }

      // ── 5. PROPOSE CREATE ASSIGNMENT ───────────────────────────────────────
      case 'propose_create_assignment': {
        if (user.role === AppRole.STUDENT) {
          return {
            result: {
              error: 'Access denied: Students are not authorized to create assignments.',
            },
          };
        }

        const title = typeof args.title === 'string' ? args.title.trim() : '';
        const subjectQuery = typeof args.subject === 'string' ? args.subject.trim() : '';
        const sectionQuery = typeof args.section === 'string' ? args.section.trim() : '';
        const dueDate = typeof args.dueDate === 'string' ? args.dueDate.trim() : '';
        const dueTime = typeof args.dueTime === 'string' ? args.dueTime.trim() : '11:59 PM';
        const description = typeof args.description === 'string' ? args.description.trim() : '';
        const maximumMarks = typeof args.maximumMarks === 'number' && args.maximumMarks > 0 ? args.maximumMarks : 100;
        const assignmentType =
          typeof args.assignmentType === 'string' &&
          Object.values(AssignmentType).includes(args.assignmentType.toLowerCase() as AssignmentType)
            ? (args.assignmentType.toLowerCase() as AssignmentType)
            : AssignmentType.HOMEWORK;

        if (!title || !subjectQuery || !sectionQuery || !dueDate) {
          return {
            result: {
              error: 'Missing required assignment fields. Please provide title, subject, section, and due date.',
            },
          };
        }

        // Validate due date is in the future
        const parsedDue = new Date(dueDate);
        if (isNaN(parsedDue.getTime())) {
          return {
            result: {
              error: `Invalid dueDate "${dueDate}". Please specify a valid date in YYYY-MM-DD format.`,
            },
          };
        }

        const now = new Date();
        now.setHours(0, 0, 0, 0);
        if (parsedDue < now) {
          return {
            result: {
              error: 'Due date cannot be in the past. Please select an upcoming date.',
            },
          };
        }

        // Resolve faculty profile to find authorized teaching assignments
        let facultyDoc = await Faculty.findOne({ userId: user.id });
        if (!facultyDoc && mongoose.Types.ObjectId.isValid(user.id)) {
          facultyDoc = await Faculty.findById(user.id);
        }

        const facultyFilter: any = { collegeId: new mongoose.Types.ObjectId(collegeId), isActive: true, status: 'active' };
        if (user.role === AppRole.FACULTY) {
          const fid = facultyDoc ? facultyDoc._id : new mongoose.Types.ObjectId(user.id);
          facultyFilter.facultyId = fid;
        } else if (user.role === AppRole.HOD && user.departmentId) {
          facultyFilter.departmentId = new mongoose.Types.ObjectId(user.departmentId);
        }

        const facultyAssignments = await FacultyAssignment.find(facultyFilter)
          .populate('subjectId', 'name code')
          .populate('sectionId', 'name');

        if (facultyAssignments.length === 0) {
          return {
            result: {
              error: 'You do not have any active teaching assignments assigned to your profile in this college.',
            },
          };
        }

        // Match subject and section
        const matchedFa = facultyAssignments.find((fa: any) => {
          const sub = fa.subjectId;
          const sec = fa.sectionId;
          const subMatches =
            sub &&
            (sub.name?.toLowerCase().includes(subjectQuery.toLowerCase()) ||
              sub.code?.toLowerCase().includes(subjectQuery.toLowerCase()) ||
              subjectQuery.toLowerCase().includes(sub.name?.toLowerCase()));
          const secMatches =
            sec &&
            (sec.name?.toLowerCase().includes(sectionQuery.toLowerCase()) ||
              sectionQuery.toLowerCase().includes(sec.name?.toLowerCase()));
          return subMatches && secMatches;
        });

        if (!matchedFa) {
          const availableOptions = facultyAssignments.map((fa: any) => ({
            subject: fa.subjectId?.name || fa.subjectId?.code || 'Unknown Subject',
            section: fa.sectionId?.name || 'No Section',
          }));

          return {
            result: {
              error: `No authorized teaching assignment found matching subject "${subjectQuery}" and section "${sectionQuery}".`,
              yourAuthorizedTeachingAssignments: availableOptions,
            },
          };
        }

        const resolvedSubjectName = (matchedFa.subjectId as any)?.name || subjectQuery;
        const resolvedSectionName = (matchedFa.sectionId as any)?.name || sectionQuery;

        const preview = {
          title,
          subject: resolvedSubjectName,
          section: resolvedSectionName,
          dueDate,
          dueTime,
          maximumMarks,
          description: description || 'No additional instructions provided.',
          assignmentType,
        };

        const summary = `Create ${assignmentType} assignment "${title}" for ${resolvedSubjectName} (Section ${resolvedSectionName}), due on ${dueDate} at ${dueTime} (${maximumMarks} marks).`;

        const pendingAction = await PendingActionService.createPendingAction({
          userId: user.id,
          userRole: user.role,
          collegeId,
          actionType: 'CREATE_ASSIGNMENT',
          draftPayload: {
            facultyAssignmentId: matchedFa._id.toString(),
            title,
            description,
            assignmentType,
            dueDate,
            dueTime,
            maximumMarks,
            status: AssignmentStatus.PUBLISHED,
          },
          summary,
          preview,
        });

        const proposal: ProposalResult = {
          actionId: pendingAction.actionId,
          actionType: 'CREATE_ASSIGNMENT',
          summary,
          preview,
          expiresAt: pendingAction.expiresAt.toISOString(),
        };

        return {
          result: {
            status: 'PENDING_CONFIRMATION',
            message:
              'Assignment draft created. Please review the details in the preview below and confirm to publish.',
            proposal,
          },
          proposal,
        };
      }

      // ── 6. PROPOSE CREATE CALENDAR EVENT ───────────────────────────────────
      case 'propose_create_calendar_event': {
        if (user.role === AppRole.STUDENT) {
          return {
            result: {
              error: 'Access denied: Students are not authorized to create calendar events.',
            },
          };
        }

        const title = typeof args.title === 'string' ? args.title.trim() : '';
        const startDate = typeof args.startDate === 'string' ? args.startDate.trim() : '';
        const endDate = typeof args.endDate === 'string' ? args.endDate.trim() : startDate;
        const startTime = typeof args.startTime === 'string' ? args.startTime.trim() : undefined;
        const endTime = typeof args.endTime === 'string' ? args.endTime.trim() : undefined;
        const description = typeof args.description === 'string' ? args.description.trim() : '';
        const location = typeof args.location === 'string' ? args.location.trim() : undefined;
        const rawType = typeof args.eventType === 'string' ? args.eventType.toUpperCase().trim() : '';
        let eventType: CalendarEventType = CalendarEventType.EVENT;
        if (rawType in CalendarEventType) {
          eventType = CalendarEventType[rawType as keyof typeof CalendarEventType];
        } else if (rawType === 'ACADEMIC') {
          eventType = CalendarEventType.ACADEMIC_EVENT;
        } else if (rawType === 'COLLEGE') {
          eventType = CalendarEventType.COLLEGE_EVENT;
        } else {
          eventType = CalendarEventType.EVENT;
        }

        if (!title || !startDate) {
          return {
            result: {
              error: 'Event title and start date are required to schedule an event.',
            },
          };
        }

        const parsedStart = new Date(startDate);
        if (isNaN(parsedStart.getTime())) {
          return {
            result: {
              error: `Invalid startDate "${startDate}". Please use YYYY-MM-DD format.`,
            },
          };
        }

        // Determine scope based on user role
        let scope = CalendarEventScope.CLASS;
        if (user.role === AppRole.SUPER_ADMIN || user.role === AppRole.COLLEGE_ADMIN) {
          scope = CalendarEventScope.COLLEGE;
        } else if (user.role === AppRole.HOD) {
          scope = CalendarEventScope.DEPARTMENT;
        }

        // Check for potential scheduling conflicts on the target day in college
        const existingEvents = await CalendarEvent.find({
          collegeId: new mongoose.Types.ObjectId(collegeId),
          startDate,
          status: { $ne: 'CANCELLED' },
        }).select('title eventType startTime endTime location');

        let conflictWarning: string | undefined;
        if (existingEvents.length > 0) {
          const conflicting = existingEvents.find((ev) => {
            const timeOverlaps = doTimeIntervalsOverlap(startTime, endTime, ev.startTime, ev.endTime);
            if (!timeOverlaps) return false;

            // Room conflict if both specify the same venue/room
            if (location && ev.location && location.toLowerCase().trim() === ev.location.toLowerCase().trim()) {
              return true;
            }
            // General time conflict if at least one has no room specified or same start time
            return (startTime && ev.startTime === startTime) || (!location && !ev.location);
          });
          if (conflicting) {
            const locInfo = conflicting.location ? ` in ${conflicting.location}` : '';
            const timeInfo = conflicting.startTime ? ` at ${conflicting.startTime}${conflicting.endTime ? ' - ' + conflicting.endTime : ''}` : '';
            conflictWarning = `Note: Potential scheduling conflict detected with existing event "${conflicting.title}"${timeInfo}${locInfo}.`;
          }
        }

        const preview = {
          title,
          eventType,
          startDate,
          endDate,
          startTime: startTime || 'All Day',
          endTime: endTime || (startTime ? 'End of period' : 'All Day'),
          location: location || 'Campus',
          description: description || 'No description provided.',
          scope,
          conflictWarning,
        };

        const summary = `Schedule ${eventType} "${title}" on ${startDate}${startTime ? ' at ' + startTime : ''}${location ? ' (' + location + ')' : ''}.`;

        const pendingAction = await PendingActionService.createPendingAction({
          userId: user.id,
          userRole: user.role,
          collegeId,
          actionType: 'CREATE_CALENDAR_EVENT',
          draftPayload: {
            title,
            description,
            eventType,
            scope,
            startDate,
            endDate,
            startTime,
            endTime,
            location,
            departmentId: user.departmentId,
          },
          summary,
          preview,
        });

        const proposal: ProposalResult = {
          actionId: pendingAction.actionId,
          actionType: 'CREATE_CALENDAR_EVENT',
          summary,
          preview,
          expiresAt: pendingAction.expiresAt.toISOString(),
        };

        return {
          result: {
            status: 'PENDING_CONFIRMATION',
            message:
              'Event draft prepared. Please review the details in the preview below and confirm to schedule.',
            proposal,
          },
          proposal,
        };
      }

      default:
        return {
          result: {
            error: `Unrecognized or unauthorized tool: "${name}".`,
          },
        };
    }
  }
}
