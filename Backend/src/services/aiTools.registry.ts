import mongoose from 'mongoose';
import { FunctionDeclaration, Type } from '@google/genai';
import { AuthenticatedUser } from '../types/auth.types';
import { AppRole } from '../constants/roles';
import { TimetableService } from './timetable.service';
import { AssignmentService } from './assignment.service';
import { AcademicCalendarService } from './academicCalendar.service';
import { RequestService } from './request.service';
import { PendingActionService } from './pendingAction.service';
import { ProfileService } from './profile.service';
import { AttendanceService } from './attendance.service';
import { NoteService } from './note.service';
import { AnnouncementService } from './announcement.service';
import { ReportService } from './report.service';
import { Faculty } from '../models/faculty.model';
import { FacultyAssignment } from '../models/facultyAssignment.model';
import { CalendarEvent } from '../models/calendarEvent.model';
import { AttendanceSession } from '../models/attendanceSession.model';
import { Note } from '../models/note.model';
import { CalendarEventScope, CalendarEventType } from '../constants/calendar.constants';
import { AssignmentStatus, AssignmentType } from '../constants/assignment.constants';
import {
  ALLOWED_REQUEST_TYPES_BY_ROLE,
  RequestStatus,
  RequestType,
} from '../constants/request.constants';
import { Logger } from '../utils/logger';

// ── TOOL DECLARATIONS ──────────────────────────────────────────────────────────

export const declGetMyProfile: FunctionDeclaration = {
  name: 'get_my_profile',
  description:
    "Retrieve the authenticated user's authoritative academic profile, institutional identity, enrollment details (course, semester, section, roll number) for students, active teaching assignments for faculty, or departmental/college administrative scope for HODs and Administrators.",
  parameters: {
    type: Type.OBJECT,
    properties: {},
  },
};

export const declGetMyTimetable: FunctionDeclaration = {
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
        description:
          "Optional period targeting: 'all' (default), 'next' (upcoming period today), 'first' (first period of day), 'last' (last period of day), 'morning' (classes before 12:00 PM), or 'afternoon' (classes 12:00 PM onwards).",
      },
    },
  },
};

export const declGetMyAssignments: FunctionDeclaration = {
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
};

