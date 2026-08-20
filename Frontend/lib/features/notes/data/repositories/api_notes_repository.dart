import 'dart:async';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/imagekit_uploader.dart';
import '../../../../core/firebase/firebase_services.dart';
import '../../../../features/auth/domain/models/role_enum.dart';
import '../../domain/models/note_model.dart';
import '../../domain/utils/note_mime_helper.dart';
import 'notes_repository.dart';

class DownloadUrlResult {
  final String downloadUrl;
  final int expiresInSeconds;
  final String fileName;
  final String mimeType;
  final int fileSize;

  const DownloadUrlResult({
    required this.downloadUrl,
    required this.expiresInSeconds,
    required this.fileName,
    required this.mimeType,
    required this.fileSize,
  });

  factory DownloadUrlResult.fromJson(Map<String, dynamic> json) {
    return DownloadUrlResult(
      downloadUrl: json['downloadUrl'] as String,
      expiresInSeconds: json['expiresInSeconds'] is int
          ? json['expiresInSeconds'] as int
          : int.parse(json['expiresInSeconds'].toString()),
      fileName: json['fileName'] as String? ?? '',
      mimeType: json['mimeType'] as String? ?? 'application/pdf',
      fileSize: json['fileSize'] is int
          ? json['fileSize'] as int
          : (json['fileSize'] != null ? int.tryParse(json['fileSize'].toString()) ?? 0 : 0),
    );
  }
}

class NoteUploadAuthSession {
  final NoteModel note;
  final ImageKitUploadAuth auth;
  final String uploadUrl;

  const NoteUploadAuthSession({
    required this.note,
    required this.auth,
    required this.uploadUrl,
  });
}

class ApiNotesRepository implements NotesRepository {
  final ApiClient _apiClient;
  final ImageKitUploader _uploader;

  ApiNotesRepository({ApiClient? apiClient, ImageKitUploader? uploader})
      : _apiClient = apiClient ?? apiClientInstance,
        _uploader = uploader ?? ImageKitUploader();

  static ApiClient get apiClientInstance => apiClient;

  // =========================================================================
  // 1. NOTES RETRIEVAL & LISTING
  // =========================================================================

