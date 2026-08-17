import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_management/features/storage/domain/models/file_category.dart';
import 'package:campus_management/features/storage/domain/models/file_status.dart';
import 'package:campus_management/features/storage/domain/models/stored_file.dart';
import 'package:campus_management/features/storage/data/repositories/mock_file_storage_repository.dart';

void main() {
  group('File Management Architecture & Serialization', () {
    test('StoredFile serializes and deserializes correctly', () {
      final now = DateTime.now();
      final model = StoredFile(
        id: 'file123',
        ownerUid: 'user123',
        collegeId: 'col_99',
        category: FileCategory.profileImage,
        fileName: 'profile.jpg',
        storagePath: 'colleges/col_99/users/user123/profile/profile.jpg',
        downloadUrl: 'https://example.com/profile.jpg',
        contentType: 'image/jpeg',
        sizeBytes: 1024,
        createdAt: now,
        updatedAt: now,
        status: FileStatus.active,
      );

      final json = model.toJson();
      expect(json['id'], 'file123');
      expect(json['category'], 'profile_image');
      expect(json['status'], 'active');
      expect(json['collegeId'], 'col_99');

      final fromJson = StoredFile.fromJson(json);
      expect(fromJson.fileName, 'profile.jpg');
      expect(fromJson.category, FileCategory.profileImage);
      expect(fromJson.status, FileStatus.active);
    });
  });

  group('Mock File Storage Repository Behavior', () {
    late MockFileStorageRepository repository;

    setUp(() {
      repository = MockFileStorageRepository();
    });

    test('Uploads file and returns correct metadata', () async {
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);

      final file = await repository.uploadFile(
        bytes: bytes,
        fileName: 'test_doc.pdf',
        contentType: 'application/pdf',
        category: FileCategory.certificate,
        ownerUid: 'student_1',
        collegeId: 'college_1',
        studentId: 'student_1',
      );

      expect(file.category, FileCategory.certificate);
      expect(file.contentType, 'application/pdf');
      expect(file.sizeBytes, 5);
      expect(file.storagePath.contains('test_doc.pdf'), isTrue);

      final fetchedFile = await repository.getFileMetadata(file.storagePath);
      expect(fetchedFile.id, file.id);
      expect(fetchedFile.downloadUrl, isNotEmpty);
    });

    test('updateMetadata applies correctly', () async {
      final bytes = Uint8List.fromList([1, 2]);
      final file = await repository.uploadFile(
        bytes: bytes,
        fileName: 'notes.pdf',
        contentType: 'application/pdf',
        category: FileCategory.noteAttachment,
        ownerUid: 'faculty_1',
      );

      await repository.updateMetadata(file.storagePath, {'verified': 'true'});

      final updatedFile = await repository.getFileMetadata(file.storagePath);
      expect(updatedFile.metadata['verified'], 'true');
    });

    test('deleteFile removes object from mock storage', () async {
      final bytes = Uint8List.fromList([1]);
      final file = await repository.uploadFile(
        bytes: bytes,
        fileName: 'temp.txt',
        contentType: 'text/plain',
        category: FileCategory.other,
        ownerUid: 'user1',
      );

      expect(await repository.listFiles('mock/storage'), isNotEmpty);

      await repository.deleteFile(file.storagePath);

      expect(() => repository.getFileMetadata(file.storagePath), throwsException);
    });
  });
}
