import 'package:dio/dio.dart';
import '../../../../core/errors/acadex_error.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/models/academic_record_models.dart';

abstract class AcademicRecordsRepository {
  Future<List<AcademicHistoryItemModel>> getStudentHistory({String? studentId});

  Future<AcademicRecordDetailModel> getRecordDetail(String recordId);

  Future<PaginatedAcademicRecordsModel> getDepartmentRecords({
    String? departmentId,
    String? courseId,
    String? semesterId,
    String? academicYearId,
    String? progressionStatus,
    int page = 1,
    int limit = 20,
  });

  Future<AcademicRecordModel> updateProgressionStatus(
    String recordId, {
    required AcademicProgressionStatus status,
    String? remarks,
  });

  Future<void> updateSubjectStatus(
    String subjectRecordId, {
    required SubjectAcademicStatus status,
    String? remarks,
  });

  Future<AcademicRecordModel> initializeRecord(String studentEnrollmentId);
}

class ApiAcademicRecordsRepository implements AcademicRecordsRepository {
  final ApiClient _apiClient;

  ApiAcademicRecordsRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? apiClientInstance;

  static ApiClient get apiClientInstance => apiClient;

  @override
  Future<List<AcademicHistoryItemModel>> getStudentHistory({String? studentId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (studentId != null && studentId.isNotEmpty) {
        queryParams['studentId'] = studentId;
      }

      final response = await _apiClient.dio.get(
        '/academic-records/student-history',
        queryParameters: queryParams,
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is List) {
        return (data['data'] as List)
            .map((item) => AcademicHistoryItemModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw AcadexException.fromDio(e, context: 'Failed to load student academic history');
    } catch (e) {
      throw AcadexException(
        category: ErrorCategory.unknown,
        technicalMessage: e.toString(),
        userMessage: 'Failed to load student academic history',
      );
    }
  }

  @override
  Future<AcademicRecordDetailModel> getRecordDetail(String recordId) async {
    try {
      final response = await _apiClient.dio.get('/academic-records/detail/$recordId');
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
        return AcademicRecordDetailModel.fromJson(data['data'] as Map<String, dynamic>);
      }
      throw const AcadexException(
        category: ErrorCategory.serverError,
        technicalMessage: 'Invalid academic record detail response format',
        userMessage: 'Invalid academic record response from server',
      );
    } on DioException catch (e) {
      throw AcadexException.fromDio(e, context: 'Failed to load academic record detail');
    } catch (e) {
      throw AcadexException(
        category: ErrorCategory.unknown,
        technicalMessage: e.toString(),
        userMessage: 'Failed to load academic record detail',
      );
    }
  }

  @override
  Future<PaginatedAcademicRecordsModel> getDepartmentRecords({
    String? departmentId,
    String? courseId,
    String? semesterId,
    String? academicYearId,
    String? progressionStatus,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (departmentId != null && departmentId.isNotEmpty) queryParams['departmentId'] = departmentId;
      if (courseId != null && courseId.isNotEmpty) queryParams['courseId'] = courseId;
      if (semesterId != null && semesterId.isNotEmpty) queryParams['semesterId'] = semesterId;
      if (academicYearId != null && academicYearId.isNotEmpty) queryParams['academicYearId'] = academicYearId;
      if (progressionStatus != null && progressionStatus.isNotEmpty) queryParams['progressionStatus'] = progressionStatus;

      final response = await _apiClient.dio.get(
        '/academic-records/department',
        queryParameters: queryParams,
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
        return PaginatedAcademicRecordsModel.fromJson(data['data'] as Map<String, dynamic>);
      }
      return const PaginatedAcademicRecordsModel();
    } on DioException catch (e) {
      throw AcadexException.fromDio(e, context: 'Failed to load department academic records');
    } catch (e) {
      throw AcadexException(
        category: ErrorCategory.unknown,
        technicalMessage: e.toString(),
        userMessage: 'Failed to load department academic records',
      );
    }
  }

  @override
  Future<AcademicRecordModel> updateProgressionStatus(
    String recordId, {
    required AcademicProgressionStatus status,
    String? remarks,
  }) async {
    try {
      final payload = <String, dynamic>{
        'progressionStatus': status.value,
        if (remarks != null && remarks.isNotEmpty) 'remarks': remarks,
      };

      final response = await _apiClient.dio.patch(
        '/academic-records/$recordId/progression',
        data: payload,
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
        return AcademicRecordModel.fromJson(data['data'] as Map<String, dynamic>);
      }
      throw const AcadexException(
        category: ErrorCategory.serverError,
        technicalMessage: 'Unexpected response updating progression status',
        userMessage: 'Failed to update academic progression',
      );
    } on DioException catch (e) {
      throw AcadexException.fromDio(e, context: 'Failed to update academic progression status');
    } catch (e) {
      throw AcadexException(
        category: ErrorCategory.unknown,
        technicalMessage: e.toString(),
        userMessage: 'Failed to update academic progression status',
      );
    }
  }

  @override
  Future<void> updateSubjectStatus(
    String subjectRecordId, {
    required SubjectAcademicStatus status,
    String? remarks,
  }) async {
    try {
      final payload = <String, dynamic>{
        'status': status.value,
        if (remarks != null && remarks.isNotEmpty) 'remarks': remarks,
      };

      await _apiClient.dio.patch(
        '/academic-records/subject/$subjectRecordId/status',
        data: payload,
      );
    } on DioException catch (e) {
      throw AcadexException.fromDio(e, context: 'Failed to update subject academic status');
    } catch (e) {
      throw AcadexException(
        category: ErrorCategory.unknown,
        technicalMessage: e.toString(),
        userMessage: 'Failed to update subject academic status',
      );
    }
  }

  @override
  Future<AcademicRecordModel> initializeRecord(String studentEnrollmentId) async {
    try {
      final response = await _apiClient.dio.post(
        '/academic-records/initialize',
        data: {'studentEnrollmentId': studentEnrollmentId},
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
        return AcademicRecordModel.fromJson(data['data'] as Map<String, dynamic>);
      }
      throw const AcadexException(
        category: ErrorCategory.serverError,
        technicalMessage: 'Unexpected response initializing academic record',
        userMessage: 'Failed to initialize academic record',
      );
    } on DioException catch (e) {
      throw AcadexException.fromDio(e, context: 'Failed to initialize academic record');
    } catch (e) {
      throw AcadexException(
        category: ErrorCategory.unknown,
        technicalMessage: e.toString(),
        userMessage: 'Failed to initialize academic record',
      );
    }
  }
}
