import 'dart:developer' as developer;
import '../../../../core/firebase/firebase_services.dart';
import '../../domain/models/assigned_class.dart';
import '../../domain/models/attendance_history_record.dart';
import '../../domain/models/attendance_record.dart';
import '../../domain/models/attendance_session.dart';
import '../../domain/models/attendance_status.dart';
import '../../domain/models/college_attendance_comparison.dart';
import '../../domain/models/college_attendance_summary.dart';
import '../../domain/models/college_faculty_completion.dart';
import '../../domain/models/college_insight.dart';
import '../../domain/models/college_student_shortage.dart';
import '../../domain/models/department_attendance_comparison.dart';
import '../../domain/models/department_attendance_summary.dart';
import '../../domain/models/faculty_attendance_completion.dart';
import '../../domain/models/monthly_attendance_summary.dart';
import '../../domain/models/section_attendance_summary.dart';
import '../../domain/models/student_attendance_overview.dart';
import '../../domain/models/student_shortage.dart';
import '../../domain/models/subject_attendance.dart';
import '../../domain/models/super_admin_attendance_summary.dart';
import '../../domain/models/super_admin_faculty_completion.dart';
import '../../domain/models/super_admin_insight.dart';
import '../../domain/models/super_admin_student_shortage.dart';
import '../../domain/models/super_admin_system_health.dart';
import '../../domain/repositories/attendance_repository.dart';

class FirebaseAttendanceRepository implements AttendanceRepository {
  final FirestoreService _firestoreService;

  FirebaseAttendanceRepository(this._firestoreService);

  @override
  Future<List<AssignedClass>> getAssignedClasses(String facultyId, DateTime date) async {
    return [
      AssignedClass(
        id: 'ac1',
        subjectId: 'sub1',
        subjectName: 'Java Programming',
        sectionId: 'sec1',
        sectionName: 'DCME 3-A',
        semester: 'Semester 3',
        timeSlot: '08:30 - 09:20',
        date: date,
      ),
      AssignedClass(
        id: 'ac2',
        subjectId: 'sub2',
        subjectName: 'Operating Systems',
        sectionId: 'sec2',
        sectionName: 'DCME 5-A',
        semester: 'Semester 5',
        timeSlot: '09:30 - 10:20',
        date: date,
        isAttendanceMarked: true,
      ),
      AssignedClass(
        id: 'ac3',
        subjectId: 'sub3',
        subjectName: 'DBMS Lab',
        sectionId: 'sec3',
        sectionName: 'DCME 3-B',
        semester: 'Semester 3',
        timeSlot: '10:30 - 11:20',
        date: date,
      ),
    ];
  }

  @override
  Stream<List<AssignedClass>> watchAssignedClasses(String facultyId, DateTime date) {
    return Stream.fromFuture(getAssignedClasses(facultyId, date));
  }

  @override
  Future<List<AttendanceRecord>> getStudentsForSection(String sectionId, String subjectId, DateTime date) async {
    final sessionId = '${sectionId}_${subjectId}_${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
    final doc = await _firestoreService.getDocument('attendanceSessions', sessionId);
    if (doc != null) {
      final session = AttendanceSession.fromJson(doc);
      return session.records;
    }
    return [
      AttendanceRecord(id: 'rec_1', studentId: 's1', studentName: 'John Doe', rollNumber: 'CS2025001', sectionId: sectionId),
      AttendanceRecord(id: 'rec_2', studentId: 's2', studentName: 'Jane Smith', rollNumber: 'CS2025002', sectionId: sectionId),
      AttendanceRecord(id: 'rec_3', studentId: 's3', studentName: 'Alice Bob', rollNumber: 'CS2025003', sectionId: sectionId),
      AttendanceRecord(id: 'rec_4', studentId: 's4', studentName: 'Michael Chang', rollNumber: 'CS2025004', sectionId: sectionId),
      AttendanceRecord(id: 'rec_5', studentId: 's5', studentName: 'Sarah Connor', rollNumber: 'CS2025005', sectionId: sectionId),
      AttendanceRecord(id: 'rec_6', studentId: 's6', studentName: 'David Bowman', rollNumber: 'CS2025006', sectionId: sectionId),
    ];
  }

  @override
  Future<bool> saveSession(AttendanceSession session) async {
    final sessionId = '${session.sectionId}_${session.subjectId}_${session.date.year}${session.date.month.toString().padLeft(2, '0')}${session.date.day.toString().padLeft(2, '0')}';
    final now = DateTime.now();
    final updatedSession = session.copyWith(
      id: sessionId,
      isSubmitted: true,
      createdAt: session.createdAt ?? now,
      createdBy: session.createdBy ?? session.facultyId,
      lastModifiedAt: now,
      lastModifiedBy: session.facultyId,
    );

    developer.log('Saving Attendance Session $sessionId to Firestore', name: 'Acadex.Attendance');
    await _firestoreService.setDocument('attendanceSessions', sessionId, updatedSession.toJson());

    for (final record in session.records) {
      if (record.status != null) {
        final recordId = '${sessionId}_${record.studentId}';
        await _firestoreService.setDocument('attendance', recordId, {
          'attendanceId': recordId,
          'sessionId': sessionId,
          'studentId': record.studentId,
          'studentName': record.studentName,
          'rollNumber': record.rollNumber,
          'sectionId': record.sectionId,
          'subjectId': session.subjectId,
          'facultyId': session.facultyId,
          'date': session.date.toIso8601String().split('T').first,
          'status': record.status!.name,
          'markedAt': now.toIso8601String(),
          'markedBy': session.facultyId,
        });
      }
    }
    return true;
  }

