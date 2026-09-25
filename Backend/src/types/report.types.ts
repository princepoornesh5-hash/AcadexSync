import { DateRangePreset } from '../constants/report.constants';

export interface DateFilter {
  preset?: DateRangePreset;
  startDate?: Date;
  endDate?: Date;
}

export interface AttendanceSummaryMetrics {
  totalClasses: number;
  present: number;
  late: number;
  absent: number;
  excused: number;
  percentage: number;
  totalFaculty?: number;
  totalStudents?: number;
}

export interface SubjectAttendanceMetrics extends AttendanceSummaryMetrics {
  subjectId: string;
  subjectName: string;
  subjectCode: string;
  isLowAttendance: boolean;
}

export interface StudentAttendanceReport {
  student: {
    id: string;
    studentIdNumber: string;
    rollNumber: string;
    name: string;
    departmentId?: string;
    courseId?: string;
    semesterId?: string;
    sectionId?: string;
  };
  summary: AttendanceSummaryMetrics;
  subjectsBreakdown: SubjectAttendanceMetrics[];
  lowAttendanceAlert: boolean;
  dateRange: {
    from?: string;
    to?: string;
  };
}

export interface StudentAttendanceRankItem {
  studentId: string;
  name: string;
  rollNumber: string;
  totalClasses: number;
  present: number;
  late: number;
  absent: number;
  percentage: number;
  isLowAttendance: boolean;
}

export interface SectionAttendanceReport {
  section: {
    id: string;
    name: string;
    departmentId: string;
    courseId: string;
    semesterId: string;
  };
  summary: AttendanceSummaryMetrics & { totalSessions: number };
  subjectBreakdown: Array<{
    subjectId: string;
    subjectName: string;
    subjectCode: string;
    totalSessions: number;
    attendancePercentage: number;
  }>;
  students: StudentAttendanceRankItem[];
  lowAttendanceCount: number;
}

export interface DepartmentAttendanceReport {
  department: {
    id: string;
    name: string;
    code: string;
  };
  summary: AttendanceSummaryMetrics;
  sectionsComparison: Array<{
    sectionId: string;
    sectionName: string;
    totalStudents: number;
    attendancePercentage: number;
  }>;
  subjectsComparison: Array<{
    subjectId: string;
    subjectName: string;
    subjectCode: string;
    attendancePercentage: number;
  }>;
  lowAttendanceStudentsCount: number;
}

export interface CollegeAttendanceReport {
  college: {
    id: string;
    name: string;
    code: string;
  };
  summary: AttendanceSummaryMetrics;
  departmentComparison: Array<{
    departmentId: string;
    departmentName: string;
    departmentCode: string;
    totalStudents: number;
    attendancePercentage: number;
  }>;
  totalSessionsConducted: number;
  lowAttendanceDepartments: string[];
}

export interface FacultyActivityReport {
  faculty: {
    id: string;
    name: string;
    instituteId: string;
    designation: string;
    departmentId: string;
  };
  conductedSessionsCount: number;
  overallAttendanceRate: number;
  uniqueStudentsTaught: number;
  subjectsBreakdown: Array<{
    subjectId: string;
    subjectName: string;
    subjectCode: string;
    sessionsCount: number;
    averageAttendancePercentage: number;
  }>;
  sectionsBreakdown: Array<{
    sectionId: string;
    sectionName: string;
    sessionsCount: number;
    averageAttendancePercentage: number;
  }>;
  recentSessions: Array<{
    sessionId: string;
    date: string;
    subjectName: string;
    sectionName: string;
    markedCount: number;
  }>;
}

export interface AcademicHierarchyReport {
  collegeId?: string;
  summary: {
    totalDepartments: number;
    totalCourses: number;
    totalSemesters: number;
    totalSections: number;
    totalSubjects: number;
    totalStudents: number;
    totalFaculty: number;
    totalHod: number;
  };
  enrollmentCapacity: {
    totalCapacity: number;
    totalEnrolled: number;
    utilizationRate: number;
  };
  timetableCoverage: {
    totalSections: number;
    publishedTimetables: number;
    draftTimetables: number;
    coveragePercentage: number;
  };
}

export interface NotesReport {
  collegeId?: string;
  summary: {
    totalNotes: number;
    publishedNotes: number;
    archivedNotes: number;
    totalStorageBytes: number;
  };
  bySubject: Array<{
    subjectId: string;
    subjectName: string;
    notesCount: number;
    totalBytes: number;
  }>;
  byDepartment: Array<{
    departmentId: string;
    departmentName: string;
    notesCount: number;
  }>;
  recentNotes: Array<{
    id: string;
    title: string;
    subjectName: string;
    facultyName: string;
    createdAt: string;
    fileSize: number;
  }>;
}

export interface RoleDashboardReport {
  role: string;
  metrics: Record<string, unknown>;
  quickStats: Record<string, unknown>;
  recentActivity: Array<Record<string, unknown>>;
}
