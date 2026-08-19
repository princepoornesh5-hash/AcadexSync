import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import '../../../../core/firebase/firebase_services.dart';
import '../../../../core/firebase/firebase_initializer.dart';
import '../../domain/models/assigned_class.dart';
import '../../domain/models/attendance_history_record.dart';
import '../../domain/models/attendance_record.dart';
import '../../domain/models/attendance_session.dart';
import '../../domain/models/attendance_status.dart';
import '../../../../features/auth/domain/models/user_model.dart';
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
import '../../../../features/notifications/domain/services/notification_service.dart';
import '../../../../features/timetable/domain/models/timetable_models.dart';

class FirebaseAttendanceRepository implements AttendanceRepository {
  final FirestoreService _firestoreService;
  final UserModel? _currentUser;
  final NotificationService? notificationService;

  FirebaseAttendanceRepository(
    this._firestoreService, 
    this._currentUser, {
    this.notificationService,
  });

  void _debugLog(String operation, Map<String, dynamic> metadata) {
    if (kDebugMode) {
      final safeMetadata = Map<String, dynamic>.from(metadata)
        ..removeWhere((key, _) => key.toLowerCase().contains('password') || key.toLowerCase().contains('secret'));
      final formatted = safeMetadata.entries.map((e) => '${e.key}=${e.value}').join(', ');
      developer.log('[Attendance] $operation: $formatted', name: 'Acadex.Attendance');
    }
  }

  @override
  Future<List<AssignedClass>> getAssignedClasses(String facultyId, DateTime date) async {
    final userCollegeId = _currentUser?.collegeId;
    _debugLog('getAssignedClasses', {
      'facultyId': facultyId,
      'date': date.toIso8601String(),
      'collegeId': userCollegeId,
      'role': _currentUser?.role.name,
    });

    final dayIndex = date.weekday - 1;
    final dayName = TimetableDay.values[dayIndex].name;

    final filters = <String, dynamic>{
      'facultyId': facultyId,
      'dayOfWeek': dayName,
      if (userCollegeId != null && userCollegeId.isNotEmpty)
        'collegeId': userCollegeId,
    };

    final timetableDocs = await _firestoreService.queryCollection('timetable', filters);

    final assignedClasses = <AssignedClass>[];
    for (var doc in timetableDocs) {
      final subjectId = doc['subjectId'] as String;
      final sectionId = doc['sectionId'] as String;

      final subjectDoc = await _firestoreService.getDocument('subjects', subjectId);
      final sectionDoc = await _firestoreService.getDocument('sections', sectionId);

      assignedClasses.add(AssignedClass(
        id: doc['id'] as String,
        subjectId: subjectId,
        subjectName: subjectDoc?['name'] ?? subjectId,
        sectionId: sectionId,
        sectionName: sectionDoc?['name'] ?? sectionId,
        semester: doc['semesterId'] ?? '',
        timeSlot: '${doc['startTime']} - ${doc['endTime']}',
        date: date,
      ));
    }
    return assignedClasses;
  }

  @override
  Stream<List<AssignedClass>> watchAssignedClasses(String facultyId, DateTime date) {
    return Stream.fromFuture(getAssignedClasses(facultyId, date));
  }

  @override
  Future<List<AttendanceRecord>> getStudentsForSection(String sectionId, String subjectId, DateTime date) async {
    final sessionId = '${sectionId}_${subjectId}_${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
    final userCollegeId = _currentUser?.collegeId;
    _debugLog('getStudentsForSection', {
      'sectionId': sectionId,
      'subjectId': subjectId,
      'sessionId': sessionId,
      'collegeId': userCollegeId,
    });

    final doc = await _firestoreService.getDocument('attendanceSessions', sessionId);
    if (doc != null) {
      final session = AttendanceSession.fromJson(doc);
      return session.records;
    }

    final filters = <String, dynamic>{
      'sectionId': sectionId, 
      'isActive': true,
      if (userCollegeId != null && userCollegeId.isNotEmpty)
        'collegeId': userCollegeId,
    };

    final studentDocs = await _firestoreService.queryCollection('students', filters);
    
    return studentDocs.map((doc) => AttendanceRecord(
      id: doc['id'] as String,
      studentId: doc['id'] as String,
      studentName: doc['name'] as String,
      rollNumber: doc['rollNumber'] as String,
      sectionId: sectionId,
    )).toList();
  }

