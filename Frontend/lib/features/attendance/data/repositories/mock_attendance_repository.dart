import '../../domain/models/attendance_session.dart';
import '../../domain/models/attendance_record.dart';
import '../../domain/models/assigned_class.dart';
import '../../domain/models/subject_attendance.dart';
import '../../domain/models/attendance_history_record.dart';
import '../../domain/models/monthly_attendance_summary.dart';
import '../../domain/models/attendance_status.dart';
import '../../domain/models/department_attendance_summary.dart';
import '../../domain/models/faculty_attendance_completion.dart';
import '../../domain/models/student_shortage.dart';
import '../../domain/models/section_attendance_summary.dart';
import '../../domain/models/college_attendance_summary.dart';
import '../../domain/models/department_attendance_comparison.dart';
import '../../domain/models/college_insight.dart';
import '../../domain/models/college_faculty_completion.dart';
import '../../domain/models/college_student_shortage.dart';
import '../../domain/models/super_admin_attendance_summary.dart';
import '../../domain/models/college_attendance_comparison.dart';
import '../../domain/models/super_admin_insight.dart';
import '../../domain/models/super_admin_system_health.dart';
import '../../domain/models/super_admin_faculty_completion.dart';
import '../../domain/models/super_admin_student_shortage.dart';
import '../../domain/models/student_attendance_overview.dart';
import '../../domain/repositories/attendance_repository.dart';

class MockAttendanceRepository implements AttendanceRepository {
  final List<AttendanceSession> _sessions = [
    AttendanceSession(
      id: 'sess1',
      facultyId: 'faculty1',
      subjectId: 'sub1',
      subjectName: 'Java Programming',
      sectionId: 'sec1',
      sectionName: 'DCME 3-A',
      timeSlot: '08:30 - 09:20',
      date: DateTime.now().subtract(const Duration(days: 1)),
      isSubmitted: true,
      isLocked: true,
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      createdBy: 'faculty1',
      lastModifiedAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      lastModifiedBy: 'faculty1',
      version: 1,
      records: [
        AttendanceRecord(id: 'rec_1', studentId: 's1', studentName: 'John Doe', rollNumber: 'CS2025001', sectionId: 'sec1', status: AttendanceStatus.present),
        AttendanceRecord(id: 'rec_2', studentId: 's2', studentName: 'Jane Smith', rollNumber: 'CS2025002', sectionId: 'sec1', status: AttendanceStatus.absent),
      ],
    ),
    AttendanceSession(
      id: 'sess2',
      facultyId: 'faculty1',
      subjectId: 'sub2',
      subjectName: 'Operating Systems',
      sectionId: 'sec2',
      sectionName: 'DCME 5-A',
      timeSlot: '09:30 - 10:20',
      date: DateTime.now().subtract(const Duration(days: 2)),
      isSubmitted: true,
      isLocked: false, // Draft state
      createdAt: DateTime.now().subtract(const Duration(days: 2, hours: 1)),
      createdBy: 'faculty1',
      lastModifiedAt: DateTime.now().subtract(const Duration(days: 2, hours: 1)),
      lastModifiedBy: 'faculty1',
      version: 2,
      records: [
        AttendanceRecord(id: 'rec_3', studentId: 's3', studentName: 'Alice Bob', rollNumber: 'CS2025003', sectionId: 'sec2', status: AttendanceStatus.present),
        AttendanceRecord(id: 'rec_4', studentId: 's4', studentName: 'Michael Chang', rollNumber: 'CS2025004', sectionId: 'sec2', status: AttendanceStatus.late),
      ],
    ),
  ];

  Future<void> _delay() async => await Future.delayed(const Duration(milliseconds: 600));

