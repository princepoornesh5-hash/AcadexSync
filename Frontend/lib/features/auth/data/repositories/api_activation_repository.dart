import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_error_diagnostic.dart';
import '../../domain/models/activation_model.dart';
import '../../domain/repositories/activation_repository.dart';

class ApiActivationRepository implements ActivationRepository {
  final ApiClient _client;

  ApiActivationRepository([ApiClient? client]) : _client = client ?? apiClient;

  @override
  Future<ActivationValidationResult> validateActivationCode(String activationCode) async {
    try {
      final response = await _client.dio.post(
        '/auth/activate/validate-code',
        data: {
          'activationCode': activationCode.trim(),
        },
      );
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? body;
      return ActivationValidationResult.fromJson(data);
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to validate activation code');
    }
  }

  @override
  Future<SendOtpResult> sendActivationOtp({
    required String activationFlowId,
    required String contactMethod,
  }) async {
    try {
      final response = await _client.dio.post(
        '/auth/activate/send-otp',
        data: {
          'activationFlowId': activationFlowId,
          'contactMethod': contactMethod,
        },
      );
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? body;
      return SendOtpResult.fromJson(data);
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to send verification code');
    }
  }

  @override
  Future<VerifyOtpResult> verifyActivationOtp({
    required String activationFlowId,
    required String contactMethod,
    required String otp,
  }) async {
    try {
      final response = await _client.dio.post(
        '/auth/activate/verify-otp',
        data: {
          'activationFlowId': activationFlowId,
          'contactMethod': contactMethod,
          'otp': otp.trim(),
        },
      );
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? body;
      return VerifyOtpResult.fromJson(data);
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to verify code');
    }
  }

  @override
  Future<CompleteActivationResult> completeActivation({
    required String activationToken,
    String? password,
    String? confirmPassword,
  }) async {
    try {
      final payload = <String, dynamic>{
        'activationToken': activationToken,
      };
      if (password != null) {
        payload['password'] = password;
      }
      if (confirmPassword != null) {
        payload['confirmPassword'] = confirmPassword;
      }

      final response = await _client.dio.post(
        '/auth/activate/complete',
        data: payload,
      );
      final body = response.data as Map<String, dynamic>;
      return CompleteActivationResult.fromJson(body);
    } on DioException catch (e) {
      throw _extractError(e, 'Account activation failed');
    }
  }

  /// Extracts a human-readable, accurately diagnosed error message from a DioException.
  Exception _extractError(DioException e, String fallback) {
    return NetworkErrorDiagnostic.toException(e, fallback);
  }
}

