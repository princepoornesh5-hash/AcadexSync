import { AppRole } from '../constants/roles';

export interface DashboardGreeting {
  displayName: string;
  role: AppRole;
  avatarUrl?: string | null;
  greetingText: string;
}

export interface StudentDashboardContext {
  isEnrollmentAvailable: boolean;
  enrollmentId?: string | null;
  courseId?: string | null;
  courseName?: string | null;
  courseCode?: string | null;
  semesterId?: string | null;
  semesterName?: string | null;
  semesterNumber?: number | null;
  sectionId?: string | null;
  sectionName?: string | null;
  academicStage?: string | null;
  rollNumber?: string | null;
}

export interface FacultyDashboardContext {
  facultyId?: string | null;
  departmentId?: string | null;
  departmentName?: string | null;
  designation?: string | null;
  employeeId?: string | null;
  activeTeachingAssignmentsCount: number;
}

export interface HodDashboardContext {
  departmentId: string;
  departmentName: string;
  departmentCode: string;
  designation?: string | null;
  managedScope?: string;
}

export interface CollegeAdminDashboardContext {
  collegeId: string;
  collegeName: string;
  collegeCode: string;
  administrativeScope?: string;
}

export interface SuperAdminDashboardContext {
  scope: 'GLOBAL';
}

export type DashboardContext =
  | StudentDashboardContext
  | FacultyDashboardContext
  | HodDashboardContext
  | CollegeAdminDashboardContext
  | SuperAdminDashboardContext;

export interface StudentDashboardSummary {
  attendancePercentage: number | null;
  assignmentsCompleted: number;
  assignmentsPending: number;
  practicalsCompleted: number;
  practicalsScheduled: number;
  publishedAssessmentsCount: number;
  latestResultStatus: string | null;
}

export interface FacultyDashboardSummary {
  assignedClassesCount: number;
  pendingAttendanceSessions: number;
  submissionsAwaitingReview: number;
  pendingAssessmentMarks: number;
  openPracticalsCount: number;
}

export interface HodDashboardSummary {
  activeFacultyCount: number;
  activeStudentsCount: number;
  todayClassesCount: number;
  pendingDepartmentRequests: number;
  pendingAssessmentsCount: number;
  pendingAttendanceCount: number;
}

export interface CollegeAdminDashboardSummary {
  departmentsCount: number;
  facultyCount: number;
  studentsCount: number;
  pendingRequestsCount: number;
  activeAnnouncementsCount: number;
  activeAcademicYearsCount: number;
}

export interface SuperAdminDashboardSummary {
  collegesCount: number;
  usersCount: number;
  activeCollegesCount: number;
  systemStatus: string;
}

export type DashboardSummary =
  | StudentDashboardSummary
  | FacultyDashboardSummary
  | HodDashboardSummary
  | CollegeAdminDashboardSummary
  | SuperAdminDashboardSummary;

export type AlertSeverity = 'INFO' | 'WARNING' | 'CRITICAL';

export interface DashboardAlert {
  id: string;
  type: string;
  severity: AlertSeverity;
  title: string;
  message: string;
  route?: string;
}

export type UpcomingEventType = 'CLASS' | 'PRACTICAL' | 'ASSESSMENT' | 'EVENT' | 'HOLIDAY';

export interface DashboardUpcomingItem {
  id: string;
  type: UpcomingEventType;
  title: string;
  subtitle?: string;
  startTime: string;
  endTime?: string;
  location?: string;
  route?: string;
}

export type PendingActionType =
  | 'ASSIGNMENT_DUE'
  | 'TAKE_ATTENDANCE'
  | 'REVIEW_SUBMISSION'
  | 'ENTER_MARKS'
  | 'REQUEST_ACTION'
  | 'PROFILE_COMPLETION'
  | 'RESULT_REVIEW';

export interface DashboardPendingAction {
  id: string;
  type: PendingActionType;
  priority: 'LOW' | 'MEDIUM' | 'HIGH';
  title: string;
  description?: string;
  deadline?: string;
  route: string;
  actionLabel: string;
}

export type RecentActivityType =
  | 'ANNOUNCEMENT'
  | 'SUBMISSION'
  | 'RESULT'
  | 'REQUEST'
  | 'ASSESSMENT'
  | 'PRACTICAL';

export interface DashboardRecentActivity {
  id: string;
  type: RecentActivityType;
  title: string;
  description?: string;
  timestamp: string;
  route?: string;
}

export interface DashboardQuickAction {
  id: string;
  label: string;
  icon: string;
  route: string;
  badgeCount?: number;
  isPrimary?: boolean;
}

export interface HomeDashboardDTO {
  role: AppRole;
  greeting: DashboardGreeting;
  context: DashboardContext;
  summary: DashboardSummary;
  alerts: DashboardAlert[];
  upcoming: DashboardUpcomingItem[];
  pendingActions: DashboardPendingAction[];
  recent: DashboardRecentActivity[];
  quickActions: DashboardQuickAction[];
}