  @override
  Future<List<AssignedClass>> getAssignedClasses(String facultyId, DateTime date) async {
    await _delay();
    // Return dummy classes for the day
    return [
      AssignedClass(id: 'ac1', subjectId: 'sub1', subjectName: 'Java Programming', sectionId: 'sec1', sectionName: 'DCME 3-A', semester: 'Semester 3', timeSlot: '08:30 - 09:20', date: date),
      AssignedClass(id: 'ac2', subjectId: 'sub2', subjectName: 'Operating Systems', sectionId: 'sec2', sectionName: 'DCME 5-A', semester: 'Semester 5', timeSlot: '09:30 - 10:20', date: date, isAttendanceMarked: true),
      AssignedClass(id: 'ac3', subjectId: 'sub3', subjectName: 'DBMS Lab', sectionId: 'sec3', sectionName: 'DCME 3-B', semester: 'Semester 3', timeSlot: '10:30 - 11:20', date: date),
    ];
  }

  @override
  Stream<List<AssignedClass>> watchAssignedClasses(String facultyId, DateTime date) {
    return Stream.fromFuture(getAssignedClasses(facultyId, date));
  }

  // ==========================================
  // STUDENT METHODS
  // ==========================================

  @override
  Future<List<SubjectAttendance>> getStudentSubjectAttendance(String studentId) async {
    await _delay();
    return [
      SubjectAttendance(subjectId: 'sub1', subjectName: 'Java Programming', subjectCode: 'CS301', facultyName: 'Prof. Alan Turing', totalClasses: 40, attendedClasses: 35, missedClasses: 5),
      SubjectAttendance(subjectId: 'sub2', subjectName: 'Operating Systems', subjectCode: 'CS302', facultyName: 'Dr. Grace Hopper', totalClasses: 38, attendedClasses: 20, missedClasses: 18),
      SubjectAttendance(subjectId: 'sub3', subjectName: 'DBMS Lab', subjectCode: 'CS303L', facultyName: 'Dr. E. F. Codd', totalClasses: 20, attendedClasses: 19, missedClasses: 1),
      SubjectAttendance(subjectId: 'sub4', subjectName: 'Mathematics III', subjectCode: 'MA301', facultyName: 'Prof. John Nash', totalClasses: 42, attendedClasses: 30, missedClasses: 12),
    ];
  }

  @override
  Future<StudentAttendanceOverview> getStudentAttendanceOverview(String studentId) async {
    await _delay();
    return StudentAttendanceOverview(overallPercentage: 78.5);
  }

  @override
  Future<List<AttendanceHistoryRecord>> getStudentAttendanceHistory(String studentId) async {
    await _delay();
    final now = DateTime.now();
    return [
      AttendanceHistoryRecord(id: 'h1', date: now, subjectId: 'sub1', subjectName: 'Java Programming', facultyName: 'Prof. Alan Turing', status: AttendanceStatus.present, timeSlot: '08:30 - 09:20'),
      AttendanceHistoryRecord(id: 'h2', date: now, subjectId: 'sub2', subjectName: 'Operating Systems', facultyName: 'Dr. Grace Hopper', status: AttendanceStatus.absent, timeSlot: '09:30 - 10:20'),
      AttendanceHistoryRecord(id: 'h3', date: now, subjectId: 'sub3', subjectName: 'DBMS Lab', facultyName: 'Dr. E. F. Codd', status: AttendanceStatus.present, timeSlot: '10:30 - 11:20'),
      AttendanceHistoryRecord(id: 'h4', date: now.subtract(const Duration(days: 1)), subjectId: 'sub4', subjectName: 'Mathematics III', facultyName: 'Prof. John Nash', status: AttendanceStatus.late, timeSlot: '11:30 - 12:20'),
      AttendanceHistoryRecord(id: 'h5', date: now.subtract(const Duration(days: 1)), subjectId: 'sub1', subjectName: 'Java Programming', facultyName: 'Prof. Alan Turing', status: AttendanceStatus.present, timeSlot: '08:30 - 09:20'),
      AttendanceHistoryRecord(id: 'h6', date: now.subtract(const Duration(days: 2)), subjectId: 'sub2', subjectName: 'Operating Systems', facultyName: 'Dr. Grace Hopper', status: AttendanceStatus.absent, timeSlot: '09:30 - 10:20'),
    ];
  }

