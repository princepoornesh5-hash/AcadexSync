import 'dart:developer' as developer;
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
    // This method is only intended for development mock auth; production repo does not support it.
    throw UnimplementedError('loginAsDevelopmentRole is not supported in production');
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

      // After Firebase Auth, load the Acadex User Profile from UserProfileRepository
      final acadexUser = await _userProfileRepository.getUserProfileByUid(user.uid);
      developer.log(
        'User identity lookup result for UID ${user.uid}: ${acadexUser != null ? "Found" : "Not Found"}',
        name: 'Acadex.Auth',
      );
      
      if (acadexUser == null) {
        throw const BackendPermissionException(
          'Your Acadex profile has not been configured yet.'
        );
      }

      developer.log(
        'Role resolution result for UID ${user.uid}: role=${acadexUser.role.value}, status=${acadexUser.accountStatus.name}',
        name: 'Acadex.Auth',
      );
      
      if (acadexUser.accountStatus != AccountStatus.active) {
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
}
