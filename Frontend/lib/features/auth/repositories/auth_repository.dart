import 'package:flutter/foundation.dart';
import '../domain/models/role_enum.dart';
import '../domain/models/user_model.dart';

/// Abstract repository defining the authentication contract.
/// All methods communicate with the Node.js backend API.
abstract class AuthRepository {
  Future<UserModel> login(String identifier, String password);
  Future<UserModel> loginAsDevelopmentRole(AppRole role);
  Future<void> logout();
  Future<UserModel?> getCurrentUser();

  /// Step 1: Request password reset OTP delivery
  Future<void> sendPasswordResetEmail(String identifier);

  /// Step 2: Verify OTP and get a short-lived reset token
  Future<String> verifyPasswordResetOtp({
    required String identifier,
    required String otpCode,
  });

  /// Step 3: Reset password using the reset token
  Future<void> resetPassword({
    required String resetToken,
    required String newPassword,
  });

  /// Activate account using backend-generated credentials
  Future<Map<String, dynamic>> activateAccount({
    required String collegeCode,
    required String instituteId,
    required String activationCode,
    required String password,
  });

  /// Authenticated change password (current + new)
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
}

class MockAuthRepository implements AuthRepository {
  MockAuthRepository() {
    if (!kDebugMode) {
      throw StateError('CRITICAL: MockAuthRepository must not be instantiated in release builds.');
    }
  }

  final List<UserModel> _mockUsers = [
    const UserModel(
      id: '1',
      name: 'Super Admin User',
      email: 'admin@acadex.com',
      role: AppRole.superAdmin,
      accountStatus: AccountStatus.active,
    ),
    const UserModel(
      id: '2',
      name: 'College Admin User',
      email: 'college@acadex.com',
      role: AppRole.collegeAdmin,
      collegeId: 'mock-college-1',
      accountStatus: AccountStatus.active,
    ),
    const UserModel(
      id: '3',
      name: 'HOD User',
      email: 'hod@acadex.com',
      role: AppRole.hod,
      collegeId: 'mock-college-1',
      departmentId: 'mock-dept-1',
      accountStatus: AccountStatus.active,
    ),
    const UserModel(
      id: '4',
      name: 'Faculty User',
      email: 'faculty@acadex.com',
      role: AppRole.faculty,
      collegeId: 'mock-college-1',
      departmentId: 'mock-dept-1',
      accountStatus: AccountStatus.active,
    ),
    const UserModel(
      id: '5',
      name: 'Student User',
      email: 'student@acadex.com',
      role: AppRole.student,
      collegeId: 'mock-college-1',
      departmentId: 'mock-dept-1',
      accountStatus: AccountStatus.active,
    ),
  ];

  @override
  Future<UserModel> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    if (password != 'acadex123') {
      throw Exception('Invalid credentials');
    }
    try {
      return _mockUsers.firstWhere((user) => user.email == email);
    } catch (_) {
      throw Exception('User not found');
    }
  }

  @override
  Future<UserModel> loginAsDevelopmentRole(AppRole role) async {
    await Future.delayed(const Duration(milliseconds: 500));
    try {
      return _mockUsers.firstWhere((user) => user.role == role);
    } catch (_) {
      throw Exception('Mock user for role $role not found');
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return null;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Future<String> verifyPasswordResetOtp({
    required String identifier,
    required String otpCode,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    return 'mock-reset-token';
  }

  @override
  Future<void> resetPassword({
    required String resetToken,
    required String newPassword,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Future<Map<String, dynamic>> activateAccount({
    required String collegeCode,
    required String instituteId,
    required String activationCode,
    required String password,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    return {
      'user': {
        'id': 'mock-id',
        'name': 'Activated User',
        'email': 'activated@acadex.edu',
        'role': 'STUDENT',
        'accountStatus': 'active',
        'instituteId': instituteId,
      },
    };
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    if (currentPassword != 'acadex123') {
      throw Exception('Current password is incorrect');
    }
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 300));
  }
}