export const declGetCalendarEvents: FunctionDeclaration = {
  name: 'get_calendar_events',
  description:
    'Retrieve upcoming academic calendar events, holidays, examinations, and institution activities for the authenticated user. Defaults to upcoming 30 days if range is not specified.',
  parameters: {
    type: Type.OBJECT,
    properties: {
      startDate: {
        type: Type.STRING,
        description: "Optional start date in 'YYYY-MM-DD' format (defaults to current date in India Standard Time).",
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
};

export const declGetMyAttendance: FunctionDeclaration = {
  name: 'get_my_attendance',
  description:
    'Retrieve attendance statistics and records. For students: returns attendance percentages, classes held, attended, absent, and detailed metrics. For faculty: returns recent attendance sessions marked and teaching classes.',
  parameters: {
    type: Type.OBJECT,
    properties: {
      subjectId: {
        type: Type.STRING,
        description: 'Optional subject ID filter to inspect attendance for a particular subject.',
      },
    },
  },
};

export const declGetPublishedNotes: FunctionDeclaration = {
  name: 'get_published_notes',
  description:
    'Retrieve published academic notes, lecture slides, and study materials. For students: returns notes published for their enrolled course, semester, and section. For faculty/HOD: returns notes uploaded for their department or assigned subjects.',
  parameters: {
    type: Type.OBJECT,
    properties: {
      subjectId: {
        type: Type.STRING,
        description: 'Optional subject ID filter.',
      },
      search: {
        type: Type.STRING,
        description: 'Optional search keyword to find notes by title, topic, or chapter.',
      },
      noteType: {
        type: Type.STRING,
        description: "Optional note type filter (e.g. 'study_material', 'lecture_notes', 'syllabus').",
      },
    },
  },
};

export const declGetMyRequests: FunctionDeclaration = {
  name: 'get_my_requests',
  description:
    'Retrieve status and history of requests submitted by the authenticated user (e.g. leave, attendance correction, hall booking, certificates).',
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
};

export const declGetIncomingRequests: FunctionDeclaration = {
  name: 'get_incoming_requests',
  description:
    'Retrieve incoming academic and administrative requests submitted to the authenticated authority (Faculty, HOD, or College Admin) for review and response (e.g. student leave requests, attendance corrections, timetable changes). Only available to Faculty, HOD, and Administrators.',
  parameters: {
    type: Type.OBJECT,
    properties: {
      status: {
        type: Type.STRING,
        description: "Optional status filter ('SUBMITTED', 'RECEIVED', 'UNDER_REVIEW', 'APPROVED', 'REJECTED').",
      },
      requestType: {
        type: Type.STRING,
        description: "Optional request type filter (e.g. 'LEAVE', 'ATTENDANCE_CORRECTION', 'TIMETABLE_CHANGE').",
      },
    },
  },
};

export const declGetAnnouncements: FunctionDeclaration = {
  name: 'get_announcements',
  description:
    'Retrieve official campus announcements, institutional circulars, and notices targeted to the authenticated user.',
  parameters: {
    type: Type.OBJECT,
    properties: {
      limit: {
        type: Type.NUMBER,
        description: 'Optional maximum number of announcements to return (defaults to 10).',
      },
    },
  },
};

export const declGetReportsDashboard: FunctionDeclaration = {
  name: 'get_reports_dashboard',
  description:
    'Retrieve high-level institutional and departmental summary reports and operational analytics (e.g. attendance metrics, student/faculty counts, department overviews). Available to HOD, College Admin, and Super Admin.',
  parameters: {
    type: Type.OBJECT,
    properties: {
      preset: {
        type: Type.STRING,
        description: "Optional date range preset: 'today', 'this_week', or 'this_month'.",
      },
    },
  },
};

export const declProposeCreateRequest: FunctionDeclaration = {
  name: 'propose_create_request',
  description:
    "Propose submitting an official academic request (e.g. Leave / Sick Leave, Attendance Correction, Academic Issue, Timetable Change, Resource Request, General Request) for review and approval by the responsible authority (HOD, Faculty, or College Admin). Does NOT persist directly; generates a structured preview requiring explicit user confirmation.",
  parameters: {
    type: Type.OBJECT,
    properties: {
      requestType: {
        type: Type.STRING,
        description:
          "Permitted category of request based on role: for Student: 'LEAVE', 'ATTENDANCE_CORRECTION', 'ACADEMIC_ISSUE', 'GENERAL_REQUEST', 'COMPLAINT_ISSUE', 'DOCUMENT_REQUEST'; for Faculty: 'LEAVE', 'ON_DUTY', 'PERMISSION', 'TIMETABLE_CHANGE', 'RESOURCE_REQUEST', 'CLASSROOM_LAB_ISSUE', 'WORKLOAD_CONCERN', 'GENERAL_REQUEST', 'ASSESSMENT_MARK_CORRECTION'; for HOD: 'LEAVE', 'FACULTY_REQUIREMENT', 'RESOURCE_REQUEST', 'INFRASTRUCTURE_ISSUE', 'ACADEMIC_APPROVAL', 'EVENT_WORKSHOP_APPROVAL', 'TIMETABLE_CHANGE', 'GENERAL_ADMIN_REQUEST', 'ASSESSMENT_MARK_CORRECTION'.",
      },
      title: {
        type: Type.STRING,
        description: "Title summarizing the request (e.g. 'Sick Leave Request', 'Leave Application for Medical Checkup').",
      },
      description: {
        type: Type.STRING,
        description: 'Detailed explanation and reason for the request (required).',
      },
      startDate: {
        type: Type.STRING,
        description: "Start date in 'YYYY-MM-DD' format, or relative expression like 'today' or 'tomorrow'.",
      },
      endDate: {
        type: Type.STRING,
        description:
          "Optional end date in 'YYYY-MM-DD' format, or relative expression like 'today' or 'tomorrow' (defaults to startDate for single-day requests).",
      },
      reason: {
        type: Type.STRING,
        description:
          "Optional specific reason or illness description (e.g. 'Feeling sick with fever', 'Medical appointment').",
      },
      relatedEntityType: {
        type: Type.STRING,
        description: "Optional related entity type (e.g. 'ATTENDANCE_SESSION', 'ASSIGNMENT').",
      },
      relatedEntityId: {
        type: Type.STRING,
        description: 'Optional ID of the referenced entity.',
      },
    },
    required: ['requestType', 'description'],
  },
};

export const declProposeCreateAssignment: FunctionDeclaration = {
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
};

export const declProposeCreateCalendarEvent: FunctionDeclaration = {
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
};

export const declProposeRespondRequest: FunctionDeclaration = {
  name: 'propose_respond_request',
  description:
    'Propose an official review response (Approve, Reject, or Resolve) for an incoming request. Does NOT persist directly; generates a structured preview requiring explicit confirmation. Only available to authorized reviewers (Faculty, HOD, College Admin).',
  parameters: {
    type: Type.OBJECT,
    properties: {
      requestId: {
        type: Type.STRING,
        description: 'Unique request identifier (e.g. REQ-123456-7890 or document ID) to respond to (required).',
      },
      action: {
        type: Type.STRING,
        description: "Review decision action: 'APPROVED', 'REJECTED', or 'RESOLVED' (required).",
      },
      message: {
        type: Type.STRING,
        description: 'Response message, remarks, or rejection reason (minimum 5 characters for rejection).',
      },
    },
    required: ['requestId', 'action'],
  },
};

// ── ROLE DECLARATION SELECTOR ──────────────────────────────────────────────────

/**
 * Returns the exact, authoritative subset of Gemini FunctionDeclarations permitted for the given role.
 */
export function getFunctionDeclarationsForRole(role: AppRole): FunctionDeclaration[] {
  switch (role) {
    case AppRole.STUDENT:
      return [
        declGetMyProfile,
        declGetMyTimetable,
        declGetMyAssignments,
        declGetCalendarEvents,
        declGetMyAttendance,
        declGetPublishedNotes,
        declGetMyRequests,
        declGetAnnouncements,
        declProposeCreateRequest,
      ];
    case AppRole.FACULTY:
      return [
        declGetMyProfile,
        declGetMyTimetable,
        declGetMyAssignments,
        declGetCalendarEvents,
        declGetMyAttendance,
        declGetPublishedNotes,
        declGetMyRequests,
        declGetIncomingRequests,
        declGetAnnouncements,
        declProposeCreateRequest,
        declProposeCreateAssignment,
        declProposeCreateCalendarEvent,
        declProposeRespondRequest,
      ];
    case AppRole.HOD:
      return [
        declGetMyProfile,
        declGetMyTimetable,
        declGetMyAssignments,
        declGetCalendarEvents,
        declGetMyAttendance,
        declGetPublishedNotes,
        declGetMyRequests,
        declGetIncomingRequests,
        declGetAnnouncements,
        declGetReportsDashboard,
        declProposeCreateRequest,
        declProposeCreateAssignment,
        declProposeCreateCalendarEvent,
        declProposeRespondRequest,
      ];
    case AppRole.COLLEGE_ADMIN:
      return [
        declGetMyProfile,
        declGetMyTimetable,
        declGetMyAssignments,
        declGetCalendarEvents,
        declGetMyAttendance,
        declGetPublishedNotes,
        declGetMyRequests,
        declGetIncomingRequests,
        declGetAnnouncements,
        declGetReportsDashboard,
        declProposeCreateRequest,
        declProposeCreateCalendarEvent,
        declProposeRespondRequest,
      ];
    case AppRole.SUPER_ADMIN:
      return [
        declGetMyProfile,
        declGetCalendarEvents,
        declGetMyRequests,
        declGetIncomingRequests,
        declGetAnnouncements,
        declGetReportsDashboard,
        declProposeCreateRequest,
        declProposeCreateCalendarEvent,
        declProposeRespondRequest,
      ];
    default:
      return [];
  }
}

/**
 * Master catalog of all available function declarations
 */
export const aiFunctionDeclarations: FunctionDeclaration[] = [
  declGetMyProfile,
  declGetMyTimetable,
  declGetMyAssignments,
  declGetCalendarEvents,
  declGetMyAttendance,
  declGetPublishedNotes,
  declGetMyRequests,
  declGetIncomingRequests,
  declGetAnnouncements,
  declGetReportsDashboard,
  declProposeCreateRequest,
  declProposeCreateAssignment,
  declProposeCreateCalendarEvent,
  declProposeRespondRequest,
];

// ── TYPES & INTERFACES ─────────────────────────────────────────────────────────

export interface ToolExecutionContext {
  user: AuthenticatedUser;
  collegeId: string;
}

export interface ProposalResult {
  actionId: string;
  actionType: 'CREATE_ASSIGNMENT' | 'CREATE_CALENDAR_EVENT' | 'CREATE_REQUEST' | 'RESPOND_REQUEST';
  summary: string;
  preview: Record<string, any>;
  expiresAt: string;
}

// ── TIME & DATE HELPERS ────────────────────────────────────────────────────────

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

export function resolveRelativeDateIST(raw?: string | null): string | undefined {
  if (!raw || typeof raw !== 'string') return undefined;
  const trimmed = raw.trim().toLowerCase();
  const now = new Date();
  if (trimmed === 'today') {
    return new Intl.DateTimeFormat('en-CA', { timeZone: 'Asia/Kolkata' }).format(now);
  }
  if (trimmed === 'tomorrow') {
    const tomorrow = new Date(now.getTime() + 24 * 60 * 60 * 1000);
    return new Intl.DateTimeFormat('en-CA', { timeZone: 'Asia/Kolkata' }).format(tomorrow);
  }
  if (trimmed === 'yesterday') {
    const yesterday = new Date(now.getTime() - 24 * 60 * 60 * 1000);
    return new Intl.DateTimeFormat('en-CA', { timeZone: 'Asia/Kolkata' }).format(yesterday);
  }
  if (/^\d{4}-\d{2}-\d{2}$/.test(trimmed)) {
    return trimmed;
  }
  const parsed = new Date(trimmed);
  if (!isNaN(parsed.getTime())) {
    return new Intl.DateTimeFormat('en-CA', { timeZone: 'Asia/Kolkata' }).format(parsed);
  }
  return trimmed;
}

// ── REGISTRY & DISPATCHER ──────────────────────────────────────────────────────

export class AiToolsRegistry {
  private static roleAllowedTools: Record<AppRole, string[]> = {
    [AppRole.STUDENT]: [
      'get_my_profile',
      'get_my_timetable',
      'get_my_assignments',
      'get_calendar_events',
      'get_my_attendance',
      'get_published_notes',
      'get_my_requests',
      'get_announcements',
      'propose_create_request',
    ],
    [AppRole.FACULTY]: [
      'get_my_profile',
      'get_my_timetable',
      'get_my_assignments',
      'get_calendar_events',
      'get_my_attendance',
      'get_published_notes',
      'get_my_requests',
      'get_incoming_requests',
      'get_announcements',
      'propose_create_request',
      'propose_create_assignment',
      'propose_create_calendar_event',
      'propose_respond_request',
    ],
    [AppRole.HOD]: [
      'get_my_profile',
      'get_my_timetable',
      'get_my_assignments',
      'get_calendar_events',
      'get_my_attendance',
      'get_published_notes',
      'get_my_requests',
      'get_incoming_requests',
      'get_announcements',
      'get_reports_dashboard',
      'propose_create_request',
      'propose_create_assignment',
      'propose_create_calendar_event',
      'propose_respond_request',
    ],
    [AppRole.COLLEGE_ADMIN]: [
      'get_my_profile',
      'get_my_timetable',
      'get_my_assignments',
      'get_calendar_events',
      'get_my_attendance',
      'get_published_notes',
      'get_my_requests',
      'get_incoming_requests',
      'get_announcements',
      'get_reports_dashboard',
      'propose_create_request',
      'propose_create_calendar_event',
      'propose_respond_request',
    ],
    [AppRole.SUPER_ADMIN]: [
      'get_my_profile',
      'get_calendar_events',
      'get_my_requests',
      'get_incoming_requests',
      'get_announcements',
      'get_reports_dashboard',
      'propose_create_request',
      'propose_create_calendar_event',
      'propose_respond_request',
    ],
  };

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

    // 0. Strict Central Role Enforcement: verify tool authorization
    const allowedTools = this.roleAllowedTools[user.role] || [];
    if (!allowedTools.includes(name)) {
      return {
        result: {
          error: `Access denied: Role "${user.role}" is not authorized to invoke tool "${name}".`,
        },
      };
    }

    switch (name) {
      // ── 1. GET PROFILE ─────────────────────────────────────────────────────
      case 'get_my_profile': {
        const profile = await ProfileService.getComposedProfile(user.id, user);
        const u = profile.user;
        const rp = profile.roleProfile;

        const summary: Record<string, any> = {
          name: u.name,
          role: u.role,
          email: u.email,
          instituteId: u.instituteId,
          college: u.collegeName || 'ACADEX Institution',
          department: u.departmentName || 'General',
        };

        if (user.role === AppRole.STUDENT && rp.student) {
          const s = rp.student;
          summary.studentDetails = {
            rollNumber: s.rollNumber,
            admissionNumber: s.admissionNumber,
            academicStage: s.academicStage,
            cohort: s.cohort,
            currentEnrollment: s.currentEnrollment
              ? {
                  course: s.currentEnrollment.courseName,
                  semester: s.currentEnrollment.semesterName,
                  section: s.currentEnrollment.sectionName,
                  academicYear: s.currentEnrollment.academicYearName,
                }
              : null,
          };
        } else if (user.role === AppRole.FACULTY && rp.faculty) {
          const f = rp.faculty;
          summary.facultyDetails = {
            designation: f.designation,
            qualification: f.qualification,
            specialization: f.specialization,
            activeTeachingAssignments: (f.activeAssignments || []).map((a: any) => ({
              subject: a.subjectName,
              code: a.subjectCode,
              section: a.sectionName,
              course: a.courseName,
              semester: a.semesterName,
            })),
          };
        } else if (user.role === AppRole.HOD && rp.hod) {
          const h = rp.hod;
          summary.departmentManagement = {
            department: h.departmentName,
            code: h.departmentCode,
            managedScope: h.managedScope,
          };
        } else if (user.role === AppRole.COLLEGE_ADMIN && rp.collegeAdmin) {
          summary.institutionScope = rp.collegeAdmin.administrativeScope;
        }

        return {
          result: {
            profile: summary,
            message: `Authoritative profile for ${u.name} (${u.role}).`,
          },
        };
      }

      // ── 2. GET TIMETABLE ───────────────────────────────────────────────────
      case 'get_my_timetable': {
        const rawDay = typeof args.day === 'string' ? args.day.trim().toLowerCase() : undefined;
        let date = typeof args.date === 'string' ? args.date.trim() : undefined;
        const periodTarget = typeof args.periodTarget === 'string' ? args.periodTarget.trim().toLowerCase() : 'all';

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

      // ── 3. GET ASSIGNMENTS ─────────────────────────────────────────────────
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

        if (dueSoon) {
          simplified = simplified.filter(
            (a: any) => a.daysRemaining !== null && a.daysRemaining >= 0 && a.daysRemaining <= 7
          );
        }

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

      // ── 4. GET CALENDAR EVENTS ─────────────────────────────────────────────
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

      // ── 5. GET ATTENDANCE ──────────────────────────────────────────────────
      case 'get_my_attendance': {
        if (user.role === AppRole.STUDENT) {
          const summary = await AttendanceService.getStudentAttendanceSummary(collegeId, user.id);
          return {
            result: {
              role: user.role,
              overallPercentage: `${summary.percentage}%`,
              totalClasses: summary.totalClasses,
              attended: summary.presentCount,
              absent: summary.absentCount,
              late: summary.lateCount,
              excused: summary.excusedCount,
              message: `Your current attendance is ${summary.percentage}% (${summary.presentCount}/${summary.totalClasses} classes attended).`,
            },
          };
        } else if (user.role === AppRole.FACULTY) {
          let facultyDoc = await Faculty.findOne({ userId: user.id });
          if (!facultyDoc && mongoose.Types.ObjectId.isValid(user.id)) {
            facultyDoc = await Faculty.findById(user.id);
          }
          const fid = facultyDoc ? facultyDoc._id : new mongoose.Types.ObjectId(user.id);
          const sessions = await AttendanceSession.find({
            collegeId: new mongoose.Types.ObjectId(collegeId),
            $or: [{ facultyId: fid }, { substituteFacultyId: fid }],
          })
            .sort({ date: -1 })
            .limit(10)
            .select('subjectName sectionName date timeSlot status isSubmitted');

          return {
            result: {
              role: user.role,
              totalRecentSessions: sessions.length,
              recentSessions: sessions.map((s) => ({
                subject: s.subjectName,
                section: s.sectionName,
                date: s.date
                  ? new Intl.DateTimeFormat('en-CA', { timeZone: 'Asia/Kolkata' }).format(new Date(s.date))
                  : '',
                timeSlot: s.timeSlot,
                status: s.status,
                isSubmitted: s.isSubmitted,
              })),
              message: `Found ${sessions.length} recent attendance session(s) conducted by you.`,
            },
          };
        } else {
          const deptFilter: any = { collegeId: new mongoose.Types.ObjectId(collegeId) };
          if (user.role === AppRole.HOD && user.departmentId) {
            deptFilter.departmentId = new mongoose.Types.ObjectId(user.departmentId);
          }
          const sessionsCount = await AttendanceSession.countDocuments(deptFilter);
          return {
            result: {
              role: user.role,
              totalSessionsLogged: sessionsCount,
              message: `Total ${sessionsCount} attendance sessions registered in your administrative scope.`,
            },
          };
        }
      }

      // ── 6. GET PUBLISHED NOTES ─────────────────────────────────────────────
      case 'get_published_notes': {
        const search = typeof args.search === 'string' ? args.search.trim() : undefined;
        const subjectId = typeof args.subjectId === 'string' ? args.subjectId.trim() : undefined;
        const noteType = typeof args.noteType === 'string' ? (args.noteType.trim() as any) : undefined;

        let notesRes: any;
        if (user.role === AppRole.STUDENT) {
          notesRes = await NoteService.getStudentNotes(user, { subjectId, search, noteType, limit: 15 });
        } else if (subjectId && mongoose.Types.ObjectId.isValid(subjectId)) {
          notesRes = await NoteService.getSubjectNotes(subjectId, user, { limit: 15 });
        } else {
          const filter: any = {
            collegeId: new mongoose.Types.ObjectId(collegeId),
            lifecycleState: 'READY',
            status: 'published',
          };
          if (user.role === AppRole.FACULTY) {
            filter.authorUserId = new mongoose.Types.ObjectId(user.id);
          } else if (user.role === AppRole.HOD && user.departmentId) {
            filter.departmentId = new mongoose.Types.ObjectId(user.departmentId);
          }
          if (search) {
            const rx = new RegExp(search, 'i');
            filter.$or = [{ title: rx }, { description: rx }, { chapter: rx }];
          }
          const items = await Note.find(filter).sort({ createdAt: -1 }).limit(15);
          notesRes = { items, total: items.length };
        }

        const simplified = (notesRes.items || []).map((n: any) => ({
          id: n.id || n._id?.toString(),
          title: n.title,
          chapter: n.chapter,
          noteType: n.noteType,
          fileName: n.originalFileName,
          fileSize: n.fileSize,
          mimeType: n.mimeType,
          publishedAt: n.publishedAt || n.createdAt,
          description: n.description,
        }));

        return {
          result: {
            totalNotes: notesRes.total || simplified.length,
            notes: simplified,
            message:
              simplified.length === 0
                ? 'No published notes found matching the criteria.'
                : `Found ${simplified.length} published note(s).`,
          },
        };
      }

      // ── 7. GET MY REQUESTS ─────────────────────────────────────────────────
      case 'get_my_requests': {
        const status = typeof args.status === 'string' ? args.status.trim() : undefined;
        const requestType = typeof args.requestType === 'string' ? args.requestType.trim() : undefined;

        const res = await RequestService.listMyRequests(
          { status: status as any, requestType, limit: 10 },
          user
        );

        const simplified = res.items.map((r: any) => ({
          id: r.id || r._id?.toString(),
          requestId: r.requestId,
          title: r.title,
          requestType: r.requestType,
          status: r.status,
          targetRole: r.targetRole,
          targetName: r.targetName,
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

      // ── 8. GET INCOMING REQUESTS ───────────────────────────────────────────
      case 'get_incoming_requests': {
        if (user.role === AppRole.STUDENT) {
          return {
            result: {
              error: 'Students do not have incoming administrative or review requests.',
            },
          };
        }

        const status = typeof args.status === 'string' ? (args.status.trim() as any) : undefined;
        const requestType = typeof args.requestType === 'string' ? args.requestType.trim() : undefined;

        const res = await RequestService.listIncomingRequests(
          { status, requestType, limit: 15 },
          user
        );

        const simplified = res.items.map((r: any) => ({
          id: r.id || r._id?.toString(),
          requestId: r.requestId,
          title: r.title,
          requestType: r.requestType,
          requesterName: r.requesterName,
          requesterRole: r.requesterRole,
          status: r.status,
          createdAt: r.createdAt,
          description: r.description,
          startDate: r.details?.startDate,
          endDate: r.details?.endDate,
          reason: r.details?.reason,
        }));

        return {
          result: {
            totalIncomingRequests: res.total,
            requests: simplified,
            message:
              simplified.length === 0
                ? 'No incoming requests waiting for review.'
                : `Found ${simplified.length} incoming request(s) awaiting your action.`,
          },
        };
      }

      // ── 9. GET ANNOUNCEMENTS ───────────────────────────────────────────────
      case 'get_announcements': {
        const limit = typeof args.limit === 'number' && args.limit > 0 ? Math.min(args.limit, 20) : 10;
        const res = await AnnouncementService.listAnnouncements({ manage: false, limit }, user);

        const simplified = res.items.map((a: any) => ({
          id: a.id || a._id?.toString(),
          title: a.title,
          body: a.body,
          category: a.category,
          audienceScope: a.audienceScope,
          publishedAt: a.publishedAt || a.createdAt,
          priority: a.priority,
          isPinned: a.isPinned,
        }));

        return {
          result: {
            totalAnnouncements: res.total,
            announcements: simplified,
            message:
              simplified.length === 0
                ? 'No recent announcements available.'
                : `Found ${simplified.length} announcement(s).`,
          },
        };
      }

      // ── 10. GET REPORTS DASHBOARD ──────────────────────────────────────────
      case 'get_reports_dashboard': {
        if (user.role === AppRole.STUDENT) {
          return {
            result: {
              error: 'Students do not have access to institutional reports. Use get_my_attendance for personal metrics.',
            },
          };
        }

        const preset = typeof args.preset === 'string' ? (args.preset.trim() as any) : undefined;
        const dashboard = await ReportService.getDashboard(user, { preset, page: 1, limit: 20 });

        return {
          result: {
            role: user.role,
            dashboard,
            message: 'Dashboard and analytics report generated successfully.',
          },
        };
      }

      // ── 11. PROPOSE CREATE REQUEST ─────────────────────────────────────────
      case 'propose_create_request': {
        const description = typeof args.description === 'string' ? args.description.trim() : '';
        const titleInput = typeof args.title === 'string' ? args.title.trim() : '';
        const reason = typeof args.reason === 'string' ? args.reason.trim() : undefined;

        if (!description) {
          return {
            result: {
              error: 'Missing required request description. Please provide the reason or details of the request.',
            },
          };
        }

        // Normalize request type
        let rawType = (args.requestType || '').toString().toUpperCase().trim().replace(/[\s-]+/g, '_');
        if (rawType.includes('LEAVE') || rawType === 'SICK_LEAVE' || rawType === 'CASUAL_LEAVE') {
          rawType = 'LEAVE';
        } else if (rawType.includes('ATTENDANCE')) {
          rawType = 'ATTENDANCE_CORRECTION';
        } else if (rawType.includes('TIMETABLE')) {
          rawType = 'TIMETABLE_CHANGE';
        } else if (rawType.includes('DUTY') || rawType === 'OD') {
          rawType = 'ON_DUTY';
        } else if (rawType.includes('DOCUMENT') || rawType.includes('CERTIFICATE')) {
          rawType = 'DOCUMENT_REQUEST';
        } else if (rawType.includes('COMPLAINT')) {
          rawType = 'COMPLAINT_ISSUE';
        } else if (rawType.includes('RESOURCE')) {
          rawType = 'RESOURCE_REQUEST';
        }

        // Verify request type permission for user's role
        const allowedTypes = ALLOWED_REQUEST_TYPES_BY_ROLE[user.role] || [];
        if (!allowedTypes.includes(rawType)) {
          return {
            result: {
              error: `Request type "${rawType}" is not permitted for your role (${user.role}). Allowed types: ${allowedTypes.join(', ')}`,
              allowedTypes,
            },
          };
        }

        // Resolve dates against India Standard Time (IST)
        const now = new Date();
        const todayISTStr = new Intl.DateTimeFormat('en-CA', { timeZone: 'Asia/Kolkata' }).format(now);
        const resolvedStartDate = resolveRelativeDateIST(args.startDate) || todayISTStr;
        const resolvedEndDate = resolveRelativeDateIST(args.endDate) || resolvedStartDate;

        const defaultTitle = `${rawType.replace(/_/g, ' ').toLowerCase().replace(/\b\w/g, (c: string) => c.toUpperCase())} Request`;
        const title = titleInput || defaultTitle;

        // Authoritative target routing
        let target: { targetRole: AppRole; targetUserId?: string | null; targetName: string; departmentId?: string | null };
        try {
          target = await RequestService.resolveTarget(user, {
            requestType: rawType as RequestType,
            description,
            details: {
              startDate: resolvedStartDate,
              endDate: resolvedEndDate,
              reason: reason || description,
            },
          });
        } catch (targetErr: any) {
          return {
            result: {
              error: `Unable to route request: ${targetErr.message || 'Responsible reviewer could not be resolved.'}`,
            },
          };
        }

        const preview = {
          title,
          requestType: rawType,
          description,
          startDate: resolvedStartDate,
          endDate: resolvedEndDate,
          reason: reason || description,
          targetAuthority: target.targetName,
          targetRole: target.targetRole,
          requesterRole: user.role,
        };

        const summary = `Submit ${rawType.replace(/_/g, ' ')} request "${title}" to ${target.targetName} for ${preview.startDate}${preview.endDate !== preview.startDate ? ' to ' + preview.endDate : ''}.`;

        const pendingAction = await PendingActionService.createPendingAction({
          userId: user.id,
          userRole: user.role,
          collegeId,
          actionType: 'CREATE_REQUEST',
          draftPayload: {
            requestType: rawType,
            title,
            description,
            status: RequestStatus.SUBMITTED,
            details: {
              startDate: preview.startDate,
              endDate: preview.endDate,
              reason: preview.reason,
            },
            relatedEntityType: args.relatedEntityType,
            relatedEntityId: args.relatedEntityId,
          },
          summary,
          preview,
        });

        const proposal: ProposalResult = {
          actionId: pendingAction.actionId,
          actionType: 'CREATE_REQUEST',
          summary,
          preview,
          expiresAt: pendingAction.expiresAt.toISOString(),
        };

        return {
          result: {
            status: 'PENDING_CONFIRMATION',
            message: `Your ${rawType.replace(/_/g, ' ')} request proposal has been drafted for ${target.targetName}. Please review the preview below and confirm to submit.`,
            proposal,
          },
          proposal,
        };
      }

      // ── 12. PROPOSE CREATE ASSIGNMENT ──────────────────────────────────────
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

      // ── 13. PROPOSE CREATE CALENDAR EVENT ──────────────────────────────────
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

        let scope = CalendarEventScope.CLASS;
        if (user.role === AppRole.SUPER_ADMIN || user.role === AppRole.COLLEGE_ADMIN) {
          scope = CalendarEventScope.COLLEGE;
        } else if (user.role === AppRole.HOD) {
          scope = CalendarEventScope.DEPARTMENT;
        }

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
            if (location && ev.location && location.toLowerCase().trim() === ev.location.toLowerCase().trim()) {
              return true;
            }
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

      // ── 14. PROPOSE RESPOND REQUEST ────────────────────────────────────────
      case 'propose_respond_request': {
        if (user.role === AppRole.STUDENT) {
          return {
            result: {
              error: 'Access denied: Students are not authorized to respond to or approve requests.',
            },
          };
        }

        const requestId = typeof args.requestId === 'string' ? args.requestId.trim() : '';
        let rawAction = typeof args.action === 'string' ? args.action.toUpperCase().trim() : '';
        if (rawAction === 'APPROVE') rawAction = 'APPROVED';
        if (rawAction === 'REJECT') rawAction = 'REJECTED';
        if (rawAction === 'RESOLVE') rawAction = 'RESOLVED';
        const message = typeof args.message === 'string' ? args.message.trim() : (typeof args.remarks === 'string' ? args.remarks.trim() : '');

        if (!requestId || !rawAction) {
          return {
            result: {
              error: 'Missing required parameters: requestId and action (APPROVED, REJECTED, or RESOLVED) are required.',
            },
          };
        }

        const validActions = ['APPROVED', 'REJECTED', 'RESOLVED'];
        if (!validActions.includes(rawAction)) {
          return {
            result: {
              error: `Invalid action "${rawAction}". Allowed decisions: APPROVED, REJECTED, RESOLVED.`,
            },
          };
        }

        if (rawAction === 'REJECTED' && message.length < 5) {
          return {
            result: {
              error: 'A meaningful rejection reason (at least 5 characters) is required when rejecting a request.',
            },
          };
        }

        let targetReq;
        try {
          targetReq = await RequestService.getRequestById(requestId, user);
        } catch (err: any) {
          return {
            result: {
              error: `Cannot access request "${requestId}": ${err.message || 'Request not found or access denied.'}`,
            },
          };
        }

        if (targetReq.requesterUserId.toString() === user.id.toString()) {
          return {
            result: {
              error: 'Requesters cannot approve, reject, or resolve their own request.',
            },
          };
        }

        const decisionMessage = message || (rawAction === 'APPROVED' ? 'Request approved.' : 'Request resolved.');

        const preview = {
          requestId: targetReq.requestId,
          title: targetReq.title,
          requestType: targetReq.requestType,
          requesterName: targetReq.requesterName,
          requesterRole: targetReq.requesterRole,
          action: rawAction,
          decisionMessage,
          currentStatus: targetReq.status,
        };

        const summary = `Confirm ${rawAction} decision for request "${targetReq.title}" (${targetReq.requestId}) submitted by ${targetReq.requesterName}.`;

        const pendingAction = await PendingActionService.createPendingAction({
          userId: user.id,
          userRole: user.role,
          collegeId,
          actionType: 'RESPOND_REQUEST',
          draftPayload: {
            requestId: targetReq.id,
            action: rawAction,
            message: decisionMessage,
          },
          summary,
          preview,
        });

        const proposal: ProposalResult = {
          actionId: pendingAction.actionId,
          actionType: 'RESPOND_REQUEST',
          summary,
          preview,
          expiresAt: pendingAction.expiresAt.toISOString(),
        };

        return {
          result: {
            status: 'PENDING_CONFIRMATION',
            message: `Proposal prepared to set request ${targetReq.requestId} to ${rawAction}. Please review the details below and confirm to apply.`,
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
