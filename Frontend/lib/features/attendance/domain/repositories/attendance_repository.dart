import '../models/assigned_class.dart';
import '../models/attendance_history_record.dart';
import '../models/attendance_record.dart';
import '../models/attendance_session.dart';
import '../models/attendance_status.dart';
import '../models/college_attendance_comparison.dart';
import '../models/college_attendance_summary.dart';
import '../models/college_faculty_completion.dart';
import '../models/college_insight.dart';
import '../models/college_student_shortage.dart';
import '../models/department_attendance_comparison.dart';
import '../models/department_attendance_summary.dart';
import '../models/faculty_attendance_completion.dart';
import '../models/monthly_attendance_summary.dart';
import '../models/section_attendance_summary.dart';
import '../models/student_attendance_overview.dart';
import '../models/student_shortage.dart';
import '../models/subject_attendance.dart';
import '../models/super_admin_attendance_summary.dart';
import '../models/super_admin_faculty_completion.dart';
import '../models/super_admin_insight.dart';
import '../models/super_admin_student_shortage.dart';
import '../models/super_admin_system_health.dart';
import '../models/attendance_analytics_models.dart';

abstract class AttendanceRepository {
  Future<List<AssignedClass>> getAssignedClasses(String facultyId, DateTime date);
  Stream<List<AssignedClass>> watchAssignedClasses(String facultyId, DateTime date);

  // Student Methods
  Future<List<SubjectAttendance>> getStudentSubjectAttendance(String studentId);
  Future<StudentAttendanceOverview> getStudentAttendanceOverview(String studentId);
  Future<List<AttendanceHistoryRecord>> getStudentAttendanceHistory(String studentId, {DateTime? startDate, DateTime? endDate});
  Future<List<MonthlyAttendanceSummary>> getStudentMonthlySummary(String studentId);

  // Faculty Methods
  Future<List<AttendanceRecord>> getStudentsForSection(String sectionId, String subjectId, DateTime date, {String? timetableEntryId});
  Future<bool> saveSession(AttendanceSession session);
  Future<List<AttendanceSession>> getRecentSessions(String facultyId);
  Future<List<AttendanceSession>> getFacultySessions();

  // Session Lifecycle & Query Methods
  Future<AttendanceSession> getSessionById(String sessionId);
  Future<List<AttendanceSession>> listSessions({
    String? departmentId,
    String? sectionId,
    String? subjectId,
    String? facultyId,
    String? status,
    DateTime? from,
    DateTime? to,
    int? page,
    int? limit,
  });
  Future<AttendanceSession> lockSession(String sessionId);
  Future<AttendanceSession> closeSession(String sessionId);
  Future<AttendanceSession> cancelSession(String sessionId);
  Future<AttendanceRecord> correctRecord(String recordId, {required AttendanceStatus newStatus, required String reason});

  // HOD Methods
  Future<DepartmentAttendanceSummary> getDepartmentSummary(String departmentId);
  Stream<DepartmentAttendanceSummary> watchDepartmentSummary(String departmentId);
  Future<List<FacultyAttendanceCompletion>> getFacultyCompletionStatus(String departmentId, DateTime date);
  Future<List<StudentShortage>> getStudentShortages(String departmentId);
  Future<List<SectionAttendanceSummary>> getSectionAttendance(String departmentId, DateTime date);

  // College Admin Methods
  Future<CollegeAttendanceSummary> getCollegeSummary();
  Stream<CollegeAttendanceSummary> watchCollegeSummary();
  Future<List<DepartmentAttendanceComparison>> getDepartmentComparisons();
  Future<List<CollegeFacultyCompletion>> getCollegeFacultyCompletion(DateTime date);
  Future<List<CollegeStudentShortage>> getCollegeStudentShortages();
  Future<List<CollegeInsight>> getCollegeInsights();

  // Super Admin Methods
  Future<SuperAdminAttendanceSummary> getSuperAdminSummary();
  Stream<SuperAdminAttendanceSummary> watchSuperAdminSummary();
  Future<List<CollegeAttendanceComparison>> getCollegeComparisons();
  Future<List<SuperAdminFacultyCompletion>> getSuperAdminFacultyCompletion(DateTime date);
  Future<List<SuperAdminStudentShortage>> getSuperAdminStudentShortages();
  Future<List<SuperAdminInsight>> getSuperAdminInsights();
  Future<SuperAdminSystemHealth> getSuperAdminSystemHealth();

  // Phase 8A Attendance Analytics Aggregation Engine Methods
  Future<StudentAttendanceAnalytics> getStudentAttendanceAnalytics(String studentId, {AttendanceDateRange? dateRange});
  Future<SubjectAttendanceAnalytics> getSubjectAttendanceAnalytics(String subjectId, {String? sectionId, AttendanceDateRange? dateRange});
  Future<SectionAttendanceAnalytics> getSectionAttendanceAnalytics(String sectionId, {AttendanceDateRange? dateRange});
  Future<FacultyAttendanceAnalytics> getFacultyAttendanceAnalytics(String facultyId, {AttendanceDateRange? dateRange});
  Future<AttendanceDateRangeSummary> getAttendanceDateRangeSummary({AttendanceDateRange? dateRange, String? departmentId, String? sectionId});
}
