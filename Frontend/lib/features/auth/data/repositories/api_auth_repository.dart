import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/models/role_enum.dart';
import '../../domain/models/user_model.dart';
import '../../repositories/auth_repository.dart';

class ApiAuthRepository implements AuthRepository {
  final ApiClient _client;

  ApiAuthRepository([ApiClient? client]) : _client = client ?? apiClient;

  @override
  Future<UserModel> login(String identifier, String password) async {
    try {
      final response = await _client.dio.post('/auth/login', data: {
        'identifier': identifier.trim(),
        'password': password,
      });

      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? body;

      final accessToken = data['accessToken'] as String?;
      final refreshToken = data['refreshToken'] as String?;
      final userJson = data['user'] as Map<String, dynamic>;

      if (accessToken != null) {
        await _client.saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
      }

      return UserModel.fromJson(userJson);
    } on DioException catch (e) {
      debugPrint('[AUTH] Login network/server error: ${e.type} | message: ${e.message} | response: ${e.response?.data}');
      throw _extractError(e, 'Login failed');
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final response = await _client.dio.get('/auth/me');
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? body;
      final userJson = (data['user'] as Map<String, dynamic>?) ?? data;
      return UserModel.fromJson(userJson);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _client.dio.post('/auth/logout');
    } catch (_) {
      // Best effort remote logout
    } finally {
      await _client.clearTokens();
    }
  }

  @override
  Future<void> logoutAll() async {
    try {
      await _client.dio.post('/auth/logout-all');
    } catch (_) {
      // Best effort remote logout
    } finally {
      await _client.clearTokens();
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String identifier) async {
    try {
      await _client.dio.post('/auth/forgot-password', data: {
        'identifier': identifier.trim(),
      });
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to send verification code');
    }
  }

  @override
  Future<String> verifyPasswordResetOtp({
    required String identifier,
    required String otpCode,
  }) async {
    try {
      final response = await _client.dio.post('/auth/verify-password-reset-otp', data: {
        'identifier': identifier.trim(),
        'otp': otpCode.trim(),
      });
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? body;
      return data['resetToken'] as String;
    } on DioException catch (e) {
      throw _extractError(e, 'Invalid verification code');
    }
  }

  @override
  Future<void> resetPassword({
    required String resetToken,
    required String newPassword,
  }) async {
    try {
      await _client.dio.post('/auth/reset-password', data: {
        'resetToken': resetToken,
        'newPassword': newPassword,
      });
    } on DioException catch (e) {
      throw _extractError(e, 'Password reset failed');
    }
  }

  @override
  Future<Map<String, dynamic>> activateAccount({
    required String collegeCode,
    required String instituteId,
    required String activationCode,
    required String password,
  }) async {
    try {
      final response = await _client.dio.post('/auth/activate', data: {
        'collegeCode': collegeCode.trim(),
        'instituteId': instituteId.trim(),
        'activationCode': activationCode.trim(),
        'password': password,
      });
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? body;
      return data;
    } on DioException catch (e) {
      throw _extractError(e, 'Activation failed');
    }
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _client.dio.post('/auth/change-password', data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });
    } on DioException catch (e) {
      throw _extractError(e, 'Password change failed');
    }
  }

  @override
  Future<UserModel> loginAsDevelopmentRole(AppRole role) async {
    // Development convenience fallback — not for production
    return UserModel(
      id: 'dev-${role.value}',
      name: '${role.displayName} (Dev)',
      email: '${role.value.toLowerCase()}@acadex.edu',
      role: role,
      accountStatus: AccountStatus.active,
    );
  }

  /// Extracts a human-readable error message from a DioException.
  Exception _extractError(DioException e, String fallback) {
    if (e.response == null) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return Exception('Connection timed out while reaching ACADEX server. Please check your connection and try again.');
      }
      if (e.type == DioExceptionType.connectionError || (e.message != null && e.message!.contains('XMLHttpRequest'))) {
        return Exception('Unable to reach ACADEX server. Please check your network or verify backend service connectivity.');
      }
    }

    final message = e.response?.data?['error']?['message'] ??
        e.response?.data?['message'] ??
        (e.message != null && !e.message!.contains('XMLHttpRequest') ? e.message : null) ??
        fallback;
    return Exception(message);
  }
}
