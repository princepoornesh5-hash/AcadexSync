import 'dart:typed_data';
import 'package:uuid/uuid.dart';

import '../../domain/models/file_category.dart';
import '../../domain/models/file_status.dart';
import '../../domain/models/stored_file.dart';
import '../../domain/repositories/file_storage_repository.dart';

class MockFileStorageRepository implements FileStorageRepository {
  final Map<String, StoredFile> _storage = {};
  final _uuid = const Uuid();

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
    final fileId = _uuid.v4();
    final uniqueFileName = '${fileId}_$fileName';

    final storagePath = 'mock/storage/$uniqueFileName';
    final downloadUrl = 'https://mock.storage.acadex.com/$storagePath';

    final file = StoredFile(
      id: fileId,
      ownerUid: ownerUid,
      collegeId: collegeId,
      departmentId: departmentId,
      category: category,
      fileName: uniqueFileName,
      storagePath: storagePath,
      downloadUrl: downloadUrl,
      contentType: contentType,
      sizeBytes: bytes.length,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      status: FileStatus.active,
      metadata: customMetadata ?? {},
    );

    _storage[storagePath] = file;
    return file;
  }

  @override
  Future<String> getDownloadUrl(String storagePath) async {
    if (!_storage.containsKey(storagePath)) {
      throw Exception('Object not found at path: $storagePath');
    }
    return _storage[storagePath]!.downloadUrl;
  }

  @override
  Future<StoredFile> getFileMetadata(String storagePath) async {
    if (!_storage.containsKey(storagePath)) {
      throw Exception('Object not found at path: $storagePath');
    }
    return _storage[storagePath]!;
  }

  @override
  Future<void> deleteFile(String storagePath) async {
    if (_storage.containsKey(storagePath)) {
      _storage.remove(storagePath);
    }
  }

  @override
  Future<List<StoredFile>> listFiles(String directoryPath) async {
    return _storage.values
        .where((file) => file.storagePath.startsWith(directoryPath))
        .toList();
  }

  @override
  Future<void> updateMetadata(String storagePath, Map<String, String> newMetadata) async {
    if (!_storage.containsKey(storagePath)) {
      throw Exception('Object not found at path: $storagePath');
    }
    final existing = _storage[storagePath]!;
    final updatedMetadata = Map<String, dynamic>.from(existing.metadata)..addAll(newMetadata);
    _storage[storagePath] = existing.copyWith(
      metadata: updatedMetadata,
      updatedAt: DateTime.now(),
    );
  }
}