  @override
  Future<List<MonthlyAttendanceSummary>> getStudentMonthlySummary(String studentId) async {
    await _delay();
    return [
      MonthlyAttendanceSummary(month: 8, year: 2026, classesConducted: 40, classesAttended: 32, classesMissed: 8),
      MonthlyAttendanceSummary(month: 7, year: 2026, classesConducted: 55, classesAttended: 50, classesMissed: 5),
      MonthlyAttendanceSummary(month: 6, year: 2026, classesConducted: 45, classesAttended: 22, classesMissed: 23),
    ];
  }

  /// Generates a dummy list of students for a given section.
  /// If the session was already saved, it returns the saved records.
  @override
  Future<List<AttendanceRecord>> getStudentsForSection(String sectionId, String subjectId, DateTime date) async {
    await _delay();
    
    // Check if session already exists
    try {
      final existing = _sessions.firstWhere((s) => s.sectionId == sectionId && s.subjectId == subjectId && s.date.year == date.year && s.date.month == date.month && s.date.day == date.day);
      return List.from(existing.records);
    } catch (_) {
      // Session doesn't exist, generate fresh students (no status)
      return [
        AttendanceRecord(id: 'rec_1', studentId: 's1', studentName: 'John Doe', rollNumber: 'CS2025001', sectionId: sectionId),
        AttendanceRecord(id: 'rec_2', studentId: 's2', studentName: 'Jane Smith', rollNumber: 'CS2025002', sectionId: sectionId),
        AttendanceRecord(id: 'rec_3', studentId: 's3', studentName: 'Alice Bob', rollNumber: 'CS2025003', sectionId: sectionId),
        AttendanceRecord(id: 'rec_4', studentId: 's4', studentName: 'Michael Chang', rollNumber: 'CS2025004', sectionId: sectionId),
        AttendanceRecord(id: 'rec_5', studentId: 's5', studentName: 'Sarah Connor', rollNumber: 'CS2025005', sectionId: sectionId),
        AttendanceRecord(id: 'rec_6', studentId: 's6', studentName: 'David Bowman', rollNumber: 'CS2025006', sectionId: sectionId),
      ];
    }
  }

  @override
  Future<bool> saveSession(AttendanceSession session) async {
    await _delay();
    // In a real app, this would upsert based on (date, subject, section) or ID.
    final existingIndex = _sessions.indexWhere((s) => s.id == session.id);
    
    if (existingIndex >= 0) {
      final existing = _sessions[existingIndex];
      // Increment version and set modified metadata
      _sessions[existingIndex] = session.copyWith(
        isSubmitted: true,
        version: existing.version + 1,
        lastModifiedAt: DateTime.now(),
        lastModifiedBy: session.facultyId,
      );
    } else {
      // New session
      _sessions.add(session.copyWith(
        isSubmitted: true,
        createdAt: DateTime.now(),
        createdBy: session.facultyId,
        lastModifiedAt: DateTime.now(),
        lastModifiedBy: session.facultyId,
        version: 1,
      ));
    }
    return true;
  }

  @override
  Future<List<AttendanceSession>> getRecentSessions(String facultyId) async {
    await _delay();
    return _sessions.where((s) => s.facultyId == facultyId).toList();
  }

  // ==========================================
  // HOD METHODS
  // ==========================================

  @override
  Future<DepartmentAttendanceSummary> getDepartmentSummary(String departmentId) async {
    await _delay();
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
    await _delay();
    return [
      FacultyAttendanceCompletion(facultyId: 'f1', facultyName: 'Prof. Alan Turing', assignedSubjects: ['Java Programming'], completedClasses: 2, pendingClasses: 0, lastCompletionTime: DateTime.now().subtract(const Duration(minutes: 30))),
      FacultyAttendanceCompletion(facultyId: 'f2', facultyName: 'Dr. Grace Hopper', assignedSubjects: ['Operating Systems', 'Compiler Design'], completedClasses: 1, pendingClasses: 1, lastCompletionTime: DateTime.now().subtract(const Duration(hours: 1))),
      FacultyAttendanceCompletion(facultyId: 'f3', facultyName: 'Dr. E. F. Codd', assignedSubjects: ['DBMS Lab'], completedClasses: 0, pendingClasses: 2),
      FacultyAttendanceCompletion(facultyId: 'f4', facultyName: 'Prof. John Nash', assignedSubjects: ['Mathematics III'], completedClasses: 1, pendingClasses: 0, lastCompletionTime: DateTime.now().subtract(const Duration(minutes: 5))),
    ];
  }