  @override
  Future<List<AttendanceSession>> getRecentSessions(String facultyId) async {
    return [];
  }

  @override
  Future<List<SubjectAttendance>> getStudentSubjectAttendance(String studentId) async {
    return [
      SubjectAttendance(subjectId: 'sub1', subjectName: 'Java Programming', subjectCode: 'CS301', facultyName: 'Prof. Alan Turing', totalClasses: 40, attendedClasses: 35, missedClasses: 5),
      SubjectAttendance(subjectId: 'sub2', subjectName: 'Operating Systems', subjectCode: 'CS302', facultyName: 'Dr. Grace Hopper', totalClasses: 38, attendedClasses: 20, missedClasses: 18),
      SubjectAttendance(subjectId: 'sub3', subjectName: 'DBMS Lab', subjectCode: 'CS303L', facultyName: 'Dr. E. F. Codd', totalClasses: 20, attendedClasses: 19, missedClasses: 1),
      SubjectAttendance(subjectId: 'sub4', subjectName: 'Mathematics III', subjectCode: 'MA301', facultyName: 'Prof. John Nash', totalClasses: 42, attendedClasses: 30, missedClasses: 12),
    ];
  }

  @override
  Future<StudentAttendanceOverview> getStudentAttendanceOverview(String studentId) async {
    return StudentAttendanceOverview(overallPercentage: 78.5);
  }

  @override
  Future<List<AttendanceHistoryRecord>> getStudentAttendanceHistory(String studentId) async {
    final now = DateTime.now();
    return [
      AttendanceHistoryRecord(id: 'h1', date: now, subjectId: 'sub1', subjectName: 'Java Programming', facultyName: 'Prof. Alan Turing', status: AttendanceStatus.present, timeSlot: '08:30 - 09:20'),
      AttendanceHistoryRecord(id: 'h2', date: now, subjectId: 'sub2', subjectName: 'Operating Systems', facultyName: 'Dr. Grace Hopper', status: AttendanceStatus.absent, timeSlot: '09:30 - 10:20'),
      AttendanceHistoryRecord(id: 'h3', date: now, subjectId: 'sub3', subjectName: 'DBMS Lab', facultyName: 'Dr. E. F. Codd', status: AttendanceStatus.present, timeSlot: '10:30 - 11:20'),
    ];
  }

  @override
  Future<List<MonthlyAttendanceSummary>> getStudentMonthlySummary(String studentId) async {
    return [
      MonthlyAttendanceSummary(month: 8, year: 2026, classesConducted: 40, classesAttended: 32, classesMissed: 8),
      MonthlyAttendanceSummary(month: 7, year: 2026, classesConducted: 55, classesAttended: 50, classesMissed: 5),
    ];
  }

  @override
  Future<DepartmentAttendanceSummary> getDepartmentSummary(String departmentId) async {
    return DepartmentAttendanceSummary(
      overallPercentage: 78.5,
      studentsBelow75: 24,
      facultyCompleted: 12,
      facultyPending: 3,
      todayClasses: 15,
      totalStudents: 450,
      totalFaculty: 15,
    );
  }

  @override
  Stream<DepartmentAttendanceSummary> watchDepartmentSummary(String departmentId) {
    return Stream.fromFuture(getDepartmentSummary(departmentId));
  }

  @override
  Future<List<FacultyAttendanceCompletion>> getFacultyCompletionStatus(String departmentId, DateTime date) async {
    return [
      FacultyAttendanceCompletion(facultyId: 'f1', facultyName: 'Prof. Alan Turing', assignedSubjects: ['Java Programming'], completedClasses: 2, pendingClasses: 0, lastCompletionTime: DateTime.now().subtract(const Duration(minutes: 30))),
      FacultyAttendanceCompletion(facultyId: 'f2', facultyName: 'Dr. Grace Hopper', assignedSubjects: ['Operating Systems'], completedClasses: 1, pendingClasses: 1, lastCompletionTime: DateTime.now().subtract(const Duration(hours: 1))),
    ];
  }

  @override
  Future<List<StudentShortage>> getStudentShortages(String departmentId) async {
    return [
      StudentShortage(studentId: 's10', studentName: 'Peter Parker', rollNumber: 'CS2025010', semester: 'Semester 3', section: 'DCME 3-A', currentPercentage: 62.4),
      StudentShortage(studentId: 's11', studentName: 'Clark Kent', rollNumber: 'CS2025011', semester: 'Semester 5', section: 'DCME 5-A', currentPercentage: 72.1),
    ];
  }

