import '../../../auth/domain/models/role_enum.dart';
import '../../domain/models/user_profile_model.dart';
import '../../domain/models/user_status_enum.dart';
import 'user_repository.dart';

class MockUserRepository implements UserRepository {
  final List<UserProfileModel> _users = [
    const UserProfileModel(
      id: 'super-admin-1',
      name: 'System Admin',
      email: 'admin@acadex.com',
      role: AppRole.superAdmin,
      status: UserStatus.active,
      phone: '+1234567890',
    ),
    const UserProfileModel(
      id: 'college-admin-1',
      name: 'Dr. Robert Smith',
      email: 'principal@college.edu',
      role: AppRole.collegeAdmin,
      status: UserStatus.active,
      phone: '+1987654321',
      employeeId: 'CA-001',
    ),
    const UserProfileModel(
      id: 'hod-1',
      name: 'Dr. Emily Chen',
      email: 'hod.cs@college.edu',
      role: AppRole.hod,
      status: UserStatus.active,
      phone: '+1122334455',
      employeeId: 'HOD-CS-001',
      departmentId: 'cs-dept',
    ),
    const UserProfileModel(
      id: 'fac-1',
      name: 'Prof. Michael Johnson',
      email: 'michael.j@college.edu',
      role: AppRole.faculty,
      status: UserStatus.active,
      phone: '+1555666777',
      employeeId: 'FAC-001',
      departmentId: 'cs-dept',
      assignedSubjects: ['CS101', 'CS201'],
      assignedClasses: ['CS-A', 'CS-B'],
    ),
    const UserProfileModel(
      id: 'stu-1',
      name: 'Alex Carter',
      email: 'alex.c@student.college.edu',
      role: AppRole.student,
      status: UserStatus.active,
      phone: '+1999888777',
      rollNumber: '2023CS001',
      departmentId: 'cs-dept',
      semesterId: 'sem-3',
      sectionId: 'sec-a',
      attendancePercentage: 85.5,
    ),
  ];

  @override
  Future<List<UserProfileModel>> getUsers({
    String? scopeCollegeId,
    String? scopeDepartmentId,
    AppRole? role,
    String? departmentId,
    UserStatus? status,
    String? searchQuery,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600)); // Simulate network

    return _users.where((user) {
      if (scopeCollegeId != null && user.collegeId != scopeCollegeId) return false;
      if (scopeDepartmentId != null && user.departmentId != scopeDepartmentId) return false;

      if (role != null && user.role != role) return false;
      if (departmentId != null && user.departmentId != departmentId) return false;
      if (status != null && user.status != status) return false;

      if (searchQuery != null && searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final nameMatch = user.name.toLowerCase().contains(query);
        final emailMatch = user.email.toLowerCase().contains(query);
        final empIdMatch = user.employeeId?.toLowerCase().contains(query) ?? false;
        final rollNoMatch = user.rollNumber?.toLowerCase().contains(query) ?? false;
        
        if (!nameMatch && !emailMatch && !empIdMatch && !rollNoMatch) return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<UserProfileModel?> getUserById(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _users.firstWhere((user) => user.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<UserProfileModel> createUser(UserProfileModel user) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Validation
    final emailExists = _users.any((u) => u.email == user.email);
    if (emailExists) throw Exception('Email already exists');

    if (user.employeeId != null && user.employeeId!.isNotEmpty) {
      final empExists = _users.any((u) => u.employeeId == user.employeeId);
      if (empExists) throw Exception('Employee ID already exists');
    }

    if (user.rollNumber != null && user.rollNumber!.isNotEmpty) {
      final rollExists = _users.any((u) => u.rollNumber == user.rollNumber);
      if (rollExists) throw Exception('Roll Number already exists');
    }

    final newUser = user.copyWith(id: 'usr-${DateTime.now().millisecondsSinceEpoch}');
    _users.add(newUser);
    return newUser;
  }

  @override
  Future<dynamic> createUserWithInvitation(UserProfileModel user) async {
    final createdUser = await createUser(user);
    return createdUser;
  }

  @override
  Future<String> reissueActivationCodeForUser(String userId) async {
    return 'MOCK-ACTV-CODE';
  }

  @override
  Future<UserProfileModel> updateUser(UserProfileModel user) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _users.indexWhere((u) => u.id == user.id);
    if (index == -1) throw Exception('User not found');
    
    // Check for unique constraints on update
    if (user.email != _users[index].email && _users.any((u) => u.email == user.email && u.id != user.id)) {
      throw Exception('Email already in use');
    }

    _users[index] = user;
    return user;
  }

  @override
  Future<void> deleteUser(String id) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final index = _users.indexWhere((u) => u.id == id);
    if (index != -1) {
      _users[index] = _users[index].copyWith(status: UserStatus.inactive);
    }
  }

  @override
  Future<void> reactivateUser(String id) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final index = _users.indexWhere((u) => u.id == id);
    if (index != -1) {
      _users[index] = _users[index].copyWith(status: UserStatus.active);
    }
  }
}
