import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../domain/models/user_profile_model.dart';
import '../../domain/models/user_status_enum.dart';
import 'user_repository.dart';

class CreateUserResult {
  final UserProfileModel user;
  final String activationCode;
  final String? invitationId;
  final String? collegeCode;
  final DateTime? expiresAt;

  const CreateUserResult({
    required this.user,
    required this.activationCode,
    this.invitationId,
    this.collegeCode,
    this.expiresAt,
  });
}

class ApiUserRepository implements UserRepository {
  final ApiClient _client;

  ApiUserRepository([ApiClient? client]) : _client = client ?? apiClient;

  @override
  Future<List<UserProfileModel>> getUsers({
    String? scopeCollegeId,
    String? scopeDepartmentId,
    AppRole? role,
    String? departmentId,
    UserStatus? status,
    String? searchQuery,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (scopeCollegeId != null && scopeCollegeId.isNotEmpty) {
        queryParams['collegeId'] = scopeCollegeId;
      }
      if (role != null) {
        queryParams['role'] = role.value;
      }

      final response = await _client.dio.get('/users', queryParameters: queryParams);
      final body = response.data;
      final list = (body is Map<String, dynamic> && body['data'] is List)
          ? body['data'] as List
          : (body is List ? body : []);

      var users = list
          .map((e) => UserProfileModel.fromJson(e as Map<String, dynamic>))
          .toList();

      // Scoped & filter refinement over authoritative backend dataset
      final effectiveDeptId = departmentId ?? scopeDepartmentId;
      if (effectiveDeptId != null && effectiveDeptId.isNotEmpty) {
        users = users.where((u) => u.departmentId == effectiveDeptId).toList();
      }

      if (status != null) {
        users = users.where((u) {
          final sName = u.accountStatus.name.toLowerCase();
          switch (status) {
            case UserStatus.active:
              return sName == 'active';
            case UserStatus.pending:
              return sName.contains('pending');
            case UserStatus.deactivated:
              return sName.contains('deactivat');
            case UserStatus.inactive:
              return sName == 'inactive';
            case UserStatus.suspended:
              return sName == 'suspended';
            case UserStatus.graduated:
              return sName == 'graduated';
            case UserStatus.transferred:
              return sName == 'transferred';
          }
        }).toList();
      }

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim().toLowerCase();
        users = users.where((u) {
          final nameMatch = u.name.toLowerCase().contains(q);
          final emailMatch = u.email.toLowerCase().contains(q);
          final phoneMatch = u.phone.toLowerCase().contains(q);
          final empMatch = u.employeeId?.toLowerCase().contains(q) ?? false;
          final rollMatch = u.rollNumber?.toLowerCase().contains(q) ?? false;
          final instMatch = u.instituteId?.toLowerCase().contains(q) ?? false;
          return nameMatch || emailMatch || phoneMatch || empMatch || rollMatch || instMatch;
        }).toList();
      }

      return users;
    } on DioException catch (e) {
      final message = e.response?.data?['error']?['message'] ??
          e.response?.data?['message'] ??
          'Failed to load users from backend';
      throw Exception(message);
    }
  }

  @override
  Future<UserProfileModel?> getUserById(String id) async {
    try {
      final response = await _client.dio.get('/users/$id');
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? body;
      return UserProfileModel.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  /// Provision User via backend invitation service: creates user in PENDING_ACTIVATION
  /// and returns authoritative single-use activation code.
  @override
  Future<CreateUserResult> createUserWithInvitation(UserProfileModel user) async {
    try {
      final instituteId = user.employeeId ?? user.rollNumber ?? user.instituteId ?? user.id;
      final payload = <String, dynamic>{
        'name': user.name.trim(),
        'instituteId': instituteId.trim().toUpperCase(),
        'role': user.role.value,
        if (user.email.isNotEmpty) 'email': user.email.trim().toLowerCase(),
        if (user.phone.isNotEmpty) 'phone': user.phone.trim(),
        if (user.collegeId != null && user.collegeId!.isNotEmpty) 'collegeId': user.collegeId,
        if (user.departmentId != null && user.departmentId!.isNotEmpty) 'departmentId': user.departmentId,
        if (user.courseId != null && user.courseId!.isNotEmpty) 'courseId': user.courseId,
        if (user.sectionId != null && user.sectionId!.isNotEmpty) 'sectionId': user.sectionId,
        if (user.semesterId != null && user.semesterId!.isNotEmpty) 'semesterId': user.semesterId,
      };

      final response = await _client.dio.post('/auth/invitations', data: payload);
      final body = response.data as Map<String, dynamic>;
      final data = (body['data'] as Map<String, dynamic>?) ?? body;

      final userData = data['user'] as Map<String, dynamic>? ?? {};
      final createdUser = UserProfileModel.fromJson(userData);
      final activationCode = data['activationCode']?.toString() ?? '';
      final invitationData = data['invitation'] as Map<String, dynamic>?;
      final invitationId = (invitationData?['id'] ?? invitationData?['_id'])?.toString();
      final expiresAtRaw = invitationData?['expiresAt']?.toString();
      final expiresAt = expiresAtRaw != null ? DateTime.tryParse(expiresAtRaw) : null;
      final collegeCode = data['collegeCode']?.toString() ??
          userData['collegeCode']?.toString();

      return CreateUserResult(
        user: createdUser,
        activationCode: activationCode,
        invitationId: invitationId,
        collegeCode: collegeCode,
        expiresAt: expiresAt,
      );
    } on DioException catch (e) {
      final message = e.response?.data?['error']?['message'] ??
          e.response?.data?['message'] ??
          'Failed to create user invitation';
      throw Exception(message);
    }
  }

  Future<String> generateActivationCode(UserProfileModel user) async {
    return reissueActivationCodeForUser(user.id);
  }

  @override
  Future<UserProfileModel> createUser(UserProfileModel user) async {
    // Primary authoritative pathway: invite and provision user
    final result = await createUserWithInvitation(user);
    return result.user;
  }

  @override
  Future<UserProfileModel> updateUser(UserProfileModel user) async {
    try {
      final instituteId = user.employeeId ?? user.rollNumber ?? user.instituteId;
      final response = await _client.dio.put('/users/${user.id}', data: {
        'name': user.name.trim(),
        'phone': user.phone.trim(),
        if (user.email.isNotEmpty) 'email': user.email.trim().toLowerCase(),
        'role': user.role.value,
        'accountStatus': user.accountStatus.value, // Exact backend lowercase: active, pending_activation, deactivated, etc.
        if (instituteId != null && instituteId.isNotEmpty) 'instituteId': instituteId.trim().toUpperCase(),
        if (user.departmentId != null) 'departmentId': user.departmentId,
        if (user.courseId != null) 'courseId': user.courseId,
        if (user.sectionId != null) 'sectionId': user.sectionId,
        if (user.semesterId != null) 'semesterId': user.semesterId,
        if (user.profilePictureUrl != null) 'profilePictureUrl': user.profilePictureUrl,
      });

      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? body;
      return UserProfileModel.fromJson(data);
    } on DioException catch (e) {
      final message = e.response?.data?['error']?['message'] ??
          e.response?.data?['message'] ??
          'Failed to update user record';
      throw Exception(message);
    }
  }

  @override
  Future<void> deleteUser(String id) async {
    try {
      await _client.dio.put('/users/$id', data: {
        'accountStatus': 'deactivated', // Backend AccountStatus.DEACTIVATED
      });
    } on DioException catch (e) {
      final message = e.response?.data?['error']?['message'] ??
          e.response?.data?['message'] ??
          'Failed to deactivate user account';
      throw Exception(message);
    }
  }

  @override
  Future<void> reactivateUser(String id) async {
    try {
      await _client.dio.put('/users/$id', data: {
        'accountStatus': 'active', // Backend AccountStatus.ACTIVE
      });
    } on DioException catch (e) {
      final message = e.response?.data?['error']?['message'] ??
          e.response?.data?['message'] ??
          'Failed to reactivate user account';
      throw Exception(message);
    }
  }

  /// Reissue activation code via backend invitation management
  @override
  Future<String> reissueActivationCodeForUser(String userId) async {
    try {
      // 1. Fetch pending invitations to find the active invitation record for this user
      final invitationsResponse = await _client.dio.get('/auth/invitations', queryParameters: {
        'status': 'pending',
      });
      final invBody = invitationsResponse.data;
      final invList = (invBody is Map<String, dynamic> && invBody['data'] is List)
          ? invBody['data'] as List
          : (invBody is List ? invBody : []);

      String? invitationId;
      for (final item in invList) {
        if (item is Map<String, dynamic>) {
          final targetUserId = item['userId']?.toString();
          if (targetUserId == userId) {
            invitationId = (item['id'] ?? item['_id'])?.toString();
            break;
          }
        }
      }

      if (invitationId == null) {
        // If not found in pending list, search all invitations
        final allInvResponse = await _client.dio.get('/auth/invitations');
        final allBody = allInvResponse.data;
        final allList = (allBody is Map<String, dynamic> && allBody['data'] is List)
            ? allBody['data'] as List
            : (allBody is List ? allBody : []);

        for (final item in allList) {
          if (item is Map<String, dynamic>) {
            final targetUserId = item['userId']?.toString();
            if (targetUserId == userId) {
              invitationId = (item['id'] ?? item['_id'])?.toString();
              break;
            }
          }
        }
      }

      if (invitationId != null) {
        final reissueResponse = await _client.dio.post('/auth/invitations/$invitationId/reissue');
        final rBody = reissueResponse.data as Map<String, dynamic>;
        final rData = (rBody['data'] as Map<String, dynamic>?) ?? rBody;
        final code = rData['activationCode']?.toString();
        if (code != null && code.isNotEmpty) {
          return code;
        }
      }

      throw Exception('No valid pending invitation found to reissue for this user.');
    } on DioException catch (e) {
      final message = e.response?.data?['error']?['message'] ??
          e.response?.data?['message'] ??
          'Failed to reissue activation code';
      throw Exception(message);
    }
  }

  // --- ImageKit Profile Image Upload Flow ---
  Future<Map<String, dynamic>> requestProfileImageUploadUrl({
    String? userId,
    required String fileName,
    required int fileSize,
    required String mimeType,
  }) async {
    try {
      final endpoint = userId != null
          ? '/users/$userId/profile-image/upload-url'
          : '/users/me/profile-image/upload-url';

      final response = await _client.dio.post(endpoint, data: {
        'fileName': fileName,
        'fileSize': fileSize,
        'mimeType': mimeType,
      });

      final body = response.data as Map<String, dynamic>;
      return (body['data'] as Map<String, dynamic>?) ?? body;
    } on DioException catch (e) {
      final message = e.response?.data?['error']?['message'] ??
          e.response?.data?['message'] ??
          'Failed to get upload authorization';
      throw Exception(message);
    }
  }

  Future<UserProfileModel> completeProfileImageUpload({
    String? userId,
    required String fileId,
    required String fileUrl,
  }) async {
    try {
      final endpoint = userId != null
          ? '/users/$userId/profile-image/complete'
          : '/users/me/profile-image/complete';

      final response = await _client.dio.post(endpoint, data: {
        'fileId': fileId,
        'fileUrl': fileUrl,
      });

      final body = response.data as Map<String, dynamic>;
      final data = (body['data'] as Map<String, dynamic>?) ?? body;
      return UserProfileModel.fromJson(data);
    } on DioException catch (e) {
      final message = e.response?.data?['error']?['message'] ??
          e.response?.data?['message'] ??
          'Failed to complete profile picture update';
      throw Exception(message);
    }
  }
}
