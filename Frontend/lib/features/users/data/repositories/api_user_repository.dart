import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../domain/models/user_profile_model.dart';
import '../../domain/models/user_status_enum.dart';
import 'user_repository.dart';

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
      if (departmentId != null) queryParams['departmentId'] = departmentId;
      if (role != null) queryParams['role'] = role.value;
      if (searchQuery != null && searchQuery.isNotEmpty) queryParams['search'] = searchQuery;

      final response = await _client.dio.get('/users', queryParameters: queryParams);
      final body = response.data;
      final list = (body is Map<String, dynamic> && body['data'] is List)
          ? body['data'] as List
          : (body is List ? body : []);

      return list
          .map((e) => UserProfileModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      final message = e.response?.data?['error']?['message'] ??
          e.response?.data?['message'] ??
          'Failed to load users';
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

  @override
  Future<UserProfileModel> createUser(UserProfileModel user) async {
    try {
      final instituteId = user.employeeId ?? user.rollNumber ?? user.id;
      final response = await _client.dio.post('/users', data: {
        'name': user.name,
        'email': user.email,
        'phone': user.phone,
        'role': user.role.value,
        'instituteId': instituteId.isNotEmpty ? instituteId : 'ID_${DateTime.now().millisecondsSinceEpoch}',
        if (user.collegeId != null) 'collegeId': user.collegeId,
        if (user.departmentId != null) 'departmentId': user.departmentId,
        if (user.courseId != null) 'courseId': user.courseId,
        if (user.sectionId != null) 'sectionId': user.sectionId,
        if (user.semesterId != null) 'semesterId': user.semesterId,
      });

      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? body;
      return UserProfileModel.fromJson(data);
    } on DioException catch (e) {
      final message = e.response?.data?['error']?['message'] ??
          e.response?.data?['message'] ??
          'Failed to create user';
      throw Exception(message);
    }
  }

  @override
  Future<UserProfileModel> updateUser(UserProfileModel user) async {
    try {
      final response = await _client.dio.put('/users/${user.id}', data: {
        'name': user.name,
        'phone': user.phone,
        if (user.email.isNotEmpty) 'email': user.email,
        'role': user.role.value,
        'accountStatus': user.accountStatus.name.toUpperCase(),
        if (user.employeeId != null) 'instituteId': user.employeeId,
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
          'Failed to update user';
      throw Exception(message);
    }
  }

  @override
  Future<void> deleteUser(String id) async {
    try {
      await _client.dio.put('/users/$id', data: {
        'accountStatus': 'DEACTIVATED',
      });
    } on DioException catch (e) {
      final message = e.response?.data?['error']?['message'] ??
          e.response?.data?['message'] ??
          'Failed to deactivate user';
      throw Exception(message);
    }
  }

  @override
  Future<void> reactivateUser(String id) async {
    try {
      await _client.dio.put('/users/$id', data: {
        'accountStatus': 'ACTIVE',
      });
    } on DioException catch (e) {
      final message = e.response?.data?['error']?['message'] ??
          e.response?.data?['message'] ??
          'Failed to reactivate user';
      throw Exception(message);
    }
  }

  Future<String> generateActivationCode(UserProfileModel user) async {
    try {
      final response = await _client.dio.post('/auth/invitations', data: {
        'name': user.name,
        'email': user.email,
        'role': user.role.value,
        if (user.collegeId != null) 'collegeId': user.collegeId,
        if (user.departmentId != null) 'departmentId': user.departmentId,
        'deliveryMethod': 'email',
      });
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? body;
      return data['code']?.toString() ?? data['activationCode']?.toString() ?? 'INV-${DateTime.now().millisecondsSinceEpoch}';
    } catch (_) {
      return 'ACADEX-${(user.employeeId ?? user.id).toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '')}';
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