  @override
  Future<List<StudentShortage>> getStudentShortages(String departmentId) async {
    await _delay();
    return [
      StudentShortage(studentId: 's10', studentName: 'Peter Parker', rollNumber: 'CS2025010', semester: 'Semester 3', section: 'DCME 3-A', currentPercentage: 62.4),
      StudentShortage(studentId: 's11', studentName: 'Clark Kent', rollNumber: 'CS2025011', semester: 'Semester 5', section: 'DCME 5-A', currentPercentage: 72.1),
      StudentShortage(studentId: 's12', studentName: 'Bruce Wayne', rollNumber: 'CS2025012', semester: 'Semester 3', section: 'DCME 3-B', currentPercentage: 58.0),
      StudentShortage(studentId: 's13', studentName: 'Diana Prince', rollNumber: 'CS2025013', semester: 'Semester 5', section: 'DCME 5-B', currentPercentage: 74.5),
    ];
  }

  @override
  Future<List<SectionAttendanceSummary>> getSectionAttendance(String departmentId, DateTime date) async {
    await _delay();
    return [
      SectionAttendanceSummary(sectionId: 'sec1', sectionName: 'DCME 3-A', semester: 'Semester 3', attendancePercentage: 85.2, present: 52, absent: 8, late: 2, totalStudents: 60),
      SectionAttendanceSummary(sectionId: 'sec2', sectionName: 'DCME 3-B', semester: 'Semester 3', attendancePercentage: 79.5, present: 48, absent: 12, late: 5, totalStudents: 60),
      SectionAttendanceSummary(sectionId: 'sec3', sectionName: 'DCME 5-A', semester: 'Semester 5', attendancePercentage: 92.1, present: 58, absent: 2, late: 0, totalStudents: 60),
      SectionAttendanceSummary(sectionId: 'sec4', sectionName: 'DCME 5-B', semester: 'Semester 5', attendancePercentage: 71.4, present: 42, absent: 18, late: 3, totalStudents: 60),
    ];
  }

  // ==========================================
  // COLLEGE ADMIN METHODS
  // ==========================================

  @override
  Future<CollegeAttendanceSummary> getCollegeSummary() async {
    await _delay();
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
    await _delay();
    return [
      DepartmentAttendanceComparison(departmentId: 'd1', departmentName: 'Computer Engineering', attendancePercentage: 84.5, studentCount: 850, facultyCount: 35, todayCompletionPercentage: 95.0, trend: TrendDirection.up),
      DepartmentAttendanceComparison(departmentId: 'd2', departmentName: 'ECE', attendancePercentage: 82.1, studentCount: 720, facultyCount: 30, todayCompletionPercentage: 88.5, trend: TrendDirection.up),
      DepartmentAttendanceComparison(departmentId: 'd3', departmentName: 'Mechanical Engineering', attendancePercentage: 78.4, studentCount: 650, facultyCount: 28, todayCompletionPercentage: 75.0, trend: TrendDirection.down),
      DepartmentAttendanceComparison(departmentId: 'd4', departmentName: 'Civil Engineering', attendancePercentage: 76.2, studentCount: 580, facultyCount: 25, todayCompletionPercentage: 80.0, trend: TrendDirection.neutral),
      DepartmentAttendanceComparison(departmentId: 'd5', departmentName: 'EEE', attendancePercentage: 79.8, studentCount: 450, facultyCount: 27, todayCompletionPercentage: 90.0, trend: TrendDirection.up),
    ];
  }

