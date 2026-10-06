import mongoose from 'mongoose';
import { User } from '../models/user.model';
import { Student } from '../models/student.model';
import { StudentEnrollment } from '../models/studentEnrollment.model';
import { Faculty } from '../models/faculty.model';
import { FacultyAssignment } from '../models/facultyAssignment.model';
import { Department } from '../models/department.model';
import { College } from '../models/college.model';
import { AcademicYear } from '../models/academicYear.model';
import { AttendanceSession } from '../models/attendanceSession.model';
import { AttendanceRecord } from '../models/attendanceRecord.model';
import { Assignment } from '../models/assignment.model';
import { AssignmentSubmission } from '../models/assignmentSubmission.model';
import { FacultyReviewStatus } from '../constants/assignment.constants';
import { PracticalSession } from '../models/practicalSession.model';
import { PracticalParticipation } from '../models/practicalParticipation.model';
import { InternalAssessment, AssessmentStatus } from '../models/internalAssessment.model';
import { AcademicResult } from '../models/academicResult.model';
import { ResultLifecycleStatus } from '../constants/academicResult.constants';
import { RequestModel } from '../models/request.model';
import { RequestStatus } from '../constants/request.constants';
import { Announcement } from '../models/announcement.model';
import { Notification } from '../models/notification.model';
import { AcademicCalendarService } from './academicCalendar.service';
import { AuthenticatedUser } from '../types/auth.types';
import { AppRole } from '../constants/roles';
import { CollegeStatus, TimetableStatus, TimetableDay } from '../constants/status';
import { Timetable } from '../models/timetable.model';
import { ApiError } from '../utils/apiError';
import { logger } from '../utils/logger';
import {
  HomeDashboardDTO,
  DashboardGreeting,
  DashboardAlert,
  DashboardUpcomingItem,
  DashboardPendingAction,
  DashboardRecentActivity,
  DashboardQuickAction,
  StudentDashboardContext,
  StudentDashboardSummary,
  FacultyDashboardContext,
  FacultyDashboardSummary,
  HodDashboardContext,
  HodDashboardSummary,
  CollegeAdminDashboardContext,
  CollegeAdminDashboardSummary,
  SuperAdminDashboardContext,
  SuperAdminDashboardSummary,
} from '../types/dashboard.types';