  @override
  Future<bool> saveSession(AttendanceSession session) async {
    final sessionId = '${session.sectionId}_${session.subjectId}_${session.date.year}${session.date.month.toString().padLeft(2, '0')}${session.date.day.toString().padLeft(2, '0')}';
    final now = DateTime.now();

    final collegeId = session.collegeId.isNotEmpty 
        ? session.collegeId 
        : (_currentUser?.collegeId ?? (FirebaseInitializer.shouldUseMock ? 'col-1' : ''));
    final departmentId = session.departmentId.isNotEmpty 
        ? session.departmentId 
        : (_currentUser?.departmentId ?? (FirebaseInitializer.shouldUseMock ? 'dept-1' : ''));
    final facultyId = session.facultyId.isNotEmpty 
        ? session.facultyId 
        : (_currentUser?.id ?? '');

    if (!FirebaseInitializer.shouldUseMock) {
      if (collegeId.isEmpty || facultyId.isEmpty) {
        throw StateError("Incomplete profile: Missing collegeId or facultyId.");
      }
    }

    final updatedSession = session.copyWith(
      id: sessionId,
      collegeId: collegeId,
      departmentId: departmentId,
      facultyId: facultyId,
      isSubmitted: true,
      createdAt: session.createdAt ?? now,
      createdBy: session.createdBy ?? facultyId,
      lastModifiedAt: now,
      lastModifiedBy: facultyId,
    );

    _debugLog('saveSession', {
      'sessionId': sessionId,
      'facultyId': facultyId,
      'collegeId': collegeId,
      'departmentId': departmentId,
      'recordsCount': session.records.length,
    });

    final batchDocs = <String, Map<String, dynamic>>{};
    batchDocs['attendanceSessions/$sessionId'] = updatedSession.toJson();

    final dateString = session.date.toIso8601String().split('T').first;

    for (final record in session.records) {
      if (record.status != null) {
        final recordId = '${sessionId}_${record.studentId}';
        batchDocs['attendance/$recordId'] = {
          'attendanceId': recordId,
          'sessionId': sessionId,
          'studentId': record.studentId,
          'studentName': record.studentName,
          'rollNumber': record.rollNumber,
          'sectionId': record.sectionId.isNotEmpty ? record.sectionId : session.sectionId,
          'subjectId': session.subjectId,
          'facultyId': facultyId,
          'collegeId': collegeId,
          'departmentId': departmentId,
          'date': dateString,
          'status': record.status!.name,
          'markedAt': now.toIso8601String(),
          'markedBy': facultyId,
        };
      }
    }

    await _firestoreService.batchSetDocuments(batchDocs);

    if (notificationService != null) {
      try {
        await notificationService!.notifyAttendanceMarked(
          sectionId: updatedSession.sectionId,
          subjectName: updatedSession.subjectName.isNotEmpty ? updatedSession.subjectName : updatedSession.subjectId,
          sessionDate: updatedSession.date,
        );
      } catch (e) {
        _debugLog('notifyAttendanceMarked_failed', {'error': e.toString()});
      }
    }

    return true;
  }

  @override
  Future<List<AttendanceSession>> getRecentSessions(String facultyId) async {
    final userCollegeId = _currentUser?.collegeId;
    _debugLog('getRecentSessions', {
      'facultyId': facultyId,
      'collegeId': userCollegeId,
    });

    final filters = <String, dynamic>{
      'facultyId': facultyId,
      if (userCollegeId != null && userCollegeId.isNotEmpty)
        'collegeId': userCollegeId,
    };

    final docs = await _firestoreService.queryCollection('attendanceSessions', filters);
    final sessions = docs.map((doc) => AttendanceSession.fromJson(doc)).toList();
    sessions.sort((a, b) => b.date.compareTo(a.date));
    return sessions;
  }

