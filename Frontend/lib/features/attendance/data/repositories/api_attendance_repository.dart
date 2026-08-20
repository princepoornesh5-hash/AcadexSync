import '../../../../core/network/api_client.dart';
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
import '../../domain/models/attendance_analytics_models.dart';
import '../../domain/repositories/attendance_repository.dart';
import 'mock_attendance_repository.dart';

class ApiAttendanceRepository implements AttendanceRepository {
  final ApiClient _client;
  final MockAttendanceRepository _fallbackMock;

  ApiAttendanceRepository([ApiClient? client])
      : _client = client ?? apiClient,
        _fallbackMock = MockAttendanceRepository();

  @override
  Future<List<AssignedClass>> getAssignedClasses(String facultyId, DateTime date) async {
    try {
      final response = await _client.dio.get('/academics/faculty/workload');
      final body = response.data;
      final data = body is Map<String, dynamic> ? (body['data'] ?? body) : body;
      
      final list = data is List ? data : (data is Map && data['workload'] is List ? data['workload'] as List : null);
      if (list != null && list.isNotEmpty) {
        return list.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value as Map<String, dynamic>;
          final subjectName = (item['subjectName'] ?? item['subject'] ?? 'Subject').toString();
          final sectionName = (item['sectionName'] ?? item['section'] ?? 'A').toString();
          final subjectId = (item['subjectId'] ?? '').toString();
          final sectionId = (item['sectionId'] ?? '').toString();
          final timeSlot = (item['timeSlot'] ?? '${9 + idx}:00 AM - ${10 + idx}:00 AM').toString();
          
          return AssignedClass(
            id: (item['id'] ?? 'class_$idx').toString(),
            subjectName: subjectName,
            subjectId: subjectId,
            sectionName: sectionName,
            sectionId: sectionId,
            semester: (item['semester'] ?? item['semesterId'] ?? 'Semester 1').toString(),
            timeSlot: timeSlot,
            roomNumber: (item['roomNumber'] ?? item['room'] ?? '101').toString(),
            date: date,
            isAttendanceMarked: item['isAttendanceMarked'] == true,
          );
        }).toList();
      }
      return _fallbackMock.getAssignedClasses(facultyId, date);
    } catch (_) {
      return _fallbackMock.getAssignedClasses(facultyId, date);
    }
  }

  @override
  Stream<List<AssignedClass>> watchAssignedClasses(String facultyId, DateTime date) =>
      Stream.fromFuture(getAssignedClasses(facultyId, date));

  @override
  Future<List<SubjectAttendance>> getStudentSubjectAttendance(String studentId) async {
    try {
      final response = await _client.dio.get('/attendance/students/me/subjects');
      final body = response.data;
      final data = body is Map<String, dynamic> ? (body['data'] ?? body) : body;
      final subjects = data is List ? data : (data is Map && data['subjects'] is List ? data['subjects'] as List : null);
      if (subjects != null && subjects.isNotEmpty) {
        return subjects.map((s) {
          final m = s as Map<String, dynamic>;
          final present = (m['presentCount'] as num?)?.toInt() ?? (m['present'] as num?)?.toInt() ?? 0;
          final total = (m['totalClasses'] as num?)?.toInt() ?? (m['total'] as num?)?.toInt() ?? 0;
          final missed = total >= present ? total - present : 0;
          return SubjectAttendance(
            subjectId: (m['subjectId'] ?? '').toString(),
            subjectName: (m['subjectName'] ?? '').toString(),
            subjectCode: (m['subjectCode'] ?? '').toString(),
            facultyName: (m['facultyName'] ?? 'Faculty').toString(),
            totalClasses: total,
            attendedClasses: present,
            missedClasses: missed,
          );
        }).toList();
      }
      return _fallbackMock.getStudentSubjectAttendance(studentId);
    } catch (_) {
      return _fallbackMock.getStudentSubjectAttendance(studentId);
    }
  }

  @override
  Future<StudentAttendanceOverview> getStudentAttendanceOverview(String studentId) async {
    try {
      final response = await _client.dio.get('/attendance/students/me/summary');
      final body = response.data;
      final data = body is Map<String, dynamic> ? (body['data'] ?? body) : body;
      if (data is Map<String, dynamic>) {
        final total = (data['totalClasses'] as num?)?.toInt() ?? 0;
        final present = (data['presentCount'] as num?)?.toInt() ?? 0;
        final percentage = (data['percentage'] as num?)?.toDouble() ?? (total > 0 ? (present / total) * 100 : 0.0);
        return StudentAttendanceOverview(
          overallPercentage: percentage,
        );
      }
      return _fallbackMock.getStudentAttendanceOverview(studentId);
    } catch (_) {
      return _fallbackMock.getStudentAttendanceOverview(studentId);
    }
  }

  @override
  Future<List<AttendanceHistoryRecord>> getStudentAttendanceHistory(
    String studentId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) queryParams['from'] = startDate.toIso8601String();
      if (endDate != null) queryParams['to'] = endDate.toIso8601String();

      final response = await _client.dio.get(
        '/attendance/students/me',
        queryParameters: queryParams,
      );
      final body = response.data;
      final data = body is Map<String, dynamic> ? (body['data'] ?? body) : body;
      final items = data is Map && data['items'] is List
          ? data['items'] as List
          : (data is List ? data : null);

      if (items != null && items.isNotEmpty) {
        return items.map((item) {
          final m = item as Map<String, dynamic>;
          final statusStr = (m['status'] ?? 'PRESENT').toString().toLowerCase();
          AttendanceStatus status;
          if (statusStr.contains('late')) {
            status = AttendanceStatus.late;
          } else if (statusStr.contains('absent')) {
            status = AttendanceStatus.absent;
          } else if (statusStr.contains('excused')) {
            status = AttendanceStatus.excused;
          } else {
            status = AttendanceStatus.present;
          }

          final dateParsed = m['date'] != null
              ? DateTime.tryParse(m['date'].toString()) ?? DateTime.now()
              : DateTime.now();

          return AttendanceHistoryRecord(
            id: (m['id'] ?? m['_id'] ?? '').toString(),
            subjectId: (m['subjectId'] ?? '').toString(),
            subjectName: (m['subjectName'] ?? 'Subject').toString(),
            date: dateParsed,
            timeSlot: (m['timeSlot'] ?? '10:00 AM - 11:00 AM').toString(),
            status: status,
            facultyName: (m['facultyName'] ?? 'Faculty').toString(),
          );
        }).toList();
      }
      return _fallbackMock.getStudentAttendanceHistory(studentId, startDate: startDate, endDate: endDate);
    } catch (_) {
      return _fallbackMock.getStudentAttendanceHistory(studentId, startDate: startDate, endDate: endDate);
    }
  }

  @override
  Future<List<MonthlyAttendanceSummary>> getStudentMonthlySummary(String studentId) =>
      _fallbackMock.getStudentMonthlySummary(studentId);

  @override
  Future<List<AttendanceRecord>> getStudentsForSection(
    String sectionId,
    String subjectId,
    DateTime date, {
    String? timetableEntryId,
  }) async {
    try {
      final response = await _client.dio.get(
        '/academics/students/enrollment',
        queryParameters: {'sectionId': sectionId},
      );
      final body = response.data;
      final data = body is Map<String, dynamic> ? (body['data'] ?? body) : body;
      final list = data is List ? data : (data is Map && data['enrollments'] is List ? data['enrollments'] as List : null);

      if (list != null && list.isNotEmpty) {
        return list.map((item) {
          final m = item as Map<String, dynamic>;
          final sId = (m['studentId'] ?? m['id'] ?? m['_id'] ?? '').toString();
          final sName = (m['studentName'] ?? m['name'] ?? 'Student').toString();
          final roll = (m['rollNumber'] ?? m['instituteId'] ?? 'ROLL-01').toString();

          return AttendanceRecord(
            id: 'rec_$sId',
            studentId: sId,
            studentName: sName,
            rollNumber: roll,
            sectionId: sectionId,
            status: null, // Initial unmarked status for faculty to mark
          );
        }).toList();
      }
      return _fallbackMock.getStudentsForSection(sectionId, subjectId, date, timetableEntryId: timetableEntryId);
    } catch (_) {
      return _fallbackMock.getStudentsForSection(sectionId, subjectId, date, timetableEntryId: timetableEntryId);
    }
  }

  @override
  Future<bool> saveSession(AttendanceSession session) async {
    try {
      final response = await _client.dio.post('/attendance/sessions', data: {
        'collegeId': session.collegeId,
        'departmentId': session.departmentId,
        'sectionId': session.sectionId,
        'sectionName': session.sectionName,
        'subjectId': session.subjectId,
        'subjectName': session.subjectName,
        'facultyId': session.facultyId,
        'timeSlot': session.timeSlot,
        'date': session.date.toIso8601String().substring(0, 10),
        'records': session.records.map((r) => {
          'studentId': r.studentId,
          'studentName': r.studentName,
          'rollNumber': r.rollNumber,
          'status': (r.status?.name ?? 'PRESENT').toUpperCase(),
        }).toList(),
      });
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return _fallbackMock.saveSession(session);
    }
  }

  @override
  Future<List<AttendanceSession>> getRecentSessions(String facultyId) async {
    try {
      final response = await _client.dio.get('/attendance/faculty/me');
      final body = response.data;
      final data = body is Map<String, dynamic> ? (body['data'] ?? body) : body;
      final list = data is List ? data : (data is Map && data['sessions'] is List ? data['sessions'] as List : null);

      if (list != null && list.isNotEmpty) {
        return list.map((item) {
          final m = item as Map<String, dynamic>;
          final dateParsed = m['date'] != null
              ? DateTime.tryParse(m['date'].toString()) ?? DateTime.now()
              : DateTime.now();

          final secId = (m['sectionId'] ?? '').toString();
          final recordsRaw = (m['records'] as List?) ?? [];
          final records = recordsRaw.map((r) {
            final rm = r as Map<String, dynamic>;
            final stStr = (rm['status'] ?? 'PRESENT').toString().toLowerCase();
            AttendanceStatus st;
            if (stStr.contains('late')) {
              st = AttendanceStatus.late;
            } else if (stStr.contains('absent')) {
              st = AttendanceStatus.absent;
            } else if (stStr.contains('excused')) {
              st = AttendanceStatus.excused;
            } else {
              st = AttendanceStatus.present;
            }
            final rStudentId = (rm['studentId'] ?? '').toString();
            return AttendanceRecord(
              id: (rm['id'] ?? 'rec_$rStudentId').toString(),
              studentId: rStudentId,
              studentName: (rm['studentName'] ?? 'Student').toString(),
              rollNumber: (rm['rollNumber'] ?? '').toString(),
              sectionId: secId,
              status: st,
            );
          }).toList();

          return AttendanceSession(
            id: (m['id'] ?? m['_id'] ?? '').toString(),
            collegeId: (m['collegeId'] ?? '').toString(),
            departmentId: (m['departmentId'] ?? '').toString(),
            sectionId: secId,
            sectionName: (m['sectionName'] ?? 'Section').toString(),
            subjectId: (m['subjectId'] ?? '').toString(),
            subjectName: (m['subjectName'] ?? 'Subject').toString(),
            facultyId: (m['facultyId'] ?? facultyId).toString(),
            timeSlot: (m['timeSlot'] ?? '10:00 AM - 11:00 AM').toString(),
            date: dateParsed,
            records: records,
          );
        }).toList();
      }
      return _fallbackMock.getRecentSessions(facultyId);
    } catch (_) {
      return _fallbackMock.getRecentSessions(facultyId);
    }
  }

  @override
  Future<DepartmentAttendanceSummary> getDepartmentSummary(String departmentId) =>
      _fallbackMock.getDepartmentSummary(departmentId);

  @override
  Stream<DepartmentAttendanceSummary> watchDepartmentSummary(String departmentId) =>
      _fallbackMock.watchDepartmentSummary(departmentId);

  @override
  Future<List<FacultyAttendanceCompletion>> getFacultyCompletionStatus(String departmentId, DateTime date) =>
      _fallbackMock.getFacultyCompletionStatus(departmentId, date);

  @override
  Future<List<StudentShortage>> getStudentShortages(String departmentId) =>
      _fallbackMock.getStudentShortages(departmentId);

  @override
  Future<List<SectionAttendanceSummary>> getSectionAttendance(String departmentId, DateTime date) =>
      _fallbackMock.getSectionAttendance(departmentId, date);

  @override
  Future<CollegeAttendanceSummary> getCollegeSummary() =>
      _fallbackMock.getCollegeSummary();

  @override
  Stream<CollegeAttendanceSummary> watchCollegeSummary() =>
      _fallbackMock.watchCollegeSummary();

  @override
  Future<List<DepartmentAttendanceComparison>> getDepartmentComparisons() =>
      _fallbackMock.getDepartmentComparisons();

  @override
  Future<List<CollegeInsight>> getCollegeInsights() =>
      _fallbackMock.getCollegeInsights();

  @override
  Future<List<CollegeFacultyCompletion>> getCollegeFacultyCompletion(DateTime date) =>
      _fallbackMock.getCollegeFacultyCompletion(date);

  @override
  Future<List<CollegeStudentShortage>> getCollegeStudentShortages() =>
      _fallbackMock.getCollegeStudentShortages();

  @override
  Future<SuperAdminAttendanceSummary> getSuperAdminSummary() =>
      _fallbackMock.getSuperAdminSummary();

  @override
  Stream<SuperAdminAttendanceSummary> watchSuperAdminSummary() =>
      _fallbackMock.watchSuperAdminSummary();

  @override
  Future<List<CollegeAttendanceComparison>> getCollegeComparisons() =>
      _fallbackMock.getCollegeComparisons();

  @override
  Future<List<SuperAdminInsight>> getSuperAdminInsights() =>
      _fallbackMock.getSuperAdminInsights();

  @override
  Future<SuperAdminSystemHealth> getSuperAdminSystemHealth() =>
      _fallbackMock.getSuperAdminSystemHealth();

  @override
  Future<List<SuperAdminFacultyCompletion>> getSuperAdminFacultyCompletion(DateTime date) =>
      _fallbackMock.getSuperAdminFacultyCompletion(date);

  @override
  Future<List<SuperAdminStudentShortage>> getSuperAdminStudentShortages() =>
      _fallbackMock.getSuperAdminStudentShortages();

  @override
  Future<StudentAttendanceAnalytics> getStudentAttendanceAnalytics(String studentId, {AttendanceDateRange? dateRange}) =>
      _fallbackMock.getStudentAttendanceAnalytics(studentId, dateRange: dateRange);

  @override
  Future<SubjectAttendanceAnalytics> getSubjectAttendanceAnalytics(String subjectId, {String? sectionId, AttendanceDateRange? dateRange}) =>
      _fallbackMock.getSubjectAttendanceAnalytics(subjectId, sectionId: sectionId, dateRange: dateRange);

  @override
  Future<SectionAttendanceAnalytics> getSectionAttendanceAnalytics(String sectionId, {AttendanceDateRange? dateRange}) =>
      _fallbackMock.getSectionAttendanceAnalytics(sectionId, dateRange: dateRange);

  @override
  Future<FacultyAttendanceAnalytics> getFacultyAttendanceAnalytics(String facultyId, {AttendanceDateRange? dateRange}) =>
      _fallbackMock.getFacultyAttendanceAnalytics(facultyId, dateRange: dateRange);

  @override
  Future<AttendanceDateRangeSummary> getAttendanceDateRangeSummary({AttendanceDateRange? dateRange, String? departmentId, String? sectionId}) =>
      _fallbackMock.getAttendanceDateRangeSummary(dateRange: dateRange, departmentId: departmentId, sectionId: sectionId);
}
