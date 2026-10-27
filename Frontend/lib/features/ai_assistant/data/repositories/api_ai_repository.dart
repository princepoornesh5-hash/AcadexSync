import 'package:dio/dio.dart';
import '../../domain/repositories/ai_repository.dart';
import '../../domain/models/ai_response.dart';
import '../../../../core/network/api_client.dart';

class ApiAiRepository implements AiRepository {
  final ApiClient _client;

  ApiAiRepository({ApiClient? client}) : _client = client ?? apiClient;

  @override
  Future<String> sendMessage({
    required String query,
    required Map<String, dynamic> context,
  }) async {
    final res = await sendChatMessage(query: query, context: context);
    return res.answer;
  }

  @override
  Future<AiResponse> sendChatMessage({
    required String query,
    required Map<String, dynamic> context,
    List<Map<String, String>>? history,
  }) async {
    try {
      final response = await _client.dio.post(
        '/ai/chat',
        data: {
          'message': query.trim(),
          if (history != null && history.isNotEmpty) 'history': history,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        final innerData = data['data'];
        if (innerData is Map<String, dynamic>) {
          final answer = innerData['answer'] as String? ?? 'I have processed your request.';
          final proposal = innerData['proposal'] as Map<String, dynamic>?;
          final model = innerData['model'] as String?;
          return AiResponse(answer: answer, model: model, proposal: proposal);
        }
        if (data['answer'] != null) {
          return AiResponse(answer: data['answer'] as String);
        }
      }

      return const AiResponse(answer: "No answer received from ACADEX AI Assistant.");
    } on DioException catch (dioError) {
      throw _mapDioError(dioError);
    } catch (_) {
      throw Exception('Acadex AI is temporarily unavailable.');
    }
  }

  @override
  Future<Map<String, dynamic>> confirmAction({
    required String actionId,
    String? idempotencyKey,
  }) async {
    try {
      final response = await _client.dio.post(
        '/ai/action/confirm',
        data: {
          'actionId': actionId,
          if (idempotencyKey != null) 'idempotencyKey': idempotencyKey,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
        return data['data'] as Map<String, dynamic>;
      }
      return {'status': 'EXECUTED'};
    } on DioException catch (dioError) {
      throw _mapDioError(dioError);
    } catch (_) {
      throw Exception('Failed to confirm action. Please try again.');
    }
  }

  @override
  Future<Map<String, dynamic>> cancelAction({
    required String actionId,
  }) async {
    try {
      final response = await _client.dio.post(
        '/ai/action/cancel',
        data: {
          'actionId': actionId,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
        return data['data'] as Map<String, dynamic>;
      }
      return {'status': 'CANCELLED'};
    } on DioException catch (dioError) {
      throw _mapDioError(dioError);
    } catch (_) {
      throw Exception('Failed to cancel action.');
    }
  }

  @override
  Future<Map<String, dynamic>> getActionStatus({
    required String actionId,
  }) async {
    try {
      final response = await _client.dio.get('/ai/action/$actionId');
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
        return data['data'] as Map<String, dynamic>;
      }
      return {'actionId': actionId, 'status': 'UNKNOWN'};
    } on DioException catch (dioError) {
      throw _mapDioError(dioError);
    } catch (_) {
      throw Exception('Failed to retrieve action status.');
    }
  }

  Exception _mapDioError(DioException dioError) {
    final statusCode = dioError.response?.statusCode;

    if (statusCode == 401) {
      return Exception('Session expired. Please log in again.');
    } else if (statusCode == 403) {
      return Exception('Access denied. You do not have permission to execute this action.');
    } else if (statusCode == 409) {
      return Exception('This action proposal has already been executed or cancelled.');
    } else if (statusCode == 429) {
      return Exception('Too many requests. Please wait a moment before sending another message.');
    } else if (statusCode == 503) {
      final errorData = dioError.response?.data;
      if (errorData is Map && errorData['error'] is Map && errorData['error']['message'] != null) {
        return Exception(errorData['error']['message']);
      }
      return Exception('AI Assistant service is not configured on the server.');
    } else if (statusCode == 504) {
      return Exception('AI Assistant timed out waiting for upstream response. Please try again.');
    } else if (dioError.type == DioExceptionType.connectionTimeout ||
        dioError.type == DioExceptionType.receiveTimeout ||
        dioError.type == DioExceptionType.connectionError) {
      return Exception('Network connection failure. Please check your internet connection.');
    }

    final errorData = dioError.response?.data;
    if (errorData is Map && errorData['error'] is Map && errorData['error']['message'] != null) {
      return Exception(errorData['error']['message']);
    }

    return Exception('Acadex AI is temporarily unavailable.');
  }
}