  @override
  Future<List<SectionAttendanceSummary>> getSectionAttendance(String departmentId, DateTime date) async {
    return [
      SectionAttendanceSummary(sectionId: 'sec1', sectionName: 'DCME 3-A', semester: 'Semester 3', attendancePercentage: 85.2, present: 52, absent: 8, late: 2, totalStudents: 60),
      SectionAttendanceSummary(sectionId: 'sec2', sectionName: 'DCME 3-B', semester: 'Semester 3', attendancePercentage: 79.5, present: 48, absent: 12, late: 5, totalStudents: 60),
    ];
  }

  @override
  Future<CollegeAttendanceSummary> getCollegeSummary() async {
    return CollegeAttendanceSummary(
      totalDepartments: 5,
      totalStudents: 3250,
      totalFaculty: 145,
      todayAttendancePercentage: 81.2,
      studentsBelowThreshold: 154,
      pendingFaculty: 22,
      completedFaculty: 123,
    );
  }

  @override
  Stream<CollegeAttendanceSummary> watchCollegeSummary() {
    return Stream.fromFuture(getCollegeSummary());
  }

  @override
  Future<List<DepartmentAttendanceComparison>> getDepartmentComparisons() async {
    return [
      DepartmentAttendanceComparison(departmentId: 'd1', departmentName: 'Computer Engineering', attendancePercentage: 84.5, studentCount: 850, facultyCount: 35, todayCompletionPercentage: 95.0, trend: TrendDirection.up),
      DepartmentAttendanceComparison(departmentId: 'd2', departmentName: 'ECE', attendancePercentage: 82.1, studentCount: 720, facultyCount: 30, todayCompletionPercentage: 88.5, trend: TrendDirection.up),
    ];
  }

  @override
  Future<List<CollegeFacultyCompletion>> getCollegeFacultyCompletion(DateTime date) async {
    return [
      CollegeFacultyCompletion(facultyId: 'f1', facultyName: 'Dr. Emily Chen', departmentName: 'Computer Engineering', assignedSubjects: ['Data Structures'], completedClasses: 2, pendingClasses: 0, lastCompletionTime: DateTime.now().subtract(const Duration(minutes: 15))),
    ];
  }

  @override
  Future<List<CollegeStudentShortage>> getCollegeStudentShortages() async {
    return [
      CollegeStudentShortage(studentId: 's20', studentName: 'Tom Holland', rollNumber: 'ME2025020', departmentName: 'Mechanical', semester: 'Semester 5', currentPercentage: 55.2, status: ShortageStatus.critical),
    ];
  }

  @override
  Future<List<CollegeInsight>> getCollegeInsights() async {
    return [
      CollegeInsight(title: 'Highest Attendance', value: 'Computer Engineering', subtitle: '84.5% Overall', isPositive: true),
    ];
  }

  @override
  Future<SuperAdminAttendanceSummary> getSuperAdminSummary() async {
    return SuperAdminAttendanceSummary(
      totalColleges: 8,
      totalDepartments: 42,
      totalFaculty: 1250,
      totalStudents: 18400,
      todayAttendancePercentage: 84.5,
      pendingColleges: 2,
    );
  }

  @override
  Stream<SuperAdminAttendanceSummary> watchSuperAdminSummary() {
    return Stream.fromFuture(getSuperAdminSummary());
  }

  @override
  Future<List<CollegeAttendanceComparison>> getCollegeComparisons() async {
    return [
      CollegeAttendanceComparison(collegeId: 'c1', collegeName: 'Acadex Institute of Technology', collegeCode: 'AIT', attendancePercentage: 88.2, studentCount: 4500, facultyCount: 320, departmentCount: 8, completionRate: 98.0, trend: TrendDirection.up),
    ];
  }

  @override
  Future<List<SuperAdminFacultyCompletion>> getSuperAdminFacultyCompletion(DateTime date) async {
    return [
      SuperAdminFacultyCompletion(facultyId: 'f1', facultyName: 'Dr. Emily Chen', collegeName: 'AIT', departmentName: 'Computer Engineering', assignedSubjects: ['Data Structures'], completedClasses: 2, pendingClasses: 0, lastCompletionTime: DateTime.now().subtract(const Duration(minutes: 15))),
    ];
  }

  @override
  Future<List<SuperAdminStudentShortage>> getSuperAdminStudentShortages() async {
    return [
      SuperAdminStudentShortage(studentId: 's20', studentName: 'Tom Holland', rollNumber: 'ME2025020', collegeName: 'AIT', departmentName: 'Mechanical', semester: 'Semester 5', currentPercentage: 55.2, status: ShortageStatus.critical),
    ];
  }

  @override
  Future<List<SuperAdminInsight>> getSuperAdminInsights() async {
    return [
      SuperAdminInsight(title: 'Top Performing College', value: 'Acadex Medical College', subtitle: '92.5% Average Attendance', isPositive: true),
    ];
  }

  @override
  Future<SuperAdminSystemHealth> getSuperAdminSystemHealth() async {
    return SuperAdminSystemHealth(
      serverStatus: 'Healthy',
      syncStatus: 'All Systems Synced',
      apiLatency: '45ms',
      activeUsers: 3450,
    );
  }
}
