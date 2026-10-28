import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_error_diagnostic.dart';
import '../../domain/models/role_enum.dart';
import '../../domain/models/user_model.dart';
import '../../repositories/auth_repository.dart';

class ApiAuthRepository implements AuthRepository {
  final ApiClient _client;

  ApiAuthRepository([ApiClient? client]) : _client = client ?? apiClient;

  @override
  Future<UserModel> login(String identifier, String password) async {
    try {
      final response = await _client.dio.post(
        '/auth/login',
        data: {'identifier': identifier.trim(), 'password': password},
      );

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
      debugPrint(
        '[AUTH] Login network/server error: ${e.type} | message: ${e.message} | response: ${e.response?.data}',
      );
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
      await _client.dio.post(
        '/auth/forgot-password',
        data: {'identifier': identifier.trim()},
      );
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
      final response = await _client.dio.post(
        '/auth/verify-password-reset-otp',
        data: {'identifier': identifier.trim(), 'otp': otpCode.trim()},
      );
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
      await _client.dio.post(
        '/auth/reset-password',
        data: {'resetToken': resetToken, 'newPassword': newPassword},
      );
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
      final response = await _client.dio.post(
        '/auth/activate',
        data: {
          'collegeCode': collegeCode.trim(),
          'instituteId': instituteId.trim(),
          'activationCode': activationCode.trim(),
          'password': password,
        },
      );
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
      await _client.dio.post(
        '/auth/change-password',
        data: {'currentPassword': currentPassword, 'newPassword': newPassword},
      );
    } on DioException catch (e) {
      throw _extractError(e, 'Password change failed');
    }
  }

  @override
  Future<UserModel> loginAsDevelopmentRole(AppRole role) async {
    try {
      final response = await _client.dio.post(
        '/auth/dev-login',
        data: {'role': role.value},
      );

      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? body;
      final accessToken = data['accessToken'] as String?;
      final refreshToken = data['refreshToken'] as String?;
      final userJson = data['user'] as Map<String, dynamic>;
      final workspaceId = data['workspaceId'] as String?;

      if (accessToken != null) {
        await _client.saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
      }

      if (workspaceId != null && workspaceId.isNotEmpty) {
        await _client.setActiveWorkspace(workspaceId);
      }

      return UserModel.fromJson(userJson);
    } on DioException catch (e) {
      debugPrint(
        '[AUTH] Dev-login network/server error: ${e.type} | message: ${e.message} | response: ${e.response?.data}',
      );
      throw _extractError(e, 'Development login failed');
    }
  }

  @override
  Future<void> requestLoginOtp(String email) async {
    try {
      await _client.dio.post(
        '/auth/login/request-otp',
        data: {'email': email.trim()},
      );
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to request login verification code');
    }
  }

  @override
  Future<UserModel> loginWithOtp(String email, String otp) async {
    try {
      final response = await _client.dio.post(
        '/auth/login/verify-otp',
        data: {'email': email.trim(), 'otp': otp.trim()},
      );

      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? body;

      final accessToken = data['accessToken'] as String?;
      final refreshToken = data['refreshToken'] as String?;
      final userJson = data['user'] as Map<String, dynamic>;
      final workspaceId = data['workspaceId'] as String?;

      if (accessToken != null) {
        await _client.saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
      }

      if (workspaceId != null && workspaceId.isNotEmpty) {
        await _client.setActiveWorkspace(workspaceId);
      }

      return UserModel.fromJson(userJson);
    } on DioException catch (e) {
      throw _extractError(e, 'Invalid or expired verification code');
    }
  }

  @override
  Future<void> requestRegistrationOtp(String email) async {
    try {
      await _client.dio.post(
        '/auth/register/request-otp',
        data: {'email': email.trim()},
      );
    } on DioException catch (e) {
      throw _extractError(
        e,
        'Failed to request registration verification code',
      );
    }
  }

  @override
  Future<String> verifyRegistrationOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await _client.dio.post(
        '/auth/register/verify-otp',
        data: {'email': email.trim(), 'otp': otp.trim()},
      );
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? body;
      return data['registrationToken'] as String;
    } on DioException catch (e) {
      throw _extractError(e, 'Invalid or expired verification code');
    }
  }

  @override
  Future<UserModel> completeRegistration({
    required String registrationToken,
    required String password,
    required String confirmPassword,
    String? name,
  }) async {
    try {
      final payload = <String, dynamic>{
        'registrationToken': registrationToken.trim(),
        'password': password,
        'confirmPassword': confirmPassword,
      };
      if (name != null && name.trim().isNotEmpty) {
        payload['name'] = name.trim();
      }

      final response = await _client.dio.post(
        '/auth/register/complete',
        data: payload,
      );

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
      throw _extractError(e, 'Account registration failed');
    }
  }

  @override
  Future<void> requestInstitutionalActivationOtp(String email) async {
    try {
      await _client.dio.post(
        '/auth/institutional-activate/request-otp',
        data: {'email': email.trim()},
      );
    } on DioException catch (e) {
      throw _extractError(e, 'Failed to request activation verification code');
    }
  }

  @override
  Future<String> verifyInstitutionalActivationOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await _client.dio.post(
        '/auth/institutional-activate/verify-otp',
        data: {'email': email.trim(), 'otp': otp.trim()},
      );
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? body;
      return data['emailVerificationToken'] as String;
    } on DioException catch (e) {
      throw _extractError(e, 'Invalid or expired verification code');
    }
  }

  @override
  Future<Map<String, dynamic>> completeInstitutionalActivation({
    required String emailVerificationToken,
    required String activationCode,
    String? password,
    String? confirmPassword,
  }) async {
    try {
      final payload = <String, dynamic>{
        'emailVerificationToken': emailVerificationToken.trim(),
        'activationCode': activationCode.trim(),
      };
      if (password != null && password.isNotEmpty) {
        payload['password'] = password;
      }
      if (confirmPassword != null && confirmPassword.isNotEmpty) {
        payload['confirmPassword'] = confirmPassword;
      }

      final response = await _client.dio.post(
        '/auth/institutional-activate/complete',
        data: payload,
      );

      final body = response.data as Map<String, dynamic>;
      return (body['data'] as Map<String, dynamic>?) ?? body;
    } on DioException catch (e) {
      throw _extractError(e, 'Institutional activation failed');
    }
  }

  /// Extracts a human-readable, accurately diagnosed error message from a DioException.
  Exception _extractError(DioException e, String fallback) {
    return NetworkErrorDiagnostic.toException(e, fallback);
  }
}
