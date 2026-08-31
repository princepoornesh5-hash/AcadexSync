import 'package:dio/dio.dart';
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

class ApiAttendanceRepository implements AttendanceRepository {
  final ApiClient _client;

  ApiAttendanceRepository([ApiClient? client]) : _client = client ?? apiClient;

  Exception _extractError(DioException e, String fallback) {
    String? message;
    final data = e.response?.data;
    if (data is Map) {
      final err = data['error'];
      if (err is Map) {
        message = err['message']?.toString();
      } else if (err is String) {
        message = err;
      }
      message ??= data['message']?.toString();
    } else if (data is String && data.isNotEmpty) {
      message = data;
    }
    message ??= e.message ?? fallback;
    return Exception(message);
  }

  @override
  Future<List<AssignedClass>> getAssignedClasses(String facultyId, DateTime date) async {
    try {
      final response = await _client.dio.get('/timetables/faculty/$facultyId');
      final body = response.data;
      final data = body is Map<String, dynamic> ? (body['data'] ?? body) : body;
      final list = data is List ? data : (data is Map && data['entries'] is List ? data['entries'] as List : null);
      if (list != null) {
        return list.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value as Map<String, dynamic>;
          final subjectName = (item['subjectName'] ?? item['subject']?['name'] ?? 'Subject').toString();
          final sectionName = (item['sectionName'] ?? item['section']?['name'] ?? 'A').toString();
          final subjectId = (item['subjectId'] ?? item['subject']?['_id'] ?? '').toString();
          final sectionId = (item['sectionId'] ?? item['section']?['_id'] ?? '').toString();
          final timeSlot = (item['timeSlot'] ?? '${item['startTime'] ?? '09:00'} - ${item['endTime'] ?? '10:00'}').toString();

          return AssignedClass(
            id: (item['id'] ?? item['_id'] ?? 'class_$idx').toString(),
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
      return [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 404 || (e.response?.statusCode != null && e.response!.statusCode! >= 400) || e.type == DioExceptionType.connectionError) {
        return [];
      }
      throw _extractError(e, 'Failed to fetch assigned classes');
    } catch (_) {
      return [];
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
      if (subjects != null) {
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
      return [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return [];
      throw _extractError(e, 'Failed to fetch subject attendance');
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
      return StudentAttendanceOverview(overallPercentage: 0.0);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return StudentAttendanceOverview(overallPercentage: 0.0);
      throw _extractError(e, 'Failed to fetch student attendance overview');
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

      if (items != null) {
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
      return [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 404 || (e.response?.statusCode != null && e.response!.statusCode! >= 400) || e.type == DioExceptionType.connectionError) {
        return [];
      }
      throw _extractError(e, 'Failed to fetch attendance history');
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<MonthlyAttendanceSummary>> getStudentMonthlySummary(String studentId) async {
    return [];
  }

  @override
  Future<List<AttendanceRecord>> getStudentsForSection(
    String sectionId,
    String subjectId,
    DateTime date, {
    String? timetableEntryId,
  }) async {
    try {
      final response = await _client.dio.get(
        '/academics/students',
        queryParameters: {'sectionId': sectionId},
      );
      final body = response.data;
      final data = body is Map<String, dynamic> ? (body['data'] ?? body) : body;
      final list = data is List ? data : (data is Map && data['items'] is List ? data['items'] as List : null);

      if (list != null) {
        return list.map((item) {
          final m = item as Map<String, dynamic>;
          final sId = (m['id'] ?? m['_id'] ?? '').toString();
          final sName = (m['name'] ?? 'Student').toString();
          final roll = (m['rollNumber'] ?? m['instituteId'] ?? 'ROLL-01').toString();

          return AttendanceRecord(
            id: 'rec_$sId',
            studentId: sId,
            studentName: sName,
            rollNumber: roll,
            sectionId: sectionId,
            status: null,
          );
        }).toList();
      }
      return [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return [];
      throw _extractError(e, 'Failed to fetch students for section');
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
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to submit attendance session');
    }
  }

  @override
  Future<List<AttendanceSession>> getRecentSessions(String facultyId) async {
    try {
      final response = await _client.dio.get('/attendance/faculty/me');
      final body = response.data;
      final data = body is Map<String, dynamic> ? (body['data'] ?? body) : body;
      final list = data is List ? data : (data is Map && data['sessions'] is List ? data['sessions'] as List : null);

      if (list != null) {
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
      return [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return [];
      throw _extractError(e, 'Failed to fetch faculty sessions');
    }
  }

  @override
  Future<DepartmentAttendanceSummary> getDepartmentSummary(String departmentId) async {
    try {
      final response = await _client.dio.get('/reports/attendance/department/$departmentId');
      final body = response.data;
      final data = body is Map<String, dynamic> ? (body['data'] ?? body) : body;
      if (data is Map<String, dynamic>) {
        final summary = data['summary'] as Map<String, dynamic>? ?? data;
        return DepartmentAttendanceSummary(
          overallPercentage: (summary['attendancePercentage'] as num?)?.toDouble() ?? 0.0,
          studentsBelow75: (summary['studentsBelow75'] as num?)?.toInt() ?? 0,
          facultyCompleted: (summary['facultyCompleted'] as num?)?.toInt() ?? 0,
          facultyPending: (summary['facultyPending'] as num?)?.toInt() ?? 0,
          todayClasses: (summary['todayClasses'] as num?)?.toInt() ?? 0,
          totalStudents: (summary['totalStudents'] as num?)?.toInt() ?? 0,
          totalFaculty: (summary['totalFaculty'] as num?)?.toInt() ?? 0,
        );
      }
      return DepartmentAttendanceSummary(
        overallPercentage: 0.0,
        studentsBelow75: 0,
        facultyCompleted: 0,
        facultyPending: 0,
        todayClasses: 0,
        totalStudents: 0,
        totalFaculty: 0,
      );
    } catch (_) {
      return DepartmentAttendanceSummary(
        overallPercentage: 0.0,
        studentsBelow75: 0,
        facultyCompleted: 0,
        facultyPending: 0,
        todayClasses: 0,
        totalStudents: 0,
        totalFaculty: 0,
      );
    }
  }

  @override
  Stream<DepartmentAttendanceSummary> watchDepartmentSummary(String departmentId) =>
      Stream.fromFuture(getDepartmentSummary(departmentId));

  @override
  Future<List<FacultyAttendanceCompletion>> getFacultyCompletionStatus(String departmentId, DateTime date) async => [];

  @override
  Future<List<StudentShortage>> getStudentShortages(String departmentId) async => [];

  @override
  Future<List<SectionAttendanceSummary>> getSectionAttendance(String departmentId, DateTime date) async => [];

  @override
  Future<CollegeAttendanceSummary> getCollegeSummary() async {
    try {
      final response = await _client.dio.get('/reports/dashboard');
      final body = response.data;
      final data = body is Map<String, dynamic> ? (body['data'] ?? body) : body;
      if (data is Map<String, dynamic>) {
        final metrics = (data['metrics'] as Map<String, dynamic>?) ??
            (data['kpis'] as Map<String, dynamic>?) ??
            data;
        return CollegeAttendanceSummary(
          todayAttendancePercentage: (metrics['collegeAttendancePercentage'] as num?)?.toDouble() ??
              (metrics['avgAttendance'] as num?)?.toDouble() ??
              0.0,
          totalStudents: (metrics['studentsCount'] as num?)?.toInt() ??
              (metrics['totalStudents'] as num?)?.toInt() ??
              0,
          totalFaculty: (metrics['facultyCount'] as num?)?.toInt() ??
              (metrics['totalFaculty'] as num?)?.toInt() ??
              0,
          totalDepartments: (metrics['departmentsCount'] as num?)?.toInt() ??
              (metrics['totalDepartments'] as num?)?.toInt() ??
              0,
          studentsBelowThreshold: (metrics['studentsBelowThreshold'] as num?)?.toInt() ?? 0,
          pendingFaculty: 0,
          completedFaculty: (metrics['facultyCount'] as num?)?.toInt() ??
              (metrics['totalFaculty'] as num?)?.toInt() ??
              0,
        );
      }
      return CollegeAttendanceSummary(
        todayAttendancePercentage: 0.0,
        totalStudents: 0,
        totalFaculty: 0,
        totalDepartments: 0,
        studentsBelowThreshold: 0,
        pendingFaculty: 0,
        completedFaculty: 0,
      );
    } catch (_) {
      return CollegeAttendanceSummary(
        todayAttendancePercentage: 0.0,
        totalStudents: 0,
        totalFaculty: 0,
        totalDepartments: 0,
        studentsBelowThreshold: 0,
        pendingFaculty: 0,
        completedFaculty: 0,
      );
    }
  }

  @override
  Stream<CollegeAttendanceSummary> watchCollegeSummary() =>
      Stream.fromFuture(getCollegeSummary());

  @override
  Future<List<DepartmentAttendanceComparison>> getDepartmentComparisons() async => [];

  @override
  Future<List<CollegeInsight>> getCollegeInsights() async => [];

  @override
  Future<List<CollegeFacultyCompletion>> getCollegeFacultyCompletion(DateTime date) async => [];

  @override
  Future<List<CollegeStudentShortage>> getCollegeStudentShortages() async => [];

  @override
  Future<SuperAdminAttendanceSummary> getSuperAdminSummary() async {
    try {
      final response = await _client.dio.get('/reports/dashboard');
      final body = response.data;
      final data = body is Map<String, dynamic> ? (body['data'] ?? body) : body;
      if (data is Map<String, dynamic>) {
        final metrics = (data['metrics'] as Map<String, dynamic>?) ??
            (data['kpis'] as Map<String, dynamic>?) ??
            data;
        return SuperAdminAttendanceSummary(
          totalColleges: (metrics['totalColleges'] as num?)?.toInt() ??
              (metrics['collegesCount'] as num?)?.toInt() ??
              0,
          totalDepartments: (metrics['totalDepartments'] as num?)?.toInt() ??
              (metrics['departmentsCount'] as num?)?.toInt() ??
              0,
          totalStudents: (metrics['totalStudents'] as num?)?.toInt() ??
              (metrics['studentsCount'] as num?)?.toInt() ??
              0,
          totalFaculty: (metrics['totalFaculty'] as num?)?.toInt() ??
              (metrics['facultyCount'] as num?)?.toInt() ??
              0,
          todayAttendancePercentage: (metrics['systemAttendancePercentage'] as num?)?.toDouble() ??
              (metrics['avgAttendance'] as num?)?.toDouble() ??
              0.0,
          pendingColleges: 0,
        );
      }
      return SuperAdminAttendanceSummary(
        totalColleges: 0,
        totalDepartments: 0,
        totalStudents: 0,
        totalFaculty: 0,
        todayAttendancePercentage: 0.0,
        pendingColleges: 0,
      );
    } catch (_) {
      return SuperAdminAttendanceSummary(
        totalColleges: 0,
        totalDepartments: 0,
        totalStudents: 0,
        totalFaculty: 0,
        todayAttendancePercentage: 0.0,
        pendingColleges: 0,
      );
    }
  }

  @override
  Stream<SuperAdminAttendanceSummary> watchSuperAdminSummary() =>
      Stream.fromFuture(getSuperAdminSummary());

  @override
  Future<List<CollegeAttendanceComparison>> getCollegeComparisons() async => [];

  @override
  Future<List<SuperAdminInsight>> getSuperAdminInsights() async => [];

  @override
  Future<SuperAdminSystemHealth> getSuperAdminSystemHealth() async =>
      SuperAdminSystemHealth(
        serverStatus: 'Healthy',
        syncStatus: 'Synchronized',
        apiLatency: '45ms',
        activeUsers: 0,
      );

  @override
  Future<List<SuperAdminFacultyCompletion>> getSuperAdminFacultyCompletion(DateTime date) async => [];

  @override
  Future<List<SuperAdminStudentShortage>> getSuperAdminStudentShortages() async => [];

  @override
  Future<StudentAttendanceAnalytics> getStudentAttendanceAnalytics(String studentId, {AttendanceDateRange? dateRange}) async {
    final overview = await getStudentAttendanceOverview(studentId);
    return StudentAttendanceAnalytics(
      studentId: studentId,
      attendancePercentage: overview.overallPercentage,
      isLowAttendance: overview.overallPercentage < 75.0,
      dateRange: dateRange,
    );
  }

  @override
  Future<SubjectAttendanceAnalytics> getSubjectAttendanceAnalytics(String subjectId, {String? sectionId, AttendanceDateRange? dateRange}) async {
    return SubjectAttendanceAnalytics(
      subjectId: subjectId,
      attendancePercentage: 0.0,
      dateRange: dateRange,
    );
  }

  @override
  Future<SectionAttendanceAnalytics> getSectionAttendanceAnalytics(String sectionId, {AttendanceDateRange? dateRange}) async {
    return SectionAttendanceAnalytics(
      sectionId: sectionId,
      attendancePercentage: 0.0,
      dateRange: dateRange,
    );
  }

  @override
  Future<FacultyAttendanceAnalytics> getFacultyAttendanceAnalytics(String facultyId, {AttendanceDateRange? dateRange}) async {
    return FacultyAttendanceAnalytics(
      facultyId: facultyId,
      attendancePercentage: 100.0,
      dateRange: dateRange,
    );
  }

  @override
  Future<AttendanceDateRangeSummary> getAttendanceDateRangeSummary({AttendanceDateRange? dateRange, String? departmentId, String? sectionId}) async {
    final now = DateTime.now();
    return AttendanceDateRangeSummary(
      startDate: dateRange?.startDate ?? DateTime(now.year, now.month, 1),
      endDate: dateRange?.endDate ?? now,
      attendancePercentage: 0.0,
    );
  }
}
