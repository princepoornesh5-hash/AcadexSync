import '../../../../core/network/api_client.dart';
import '../../domain/models/report_models.dart';

abstract class ReportsRepository {
  Future<RoleDashboardReportModel?> getDashboard({
    DateRangePreset preset = DateRangePreset.thisMonth,
    DateTime? startDate,
    DateTime? endDate,
    String? collegeId,
    String? departmentId,
  });

  Future<StudentAttendanceReportModel?> getStudentAttendanceReport({
    String studentId = 'me',
    DateRangePreset preset = DateRangePreset.thisMonth,
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<SectionAttendanceReportModel?> getSectionAttendanceReport({
    required String sectionId,
    DateRangePreset preset = DateRangePreset.thisMonth,
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<DepartmentAttendanceReportModel?> getDepartmentAttendanceReport({
    required String departmentId,
    DateRangePreset preset = DateRangePreset.thisMonth,
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<CollegeAttendanceReportModel?> getCollegeAttendanceReport({
    required String collegeId,
    DateRangePreset preset = DateRangePreset.thisMonth,
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<AcademicHierarchyReportModel?> getAcademicReport({
    String? collegeId,
    String? departmentId,
  });

  Future<NotesAnalyticsReportModel?> getNotesReport({
    String? collegeId,
    String? departmentId,
  });
}

class ApiReportsRepository implements ReportsRepository {
  final ApiClient _apiClient;

  ApiReportsRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Map<String, dynamic> _buildQueryParams({
    DateRangePreset preset = DateRangePreset.thisMonth,
    DateTime? startDate,
    DateTime? endDate,
    String? collegeId,
    String? departmentId,
  }) {
    final params = <String, dynamic>{
      'preset': preset.toApiValue(),
    };
    if (startDate != null) params['startDate'] = startDate.toIso8601String();
    if (endDate != null) params['endDate'] = endDate.toIso8601String();
    if (collegeId != null && collegeId.isNotEmpty) params['collegeId'] = collegeId;
    if (departmentId != null && departmentId.isNotEmpty) params['departmentId'] = departmentId;
    return params;
  }

  @override
  Future<RoleDashboardReportModel?> getDashboard({
    DateRangePreset preset = DateRangePreset.thisMonth,
    DateTime? startDate,
    DateTime? endDate,
    String? collegeId,
    String? departmentId,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/reports/dashboard',
        queryParameters: _buildQueryParams(
          preset: preset,
          startDate: startDate,
          endDate: endDate,
          collegeId: collegeId,
          departmentId: departmentId,
        ),
      );
      final data = response.data;
      if (data != null && data['success'] == true && data['data'] != null) {
        return RoleDashboardReportModel.fromJson(data['data'] as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<StudentAttendanceReportModel?> getStudentAttendanceReport({
    String studentId = 'me',
    DateRangePreset preset = DateRangePreset.thisMonth,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/reports/attendance/student/$studentId',
        queryParameters: _buildQueryParams(
          preset: preset,
          startDate: startDate,
          endDate: endDate,
        ),
      );
      final data = response.data;
      if (data != null && data['success'] == true && data['data'] != null) {
        return StudentAttendanceReportModel.fromJson(data['data'] as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<SectionAttendanceReportModel?> getSectionAttendanceReport({
    required String sectionId,
    DateRangePreset preset = DateRangePreset.thisMonth,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/reports/attendance/section/$sectionId',
        queryParameters: _buildQueryParams(
          preset: preset,
          startDate: startDate,
          endDate: endDate,
        ),
      );
      final data = response.data;
      if (data != null && data['success'] == true && data['data'] != null) {
        return SectionAttendanceReportModel.fromJson(data['data'] as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<DepartmentAttendanceReportModel?> getDepartmentAttendanceReport({
    required String departmentId,
    DateRangePreset preset = DateRangePreset.thisMonth,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/reports/attendance/department/$departmentId',
        queryParameters: _buildQueryParams(
          preset: preset,
          startDate: startDate,
          endDate: endDate,
        ),
      );
      final data = response.data;
      if (data != null && data['success'] == true && data['data'] != null) {
        return DepartmentAttendanceReportModel.fromJson(data['data'] as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<CollegeAttendanceReportModel?> getCollegeAttendanceReport({
    required String collegeId,
    DateRangePreset preset = DateRangePreset.thisMonth,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/reports/attendance/college/$collegeId',
        queryParameters: _buildQueryParams(
          preset: preset,
          startDate: startDate,
          endDate: endDate,
        ),
      );
      final data = response.data;
      if (data != null && data['success'] == true && data['data'] != null) {
        return CollegeAttendanceReportModel.fromJson(data['data'] as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<AcademicHierarchyReportModel?> getAcademicReport({
    String? collegeId,
    String? departmentId,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/reports/academic',
        queryParameters: _buildQueryParams(
          collegeId: collegeId,
          departmentId: departmentId,
        ),
      );
      final data = response.data;
      if (data != null && data['success'] == true && data['data'] != null) {
        return AcademicHierarchyReportModel.fromJson(data['data'] as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<NotesAnalyticsReportModel?> getNotesReport({
    String? collegeId,
    String? departmentId,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/reports/notes',
        queryParameters: _buildQueryParams(
          collegeId: collegeId,
          departmentId: departmentId,
        ),
      );
      final data = response.data;
      if (data != null && data['success'] == true && data['data'] != null) {
        return NotesAnalyticsReportModel.fromJson(data['data'] as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
