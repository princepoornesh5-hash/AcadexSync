import 'package:dio/dio.dart';
import '../../../../core/errors/acadex_error.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/models/request_model.dart';
import 'requests_repository.dart';

class ApiRequestsRepository implements RequestsRepository {
  final ApiClient _apiClient;

  ApiRequestsRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? apiClientInstance;

  static ApiClient get apiClientInstance => apiClient;

  @override
  Future<List<RequestModel>> getMyRequests({
    RequestStatus? status,
    String? requestType,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        if (status != null) 'status': status.value,
        if (requestType != null && requestType.isNotEmpty) 'requestType': requestType,
      };

      final response = await _apiClient.dio.get(
        '/requests/my',
        queryParameters: queryParams,
      );

      if (response.data != null && response.data['data'] != null) {
        final data = response.data['data'];
        final items = (data['items'] as List?) ?? (data is List ? data : []);
        return items
            .map((item) => RequestModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw AcadexException.fromDio(e, context: 'Failed to load your requests');
    }
  }

  @override
  Future<List<RequestModel>> getIncomingRequests({
    RequestStatus? status,
    String? requestType,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        if (status != null) 'status': status.value,
        if (requestType != null && requestType.isNotEmpty) 'requestType': requestType,
      };

      final response = await _apiClient.dio.get(
        '/requests/incoming',
        queryParameters: queryParams,
      );

      if (response.data != null && response.data['data'] != null) {
        final data = response.data['data'];
        final items = (data['items'] as List?) ?? (data is List ? data : []);
        return items
            .map((item) => RequestModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw AcadexException.fromDio(e, context: 'Failed to load incoming requests');
    }
  }

  @override
  Future<RequestSummaryCounts> getSummaryCounts() async {
    try {
      final response = await _apiClient.dio.get('/requests/counts');
      if (response.data != null && response.data['data'] != null) {
        return RequestSummaryCounts.fromJson(
          Map<String, dynamic>.from(response.data['data'] as Map),
        );
      }
      return const RequestSummaryCounts();
    } on DioException catch (_) {
      // Graceful fallback for dashboard widgets
      return const RequestSummaryCounts();
    }
  }

  @override
  Future<RequestModel?> getRequestById(String id) async {
    try {
      final response = await _apiClient.dio.get('/requests/$id');
      if (response.data != null && response.data['data'] != null) {
        return RequestModel.fromJson(
          Map<String, dynamic>.from(response.data['data'] as Map),
        );
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw AcadexException.fromDio(e, context: 'Failed to load request detail');
    }
  }

  @override
  Future<RequestModel> createRequest({
    required RequestType requestType,
    String? title,
    required String description,
    AcademicContextModel? academicContext,
    RequestDetailsModel? details,
  }) async {
    try {
      final payload = <String, dynamic>{
        'requestType': requestType.value,
        if (title != null && title.isNotEmpty) 'title': title,
        'description': description,
        if (academicContext != null) 'academicContext': academicContext.toJson(),
        if (details != null) 'details': details.toJson(),
      };

      final response = await _apiClient.dio.post(
        '/requests',
        data: payload,
      );

      if (response.data != null && response.data['data'] != null) {
        return RequestModel.fromJson(
          Map<String, dynamic>.from(response.data['data'] as Map),
        );
      }
      throw const AcadexException(
        category: ErrorCategory.unknown,
        technicalMessage: 'Empty response payload on request creation',
        userMessage: "Couldn't submit your request. Please try again.",
      );
    } on DioException catch (e) {
      throw AcadexException.fromDio(e, fallback: "Couldn't submit your request. Please try again.");
    }
  }

  @override
  Future<RequestModel> respondToRequest({
    required String id,
    required String action,
    String? message,
  }) async {
    try {
      final payload = <String, dynamic>{
        'action': action,
        if (message != null && message.isNotEmpty) 'message': message,
      };

      final response = await _apiClient.dio.post(
        '/requests/$id/respond',
        data: payload,
      );

      if (response.data != null && response.data['data'] != null) {
        return RequestModel.fromJson(
          Map<String, dynamic>.from(response.data['data'] as Map),
        );
      }
      throw const AcadexException(
        category: ErrorCategory.unknown,
        technicalMessage: 'Empty response payload on request respond',
        userMessage: 'Unable to submit your response. Please try again.',
      );
    } on DioException catch (e) {
      throw AcadexException.fromDio(e, fallback: 'Unable to submit your response. Please try again.');
    }
  }

  @override
  Future<RequestModel> updateStatus({
    required String id,
    required RequestStatus status,
    String? note,
  }) async {
    try {
      final payload = <String, dynamic>{
        'status': status.value,
        if (note != null && note.isNotEmpty) 'note': note,
      };

      final response = await _apiClient.dio.patch(
        '/requests/$id/status',
        data: payload,
      );

      if (response.data != null && response.data['data'] != null) {
        return RequestModel.fromJson(
          Map<String, dynamic>.from(response.data['data'] as Map),
        );
      }
      throw const AcadexException(
        category: ErrorCategory.unknown,
        technicalMessage: 'Empty response payload on status update',
        userMessage: 'Unable to update request status. Please try again.',
      );
    } on DioException catch (e) {
      throw AcadexException.fromDio(e, fallback: 'Unable to update request status. Please try again.');
    }
  }
}