  @override
  Future<List<CollegeFacultyCompletion>> getCollegeFacultyCompletion(DateTime date) async {
    await _delay();
    return [
      CollegeFacultyCompletion(facultyId: 'f1', facultyName: 'Dr. Emily Chen', departmentName: 'Computer Engineering', assignedSubjects: ['Data Structures'], completedClasses: 2, pendingClasses: 0, lastCompletionTime: DateTime.now().subtract(const Duration(minutes: 15))),
      CollegeFacultyCompletion(facultyId: 'f2', facultyName: 'Prof. Robert Smith', departmentName: 'Mechanical Engineering', assignedSubjects: ['Thermodynamics'], completedClasses: 1, pendingClasses: 1, lastCompletionTime: DateTime.now().subtract(const Duration(hours: 2))),
      CollegeFacultyCompletion(facultyId: 'f3', facultyName: 'Dr. Aisha Patel', departmentName: 'ECE', assignedSubjects: ['Signals & Systems'], completedClasses: 0, pendingClasses: 2),
      CollegeFacultyCompletion(facultyId: 'f4', facultyName: 'Prof. Michael Johnson', departmentName: 'Civil Engineering', assignedSubjects: ['Structural Analysis'], completedClasses: 3, pendingClasses: 0, lastCompletionTime: DateTime.now().subtract(const Duration(minutes: 5))),
    ];
  }

  @override
  Future<List<CollegeStudentShortage>> getCollegeStudentShortages() async {
    await _delay();
    return [
      CollegeStudentShortage(studentId: 's20', studentName: 'Tom Holland', rollNumber: 'ME2025020', departmentName: 'Mechanical', semester: 'Semester 5', currentPercentage: 55.2, status: ShortageStatus.critical),
      CollegeStudentShortage(studentId: 's21', studentName: 'Zendaya Coleman', rollNumber: 'CE2025021', departmentName: 'Civil', semester: 'Semester 3', currentPercentage: 62.5, status: ShortageStatus.critical),
      CollegeStudentShortage(studentId: 's22', studentName: 'Jacob Batalon', rollNumber: 'CS2025022', departmentName: 'Computer Science', semester: 'Semester 5', currentPercentage: 71.0, status: ShortageStatus.warning),
      CollegeStudentShortage(studentId: 's23', studentName: 'Laura Harrier', rollNumber: 'EC2025023', departmentName: 'ECE', semester: 'Semester 7', currentPercentage: 68.4, status: ShortageStatus.warning),
    ];
  }

  @override
  Future<List<CollegeInsight>> getCollegeInsights() async {
    await _delay();
    return [
      CollegeInsight(title: 'Highest Attendance', value: 'Computer Engineering', subtitle: '84.5% Overall', isPositive: true),
      CollegeInsight(title: 'Lowest Attendance', value: 'Civil Engineering', subtitle: '76.2% Overall', isPositive: false),
      CollegeInsight(title: 'Pending Faculty', value: '22', subtitle: 'Across all departments', isPositive: false),
      CollegeInsight(title: 'Critical Shortages', value: '154', subtitle: 'Students below 65%', isPositive: false),
    ];
  }

  // ==========================================
  // SUPER ADMIN METHODS
  // ==========================================

  @override
  Future<SuperAdminAttendanceSummary> getSuperAdminSummary() async {
    await _delay();
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
    await _delay();
    return [
      CollegeAttendanceComparison(collegeId: 'c1', collegeName: 'Acadex Institute of Technology', collegeCode: 'AIT', attendancePercentage: 88.2, studentCount: 4500, facultyCount: 320, departmentCount: 8, completionRate: 98.0, trend: TrendDirection.up),
      CollegeAttendanceComparison(collegeId: 'c2', collegeName: 'Acadex Business School', collegeCode: 'ABS', attendancePercentage: 85.1, studentCount: 2200, facultyCount: 150, departmentCount: 4, completionRate: 95.5, trend: TrendDirection.up),
      CollegeAttendanceComparison(collegeId: 'c3', collegeName: 'Acadex College of Arts & Science', collegeCode: 'ACAS', attendancePercentage: 81.4, studentCount: 3800, facultyCount: 240, departmentCount: 12, completionRate: 88.0, trend: TrendDirection.down),
      CollegeAttendanceComparison(collegeId: 'c4', collegeName: 'Acadex Medical College', collegeCode: 'AMC', attendancePercentage: 92.5, studentCount: 1800, facultyCount: 450, departmentCount: 15, completionRate: 100.0, trend: TrendDirection.up),
      CollegeAttendanceComparison(collegeId: 'c5', collegeName: 'Acadex Law Academy', collegeCode: 'ALA', attendancePercentage: 79.8, studentCount: 1200, facultyCount: 80, departmentCount: 3, completionRate: 82.0, trend: TrendDirection.neutral),
    ];
  }

