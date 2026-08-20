import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:campus_management/core/network/api_client.dart';
import 'package:campus_management/features/reports/data/repositories/reports_repository.dart';
import 'package:campus_management/features/reports/domain/models/report_models.dart';

class MockDio extends Fake implements Dio {
  final Map<String, dynamic> responses = {};
  final List<String> recordedCalls = [];
  final Map<String, Map<String, dynamic>?> recordedQueryParams = {};

  @override
  Future<Response<T>> get<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    recordedCalls.add('GET $path');
    recordedQueryParams['GET $path'] = queryParameters;
    final resData = responses['GET $path'] ?? {'success': true, 'data': {}};
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      data: resData as T,
      statusCode: 200,
    );
  }
}

void main() {
  late MockDio mockDio;
  late ApiClient apiClient;
  late ApiReportsRepository repo;

  setUp(() {
    mockDio = MockDio();
    apiClient = ApiClient(customDio: mockDio);
    repo = ApiReportsRepository(apiClient: apiClient);
  });

  test('1. getDashboard parses role dashboard correctly', () async {
    mockDio.responses['GET /reports/dashboard'] = {
      'success': true,
      'data': {
        'role': 'SUPER_ADMIN',
        'metrics': {
          'totalColleges': 2,
          'totalStudents': 200,
          'systemAttendancePercentage': 85.5,
        },
        'quickStats': {
          'totalColleges': 2,
        },
        'recentActivity': [
          {'collegeId': 'c1', 'name': 'College A', 'attendancePercentage': 90.0},
        ],
      },
    };

    final result = await repo.getDashboard(preset: DateRangePreset.thisMonth);
    expect(result, isNotNull);
    expect(result!.role, 'SUPER_ADMIN');
    expect(result.metrics['totalColleges'], 2);
    expect(result.metrics['systemAttendancePercentage'], 85.5);
    expect(result.recentActivity.length, 1);
    expect(mockDio.recordedCalls, contains('GET /reports/dashboard'));
    expect(mockDio.recordedQueryParams['GET /reports/dashboard']?['preset'], 'this_month');
  });

  test('2. getStudentAttendanceReport parses student analytics accurately', () async {
    mockDio.responses['GET /reports/attendance/student/me'] = {
      'success': true,
      'data': {
        'student': {
          'id': 'stu_1',
          'name': 'Alice Student',
          'rollNumber': 'CSE-01',
          'studentIdNumber': 'STU-001',
        },
        'summary': {
          'totalClasses': 20,
          'present': 18,
          'late': 1,
          'absent': 1,
          'excused': 0,
          'percentage': 95.0,
        },
        'subjects': [
          {
            'subjectId': 'sub_1',
            'subjectName': 'Operating Systems',
            'subjectCode': 'CS501',
            'totalClasses': 10,
            'present': 9,
            'late': 1,
            'absent': 0,
            'excused': 0,
            'percentage': 100.0,
            'lowAttendanceAlert': false,
          },
        ],
        'riskProfile': {
          'percentage': 95.0,
          'threshold': 75.0,
          'isLowAttendance': false,
          'status': 'NORMAL',
        },
        'recentTrends': [
          {
            'date': '2026-08-19',
            'status': 'present',
            'subjectName': 'Operating Systems',
            'timeSlot': '09:00 - 10:00',
          },
        ],
      },
    };

    final report = await repo.getStudentAttendanceReport(studentId: 'me');
    expect(report, isNotNull);
    expect(report!.student.name, 'Alice Student');
    expect(report.summary.percentage, 95.0);
    expect(report.subjects.length, 1);
    expect(report.subjects[0].subjectName, 'Operating Systems');
    expect(report.subjects[0].percentage, 100.0);
    expect(report.riskProfile.isLowAttendance, false);
    expect(report.recentTrends.length, 1);
  });

  test('3. getSectionAttendanceReport parses section summaries and student rankings', () async {
    mockDio.responses['GET /reports/attendance/section/sec_1'] = {
      'success': true,
      'data': {
        'section': {
          'id': 'sec_1',
          'name': 'Section A',
        },
        'summary': {
          'totalClasses': 40,
          'present': 35,
          'late': 3,
          'absent': 2,
          'excused': 0,
          'percentage': 95.0,
          'totalSessions': 20,
        },
        'subjectBreakdown': [
          {
            'subjectId': 'sub_1',
            'subjectName': 'Operating Systems',
            'subjectCode': 'CS501',
            'totalSessions': 10,
            'attendancePercentage': 90.0,
          },
        ],
        'students': [
          {
            'studentId': 'stu_1',
            'studentName': 'Alice Student',
            'rollNumber': 'CSE-01',
            'totalClasses': 20,
            'attendedClasses': 19,
            'attendancePercentage': 95.0,
            'isLowAttendance': false,
            'rank': 1,
          },
          {
            'studentId': 'stu_2',
            'studentName': 'Bob Student',
            'rollNumber': 'CSE-02',
            'totalClasses': 20,
            'attendedClasses': 10,
            'attendancePercentage': 50.0,
            'isLowAttendance': true,
            'rank': 2,
          },
        ],
        'lowAttendanceCount': 1,
      },
    };

    final report = await repo.getSectionAttendanceReport(sectionId: 'sec_1');
    expect(report, isNotNull);
    expect(report!.section['name'], 'Section A');
    expect(report.summary.percentage, 95.0);
    expect(report.students.length, 2);
    expect(report.students[1].isLowAttendance, true);
    expect(report.lowAttendanceCount, 1);
  });

  test('4. getDepartmentAttendanceReport parses department analytics', () async {
    mockDio.responses['GET /reports/attendance/department/dept_1'] = {
      'success': true,
      'data': {
        'department': {
          'id': 'dept_1',
          'name': 'Computer Science',
          'code': 'CSE',
        },
        'summary': {
          'totalClasses': 100,
          'present': 80,
          'late': 10,
          'absent': 10,
          'excused': 0,
          'percentage': 90.0,
        },
        'sectionsComparison': [
          {
            'sectionId': 'sec_1',
            'sectionName': 'Section A',
            'totalStudents': 60,
            'attendancePercentage': 92.0,
          },
        ],
        'subjectsComparison': [
          {
            'subjectId': 'sub_1',
            'subjectName': 'OS',
            'subjectCode': 'CS501',
            'attendancePercentage': 95.0,
          },
        ],
        'lowAttendanceStudentsCount': 2,
      },
    };

    final report = await repo.getDepartmentAttendanceReport(departmentId: 'dept_1');
    expect(report, isNotNull);
    expect(report!.department['name'], 'Computer Science');
    expect(report.summary.percentage, 90.0);
    expect(report.sectionsComparison.length, 1);
    expect(report.subjectsComparison.length, 1);
    expect(report.lowAttendanceStudentsCount, 2);
  });

  test('5. getCollegeAttendanceReport parses college-wide comparisons', () async {
    mockDio.responses['GET /reports/attendance/college/col_1'] = {
      'success': true,
      'data': {
        'college': {
          'id': 'col_1',
          'name': 'College of Engineering A',
          'code': 'COEA',
        },
        'summary': {
          'totalClasses': 200,
          'present': 170,
          'late': 10,
          'absent': 20,
          'excused': 0,
          'percentage': 90.0,
          'totalSessions': 50,
        },
        'departmentComparison': [
          {
            'departmentId': 'dept_1',
            'departmentName': 'Computer Science',
            'departmentCode': 'CSE',
            'totalStudents': 120,
            'attendancePercentage': 90.0,
          },
        ],
        'lowAttendanceDepartments': ['Mechanical Engineering'],
      },
    };

    final report = await repo.getCollegeAttendanceReport(collegeId: 'col_1');
    expect(report, isNotNull);
    expect(report!.college['name'], 'College of Engineering A');
    expect(report.departmentComparison.length, 1);
    expect(report.lowAttendanceDepartments, contains('Mechanical Engineering'));
  });

  test('6. getAcademicReport parses academic hierarchy & timetable coverage', () async {
    mockDio.responses['GET /reports/academic'] = {
      'success': true,
      'data': {
        'summary': {
          'totalDepartments': 2,
          'totalSections': 4,
          'totalStudents': 240,
        },
        'enrollmentCapacity': {
          'totalCapacity': 240,
          'totalEnrolled': 240,
          'utilizationRate': 100.0,
        },
        'timetableCoverage': {
          'totalSections': 4,
          'publishedTimetables': 4,
          'draftTimetables': 0,
          'coveragePercentage': 100.0,
        },
      },
    };

    final report = await repo.getAcademicReport();
    expect(report, isNotNull);
    expect(report!.summary['totalDepartments'], 2);
    expect(report.enrollmentCapacity['utilizationRate'], 100.0);
    expect(report.timetableCoverage['coveragePercentage'], 100.0);
  });

  test('7. getNotesReport parses notes storage volume and metrics', () async {
    mockDio.responses['GET /reports/notes'] = {
      'success': true,
      'data': {
        'totalNotes': 15,
        'publishedNotes': 12,
        'totalSizeBytes': 25000000,
        'totalSizeMB': 23.84,
        'departmentDistribution': [
          {'departmentId': 'dept_1', 'name': 'CSE', 'count': 10, 'sizeBytes': 18000000},
        ],
        'subjectDistribution': [],
      },
    };

    final report = await repo.getNotesReport();
    expect(report, isNotNull);
    expect(report!.totalNotes, 15);
    expect(report.publishedNotes, 12);
    expect(report.totalSizeMB, 23.84);
    expect(report.departmentDistribution.length, 1);
  });
}
