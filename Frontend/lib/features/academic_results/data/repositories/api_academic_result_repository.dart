import 'package:dio/dio.dart';
import '../../../../core/errors/acadex_error.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/models/academic_result_models.dart';

class ApiAcademicResultRepository {
  final ApiClient _apiClient;

  ApiAcademicResultRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? apiClientInstance;

  static ApiClient get apiClientInstance => apiClient;

  /// Fetches the latest published official result for the authenticated student.
  Future<StudentOfficialResultModel?> getStudentOfficialResult({
    String? semesterId,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/academic-results/my-official',
        queryParameters: {
          if (semesterId != null && semesterId.isNotEmpty) 'semesterId': semesterId,
        },
      );

      if (response.data != null && response.data['data'] != null) {
        return StudentOfficialResultModel.fromJson(
          Map<String, dynamic>.from(response.data['data'] as Map),
        );
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      throw AcadexException.fromDio(e, context: 'Failed to fetch student official result');
    }
  }

  /// Admin/HOD query academic results with filters.
  Future<({List<AcademicResultModel> results, int total, int page, int pages})> queryResults({
    String? courseId,
    String? academicYearId,
    String? semesterId,
    String? sectionId,
    ResultLifecycleStatus? status,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/academic-results',
        queryParameters: {
          if (courseId != null && courseId.isNotEmpty) 'courseId': courseId,
          if (academicYearId != null && academicYearId.isNotEmpty) 'academicYearId': academicYearId,
          if (semesterId != null && semesterId.isNotEmpty) 'semesterId': semesterId,
          if (sectionId != null && sectionId.isNotEmpty) 'sectionId': sectionId,
          if (status != null) 'status': status.value,
          'page': page,
          'limit': limit,
        },
      );

      final data = response.data['data'] as Map<String, dynamic>? ?? {};
      final rawList = data['results'] as List<dynamic>? ?? [];
      final total = (data['total'] as num?)?.toInt() ?? 0;
      final curPage = (data['page'] as num?)?.toInt() ?? page;
      final pages = (data['pages'] as num?)?.toInt() ?? 1;

      final results = rawList
          .map((item) => AcademicResultModel.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();

      return (results: results, total: total, page: curPage, pages: pages);
    } on DioException catch (e) {
      throw AcadexException.fromDio(e, context: 'Failed to query academic results');
    }
  }

  /// Fetches complete detail of a specific academic result.
  Future<AcademicResultModel> getResultDetail(String id) async {
    try {
      final response = await _apiClient.dio.get('/academic-results/$id');
      final data = response.data['data'] as Map<String, dynamic>? ?? {};
      return AcademicResultModel.fromJson(data);
    } on DioException catch (e) {
      throw AcadexException.fromDio(e, context: 'Failed to fetch result detail');
    }
  }

  /// Calculates semester result for a student.
  Future<AcademicResultModel> calculateSemesterResult({
    required String studentId,
    required String semesterId,
    required String academicYearId,
    required String courseId,
    String? sectionId,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/academic-results/calculate-semester',
        data: {
          'studentId': studentId,
          'semesterId': semesterId,
          'academicYearId': academicYearId,
          'courseId': courseId,
          if (sectionId != null && sectionId.isNotEmpty) 'sectionId': sectionId,
        },
      );
      final data = response.data['data'] as Map<String, dynamic>? ?? {};
      return AcademicResultModel.fromJson(data);
    } on DioException catch (e) {
      throw AcadexException.fromDio(e, context: 'Failed to calculate semester result');
    }
  }

  /// Triggers class-wide calculation batch.
  Future<Map<String, dynamic>> calculateClassResults({
    required String semesterId,
    required String academicYearId,
    required String courseId,
    String? sectionId,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/academic-results/calculate-class',
        data: {
          'semesterId': semesterId,
          'academicYearId': academicYearId,
          'courseId': courseId,
          if (sectionId != null && sectionId.isNotEmpty) 'sectionId': sectionId,
        },
      );
      return Map<String, dynamic>.from(response.data['data'] as Map? ?? {});
    } on DioException catch (e) {
      throw AcadexException.fromDio(e, context: 'Failed to calculate class results');
    }
  }

  /// Transitions result to UNDER_REVIEW.
  Future<AcademicResultModel> reviewResult(String id) async {
    try {
      final response = await _apiClient.dio.post('/academic-results/$id/review');
      final data = response.data['data'] as Map<String, dynamic>? ?? {};
      return AcademicResultModel.fromJson(data);
    } on DioException catch (e) {
      throw AcadexException.fromDio(e, context: 'Failed to review academic result');
    }
  }

  /// Locks and finalizes academic result.
  Future<AcademicResultModel> finalizeResult(String id) async {
    try {
      final response = await _apiClient.dio.post('/academic-results/$id/finalize');
      final data = response.data['data'] as Map<String, dynamic>? ?? {};
      return AcademicResultModel.fromJson(data);
    } on DioException catch (e) {
      throw AcadexException.fromDio(e, context: 'Failed to finalize academic result');
    }
  }

  /// Officially publishes finalized academic result.
  Future<AcademicResultModel> publishResult(String id) async {
    try {
      final response = await _apiClient.dio.post('/academic-results/$id/publish');
      final data = response.data['data'] as Map<String, dynamic>? ?? {};
      return AcademicResultModel.fromJson(data);
    } on DioException catch (e) {
      throw AcadexException.fromDio(e, context: 'Failed to publish academic result');
    }
  }

  /// Reopens finalized/published result with mandatory audit justification.
  Future<AcademicResultModel> reopenResult(String id, {required String reason}) async {
    try {
      final response = await _apiClient.dio.post(
        '/academic-results/$id/reopen',
        data: {'reason': reason},
      );
      final data = response.data['data'] as Map<String, dynamic>? ?? {};
      return AcademicResultModel.fromJson(data);
    } on DioException catch (e) {
      throw AcadexException.fromDio(e, context: 'Failed to reopen academic result');
    }
  }

  /// Gets effective rule configuration for a course.
  Future<Map<String, dynamic>> getEffectiveRuleConfig({required String courseId}) async {
    try {
      final response = await _apiClient.dio.get(
        '/academic-results/rules/effective',
        queryParameters: {'courseId': courseId},
      );
      return Map<String, dynamic>.from(response.data['data'] as Map? ?? {});
    } on DioException catch (e) {
      throw AcadexException.fromDio(e, context: 'Failed to fetch academic rule configuration');
    }
  }
}
