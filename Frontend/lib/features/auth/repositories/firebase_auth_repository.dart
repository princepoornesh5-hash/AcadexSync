import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/firebase/firebase_exceptions.dart';
import '../../../../core/firebase/firebase_services.dart';
import '../../users/domain/repositories/user_profile_repository.dart';
import '../domain/models/role_enum.dart';
import '../domain/models/user_model.dart';
import 'auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuthService _authService;
  final UserProfileRepository _userProfileRepository;

  FirebaseAuthRepository(this._authService, this._userProfileRepository);

  @override
  Future<UserModel> loginAsDevelopmentRole(AppRole role) async {
    if (!kDebugMode) {
      throw StateError('CRITICAL: Development test login is strictly prohibited in release builds.');
    }
    return MockAuthRepository().loginAsDevelopmentRole(role);
  }

  @override
  Future<UserModel> login(String email, String password) async {
    final trimmedEmail = email.trim();
    developer.log('Authentication started for email: $trimmedEmail', name: 'Acadex.Auth');

    try {
      final credential = await _authService.signIn(trimmedEmail, password);
      final user = credential.user;

      if (user == null) {
        developer.log('Firebase sign-in completed but Firebase user was null.', name: 'Acadex.Auth');
        throw Exception("Authentication succeeded but user is null.");
      }

      developer.log('Firebase authentication succeeded. Firebase UID: ${user.uid}', name: 'Acadex.Auth');

      final acadexUser = await _userProfileRepository.getUserProfileByUid(user.uid);
      developer.log(
        'User identity lookup result for UID ${user.uid}: ${acadexUser != null ? "Found" : "Not Found"}',
        name: 'Acadex.Auth',
      );

      if (acadexUser == null) {
        await _authService.signOut();
        throw const BackendPermissionException(
          'Your Acadex profile has not been configured yet.'
        );
      }

      developer.log(
        'Role resolution result for UID ${user.uid}: role=${acadexUser.role.value}, status=${acadexUser.accountStatus.name}',
        name: 'Acadex.Auth',
      );

      if (acadexUser.accountStatus != AccountStatus.active) {
        await _authService.signOut();
        throw BackendPermissionException(
          'Your account is ${acadexUser.accountStatus.name}. Access denied.'
        );
      }

      return acadexUser;
    } catch (e) {
      if (e is FirebaseAuthException) {
        developer.log(
          'FirebaseAuthException: code=${e.code}, message=${e.message}',
          name: 'Acadex.Auth',
          error: e,
        );
      } else {
        developer.log('Authentication error: $e', name: 'Acadex.Auth', error: e);
      }

      if (e is AcadexBackendException) {
        rethrow;
      }
      throw FirebaseErrorMapper.map(e);
    }
  }

  @override
  Future<void> logout() async {
    developer.log('User logout initiated', name: 'Acadex.Auth');
    await _authService.signOut();
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final user = _authService.currentUser;
    if (user == null) {
      developer.log('getCurrentUser: No active Firebase user session.', name: 'Acadex.Auth');
      return null;
    }

    developer.log('getCurrentUser: Active Firebase user found with UID: ${user.uid}', name: 'Acadex.Auth');
    final acadexUser = await _userProfileRepository.getUserProfileByUid(user.uid);
    if (acadexUser == null) {
      developer.log('getCurrentUser: User profile not found for UID: ${user.uid}', name: 'Acadex.Auth');
      return null;
    }

    developer.log('getCurrentUser: Identity restored for ${user.uid} with role: ${acadexUser.role.value}', name: 'Acadex.Auth');
    return acadexUser;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    final trimmedEmail = email.trim();
    developer.log('Password reset requested for email: $trimmedEmail', name: 'Acadex.Auth');
    await _authService.sendPasswordResetEmail(trimmedEmail);
  }

  @override
  Future<String> verifyPasswordResetOtp({
    required String identifier,
    required String otpCode,
  }) async {
    // Firebase password reset uses email links, not OTP.
    // This method is provided for interface compliance.
    throw UnimplementedError('Firebase auth uses email link reset, not OTP verification');
  }

  @override
  Future<void> resetPassword({
    required String resetToken,
    required String newPassword,
  }) async {
    // Firebase password reset uses email links.
    throw UnimplementedError('Firebase auth uses email link reset, not token-based reset');
  }

  @override
  Future<Map<String, dynamic>> activateAccount({
    required String collegeCode,
    required String instituteId,
    required String activationCode,
    required String password,
  }) async {
    // Account activation is handled by the backend API, not Firebase.
    throw UnimplementedError('Account activation is handled by the backend API');
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    // Firebase password change uses reauthentication.
    throw UnimplementedError('Use ApiAuthRepository for change password');
  }

  @override
  Future<void> logoutAll() async {
    await logout();
  }
}