  @override
  Future<List<NoteModel>> getNotes({
    required String collegeId,
    String? departmentId,
    String? courseId,
    String? semesterId,
    String? sectionId,
    String? subjectId,
    String? facultyId,
  }) async {
    final queryParams = <String, dynamic>{
      'collegeId': collegeId,
      if (departmentId != null && departmentId.isNotEmpty) 'departmentId': departmentId,
      if (courseId != null && courseId.isNotEmpty) 'courseId': courseId,
      if (semesterId != null && semesterId.isNotEmpty) 'semesterId': semesterId,
      if (sectionId != null && sectionId.isNotEmpty) 'sectionId': sectionId,
      if (subjectId != null && subjectId.isNotEmpty) 'subjectId': subjectId,
      if (facultyId != null && facultyId.isNotEmpty) 'facultyId': facultyId,
    };

    final response = await _apiClient.dio.get(
      '/academics/notes',
      queryParameters: queryParams,
    );

    if (response.data != null && response.data['data'] != null) {
      final data = response.data['data'];
      final items = (data['items'] as List?) ?? (data is List ? data : []);
      return items
          .map((item) => NoteModel.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    }
    return [];
  }

  /// Retrieves student-specific notes feed
  Future<List<NoteModel>> getStudentPersonalNotes({
    String? subjectId,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, dynamic>{
      if (subjectId != null && subjectId.isNotEmpty) 'subjectId': subjectId,
      if (search != null && search.isNotEmpty) 'search': search,
      'page': page,
      'limit': limit,
    };

    final response = await _apiClient.dio.get(
      '/academics/notes/students/me',
      queryParameters: queryParams,
    );

    if (response.data != null && response.data['data'] != null) {
      final data = response.data['data'];
      final items = (data['items'] as List?) ?? [];
      return items
          .map((item) => NoteModel.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    }
    return [];
  }

  @override
  Stream<List<NoteModel>> watchNotes({
    required AppRole role,
    required String userId,
    String? collegeId,
    String? departmentId,
    String? courseId,
    String? semesterId,
    String? sectionId,
  }) async* {
    if (role == AppRole.student) {
      final notes = await getStudentPersonalNotes();
      yield notes;
    } else {
      final notes = await getNotes(
        collegeId: collegeId ?? '',
        departmentId: departmentId,
        courseId: courseId,
        semesterId: semesterId,
        sectionId: sectionId,
      );
      yield notes;
    }
  }

  @override
  Future<PaginatedResponse<NoteModel>> getPaginatedNotes({
    required String collegeId,
    String? departmentId,
    String? courseId,
    String? semesterId,
    String? sectionId,
    String? subjectId,
    String? facultyId,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    final notes = await getNotes(
      collegeId: collegeId,
      departmentId: departmentId,
      courseId: courseId,
      semesterId: semesterId,
      sectionId: sectionId,
      subjectId: subjectId,
      facultyId: facultyId,
    );
    return PaginatedResponse(data: notes, hasMore: false);
  }

  @override
  Future<NoteModel?> getNoteById(String id) async {
    try {
      final response = await _apiClient.dio.get('/academics/notes/$id');
      if (response.data != null && response.data['data'] != null) {
        return NoteModel.fromJson(
          Map<String, dynamic>.from(response.data['data'] as Map),
        );
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  // =========================================================================
  // 2. DOWNLOAD SIGNED URL RETRIEVAL
  // =========================================================================

  Future<DownloadUrlResult> getDownloadUrl(String noteId) async {
    final response = await _apiClient.dio.get('/academics/notes/$noteId/download');
    if (response.data != null && response.data['data'] != null) {
      return DownloadUrlResult.fromJson(
        Map<String, dynamic>.from(response.data['data'] as Map),
      );
    }
    throw Exception('Failed to retrieve secure download URL');
  }

  // =========================================================================
  // 3. FACULTY TWO-PHASE DIRECT UPLOAD TO IMAGEKIT & VERIFICATION
  // =========================================================================

  /// Phase 1: Request upload authentication parameters from backend
  Future<NoteUploadAuthSession> requestUploadAuth({
    required String subjectId,
    required String title,
    String? description,
    String? chapter,
    required String fileName,
    required String mimeType,
    required int fileSize,
    String? semesterId,
    String? courseId,
    String? departmentId,
    String? sectionId,
  }) async {
    final payload = {
      'subjectId': subjectId,
      'title': title,
      'description': description ?? '',
      'chapter': chapter,
      'fileName': fileName,
      'mimeType': mimeType,
      'fileSize': fileSize,
      if (semesterId != null && semesterId.isNotEmpty) 'semesterId': semesterId,
      if (courseId != null && courseId.isNotEmpty) 'courseId': courseId,
      if (departmentId != null && departmentId.isNotEmpty) 'departmentId': departmentId,
      if (sectionId != null && sectionId.isNotEmpty) 'sectionId': sectionId,
    };

    final response = await _apiClient.dio.post(
      '/academics/notes/upload-url',
      data: payload,
    );

    if (response.data != null && response.data['data'] != null) {
      final data = response.data['data'] as Map<String, dynamic>;
      final note = NoteModel.fromJson(Map<String, dynamic>.from(data['note'] as Map));
      final auth = ImageKitUploadAuth.fromJson(Map<String, dynamic>.from(data['uploadAuth'] as Map));
      final uploadUrl = data['uploadUrl'] as String? ?? 'https://upload.imagekit.io/api/v1/files/upload';
      return NoteUploadAuthSession(note: note, auth: auth, uploadUrl: uploadUrl);
    }
    throw Exception('Failed to obtain upload authorization from backend');
  }

  /// Phase 2: Complete upload and trigger server-side ImageKit verification
  Future<NoteModel> completeUpload({
    required String noteId,
    required String fileId,
    required String fileUrl,
    String? thumbnailUrl,
  }) async {
    final response = await _apiClient.dio.post(
      '/academics/notes/$noteId/complete',
      data: {
        'fileId': fileId,
        'fileUrl': fileUrl,
        if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
      },
    );

    if (response.data != null && response.data['data'] != null) {
      return NoteModel.fromJson(
        Map<String, dynamic>.from(response.data['data'] as Map),
      );
    }
    throw Exception('Server verification of uploaded note failed');
  }

  /// Full orchestrated upload pipeline (Request -> Direct ImageKit Upload -> Server Verify)
  Future<NoteModel> uploadAndPublishNote({
    required String subjectId,
    required String title,
    String? description,
    String? chapter,
    required String fileName,
    required Uint8List fileBytes,
    String? semesterId,
    String? courseId,
    String? departmentId,
    String? sectionId,
    void Function(int sent, int total)? onProgress,
  }) async {
    final mimeType = NoteMimeHelper.resolveMimeType(fileName);
    final fileSize = fileBytes.lengthInBytes;

    if (!NoteMimeHelper.isFileSizeValid(fileSize)) {
      throw Exception('File size exceeds the maximum limit of 25MB');
    }
    if (!NoteMimeHelper.isExtensionSupported(fileName)) {
      throw Exception('Unsupported file format: $fileName');
    }

    // Step 1: Authorize with backend
    final session = await requestUploadAuth(
      subjectId: subjectId,
      title: title,
      description: description,
      chapter: chapter,
      fileName: fileName,
      mimeType: mimeType,
      fileSize: fileSize,
      semesterId: semesterId,
      courseId: courseId,
      departmentId: departmentId,
      sectionId: sectionId,
    );

    // Step 2: Direct multipart upload to ImageKit
    final uploadResult = await _uploader.uploadFile(
      fileBytes: fileBytes,
      fileName: fileName,
      auth: session.auth,
      onProgress: onProgress,
    );

    // Step 3: Authoritative backend verification & publish
    return await completeUpload(
      noteId: session.note.id,
      fileId: uploadResult.fileId,
      fileUrl: uploadResult.url,
      thumbnailUrl: uploadResult.thumbnailUrl,
    );
  }

  // =========================================================================
  // 4. NOTE MUTATIONS (CREATE, UPDATE, DELETE)
  // =========================================================================

  @override
  Future<void> createNote(NoteModel note) async {
    // For notes created with local bytes, handled by uploadAndPublishNote
    // For metadata update or non-file note creation:
    final payload = note.toJson();
    await _apiClient.dio.post('/academics/notes', data: payload);
  }

  @override
  Future<void> updateNote(NoteModel note) async {
    await _apiClient.dio.put(
      '/academics/notes/${note.id}',
      data: {
        'title': note.title,
        'description': note.description,
        'chapter': note.chapter,
      },
    );
  }

  @override
  Future<void> deleteNote(String id) async {
    await _apiClient.dio.delete('/academics/notes/$id');
  }
}
