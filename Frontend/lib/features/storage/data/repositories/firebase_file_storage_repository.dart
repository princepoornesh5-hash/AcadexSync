import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/firebase/firebase_services.dart';
import '../../domain/models/file_category.dart';
import '../../domain/models/file_status.dart';
import '../../domain/models/stored_file.dart';
import '../../domain/repositories/file_storage_repository.dart';

class FirebaseFileStorageRepository implements FileStorageRepository {
  final FirebaseStorageService _storageService;
  final _uuid = const Uuid();

  // Size limits in bytes
  static const int maxProfileImageSize = 5 * 1024 * 1024; // 5 MB
  static const int maxCertificateSize = 10 * 1024 * 1024; // 10 MB
  static const int maxNoteAttachmentSize = 25 * 1024 * 1024; // 25 MB

  FirebaseFileStorageRepository(this._storageService);

  @override
  Future<StoredFile> uploadFile({
    required Uint8List bytes,
    required String fileName,
    required String contentType,
    required FileCategory category,
    required String ownerUid,
    String? collegeId,
    String? departmentId,
    String? studentId,
    String? facultyUid,
    Map<String, String>? customMetadata,
  }) async {
    // 1. Validate Size
    _validateFileSize(bytes.length, category);

    // 2. Validate MIME type
    _validateContentType(contentType, category);

    // 3. Sanitize file name
    final sanitizedName = _sanitizeFileName(fileName);
    final fileId = _uuid.v4();
    final uniqueFileName = '${fileId}_$sanitizedName';

    // 4. Generate Path
    final storagePath = _generateStoragePath(
      category: category,
      fileName: uniqueFileName,
      ownerUid: ownerUid,
      collegeId: collegeId,
      studentId: studentId,
      facultyUid: facultyUid,
    );

    final customMap = <String, String>{
      'id': fileId,
      'ownerUid': ownerUid,
      'category': category.value,
      'originalFileName': sanitizedName,
      'createdAt': DateTime.now().toIso8601String(),
      'status': FileStatus.active.value,
    };
    if (collegeId != null) customMap['collegeId'] = collegeId;
    if (departmentId != null) customMap['departmentId'] = departmentId;
    if (customMetadata != null) customMap.addAll(customMetadata);

    // 5. Prepare Metadata
    final settableMetadata = SettableMetadata(
      contentType: contentType,
      customMetadata: customMap,
    );

    // 6. Upload
    final fullMetadata = await _storageService.uploadFile(storagePath, bytes, settableMetadata);

    // 7. Get Download URL
    final downloadUrl = await _storageService.getDownloadUrl(storagePath);

    return _mapMetadataToStoredFile(fullMetadata, downloadUrl);
  }

  @override
  Future<String> getDownloadUrl(String storagePath) async {
    return await _storageService.getDownloadUrl(storagePath);
  }

  @override
  Future<StoredFile> getFileMetadata(String storagePath) async {
    final metadata = await _storageService.getMetadata(storagePath);
    final downloadUrl = await _storageService.getDownloadUrl(storagePath);
    return _mapMetadataToStoredFile(metadata, downloadUrl);
  }

  @override
  Future<void> deleteFile(String storagePath) async {
    await _storageService.deleteFile(storagePath);
  }

  @override
  Future<List<StoredFile>> listFiles(String directoryPath) async {
    final result = await _storageService.listFiles(directoryPath);
    List<StoredFile> files = [];
    for (var ref in result.items) {
      try {
        final metadata = await ref.getMetadata();
        final url = await ref.getDownloadURL();
        files.add(_mapMetadataToStoredFile(metadata, url));
      } catch (_) {
        // Skip files that fail to load metadata
      }
    }
    return files;
  }

  @override
  Future<void> updateMetadata(String storagePath, Map<String, String> newMetadata) async {
    final settableMetadata = SettableMetadata(customMetadata: newMetadata);
    await _storageService.updateMetadata(storagePath, settableMetadata);
  }

  String _sanitizeFileName(String fileName) {
    // Prevent path traversal and invalid characters
    var safeName = fileName.replaceAll(RegExp(r'[/\\?%*:|"<>]'), '_');
    safeName = safeName.replaceAll('..', '_');
    if (safeName.length > 100) {
      safeName = safeName.substring(safeName.length - 100);
    }
    return safeName;
  }

  void _validateFileSize(int sizeBytes, FileCategory category) {
    switch (category) {
      case FileCategory.profileImage:
        if (sizeBytes > maxProfileImageSize) throw Exception('Profile image exceeds size limit of 5MB');
        break;
      case FileCategory.certificate:
        if (sizeBytes > maxCertificateSize) throw Exception('Certificate exceeds size limit of 10MB');
        break;
      case FileCategory.noteAttachment:
        if (sizeBytes > maxNoteAttachmentSize) throw Exception('Note attachment exceeds size limit of 25MB');
        break;
      case FileCategory.other:
        if (sizeBytes > maxNoteAttachmentSize) throw Exception('File exceeds size limit of 25MB');
        break;
    }
  }

  void _validateContentType(String contentType, FileCategory category) {
    // Basic executable block
    if (contentType.contains('executable') || 
        contentType.endsWith('sh') || 
        contentType.endsWith('bat') || 
        contentType.endsWith('exe') || 
        contentType.endsWith('apk')) {
      throw Exception('Executable files are not allowed.');
    }

    if (category == FileCategory.profileImage) {
      if (!contentType.startsWith('image/')) {
        throw Exception('Profile image must be an image file.');
      }
    }
  }

  String _generateStoragePath({
    required FileCategory category,
    required String fileName,
    required String ownerUid,
    String? collegeId,
    String? studentId,
    String? facultyUid,
  }) {
    // Generate isolated logical paths according to prompt requirements
    if (collegeId == null) {
      return 'global/users/$ownerUid/${category.value}/$fileName';
    }

    switch (category) {
      case FileCategory.profileImage:
        return 'colleges/$collegeId/users/$ownerUid/profile/$fileName';
      case FileCategory.certificate:
        final sId = studentId ?? ownerUid;
        return 'colleges/$collegeId/students/$sId/certificates/$fileName';
      case FileCategory.noteAttachment:
        final fId = facultyUid ?? ownerUid;
        return 'colleges/$collegeId/faculty/$fId/notes/$fileName';
      case FileCategory.other:
        return 'colleges/$collegeId/users/$ownerUid/other/$fileName';
    }
  }

  StoredFile _mapMetadataToStoredFile(FullMetadata metadata, String downloadUrl) {
    final custom = metadata.customMetadata ?? {};
    
    return StoredFile(
      id: custom['id'] ?? metadata.name,
      ownerUid: custom['ownerUid'] ?? 'unknown',
      collegeId: custom['collegeId'],
      departmentId: custom['departmentId'],
      category: FileCategoryExtension.fromValue(custom['category'] ?? 'other'),
      fileName: metadata.name,
      storagePath: metadata.fullPath,
      downloadUrl: downloadUrl,
      contentType: metadata.contentType ?? 'application/octet-stream',
      sizeBytes: metadata.size ?? 0,
      createdAt: metadata.timeCreated ?? DateTime.now(),
      updatedAt: metadata.updated ?? DateTime.now(),
      status: FileStatusExtension.fromValue(custom['status'] ?? 'active'),
      metadata: custom,
    );
  }
}
