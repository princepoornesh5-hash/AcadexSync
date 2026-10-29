import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/repositories/ai_repository.dart';
import '../../domain/models/ai_response.dart';
import '../../domain/models/ai_stream_event.dart';
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
          final answer =
              innerData['answer'] as String? ??
              'I have processed your request.';
          final proposal = innerData['proposal'] as Map<String, dynamic>?;
          final model = innerData['model'] as String?;
          return AiResponse(answer: answer, model: model, proposal: proposal);
        }
        if (data['answer'] != null) {
          return AiResponse(answer: data['answer'] as String);
        }
      }

      return const AiResponse(
        answer: "No answer received from ACADEXSYNC AI Assistant.",
      );
    } on DioException catch (dioError) {
      throw _mapDioError(dioError);
    } catch (_) {
      throw Exception('ACADEXSYNC AI is temporarily unavailable.');
    }
  }

  @override
  Future<AiResponse> sendPublicSupportQuery({
    required String query,
    List<Map<String, String>>? history,
  }) async {
    try {
      final response = await _client.dio.post(
        '/ai/public-chat',
        data: {
          'message': query.trim(),
          if (history != null && history.isNotEmpty) 'history': history,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        final innerData = data['data'];
        if (innerData is Map<String, dynamic>) {
          final answer =
              innerData['answer'] as String? ??
              'I have processed your request.';
          final model = innerData['model'] as String?;
          return AiResponse(answer: answer, model: model);
        }
      }

      return const AiResponse(
        answer:
            'I am here to assist with ACADEXSYNC onboarding and account setup.',
      );
    } on DioException catch (dioError) {
      throw _mapDioError(dioError);
    } catch (_) {
      throw Exception('ACADEXSYNC AI Support is temporarily unavailable.');
    }
  }

  @override
  Stream<AiStreamEvent> streamChatMessage({
    required String query,
    required Map<String, dynamic> context,
    List<Map<String, String>>? history,
  }) async* {
    final client = http.Client();
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: ApiClient.keyAccessToken);
      final workspaceId = await storage.read(
        key: ApiClient.keyActiveWorkspaceId,
      );

      final uri = Uri.parse('${ApiClient.defaultBaseUrl}/ai/chat/stream');
      final request = http.Request('POST', uri);
      request.headers['Content-Type'] = 'application/json';
      request.headers['Accept'] = 'text/event-stream';
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      if (workspaceId != null && workspaceId.isNotEmpty) {
        request.headers['X-Workspace-Id'] = workspaceId;
      }
      final clientCorrelationId =
          'cli_${DateTime.now().millisecondsSinceEpoch}';
      request.headers['X-Correlation-ID'] = clientCorrelationId;
      request.body = jsonEncode({
        'message': query.trim(),
        if (history != null && history.isNotEmpty) 'history': history,
      });

      final streamedResponse = await client.send(request);

      if (streamedResponse.statusCode != 200) {
        final errorBody = await streamedResponse.stream.bytesToString();
        final retryAfterHeader = streamedResponse.headers['retry-after'];
        int? retryAfterSeconds = retryAfterHeader != null
            ? int.tryParse(retryAfterHeader)
            : null;
        final correlationId =
            streamedResponse.headers['x-correlation-id'] ?? clientCorrelationId;

        String message = 'AI Assistant is temporarily unavailable.';
        String code = 'AI_ERROR';
        String category = 'generic';

        try {
          final errJson = jsonDecode(errorBody);
          if (errJson is Map && errJson['error'] is Map) {
            final err = errJson['error'] as Map;
            message = err['message'] ?? message;
            code = err['code'] ?? code;
            if (err['details'] is Map && err['details']['retryAfter'] != null) {
              retryAfterSeconds ??= int.tryParse(
                err['details']['retryAfter'].toString(),
              );
            }
          }
        } catch (_) {}

        if (streamedResponse.statusCode == 429) {
          if (code == 'APP_RATE_LIMIT_EXCEEDED' ||
              code == 'TOO_MANY_REQUESTS' ||
              code == 'CONCURRENT_REQUEST_LIMIT') {
            category = 'application_limit';
            message =
                "You've sent several requests. Please wait a moment before trying again.";
            retryAfterSeconds ??= 3;
          } else {
            category = 'gemini_quota_limit';
            message =
                "The AI service has reached its current usage limit. Please try again later.";
          }
        } else if (streamedResponse.statusCode == 504) {
          category = 'timeout';
          message = 'The AI service took too long to respond.';
        } else if (streamedResponse.statusCode == 502 ||
            streamedResponse.statusCode == 503) {
          if (code == 'AI_AUTH_ERROR' || code == 'AI_CONFIG_ERROR') {
            category = 'auth_config';
            message = 'The AI service is not configured correctly.';
          } else {
            category = 'gemini_quota_limit';
            message =
                'The AI service has reached its current usage limit. Please try again later.';
          }
        }

        yield AiStreamErrorEvent(
          code: code,
          message: message,
          httpStatus: streamedResponse.statusCode,
          retryAfterSeconds: retryAfterSeconds,
          category: category,
          correlationId: correlationId,
        );
        return;
      }

      String currentEvent = 'message';
      final lines = streamedResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;

        if (trimmed.startsWith('event:')) {
          currentEvent = trimmed.substring(6).trim();
        } else if (trimmed.startsWith('data:')) {
          final dataStr = trimmed.substring(5).trim();
          try {
            final data = jsonDecode(dataStr);
            if (currentEvent == 'start') {
              yield AiStreamStartEvent(
                model: data['model'] as String? ?? '',
                correlationId: data['correlationId'] as String? ?? '',
              );
            } else if (currentEvent == 'delta') {
              yield AiStreamDeltaEvent(text: data['text'] as String? ?? '');
            } else if (currentEvent == 'proposal') {
              yield AiStreamProposalEvent(
                proposal: data as Map<String, dynamic>,
              );
            } else if (currentEvent == 'done') {
              yield AiStreamDoneEvent(
                answer: data['answer'] as String? ?? '',
                model: data['model'] as String?,
                proposal: data['proposal'] as Map<String, dynamic>?,
              );
            } else if (currentEvent == 'error') {
              int? retrySeconds;
              if (data['retryAfterSeconds'] != null) {
                retrySeconds = int.tryParse(
                  data['retryAfterSeconds'].toString(),
                );
              }
              final errCode = data['code'] as String? ?? 'AI_ERROR';
              String category = data['category'] as String? ?? 'generic';
              String errMessage = data['message'] as String? ?? 'Stream failed';

              if (data['httpStatus'] == 429) {
                if (errCode == 'APP_RATE_LIMIT_EXCEEDED' ||
                    errCode == 'TOO_MANY_REQUESTS') {
                  category = 'application_limit';
                  errMessage =
                      "You've sent several requests. Please wait a moment before trying again.";
                  retrySeconds ??= 3;
                } else {
                  category = 'gemini_quota_limit';
                  errMessage =
                      "The AI service has reached its current usage limit. Please try again later.";
                }
              }

              yield AiStreamErrorEvent(
                code: errCode,
                message: errMessage,
                httpStatus: data['httpStatus'] as int?,
                retryAfterSeconds: retrySeconds,
                category: category,
                correlationId:
                    data['correlationId'] as String? ?? clientCorrelationId,
              );
            }
          } catch (e) {
            if (currentEvent == 'delta') {
              yield AiStreamDeltaEvent(text: dataStr);
            }
          }
        }
      }
    } catch (e) {
      yield AiStreamErrorEvent(
        code: 'AI_NETWORK_ERROR',
        category: 'network',
        message:
            'Network connection failure. Please check your internet connection.',
      );
    } finally {
      client.close();
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
      if (data is Map<String, dynamic> &&
          data['data'] is Map<String, dynamic>) {
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
  Future<Map<String, dynamic>> cancelAction({required String actionId}) async {
    try {
      final response = await _client.dio.post(
        '/ai/action/cancel',
        data: {'actionId': actionId},
      );

      final data = response.data;
      if (data is Map<String, dynamic> &&
          data['data'] is Map<String, dynamic>) {
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
      if (data is Map<String, dynamic> &&
          data['data'] is Map<String, dynamic>) {
        return data['data'] as Map<String, dynamic>;
      }
      return {'actionId': actionId, 'status': 'UNKNOWN'};
    } on DioException catch (dioError) {
      throw _mapDioError(dioError);
    } catch (_) {
      throw Exception('Failed to retrieve action status.');
    }
  }

  AiChatException _mapDioError(DioException dioError) {
    final statusCode = dioError.response?.statusCode;
    final dynamic responseData = dioError.response?.data;
    final headers = dioError.response?.headers;

    int? retryAfterSeconds;
    final retryHeader = headers?.value('retry-after');
    if (retryHeader != null) {
      retryAfterSeconds = int.tryParse(retryHeader);
    }

    final correlationId = headers?.value('x-correlation-id');

    String? backendCode;
    String? backendMessage;
    if (responseData is Map) {
      final err = responseData['error'];
      if (err is Map) {
        backendCode = err['code']?.toString();
        backendMessage = err['message']?.toString();
        if (err['details'] is Map && err['details']['retryAfter'] != null) {
          retryAfterSeconds ??= int.tryParse(
            err['details']['retryAfter'].toString(),
          );
        }
      }
    }

    if (statusCode == 401) {
      return AiChatException(
        statusCode: 401,
        code: 'UNAUTHORIZED',
        category: 'auth_config',
        message: 'Session expired. Please log in again.',
        correlationId: correlationId,
      );
    } else if (statusCode == 403) {
      return AiChatException(
        statusCode: 403,
        code: 'FORBIDDEN',
        category: 'auth_config',
        message:
            'Access denied. You do not have permission to execute this action.',
        correlationId: correlationId,
      );
    } else if (statusCode == 409) {
      return AiChatException(
        statusCode: 409,
        code: 'CONFLICT',
        category: 'generic',
        message: 'This action proposal has already been executed or cancelled.',
        correlationId: correlationId,
      );
    } else if (statusCode == 429) {
      if (backendCode == 'APP_RATE_LIMIT_EXCEEDED' ||
          backendCode == 'TOO_MANY_REQUESTS' ||
          backendCode == 'CONCURRENT_REQUEST_LIMIT') {
        return AiChatException(
          statusCode: 429,
          code: backendCode ?? 'APP_RATE_LIMIT_EXCEEDED',
          category: 'application_limit',
          message:
              backendMessage ??
              "You've sent several requests. Please wait a moment before trying again.",
          retryAfterSeconds: retryAfterSeconds ?? 3,
          correlationId: correlationId,
        );
      }
      return AiChatException(
        statusCode: 429,
        code: backendCode ?? 'AI_UPSTREAM_QUOTA_EXCEEDED',
        category: 'gemini_quota_limit',
        message:
            backendMessage ??
            "The AI service has reached its current usage limit. Please try again later.",
        retryAfterSeconds: retryAfterSeconds,
        correlationId: correlationId,
      );
    } else if (statusCode == 503 || statusCode == 502) {
      if (backendMessage != null && backendMessage.isNotEmpty) {
        return AiChatException(
          statusCode: statusCode,
          code: backendCode ?? 'AI_CONFIG_ERROR',
          category:
              (backendCode == 'AI_AUTH_ERROR' ||
                  backendCode == 'AI_CONFIG_ERROR')
              ? 'auth_config'
              : 'gemini_quota_limit',
          message: backendMessage,
          correlationId: correlationId,
        );
      }
      if (backendCode == 'AI_AUTH_ERROR' || backendCode == 'AI_CONFIG_ERROR') {
        return AiChatException(
          statusCode: statusCode,
          code: backendCode ?? 'AI_CONFIG_ERROR',
          category: 'auth_config',
          message: 'The AI service is not configured correctly.',
          correlationId: correlationId,
        );
      }
      return AiChatException(
        statusCode: statusCode,
        code: backendCode ?? 'AI_PROVIDER_UNAVAILABLE',
        category: 'gemini_quota_limit',
        message:
            'The AI service has reached its current usage limit. Please try again later.',
        retryAfterSeconds: retryAfterSeconds,
        correlationId: correlationId,
      );
    } else if (statusCode == 504) {
      return AiChatException(
        statusCode: 504,
        code: 'AI_GATEWAY_TIMEOUT',
        category: 'timeout',
        message: 'The AI service took too long to respond.',
        correlationId: correlationId,
      );
    } else if (dioError.type == DioExceptionType.connectionTimeout ||
        dioError.type == DioExceptionType.receiveTimeout ||
        dioError.type == DioExceptionType.connectionError) {
      return const AiChatException(
        category: 'network',
        message:
            'Network connection failure. Please check your internet connection.',
      );
    }

    return AiChatException(
      statusCode: statusCode,
      code: backendCode ?? 'AI_ERROR',
      category: 'generic',
      message: backendMessage ?? 'ACADEXSYNC AI is temporarily unavailable.',
      correlationId: correlationId,
    );
  }
}

class AiChatException implements Exception {
  final String message;
  final String code;
  final String
  category; // 'application_limit', 'gemini_quota_limit', 'timeout', 'auth_config', 'network', 'generic'
  final int? statusCode;
  final int? retryAfterSeconds;
  final String? correlationId;

  const AiChatException({
    required this.message,
    this.code = 'AI_ERROR',
    this.category = 'generic',
    this.statusCode,
    this.retryAfterSeconds,
    this.correlationId,
  });

  @override
  String toString() => message;
}
