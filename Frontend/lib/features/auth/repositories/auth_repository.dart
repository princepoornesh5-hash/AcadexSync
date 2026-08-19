import 'package:flutter/foundation.dart';
import '../domain/models/role_enum.dart';
import '../domain/models/user_model.dart';

// Abstract repository defining authentication contract
abstract class AuthRepository {
  Future<UserModel> login(String email, String password);
  Future<UserModel> loginAsDevelopmentRole(AppRole role);
  Future<void> logout();
  Future<UserModel?> getCurrentUser();
  Future<void> sendPasswordResetEmail(String email);
}

class MockAuthRepository implements AuthRepository {
  MockAuthRepository() {
    if (!kDebugMode) {
      throw StateError('CRITICAL: MockAuthRepository must not be instantiated in release builds.');
    }
  }

  // Dummy Users
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
    // Simulate network delay
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
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    try {
      return _mockUsers.firstWhere((user) => user.role == role);
    } catch (_) {
      throw Exception('Mock user for role $role not found');
    }
  }


  @override
  Future<UserModel?> getCurrentUser() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    // Return null in mock, as SessionManager will handle storing the token/user locally for now
    return null;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await Future.delayed(const Duration(seconds: 1));
    // Simulate a successful reset in mock
  }
  @override
  Future<void> logout() async {
    // Simulate logout delay
    await Future.delayed(const Duration(milliseconds: 300));
    // No action needed for mock
  }

}