  @override
  Future<List<SuperAdminFacultyCompletion>> getSuperAdminFacultyCompletion(DateTime date) async {
    await _delay();
    return [
      SuperAdminFacultyCompletion(facultyId: 'f1', facultyName: 'Dr. Emily Chen', collegeName: 'AIT', departmentName: 'Computer Engineering', assignedSubjects: ['Data Structures'], completedClasses: 2, pendingClasses: 0, lastCompletionTime: DateTime.now().subtract(const Duration(minutes: 15))),
      SuperAdminFacultyCompletion(facultyId: 'f2', facultyName: 'Prof. Robert Smith', collegeName: 'AIT', departmentName: 'Mechanical Engineering', assignedSubjects: ['Thermodynamics'], completedClasses: 1, pendingClasses: 1, lastCompletionTime: DateTime.now().subtract(const Duration(hours: 2))),
      SuperAdminFacultyCompletion(facultyId: 'f5', facultyName: 'Dr. Sarah Connor', collegeName: 'AMC', departmentName: 'Anatomy', assignedSubjects: ['Human Anatomy'], completedClasses: 1, pendingClasses: 0, lastCompletionTime: DateTime.now().subtract(const Duration(hours: 1))),
      SuperAdminFacultyCompletion(facultyId: 'f6', facultyName: 'Prof. Alan Grant', collegeName: 'ACAS', departmentName: 'Biology', assignedSubjects: ['Genetics'], completedClasses: 0, pendingClasses: 2),
    ];
  }

  @override
  Future<List<SuperAdminStudentShortage>> getSuperAdminStudentShortages() async {
    await _delay();
    return [
      SuperAdminStudentShortage(studentId: 's20', studentName: 'Tom Holland', rollNumber: 'ME2025020', collegeName: 'AIT', departmentName: 'Mechanical', semester: 'Semester 5', currentPercentage: 55.2, status: ShortageStatus.critical),
      SuperAdminStudentShortage(studentId: 's21', studentName: 'Zendaya Coleman', rollNumber: 'CE2025021', collegeName: 'AIT', departmentName: 'Civil', semester: 'Semester 3', currentPercentage: 62.5, status: ShortageStatus.critical),
      SuperAdminStudentShortage(studentId: 's24', studentName: 'Chris Evans', rollNumber: 'LAW2025001', collegeName: 'ALA', departmentName: 'Corporate Law', semester: 'Semester 1', currentPercentage: 45.0, status: ShortageStatus.critical),
      SuperAdminStudentShortage(studentId: 's25', studentName: 'Scarlett Johansson', rollNumber: 'MED2025112', collegeName: 'AMC', departmentName: 'Surgery', semester: 'Semester 7', currentPercentage: 69.8, status: ShortageStatus.warning),
    ];
  }

  @override
  Future<List<SuperAdminInsight>> getSuperAdminInsights() async {
    await _delay();
    return [
      SuperAdminInsight(title: 'Top Performing College', value: 'Acadex Medical College', subtitle: '92.5% Average Attendance', isPositive: true),
      SuperAdminInsight(title: 'Lowest Performing', value: 'Acadex Law Academy', subtitle: '79.8% Average Attendance', isPositive: false),
      SuperAdminInsight(title: 'Pending Faculty', value: '85', subtitle: 'Across 8 colleges', isPositive: false),
      SuperAdminInsight(title: 'Critical Shortages', value: '420', subtitle: 'Students below 65%', isPositive: false),
    ];
  }

  @override
  Future<SuperAdminSystemHealth> getSuperAdminSystemHealth() async {
    await _delay();
    return SuperAdminSystemHealth(
      serverStatus: 'Healthy',
      syncStatus: 'All Systems Synced',
      apiLatency: '45ms',
      activeUsers: 3450,
    );
  }
}

final mockAttendanceRepo = MockAttendanceRepository();