  @override
  Future<List<SubjectAttendance>> getStudentSubjectAttendance(String studentId) async {
    final userCollegeId = _currentUser?.collegeId;
    _debugLog('getStudentSubjectAttendance', {
      'studentId': studentId,
      'collegeId': userCollegeId,
    });

    final filters = <String, dynamic>{
      'studentId': studentId,
      if (userCollegeId != null && userCollegeId.isNotEmpty)
        'collegeId': userCollegeId,
    };

    final docs = await _firestoreService.queryCollection('attendance', filters);
    
    final Map<String, int> totalClasses = {};
    final Map<String, int> attendedClasses = {};
    
    for (var doc in docs) {
      final subjectId = doc['subjectId'] as String;
      final status = doc['status'] as String;
      
      totalClasses[subjectId] = (totalClasses[subjectId] ?? 0) + 1;
      if (status == AttendanceStatus.present.name || status == AttendanceStatus.late.name) {
        attendedClasses[subjectId] = (attendedClasses[subjectId] ?? 0) + 1;
      }
    }

    final result = <SubjectAttendance>[];
    for (final subjectId in totalClasses.keys) {
      final subjectDoc = await _firestoreService.getDocument('subjects', subjectId);
      final total = totalClasses[subjectId]!;
      final attended = attendedClasses[subjectId] ?? 0;
      
      result.add(SubjectAttendance(
        subjectId: subjectId,
        subjectName: subjectDoc?['name'] ?? subjectId,
        subjectCode: subjectDoc?['code'] ?? '',
        facultyName: 'Assigned Faculty',
        totalClasses: total,
        attendedClasses: attended,
        missedClasses: total - attended,
      ));
    }
    return result;
  }

  @override
  Future<StudentAttendanceOverview> getStudentAttendanceOverview(String studentId) async {
    final stats = await getStudentSubjectAttendance(studentId);
    if (stats.isEmpty) return StudentAttendanceOverview(overallPercentage: 0.0);
    
    int total = 0;
    int attended = 0;
    for (var stat in stats) {
      total += stat.totalClasses;
      attended += stat.attendedClasses;
    }
    return StudentAttendanceOverview(overallPercentage: total > 0 ? (attended / total) * 100 : 0.0);
  }

  @override
  Future<List<AttendanceHistoryRecord>> getStudentAttendanceHistory(String studentId, {DateTime? startDate, DateTime? endDate}) async {
    final userCollegeId = _currentUser?.collegeId;
    _debugLog('getStudentAttendanceHistory', {
      'studentId': studentId,
      'collegeId': userCollegeId,
    });

    final filters = <String, dynamic>{
      'studentId': studentId,
      if (userCollegeId != null && userCollegeId.isNotEmpty)
        'collegeId': userCollegeId,
    };

    final docs = await _firestoreService.queryCollection('attendance', filters);
    
    final records = <AttendanceHistoryRecord>[];
    for (var doc in docs) {
      final dateStr = doc['date'] as String;
      final date = DateTime.parse(dateStr);
      
      if (startDate != null && date.isBefore(startDate)) continue;
      if (endDate != null && date.isAfter(endDate)) continue;
      
      final subjectId = doc['subjectId'] as String;
      final subjectDoc = await _firestoreService.getDocument('subjects', subjectId);
      final facultyId = doc['facultyId'] as String;
      final facultyDoc = await _firestoreService.getDocument('faculty', facultyId);
      
      final statusStr = doc['status'] as String;
      final status = AttendanceStatus.values.firstWhere((e) => e.name == statusStr, orElse: () => AttendanceStatus.absent);

      records.add(AttendanceHistoryRecord(
        id: doc['attendanceId'] as String,
        date: date,
        subjectId: subjectId,
        subjectName: subjectDoc?['name'] ?? subjectId,
        facultyName: facultyDoc?['name'] ?? 'Faculty',
        status: status,
        timeSlot: 'Regular Class',
      ));
    }
    
    records.sort((a, b) => b.date.compareTo(a.date));
    return records;
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