export class DashboardService {
  /**
   * Primary entry point for role-aware home dashboard aggregation.
   * Answers: "What matters to me right now?"
   */
  static async getHomeDashboard(
    requester: AuthenticatedUser,
    query?: { date?: string }
  ): Promise<HomeDashboardDTO> {
    const user = await User.findById(requester.id).lean();
    if (!user) {
      throw ApiError.unauthorized('Authenticated user document not found');
    }

    const collegeId = requester.collegeId ? requester.collegeId.toString() : '';
    if (requester.role !== AppRole.SUPER_ADMIN && !collegeId) {
      throw ApiError.badRequest('Tenant college ID is required for role dashboard');
    }

    const greeting = this.buildGreeting(user.name, requester.role, user.profilePictureUrl);

    switch (requester.role) {
      case AppRole.STUDENT:
        return this.buildStudentDashboard(requester, user, collegeId, greeting, query?.date);
      case AppRole.FACULTY:
        return this.buildFacultyDashboard(requester, user, collegeId, greeting, query?.date);
      case AppRole.HOD:
        return this.buildHodDashboard(requester, user, collegeId, greeting, query?.date);
      case AppRole.COLLEGE_ADMIN:
        return this.buildCollegeAdminDashboard(requester, user, collegeId, greeting, query?.date);
      case AppRole.SUPER_ADMIN:
        return this.buildSuperAdminDashboard(requester, user, greeting);
      default:
        throw ApiError.forbidden(`Unsupported role ${requester.role} for home dashboard`);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 1. GREETING BUILDER
  // ─────────────────────────────────────────────────────────────────────────────
  private static buildGreeting(
    name: string,
    role: AppRole,
    avatarUrl?: string | null
  ): DashboardGreeting {
    const hour = new Date().getHours();
    let greetingText = 'Good evening';
    if (hour >= 5 && hour < 12) {
      greetingText = 'Good morning';
    } else if (hour >= 12 && hour < 17) {
      greetingText = 'Good afternoon';
    }

    return {
      displayName: name,
      role,
      avatarUrl: avatarUrl || null,
      greetingText,
    };
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 2. STUDENT DASHBOARD
  // ─────────────────────────────────────────────────────────────────────────────
  private static async buildStudentDashboard(
    requester: AuthenticatedUser,
    user: any,
    collegeId: string,
    greeting: DashboardGreeting,
    customDate?: string
  ): Promise<HomeDashboardDTO> {
    const student = await Student.findOne({ userId: user._id, collegeId }).lean();
    const studentId = student?._id;

    // 1. Current Enrollment Context
    let enrollmentContext: StudentDashboardContext = {
      isEnrollmentAvailable: false,
    };

    let activeEnrollment: any = null;
    if (studentId) {
      activeEnrollment = await StudentEnrollment.findOne({
        studentId,
        collegeId,
        status: { $in: ['active', 'ACTIVE'] },
      })
        .populate('courseId academicYearId semesterId sectionId')
        .lean();

      if (activeEnrollment) {
        enrollmentContext = {
          isEnrollmentAvailable: true,
          enrollmentId: activeEnrollment._id.toString(),
          courseId: activeEnrollment.courseId?._id?.toString() || null,
          courseName: activeEnrollment.courseId?.name || null,
          courseCode: activeEnrollment.courseId?.code || null,
          semesterId: activeEnrollment.semesterId?._id?.toString() || null,
          semesterName: activeEnrollment.semesterId?.name || null,
          semesterNumber: activeEnrollment.semesterId?.number ?? activeEnrollment.semesterId?.semesterNumber ?? null,
          sectionId: activeEnrollment.sectionId?._id?.toString() || null,
          sectionName: activeEnrollment.sectionId?.name || null,
          academicStage: activeEnrollment.academicStage || student.academicStage || null,
          rollNumber: student.rollNumber || null,
        };
      }
    }

    // 2. Parallel Metrics Gathering (Bounded, Protected, Non-blocking)
    const [
      attendanceSummary,
      assignmentsMetrics,
      practicalsMetrics,
      publishedAssessmentsCount,
      resultInfo,
      unreadNotificationCount,
      pendingRequestsCount,
      recentRequests,
      announcements,
      upcomingCalendar,
    ] = await Promise.all([
      this.getStudentAttendanceSummary(studentId, collegeId),
      this.getStudentAssignmentsMetrics(studentId, collegeId, enrollmentContext),
      this.getStudentPracticalsMetrics(studentId, collegeId),
      this.getStudentAssessmentsCount(collegeId, enrollmentContext),
      this.getStudentLatestResultInfo(studentId, collegeId),
      Notification.countDocuments({
        recipientUserId: requester.id,
        isRead: false,
      }),
      RequestModel.countDocuments({
        requesterUserId: requester.id,
        collegeId: new mongoose.Types.ObjectId(collegeId),
        status: { $in: [RequestStatus.SUBMITTED, RequestStatus.RECEIVED, RequestStatus.IN_REVIEW, RequestStatus.UNDER_REVIEW] },
      }),
      RequestModel.find({
        requesterUserId: new mongoose.Types.ObjectId(requester.id),
        collegeId: new mongoose.Types.ObjectId(collegeId),
      })
        .sort({ createdAt: -1 })
        .limit(3)
        .lean(),
      this.getRecentAnnouncements(collegeId, AppRole.STUDENT, 3),
      this.getStudentUpcomingSchedule(collegeId, activeEnrollment, requester, customDate, 4),
    ]);

    const summary: StudentDashboardSummary = {
      attendancePercentage: attendanceSummary.percentage,
      assignmentsCompleted: assignmentsMetrics.completed,
      assignmentsPending: assignmentsMetrics.pending,
      practicalsCompleted: practicalsMetrics.completed,
      practicalsScheduled: practicalsMetrics.scheduled,
      publishedAssessmentsCount,
      latestResultStatus: resultInfo.status,
    };

    // 3. Alerts Construction
    const alerts: DashboardAlert[] = [];
    if (attendanceSummary.percentage !== null && attendanceSummary.percentage < 75) {
      alerts.push({
        id: 'alert_low_attendance',
        type: 'ATTENDANCE_WARNING',
        severity: 'WARNING',
        title: 'Attendance Notice',
        message: `Your current attendance is ${attendanceSummary.percentage.toFixed(1)}%. Maintain at least 75% for exam eligibility.`,
        route: '/attendance',
      });
    }

    if (unreadNotificationCount > 0) {
      alerts.push({
        id: 'unread_notifications',
        type: 'UNREAD_NOTIFICATIONS',
        severity: 'INFO',
        title: 'New Notifications',
        message: `You have ${unreadNotificationCount} unread notification${unreadNotificationCount > 1 ? 's' : ''}.`,
        route: '/notifications',
      });
    }

    if (!enrollmentContext.isEnrollmentAvailable) {
      alerts.push({
        id: 'alert_no_enrollment',
        type: 'ENROLLMENT_UNAVAILABLE',
        severity: 'INFO',
        title: 'Academic Context Notice',
        message: 'Your current academic enrollment is not available. Contact administration.',
        route: '/profile',
      });
    }

    // 4. Pending Actions Construction
    const pendingActions: DashboardPendingAction[] = [];
    if (assignmentsMetrics.dueSoon) {
      pendingActions.push({
        id: `action_asgn_${assignmentsMetrics.dueSoon._id}`,
        type: 'ASSIGNMENT_DUE',
        priority: 'HIGH',
        title: assignmentsMetrics.dueSoon.title,
        description: `Due on ${new Date(assignmentsMetrics.dueSoon.dueDateTime).toLocaleDateString()}`,
        deadline: new Date(assignmentsMetrics.dueSoon.dueDateTime).toISOString(),
        route: `/assignments`,
        actionLabel: 'View Assignment',
      });
    }

    if (pendingRequestsCount > 0) {
      pendingActions.push({
        id: 'action_my_requests',
        type: 'REQUEST_ACTION',
        priority: 'LOW',
        title: 'Active Requests',
        description: `You have ${pendingRequestsCount} pending request(s) under review.`,
        route: '/requests',
        actionLabel: 'View Requests',
      });
    }

    // 5. Recent Activity
    const recent: DashboardRecentActivity[] = announcements.map((a: any) => ({
      id: a._id.toString(),
      type: 'ANNOUNCEMENT',
      title: a.title,
      description: a.body.length > 80 ? `${a.body.substring(0, 80)}...` : a.body,
      timestamp: (a.publishedAt || a.createdAt).toISOString(),
      route: '/announcements',
    }));

    for (const req of recentRequests) {
      recent.push({
        id: req._id.toString(),
        type: 'REQUEST',
        title: req.title,
        description: `Status: ${req.status}`,
        timestamp: (req.updatedAt || req.createdAt).toISOString(),
        route: `/requests`,
      });
    }

    if (resultInfo.result) {
      recent.push({
        id: `res_${resultInfo.result._id}`,
        type: 'RESULT',
        title: `Official Result Published`,
        description: `Overall: ${resultInfo.result.summary?.overallResult || 'Published'}`,
        timestamp: (resultInfo.result.publishedAt || resultInfo.result.updatedAt).toISOString(),
        route: '/academic-results',
      });
    }

    // 6. Role Quick Actions
    const quickActions: DashboardQuickAction[] = [
      { id: 'qa_attendance', label: 'Attendance', icon: 'checkSquare', route: '/attendance', isPrimary: true },
      { id: 'qa_assignments', label: 'Assignments', icon: 'fileSpreadsheet', route: '/assignments', badgeCount: assignmentsMetrics.pending },
      { id: 'qa_practicals', label: 'Practicals', icon: 'flaskConical', route: '/practicals' },
      { id: 'qa_assessments', label: 'Assessments', icon: 'penTool', route: '/assessments' },
      { id: 'qa_results', label: 'Official Results', icon: 'award', route: '/academic-results' },
      { id: 'qa_academic_records', label: 'Academic Records', icon: 'fileText', route: '/academic-records/history' },
      { id: 'qa_calendar', label: 'Calendar', icon: 'calendarDays', route: '/calendar' },
      { id: 'qa_requests', label: 'Requests', icon: 'inbox', route: '/requests', badgeCount: pendingRequestsCount },
      { id: 'qa_notifications', label: 'Notifications', icon: 'bell', route: '/notifications', badgeCount: unreadNotificationCount },
    ];

    return {
      role: AppRole.STUDENT,
      greeting,
      context: enrollmentContext,
      summary,
      alerts,
      upcoming: upcomingCalendar,
      pendingActions,
      recent,
      quickActions,
    };
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 3. FACULTY DASHBOARD
  // ─────────────────────────────────────────────────────────────────────────────
  private static async buildFacultyDashboard(
    requester: AuthenticatedUser,
    user: any,
    collegeId: string,
    greeting: DashboardGreeting,
    customDate?: string
  ): Promise<HomeDashboardDTO> {
    const faculty = await Faculty.findOne({ userId: user._id, collegeId })
      .populate('departmentId')
      .lean();
    const facultyId = faculty?._id;

    const activeAssignments = facultyId
      ? await FacultyAssignment.find({
          facultyId,
          collegeId,
          $or: [{ status: { $in: ['active', 'ACTIVE'] } }, { isActive: true }],
        }).lean()
      : [];

    const context: FacultyDashboardContext = {
      facultyId: facultyId ? facultyId.toString() : null,
      departmentId: (faculty?.departmentId as any)?._id?.toString() || null,
      departmentName: (faculty?.departmentId as any)?.name || null,
      designation: faculty?.designation || null,
      employeeId: faculty?.employeeId || null,
      activeTeachingAssignmentsCount: activeAssignments.length,
    };

    const createdAssignmentIds = facultyId
      ? await Assignment.find({
          collegeId: new mongoose.Types.ObjectId(collegeId),
          $or: [{ facultyId }, { createdBy: user._id }],
        }).distinct('_id')
      : [];

    // Parallel metric queries
    const today = new Date();
    const todayStart = new Date(today.getFullYear(), today.getMonth(), today.getDate(), 0, 0, 0, 0);
    const todayEnd = new Date(today.getFullYear(), today.getMonth(), today.getDate(), 23, 59, 59, 999);

    const [
      pendingAttendanceSessions,
      submissionsAwaitingReview,
      pendingAssessmentMarks,
      openPracticalsCount,
      incomingRequestsCount,
      unreadNotificationCount,
      announcements,
      upcomingCalendar,
    ] = await Promise.all([
      facultyId
        ? AttendanceSession.countDocuments({
            facultyId,
            collegeId,
            date: { $gte: todayStart, $lte: todayEnd },
            status: { $in: ['SCHEDULED', 'IN_PROGRESS'] },
          })
        : 0,
      createdAssignmentIds.length > 0
        ? AssignmentSubmission.countDocuments({
            collegeId: new mongoose.Types.ObjectId(collegeId),
            assignmentId: { $in: createdAssignmentIds },
            status: { $in: ['SUBMITTED', 'RESUBMITTED'] },
            reviewStatus: { $ne: FacultyReviewStatus.REVIEWED },
          })
        : 0,
      facultyId
        ? InternalAssessment.countDocuments({
            collegeId,
            facultyId,
            status: { $in: [AssessmentStatus.DRAFT, AssessmentStatus.OPEN] },
          })
        : 0,
      facultyId
        ? PracticalSession.countDocuments({
            collegeId,
            facultyId,
            status: { $in: ['SCHEDULED', 'IN_PROGRESS'] },
          })
        : 0,
      RequestModel.countDocuments({
        collegeId: new mongoose.Types.ObjectId(collegeId),
        assignedToUserId: requester.id,
        status: { $in: [RequestStatus.SUBMITTED, RequestStatus.RECEIVED, RequestStatus.IN_REVIEW, RequestStatus.UNDER_REVIEW] },
      }),
      Notification.countDocuments({
        recipientUserId: requester.id,
        isRead: false,
      }),
      this.getRecentAnnouncements(collegeId, AppRole.FACULTY, 3),
      this.getUpcomingCalendarEvents(requester, customDate, 4),
    ]);

    const summary: FacultyDashboardSummary = {
      assignedClassesCount: activeAssignments.length,
      pendingAttendanceSessions,
      submissionsAwaitingReview,
      pendingAssessmentMarks,
      openPracticalsCount,
    };

    // Alerts
    const alerts: DashboardAlert[] = [];
    if (pendingAttendanceSessions > 0) {
      alerts.push({
        id: 'alert_pending_attendance',
        type: 'ATTENDANCE_PENDING',
        severity: 'WARNING',
        title: 'Pending Class Attendance',
        message: `You have ${pendingAttendanceSessions} class session(s) today awaiting attendance completion.`,
        route: '/attendance',
      });
    }

    if (submissionsAwaitingReview > 0) {
      alerts.push({
        id: 'alert_submissions_review',
        type: 'SUBMISSIONS_PENDING',
        severity: 'INFO',
        title: 'Submissions to Grade',
        message: `${submissionsAwaitingReview} student submission(s) require evaluation.`,
        route: '/assignments',
      });
    }

    // Pending Actions
    const pendingActions: DashboardPendingAction[] = [];
    if (pendingAttendanceSessions > 0) {
      pendingActions.push({
        id: 'action_take_attendance',
        type: 'TAKE_ATTENDANCE',
        priority: 'HIGH',
        title: 'Mark Today Attendance',
        description: 'Complete attendance register for scheduled lectures.',
        route: '/attendance',
        actionLabel: 'Mark Attendance',
      });
    }

    if (submissionsAwaitingReview > 0) {
      pendingActions.push({
        id: 'action_review_submissions',
        type: 'REVIEW_SUBMISSION',
        priority: 'MEDIUM',
        title: 'Review Assignments',
        description: `${submissionsAwaitingReview} submissions waiting for marks.`,
        route: '/assignments',
        actionLabel: 'Review',
      });
    }

    if (pendingAssessmentMarks > 0) {
      pendingActions.push({
        id: 'action_enter_marks',
        type: 'ENTER_MARKS',
        priority: 'MEDIUM',
        title: 'Assessment Marks Entry',
        description: `${pendingAssessmentMarks} internal assessment(s) open for score entry.`,
        route: '/assessments',
        actionLabel: 'Enter Marks',
      });
    }

    if (incomingRequestsCount > 0) {
      pendingActions.push({
        id: 'action_incoming_requests',
        type: 'REQUEST_ACTION',
        priority: 'HIGH',
        title: 'Student Requests Action',
        description: `${incomingRequestsCount} incoming request(s) awaiting your decision.`,
        route: '/requests',
        actionLabel: 'View Requests',
      });
    }

    // Recent Activity
    const recent: DashboardRecentActivity[] = announcements.map((a: any) => ({
      id: a._id.toString(),
      type: 'ANNOUNCEMENT',
      title: a.title,
      description: a.body.length > 80 ? `${a.body.substring(0, 80)}...` : a.body,
      timestamp: (a.publishedAt || a.createdAt).toISOString(),
      route: '/announcements',
    }));

    // Quick Actions
    const quickActions: DashboardQuickAction[] = [
      { id: 'qa_mark_attendance', label: 'Mark Attendance', icon: 'checkSquare', route: '/attendance', isPrimary: true },
      { id: 'qa_assignments', label: 'Assignments', icon: 'fileSpreadsheet', route: '/assignments', badgeCount: submissionsAwaitingReview },
      { id: 'qa_practicals', label: 'Practicals', icon: 'flaskConical', route: '/practicals', badgeCount: openPracticalsCount },
      { id: 'qa_assessments', label: 'Assessments', icon: 'penTool', route: '/assessments', badgeCount: pendingAssessmentMarks },
      { id: 'qa_timetable', label: 'Timetable', icon: 'calendar', route: '/timetable' },
      { id: 'qa_calendar', label: 'Calendar', icon: 'calendarDays', route: '/calendar' },
      { id: 'qa_requests', label: 'Requests', icon: 'inbox', route: '/requests', badgeCount: incomingRequestsCount },
      { id: 'qa_notifications', label: 'Notifications', icon: 'bell', route: '/notifications', badgeCount: unreadNotificationCount },
    ];

    return {
      role: AppRole.FACULTY,
      greeting,
      context,
      summary,
      alerts,
      upcoming: upcomingCalendar,
      pendingActions,
      recent,
      quickActions,
    };
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 4. HOD DASHBOARD
  // ─────────────────────────────────────────────────────────────────────────────
  private static async buildHodDashboard(
    requester: AuthenticatedUser,
    user: any,
    collegeId: string,
    greeting: DashboardGreeting,
    customDate?: string
  ): Promise<HomeDashboardDTO> {
    // Resolve HOD department strictly
    const faculty = await Faculty.findOne({ userId: user._id, collegeId }).lean();
    let department = faculty?._id
      ? await Department.findOne({ collegeId, hodId: faculty._id }).lean()
      : null;

    if (!department && faculty?.departmentId) {
      department = await Department.findOne({ collegeId, _id: faculty.departmentId }).lean();
    }

    if (!department && (user.departmentId || requester.departmentId)) {
      department = await Department.findOne({
        collegeId,
        _id: user.departmentId || requester.departmentId,
      }).lean();
    }

    if (!department) {
      throw ApiError.badRequest('No department leadership assignment found for this HOD');
    }

    const departmentId = department._id;

    const context: HodDashboardContext = {
      departmentId: departmentId.toString(),
      departmentName: department.name,
      departmentCode: department.code,
      designation: faculty?.designation || 'Head of Department',
      managedScope: 'Department Academic & Faculty Operations',
    };

    const today = new Date();
    const todayStart = new Date(today.getFullYear(), today.getMonth(), today.getDate(), 0, 0, 0, 0);
    const todayEnd = new Date(today.getFullYear(), today.getMonth(), today.getDate(), 23, 59, 59, 999);

    const [
      activeFacultyCount,
      activeStudentsCount,
      todayClassesCount,
      pendingDepartmentRequests,
      pendingAssessmentsCount,
      pendingAttendanceCount,
      unreadNotificationCount,
      announcements,
      upcomingCalendar,
    ] = await Promise.all([
      Faculty.countDocuments({ collegeId, departmentId }),
      Student.countDocuments({ collegeId, departmentId }),
      AttendanceSession.countDocuments({
        collegeId,
        departmentId,
        date: { $gte: todayStart, $lte: todayEnd },
      }),
      RequestModel.countDocuments({
        collegeId: new mongoose.Types.ObjectId(collegeId),
        departmentId,
        status: { $in: [RequestStatus.SUBMITTED, RequestStatus.RECEIVED, RequestStatus.IN_REVIEW, RequestStatus.UNDER_REVIEW] },
      }),
      InternalAssessment.countDocuments({
        collegeId,
        departmentId,
        status: { $in: [AssessmentStatus.CLOSED, AssessmentStatus.REVIEWED] },
      }),
      AttendanceSession.countDocuments({
        collegeId,
        departmentId,
        date: { $gte: todayStart, $lte: todayEnd },
        status: { $in: ['SCHEDULED', 'IN_PROGRESS'] },
      }),
      Notification.countDocuments({
        recipientUserId: requester.id,
        isRead: false,
      }),
      this.getRecentAnnouncements(collegeId, AppRole.HOD, 3),
      this.getUpcomingCalendarEvents(requester, customDate, 4),
    ]);

    const summary: HodDashboardSummary = {
      activeFacultyCount,
      activeStudentsCount,
      todayClassesCount,
      pendingDepartmentRequests,
      pendingAssessmentsCount,
      pendingAttendanceCount,
    };

    const alerts: DashboardAlert[] = [];
    if (pendingAttendanceCount > 0) {
      alerts.push({
        id: 'alert_hod_attendance',
        type: 'ATTENDANCE_OVERSIGHT',
        severity: 'INFO',
        title: 'Department Attendance Status',
        message: `${pendingAttendanceCount} lecture(s) pending attendance completion today.`,
        route: '/attendance',
      });
    }

    if (pendingAssessmentsCount > 0) {
      alerts.push({
        id: 'alert_hod_assessments',
        type: 'ASSESSMENT_REVIEW',
        severity: 'WARNING',
        title: 'Assessments Ready for Review',
        message: `${pendingAssessmentsCount} assessment(s) awaiting HOD sign-off for publication.`,
        route: '/assessments',
      });
    }

    const pendingActions: DashboardPendingAction[] = [];
    if (pendingDepartmentRequests > 0) {
      pendingActions.push({
        id: 'action_hod_requests',
        type: 'REQUEST_ACTION',
        priority: 'HIGH',
        title: 'Pending Department Requests',
        description: `${pendingDepartmentRequests} request(s) require departmental approval.`,
        route: '/requests',
        actionLabel: 'Approve / Review',
      });
    }

    if (pendingAssessmentsCount > 0) {
      pendingActions.push({
        id: 'action_hod_publish_assessments',
        type: 'ENTER_MARKS',
        priority: 'MEDIUM',
        title: 'Review Internal Assessments',
        description: `${pendingAssessmentsCount} assessment(s) submitted for publication.`,
        route: '/assessments',
        actionLabel: 'Review Assessments',
      });
    }

    const recent: DashboardRecentActivity[] = announcements.map((a: any) => ({
      id: a._id.toString(),
      type: 'ANNOUNCEMENT',
      title: a.title,
      description: a.body.length > 80 ? `${a.body.substring(0, 80)}...` : a.body,
      timestamp: (a.publishedAt || a.createdAt).toISOString(),
      route: '/announcements',
    }));

    const quickActions: DashboardQuickAction[] = [
      { id: 'qa_timetable', label: 'Department Timetable', icon: 'calendar', route: '/timetable', isPrimary: true },
      { id: 'qa_attendance', label: 'Attendance Oversight', icon: 'checkSquare', route: '/attendance', badgeCount: pendingAttendanceCount },
      { id: 'qa_assessments', label: 'Assessments', icon: 'penTool', route: '/assessments', badgeCount: pendingAssessmentsCount },
      { id: 'qa_requests', label: 'Requests', icon: 'inbox', route: '/requests', badgeCount: pendingDepartmentRequests },
      { id: 'qa_announcements', label: 'Announcements', icon: 'megaphone', route: '/announcements' },
      { id: 'qa_calendar', label: 'Academic Calendar', icon: 'calendarDays', route: '/calendar' },
      { id: 'qa_notifications', label: 'Notifications', icon: 'bell', route: '/notifications', badgeCount: unreadNotificationCount },
    ];

    return {
      role: AppRole.HOD,
      greeting,
      context,
      summary,
      alerts,
      upcoming: upcomingCalendar,
      pendingActions,
      recent,
      quickActions,
    };
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 5. COLLEGE ADMIN DASHBOARD
  // ─────────────────────────────────────────────────────────────────────────────
  private static async buildCollegeAdminDashboard(
    requester: AuthenticatedUser,
    _user: any,
    collegeId: string,
    greeting: DashboardGreeting,
    customDate?: string
  ): Promise<HomeDashboardDTO> {
    const college = await College.findById(collegeId).lean();
    if (!college) {
      throw ApiError.badRequest('College record not found');
    }

    const context: CollegeAdminDashboardContext = {
      collegeId,
      collegeName: college.name,
      collegeCode: college.code || 'AIT',
      administrativeScope: 'Tenant Institution Operations',
    };

    const [
      departmentsCount,
      facultyCount,
      studentsCount,
      pendingRequestsCount,
      activeAnnouncementsCount,
      activeAcademicYearsCount,
      unreadNotificationCount,
      announcements,
      upcomingCalendar,
    ] = await Promise.all([
      Department.countDocuments({ collegeId }),
      Faculty.countDocuments({ collegeId }),
      Student.countDocuments({ collegeId }),
      RequestModel.countDocuments({
        collegeId: new mongoose.Types.ObjectId(collegeId),
        status: { $in: [RequestStatus.SUBMITTED, RequestStatus.RECEIVED, RequestStatus.IN_REVIEW, RequestStatus.UNDER_REVIEW] },
      }),
      Announcement.countDocuments({ collegeId, status: 'PUBLISHED' }),
      AcademicYear.countDocuments({ collegeId, status: 'ACTIVE' }),
      Notification.countDocuments({
        recipientUserId: requester.id,
        isRead: false,
      }),
      this.getRecentAnnouncements(collegeId, AppRole.COLLEGE_ADMIN, 3),
      this.getUpcomingCalendarEvents(requester, customDate, 4),
    ]);

    const summary: CollegeAdminDashboardSummary = {
      departmentsCount,
      facultyCount,
      studentsCount,
      pendingRequestsCount,
      activeAnnouncementsCount,
      activeAcademicYearsCount,
    };

    const alerts: DashboardAlert[] = [];
    if (pendingRequestsCount > 0) {
      alerts.push({
        id: 'alert_admin_requests',
        type: 'PENDING_REQUESTS',
        severity: 'INFO',
        title: 'Institutional Requests',
        message: `${pendingRequestsCount} administrative request(s) awaiting college action.`,
        route: '/requests',
      });
    }

    const pendingActions: DashboardPendingAction[] = [];
    if (pendingRequestsCount > 0) {
      pendingActions.push({
        id: 'action_admin_requests',
        type: 'REQUEST_ACTION',
        priority: 'HIGH',
        title: 'Action Institutional Requests',
        description: `Manage pending leave, certificate, or administrative requests.`,
        route: '/requests',
        actionLabel: 'Manage Requests',
      });
    }

    const recent: DashboardRecentActivity[] = announcements.map((a: any) => ({
      id: a._id.toString(),
      type: 'ANNOUNCEMENT',
      title: a.title,
      description: a.body.length > 80 ? `${a.body.substring(0, 80)}...` : a.body,
      timestamp: (a.publishedAt || a.createdAt).toISOString(),
      route: '/announcements',
    }));

    const quickActions: DashboardQuickAction[] = [
      { id: 'qa_students', label: 'Students', icon: 'graduationCap', route: '/academics/students', isPrimary: true },
      { id: 'qa_faculty', label: 'Faculty', icon: 'users', route: '/academics/faculty' },
      { id: 'qa_departments', label: 'Departments', icon: 'layers', route: '/academics/departments' },
      { id: 'qa_timetables', label: 'Timetables', icon: 'calendar', route: '/timetables' },
      { id: 'qa_assessments', label: 'Assessments', icon: 'penTool', route: '/assessments' },
      { id: 'qa_results', label: 'Academic Results', icon: 'award', route: '/academic-results' },
      { id: 'qa_requests', label: 'Requests', icon: 'inbox', route: '/requests', badgeCount: pendingRequestsCount },
      { id: 'qa_announcements', label: 'Announcements', icon: 'megaphone', route: '/announcements' },
      { id: 'qa_notifications', label: 'Notifications', icon: 'bell', route: '/notifications', badgeCount: unreadNotificationCount },
    ];

    return {
      role: AppRole.COLLEGE_ADMIN,
      greeting,
      context,
      summary,
      alerts,
      upcoming: upcomingCalendar,
      pendingActions,
      recent,
      quickActions,
    };
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 6. SUPER ADMIN DASHBOARD
  // ─────────────────────────────────────────────────────────────────────────────
  private static async buildSuperAdminDashboard(
    requester: AuthenticatedUser,
    _user: any,
    greeting: DashboardGreeting
  ): Promise<HomeDashboardDTO> {
    const context: SuperAdminDashboardContext = {
      scope: 'GLOBAL',
    };

    const [collegesCount, usersCount, activeCollegesCount, unreadNotificationCount] = await Promise.all([
      College.countDocuments(),
      User.countDocuments(),
      College.countDocuments({ status: CollegeStatus.ACTIVE }),
      Notification.countDocuments({
        recipientUserId: requester.id,
        isRead: false,
      }),
    ]);

    const summary: SuperAdminDashboardSummary = {
      collegesCount,
      usersCount,
      activeCollegesCount,
      systemStatus: 'OPERATIONAL',
    };

    const alerts: DashboardAlert[] = [
      {
        id: 'alert_super_admin_status',
        type: 'PLATFORM_STATUS',
        severity: 'INFO',
        title: 'Platform Healthy',
        message: `All multi-tenant nodes operational across ${activeCollegesCount} active colleges.`,
      },
    ];

    const pendingActions: DashboardPendingAction[] = [];

    const recent: DashboardRecentActivity[] = [
      {
        id: 'act_platform_audit',
        type: 'REQUEST',
        title: 'System Maintenance Window',
        description: 'Scheduled backup and background sync jobs active.',
        timestamp: new Date().toISOString(),
        route: '/audit',
      },
    ];

    const quickActions: DashboardQuickAction[] = [
      { id: 'qa_colleges', label: 'Colleges', icon: 'building', route: '/academics/colleges', isPrimary: true },
      { id: 'qa_users', label: 'Users', icon: 'userCheck', route: '/users' },
      { id: 'qa_audit', label: 'Audit Logs', icon: 'fileText', route: '/audit' },
      { id: 'qa_settings', label: 'Platform Settings', icon: 'settings', route: '/settings' },
      { id: 'qa_notifications', label: 'Notifications', icon: 'bell', route: '/notifications', badgeCount: unreadNotificationCount },
    ];

    return {
      role: AppRole.SUPER_ADMIN,
      greeting,
      context,
      summary,
      alerts,
      upcoming: [],
      pendingActions,
      recent,
      quickActions,
    };
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 7. SHARED COMPACT SUB-AGGREGATIONS (Bounded, Safe & Degradable)
  // ─────────────────────────────────────────────────────────────────────────────

  private static async getStudentAttendanceSummary(
    studentId: any,
    collegeId: string
  ): Promise<{ percentage: number | null }> {
    if (!studentId) return { percentage: null };

    try {
      const records = await AttendanceRecord.aggregate([
        {
          $match: {
            studentId: new mongoose.Types.ObjectId(studentId.toString()),
            collegeId: new mongoose.Types.ObjectId(collegeId),
          },
        },
        {
          $group: {
            _id: null,
            total: { $sum: 1 },
            present: {
              $sum: {
                $cond: [{ $in: ['$status', ['PRESENT', 'LATE', 'present', 'late']] }, 1, 0],
              },
            },
          },
        },
      ]);

      if (records.length === 0 || records[0].total === 0) {
        return { percentage: null };
      }

      const pct = (records[0].present / records[0].total) * 100;
      return { percentage: Math.round(pct * 10) / 10 };
    } catch (err) {
      logger.warn(`Failed to aggregate student attendance summary: ${err}`);
      return { percentage: null };
    }
  }

  private static async getStudentAssignmentsMetrics(
    studentId: any,
    collegeId: string,
    enrollment: StudentDashboardContext
  ): Promise<{ completed: number; pending: number; dueSoon: any }> {
    if (!studentId || !enrollment.isEnrollmentAvailable || !enrollment.courseId || !enrollment.semesterId) {
      return { completed: 0, pending: 0, dueSoon: null };
    }

    try {
      const courseId = new mongoose.Types.ObjectId(enrollment.courseId);
      const semesterId = new mongoose.Types.ObjectId(enrollment.semesterId);

      const [publishedAssignments, submissions] = await Promise.all([
        Assignment.find({
          collegeId: new mongoose.Types.ObjectId(collegeId),
          courseId,
          semesterId,
          status: 'PUBLISHED',
        })
          .sort({ dueDateTime: 1 })
          .lean(),
        AssignmentSubmission.find({
          collegeId: new mongoose.Types.ObjectId(collegeId),
          studentId: new mongoose.Types.ObjectId(studentId.toString()),
        }).lean(),
      ]);

      const submittedAssignmentIds = new Set(
        submissions.map((s) => s.assignmentId.toString())
      );

      let pending = 0;
      let completed = 0;
      let dueSoon: any = null;
      const now = new Date();

      for (const asgn of publishedAssignments) {
        if (submittedAssignmentIds.has(asgn._id.toString())) {
          completed++;
        } else {
          pending++;
          if (!dueSoon && new Date(asgn.dueDateTime) >= now) {
            dueSoon = asgn;
          }
        }
      }

      return { completed, pending, dueSoon };
    } catch (err) {
      logger.warn(`Failed to compute student assignments metrics: ${err}`);
      return { completed: 0, pending: 0, dueSoon: null };
    }
  }

  private static async getStudentPracticalsMetrics(
    studentId: any,
    collegeId: string
  ): Promise<{ completed: number; scheduled: number }> {
    if (!studentId) return { completed: 0, scheduled: 0 };

    try {
      const agg = await PracticalParticipation.aggregate([
        {
          $match: {
            studentId: new mongoose.Types.ObjectId(studentId.toString()),
            collegeId: new mongoose.Types.ObjectId(collegeId),
          },
        },
        {
          $group: {
            _id: null,
            completed: {
              $sum: { $cond: [{ $eq: ['$status', 'COMPLETED'] }, 1, 0] },
            },
            scheduled: {
              $sum: { $cond: [{ $in: ['$status', ['SCHEDULED', 'REGISTERED', 'IN_PROGRESS']] }, 1, 0] },
            },
          },
        },
      ]);

      if (agg.length === 0) return { completed: 0, scheduled: 0 };
      return { completed: agg[0].completed, scheduled: agg[0].scheduled };
    } catch (err) {
      logger.warn(`Failed to compute student practicals metrics: ${err}`);
      return { completed: 0, scheduled: 0 };
    }
  }

  private static async getStudentAssessmentsCount(
    collegeId: string,
    enrollment: StudentDashboardContext
  ): Promise<number> {
    if (!enrollment.isEnrollmentAvailable || !enrollment.courseId || !enrollment.semesterId) {
      return 0;
    }

    try {
      return await InternalAssessment.countDocuments({
        collegeId: new mongoose.Types.ObjectId(collegeId),
        courseId: new mongoose.Types.ObjectId(enrollment.courseId),
        semesterId: new mongoose.Types.ObjectId(enrollment.semesterId),
        status: AssessmentStatus.PUBLISHED, // NEVER unpublished!
      });
    } catch (err) {
      logger.warn(`Failed to count published student assessments: ${err}`);
      return 0;
    }
  }

  private static async getStudentLatestResultInfo(
    studentId: any,
    collegeId: string
  ): Promise<{ status: string; result: any | null }> {
    if (!studentId) return { status: 'NOT_AVAILABLE', result: null };

    try {
      const anyResult = await AcademicResult.findOne({
        studentId: new mongoose.Types.ObjectId(studentId.toString()),
        collegeId: new mongoose.Types.ObjectId(collegeId),
      })
        .sort({ createdAt: -1 })
        .lean();

      if (!anyResult) {
        return { status: 'NOT_AVAILABLE', result: null };
      }

      if (anyResult.status === ResultLifecycleStatus.PUBLISHED) {
        return { status: 'AVAILABLE', result: anyResult };
      }

      return { status: 'NOT_YET_PUBLISHED', result: null };
    } catch (err) {
      logger.warn(`Failed to fetch student result info: ${err}`);
      return { status: 'NOT_AVAILABLE', result: null };
    }
  }

  private static async getRecentAnnouncements(
    collegeId: string,
    role: AppRole,
    limit: number = 3
  ): Promise<any[]> {
    try {
      return await Announcement.find({
        collegeId: new mongoose.Types.ObjectId(collegeId),
        status: { $in: ['PUBLISHED', 'published'] },
        $or: [
          { audienceScope: { $in: ['ALL', 'COLLEGE'] } },
          { audienceScope: 'ROLE', targetRole: role },
        ],
      })
        .sort({ isPinned: -1, publishedAt: -1, createdAt: -1 })
        .limit(limit)
        .lean();
    } catch (err) {
      logger.warn(`Failed to fetch announcements for dashboard: ${err}`);
      return [];
    }
  }

  private static async getUpcomingCalendarEvents(
    requester: AuthenticatedUser,
    customDate?: string,
    limit: number = 4
  ): Promise<DashboardUpcomingItem[]> {
    try {
      const now = customDate ? new Date(customDate) : new Date();
      const startDate = now.toISOString().split('T')[0];
      const future = new Date(now);
      future.setDate(future.getDate() + 3);
      const endDate = future.toISOString().split('T')[0];

      const events = await AcademicCalendarService.getCalendarForUser(requester, {
        startDate,
        endDate,
      });

      return events.slice(0, limit).map((evt) => {
        let type: 'CLASS' | 'PRACTICAL' | 'ASSESSMENT' | 'EVENT' | 'HOLIDAY' = 'EVENT';
        if (evt.eventType === 'HOLIDAY') type = 'HOLIDAY';
        else if (evt.eventType === 'EXAM' || evt.sourceType === 'ASSESSMENT') type = 'ASSESSMENT';
        else if (evt.sourceType === 'PRACTICAL') type = 'PRACTICAL';
        else if (evt.sourceType === 'TIMETABLE') type = 'CLASS';

        return {
          id: evt.id,
          type,
          title: evt.title,
          subtitle: evt.description || undefined,
          startTime: `${evt.startDate}T${evt.startTime || '00:00:00'}Z`,
          endTime: `${evt.endDate}T${evt.endTime || '23:59:59'}Z`,
          location: (evt as any).metadata?.roomNumber ? `Room ${(evt as any).metadata.roomNumber}` : undefined,
          route: type === 'CLASS' ? '/timetable' : type === 'ASSESSMENT' ? '/assessments' : '/calendar',
        };
      });
    } catch (err) {
      logger.warn(`Failed to aggregate calendar upcoming events for dashboard: ${err}`);
      return [];
    }
  }

  private static async getStudentUpcomingSchedule(
    collegeId: string,
    activeEnrollment: any,
    requester: AuthenticatedUser,
    customDate?: string,
    limit: number = 4
  ): Promise<DashboardUpcomingItem[]> {
    try {
      const genuineEvents = await this.getUpcomingCalendarEvents(requester, customDate, limit);

      const timetableItems: DashboardUpcomingItem[] = [];
      if (activeEnrollment) {
        const sectionId = activeEnrollment.sectionId?._id || activeEnrollment.sectionId;
        const semesterId = activeEnrollment.semesterId?._id || activeEnrollment.semesterId;

        const ttQuery: any = {
          collegeId: new mongoose.Types.ObjectId(collegeId),
          status: TimetableStatus.PUBLISHED,
        };
        if (sectionId) {
          ttQuery.sectionId = new mongoose.Types.ObjectId(sectionId.toString());
        } else if (semesterId) {
          ttQuery.semesterId = new mongoose.Types.ObjectId(semesterId.toString());
        }

        const tt = await Timetable.findOne(ttQuery).populate('entries.subjectId').lean();
        if (tt && tt.entries && tt.entries.length > 0) {
          const now = customDate ? new Date(customDate) : new Date();
          for (let dayOffset = 0; dayOffset <= 2; dayOffset++) {
            const dateObj = new Date(now);
            dateObj.setDate(dateObj.getDate() + dayOffset);
            const dateStr = dateObj.toISOString().split('T')[0];
            const [y, m, d] = dateStr.split('-').map(Number);
            const utcDate = new Date(Date.UTC(y, m - 1, d, 12, 0, 0));
            const dayNum = utcDate.getUTCDay();
            const dayMap: Record<number, TimetableDay> = {
              0: TimetableDay.SUNDAY,
              1: TimetableDay.MONDAY,
              2: TimetableDay.TUESDAY,
              3: TimetableDay.WEDNESDAY,
              4: TimetableDay.THURSDAY,
              5: TimetableDay.FRIDAY,
              6: TimetableDay.SATURDAY,
            };
            const targetDay = dayMap[dayNum];

            const entries = tt.entries.filter((e: any) => e.dayOfWeek === targetDay);
            for (const entry of entries) {
              const subj: any = entry.subjectId;
              const title = (typeof subj === 'object' && subj?.name) ? subj.name : (entry.subjectName || 'Class');
              const subtitleParts: string[] = [];
              if (entry.facultyName) subtitleParts.push(entry.facultyName);
              if (entry.roomNumber) subtitleParts.push(`Room ${entry.roomNumber}`);
              else if (entry.building) subtitleParts.push(entry.building);

              timetableItems.push({
                id: `tt_${tt._id}_${entry._id || entry.startTime}_${dateStr}`,
                type: 'CLASS',
                title,
                subtitle: subtitleParts.length > 0 ? subtitleParts.join(' • ') : undefined,
                startTime: `${dateStr}T${entry.startTime || '09:00'}:00Z`,
                endTime: `${dateStr}T${entry.endTime || '10:00'}:00Z`,
                location: entry.roomNumber ? `Room ${entry.roomNumber}` : undefined,
                route: '/timetable',
              });
            }
          }
        }
      }

      const combined = [...timetableItems, ...genuineEvents];
      combined.sort((a, b) => a.startTime.localeCompare(b.startTime));
      return combined.slice(0, limit);
    } catch (err) {
      logger.warn(`Failed to aggregate student upcoming schedule: ${err}`);
      return [];
    }
  }
}
