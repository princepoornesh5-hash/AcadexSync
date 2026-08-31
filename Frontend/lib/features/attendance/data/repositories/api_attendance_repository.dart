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

          final subjectIdStr = (m['subjectId'] is Map ? (m['subjectId']['_id'] ?? m['subjectId']['id']) : m['subjectId'] ?? '').toString();
          final subjectNameStr = (m['subjectName'] ?? (m['subjectId'] is Map ? m['subjectId']['name'] : null) ?? 'Subject').toString();
          final facultyNameStr = (m['facultyName'] ?? (m['facultyId'] is Map ? m['facultyId']['name'] : null) ?? 'Faculty').toString();

          return AttendanceHistoryRecord(
            id: (m['id'] ?? m['_id'] ?? '').toString(),
            subjectId: subjectIdStr,
            subjectName: subjectNameStr,
            date: dateParsed,
            timeSlot: (m['timeSlot'] ?? '10:00 AM - 11:00 AM').toString(),
            status: status,
            facultyName: facultyNameStr,
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
      // 1. Fetch active enrollments for this section if any exist
      final Set<String> enrolledStudentIds = {};
      try {
        final enrollResponse = await _client.dio.get(
          '/academics/enrollments',
          queryParameters: {'sectionId': sectionId, 'status': 'active'},
        );
        final enrollBody = enrollResponse.data;
        final enrollData = enrollBody is Map<String, dynamic> ? (enrollBody['data'] ?? enrollBody) : enrollBody;
        final enrollList = enrollData is List ? enrollData : (enrollData is Map && enrollData['items'] is List ? enrollData['items'] as List : null);
        if (enrollList != null) {
          for (final item in enrollList) {
            if (item is Map) {
              final sid = (item['studentId'] ?? item['id'] ?? '').toString();
              if (sid.isNotEmpty) enrolledStudentIds.add(sid);
            }
          }
        }
      } catch (_) {
        // Fallback to student list directly if enrollments lookup fails
      }

      // 2. Fetch students
      final response = await _client.dio.get(
        '/academics/students',
        queryParameters: {'limit': 100},
      );
      final body = response.data;
      final data = body is Map<String, dynamic> ? (body['data'] ?? body) : body;
      final list = data is List ? data : (data is Map && data['items'] is List ? data['items'] as List : null);

      if (list != null) {
        final List<AttendanceRecord> records = [];
        for (final item in list) {
          final m = item as Map<String, dynamic>;
          final userMap = m['user'] as Map<String, dynamic>?;
          final stuMap = m['student'] as Map<String, dynamic>?;

          final studentDocId = (stuMap?['id'] ?? stuMap?['_id'] ?? '').toString();
          final userDocId = (userMap?['id'] ?? userMap?['_id'] ?? m['id'] ?? m['_id'] ?? '').toString();
          final effectiveStudentId = studentDocId.isNotEmpty ? studentDocId : userDocId;

          // If active enrollments are found for this section, filter by enrolled IDs
          if (enrolledStudentIds.isNotEmpty &&
              !enrolledStudentIds.contains(studentDocId) &&
              !enrolledStudentIds.contains(userDocId)) {
            continue;
          }

          final sName = (userMap?['name'] ?? stuMap?['name'] ?? m['name'] ?? 'Student').toString();
          final roll = (stuMap?['rollNumber'] ?? m['rollNumber'] ?? userMap?['instituteId'] ?? 'N/A').toString();

          records.add(AttendanceRecord(
            id: 'rec_$effectiveStudentId',
            studentId: effectiveStudentId,
            studentName: sName,
            rollNumber: roll,
            sectionId: sectionId,
            status: null,
          ));
        }
        return records;
      }
      return [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return [];
      throw _extractError(e, 'Failed to fetch students for section');
    } catch (_) {
      return [];
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
          'status': (r.status?.name ?? 'present').toLowerCase(),
        }).toList(),
      });
      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to submit attendance session');
    }
  }

  @override
  Future<List<AttendanceSession>> getRecentSessions(String facultyId) async {
    return getFacultySessions();
  }

  @override
  Future<List<AttendanceSession>> getFacultySessions() async {
    try {
      final response = await _client.dio.get('/attendance/faculty/me');
      final body = response.data;
      final data = body is Map<String, dynamic> ? (body['data'] ?? body) : body;
      final list = data is List ? data : (data is Map && data['sessions'] is List ? data['sessions'] as List : null);

      if (list != null) {
        return list.map((item) => AttendanceSession.fromJson(item as Map<String, dynamic>)).toList();
      }
      return [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return [];
      throw _extractError(e, 'Failed to fetch faculty sessions');
    }
  }

  @override
  Future<AttendanceSession> getSessionById(String sessionId) async {
    try {
      final response = await _client.dio.get('/attendance/sessions/$sessionId');
      final body = response.data;
      final data = body is Map<String, dynamic> ? (body['data'] ?? body) : body;
      return AttendanceSession.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to fetch session details');
    }
  }

  @override
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
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (departmentId != null && departmentId.isNotEmpty) queryParams['departmentId'] = departmentId;
      if (sectionId != null && sectionId.isNotEmpty) queryParams['sectionId'] = sectionId;
      if (subjectId != null && subjectId.isNotEmpty) queryParams['subjectId'] = subjectId;
      if (facultyId != null && facultyId.isNotEmpty) queryParams['facultyId'] = facultyId;
      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (from != null) queryParams['from'] = from.toIso8601String();
      if (to != null) queryParams['to'] = to.toIso8601String();
      if (page != null) queryParams['page'] = page;
      if (limit != null) queryParams['limit'] = limit;

      final response = await _client.dio.get('/attendance/sessions', queryParameters: queryParams);
      final body = response.data;
      final data = body is Map<String, dynamic> ? (body['data'] ?? body) : body;
      final items = data is Map && data['items'] is List
          ? data['items'] as List
          : (data is List ? data : null);

      if (items != null) {
        return items.map((item) => AttendanceSession.fromJson(item as Map<String, dynamic>)).toList();
      }
      return [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return [];
      throw _extractError(e, 'Failed to list attendance sessions');
    }
  }

  @override
  Future<AttendanceSession> lockSession(String sessionId) async {
    try {
      final response = await _client.dio.post('/attendance/sessions/$sessionId/lock');
      final body = response.data;
      final data = body is Map<String, dynamic> ? (body['data'] ?? body) : body;
      return AttendanceSession.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to lock attendance session');
    }
  }

  @override
  Future<AttendanceSession> closeSession(String sessionId) async {
    try {
      final response = await _client.dio.post('/attendance/sessions/$sessionId/close');
      final body = response.data;
      final data = body is Map<String, dynamic> ? (body['data'] ?? body) : body;
      return AttendanceSession.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to close attendance session');
    }
  }

  @override
  Future<AttendanceSession> cancelSession(String sessionId) async {
    try {
      final response = await _client.dio.post('/attendance/sessions/$sessionId/cancel');
      final body = response.data;
      final data = body is Map<String, dynamic> ? (body['data'] ?? body) : body;
      return AttendanceSession.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to cancel attendance session');
    }
  }

  @override
  Future<AttendanceRecord> correctRecord(
    String recordId, {
    required AttendanceStatus newStatus,
    required String reason,
  }) async {
    try {
      final response = await _client.dio.patch('/attendance/records/$recordId/correct', data: {
        'newStatus': newStatus.name,
        'reason': reason,
      });
      final body = response.data;
      final data = body is Map<String, dynamic> ? (body['data'] ?? body) : body;
      return AttendanceRecord.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to correct attendance record');
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
