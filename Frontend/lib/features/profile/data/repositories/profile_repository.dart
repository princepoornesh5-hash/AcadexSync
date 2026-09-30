import 'dart:typed_data';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/imagekit_uploader.dart';
import '../../domain/models/profile_models.dart';

class ProfileRepository {
  static const int maxProfileImageSizeBytes = 5 * 1024 * 1024; // 5 MB
  static const List<String> allowedImageExtensions = ['jpg', 'jpeg', 'png', 'webp'];

  final ApiClient _apiClient;
  final ImageKitUploader _uploader;

  ProfileRepository({ApiClient? apiClient, ImageKitUploader? uploader})
      : _apiClient = apiClient ?? apiClientInstance,
        _uploader = uploader ?? ImageKitUploader();

  static ApiClient get apiClientInstance => apiClient;

  static bool isImageExtensionSupported(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    return allowedImageExtensions.contains(ext);
  }

  static String resolveImageMimeType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  /// Resolves the canonical, composed profile for the authenticated user.
  Future<ComposedProfileModel> getMyProfile() async {
    final response = await _apiClient.dio.get('/profile/me');
    if (response.data != null && response.data['data'] != null) {
      return ComposedProfileModel.fromJson(
        response.data['data'] as Map<String, dynamic>,
      );
    }
    throw Exception('Failed to load user profile');
  }

  /// Updates allowed personal fields on the authenticated user's profile.
  Future<ComposedProfileModel> updateMyProfile(Map<String, dynamic> data) async {
    final response = await _apiClient.dio.patch(
      '/profile/me',
      data: data,
    );
    if (response.data != null && response.data['data'] != null) {
      return ComposedProfileModel.fromJson(
        response.data['data'] as Map<String, dynamic>,
      );
    }
    throw Exception('Failed to update profile');
  }

  /// Retrieves another user's scoped profile by ID (if authorized).
  Future<ComposedProfileModel> getProfileById(String id) async {
    final response = await _apiClient.dio.get('/profile/$id');
    if (response.data != null && response.data['data'] != null) {
      return ComposedProfileModel.fromJson(
        response.data['data'] as Map<String, dynamic>,
      );
    }
    throw Exception('Failed to load profile for user $id');
  }

  /// Scoped directory query bounded by role and tenant.
  Future<Map<String, dynamic>> getDirectory({
    String? search,
    String? role,
    String? departmentId,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }
    if (role != null && role.isNotEmpty) {
      queryParams['role'] = role;
    }
    if (departmentId != null && departmentId.isNotEmpty) {
      queryParams['departmentId'] = departmentId;
    }

    final response = await _apiClient.dio.get(
      '/profile/directory',
      queryParameters: queryParams,
    );
    if (response.data != null && response.data['data'] != null) {
      return response.data['data'] as Map<String, dynamic>;
    }
    throw Exception('Failed to load user directory');
  }

  /// Phase 1: Request upload authorization parameters from backend
  Future<ImageKitUploadAuth> requestUploadAuth({
    required String fileName,
    required String mimeType,
    required int fileSize,
    String? targetUserId,
  }) async {
    final endpoint = targetUserId != null && targetUserId.isNotEmpty
        ? '/profile/$targetUserId/avatar/upload-url'
        : '/profile/me/avatar/upload-url';

    final response = await _apiClient.dio.post(
      endpoint,
      data: {
        'fileName': fileName,
        'mimeType': mimeType,
        'fileSize': fileSize,
      },
    );

    if (response.data != null && response.data['data'] != null) {
      final data = response.data['data'] as Map<String, dynamic>;
      final authMap = data['uploadAuth'] is Map
          ? Map<String, dynamic>.from(data['uploadAuth'] as Map)
          : data;
      return ImageKitUploadAuth.fromJson(authMap);
    }
    throw Exception('Failed to obtain profile image upload authorization');
  }

  /// Phase 2: Complete upload and trigger server-side ImageKit verification
  Future<Map<String, dynamic>> completeUpload({
    required String fileId,
    required String fileUrl,
    String? targetUserId,
  }) async {
    final endpoint = targetUserId != null && targetUserId.isNotEmpty
        ? '/profile/$targetUserId/avatar/complete'
        : '/profile/me/avatar/complete';

    final response = await _apiClient.dio.post(
      endpoint,
      data: {
        'fileId': fileId,
        'fileUrl': fileUrl,
      },
    );

    if (response.data != null && response.data['data'] != null) {
      return Map<String, dynamic>.from(response.data['data'] as Map);
    }
    throw Exception('Failed to complete and verify profile picture update');
  }

  /// Full orchestrated profile image upload pipeline
  Future<String> uploadAndSetProfileImage({
    required String fileName,
    required Uint8List imageBytes,
    String? targetUserId,
    void Function(int sent, int total)? onProgress,
  }) async {
    if (!isImageExtensionSupported(fileName)) {
      throw Exception('Unsupported image format. Allowed: JPG, JPEG, PNG, WebP');
    }
    if (imageBytes.lengthInBytes > maxProfileImageSizeBytes) {
      throw Exception('Image size exceeds the maximum limit of 5MB');
    }

    final mimeType = resolveImageMimeType(fileName);
    final auth = await requestUploadAuth(
      fileName: fileName,
      mimeType: mimeType,
      fileSize: imageBytes.lengthInBytes,
      targetUserId: targetUserId,
    );

    final uploadResult = await _uploader.uploadFile(
      fileBytes: imageBytes,
      fileName: fileName,
      auth: auth,
      onProgress: onProgress,
    );

    final updatedProfile = await completeUpload(
      fileId: uploadResult.fileId,
      fileUrl: uploadResult.url,
      targetUserId: targetUserId,
    );

    // Return the updated user avatar URL
    final userData = updatedProfile['user'] as Map<String, dynamic>?;
    return (userData?['profilePictureUrl'] ?? uploadResult.url).toString();
  }
}
