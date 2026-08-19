import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_management/features/certificates/domain/models/certificate.dart';
import 'package:campus_management/features/certificates/domain/models/certificate_type.dart';
import 'package:campus_management/features/certificates/domain/models/certificate_status.dart';
import 'package:campus_management/features/certificates/domain/models/certificate_file_config.dart';
import 'package:campus_management/features/certificates/domain/models/certificate_request_model.dart';
import 'package:campus_management/features/certificates/data/repositories/firebase_certificate_repository.dart';
import 'package:campus_management/features/certificates/data/repositories/mock_certificate_repository.dart';
import 'package:campus_management/features/storage/domain/repositories/file_storage_repository.dart';
import 'package:campus_management/features/storage/domain/models/stored_file.dart';
import 'package:campus_management/features/storage/domain/models/file_category.dart';
import 'package:campus_management/core/firebase/firebase_services.dart';

// Fake FirestoreService for testing Firebase queries and operations
class FakeFirestoreService implements FirestoreService {
  final Map<String, Map<String, dynamic>> collections = {};
  Map<String, dynamic>? lastWatchFilters;
  Map<String, dynamic>? lastQueryFilters;

  @override
  Stream<List<Map<String, dynamic>>> watchQuery(
    String collection,
    Map<String, dynamic> filters, {
    int? limit = 50,
    String? orderBy,
    bool descending = false,
  }) {
    lastWatchFilters = Map.from(filters);
    final results = collections.entries
        .where((e) => e.key.startsWith('$collection/'))
        .map((e) => e.value)
        .where((doc) {
          for (final entry in filters.entries) {
            if (doc[entry.key] != entry.value) return false;
          }
          return true;
        })
        .toList();
    return Stream.value(results);
  }

  @override
  Future<List<Map<String, dynamic>>> queryCollection(
    String collection,
    Map<String, dynamic> filters, {
    int? limit = 100,
    String? orderBy,
    bool descending = false,
  }) async {
    lastQueryFilters = Map.from(filters);
    return collections.entries
        .where((e) => e.key.startsWith('$collection/'))
        .map((e) => e.value)
        .where((doc) {
          for (final entry in filters.entries) {
            if (doc[entry.key] != entry.value) return false;
          }
          return true;
        })
        .toList();
  }

  @override
  Future<Map<String, dynamic>?> getDocument(String collection, String docId) async {
    return collections['$collection/$docId'];
  }

  @override
  Future<void> setDocument(String collection, String docId, Map<String, dynamic> data, {bool merge = true}) async {
    collections['$collection/$docId'] = Map.from(data);
  }

  Future<void> updateDocument(String collection, String docId, Map<String, dynamic> data) async {
    final existing = collections['$collection/$docId'] ?? {};
    existing.addAll(data);
    collections['$collection/$docId'] = existing;
  }

  @override
  Future<void> deleteDocument(String collection, String docId) async {
    collections.remove('$collection/$docId');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Fake Storage Repository to verify physical file deletion lifecycle
class FakeFileStorageRepository implements FileStorageRepository {
  final List<String> deletedPaths = [];
  final List<String> uploadedFiles = [];

  @override
  Future<void> deleteFile(String storagePath) async {
    deletedPaths.add(storagePath);
  }

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
    uploadedFiles.add(fileName);
    final now = DateTime.now();
    return StoredFile(
      id: 'stored-123',
      ownerUid: ownerUid,
      collegeId: collegeId ?? 'col-1',
      departmentId: departmentId,
      category: category,
      fileName: fileName,
      storagePath: 'certificates/$ownerUid/$fileName',
      downloadUrl: 'https://storage.mock.local/$fileName',
      contentType: contentType,
      sizeBytes: bytes.length,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Future<String> getDownloadUrl(String storagePath) async {
    return 'https://storage.mock.local/$storagePath';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Certificates Firebase Storage Lifecycle & Security', () {
    late FakeFirestoreService fakeFirestore;
    late FakeFileStorageRepository fakeStorage;
    late FirebaseCertificateRepository repository;

    setUp(() {
      fakeFirestore = FakeFirestoreService();
      fakeStorage = FakeFileStorageRepository();
      repository = FirebaseCertificateRepository(
        fakeFirestore,
        fileStorageRepository: fakeStorage,
      );
    });

    test('watchStudentCertificates queries scoped to studentUid with real-time stream', () async {
      final now = DateTime.now();
      final cert = Certificate(
        id: 'cert-1',
        studentId: 'stud-101',
        studentUid: 'student_uid_1',
        studentName: 'Bob Builder',
        collegeId: 'college-alpha',
        departmentId: 'dept-cse',
        title: 'Google Cloud Certified Professional',
        type: CertificateType.technical,
        issuer: 'Google Cloud',
        issueDate: now,
        fileName: 'gcp_cert.pdf',
        fileType: 'pdf',
        fileSizeBytes: 204800,
        storageFileId: 'stored-123',
        storagePath: 'certificates/student_uid_1/gcp_cert.pdf',
        status: CertificateStatus.active,
        uploadedAt: now,
        updatedAt: now,
        uploadedBy: 'student_uid_1',
        isVerified: false,
      );

      await fakeFirestore.setDocument('certificates', 'cert-1', cert.toJson());

      final stream = repository.watchStudentCertificates('student_uid_1');
      final list = await stream.first;

      expect(list.length, 1);
      expect(list.first.title, 'Google Cloud Certified Professional');
      expect(fakeFirestore.lastWatchFilters?['studentUid'], 'student_uid_1');
    });

    test('deleteCertificate cleans up physical storage file and removes Firestore document', () async {
      final now = DateTime.now();
      final cert = Certificate(
        id: 'cert-to-delete',
        studentId: 'stud-101',
        studentUid: 'student_uid_1',
        studentName: 'Bob Builder',
        collegeId: 'college-alpha',
        departmentId: 'dept-cse',
        title: 'Legacy Python Certificate',
        type: CertificateType.academic,
        issuer: 'Coursera',
        issueDate: now,
        fileName: 'python.pdf',
        fileType: 'pdf',
        fileSizeBytes: 102400,
        storageFileId: 'stored-456',
        storagePath: 'certificates/student_uid_1/python.pdf',
        status: CertificateStatus.active,
        uploadedAt: now,
        updatedAt: now,
        uploadedBy: 'student_uid_1',
        isVerified: false,
      );

      await fakeFirestore.setDocument('certificates', 'cert-to-delete', cert.toJson());
      expect(await fakeFirestore.getDocument('certificates', 'cert-to-delete'), isNotNull);

      // Perform deletion
      await repository.deleteCertificate('cert-to-delete', 'student_uid_1');

      // Verify physical storage cleanup was executed
      expect(fakeStorage.deletedPaths, contains('certificates/student_uid_1/python.pdf'));

      // Verify Firestore document was removed
      final doc = await fakeFirestore.getDocument('certificates', 'cert-to-delete');
      expect(doc, isNull);
    });

    test('verifyCertificate updates status to verified and records verifier metadata', () async {
      final now = DateTime.now();
      final cert = Certificate(
        id: 'cert-to-verify',
        studentId: 'stud-101',
        studentUid: 'student_uid_1',
        studentName: 'Bob Builder',
        collegeId: 'college-alpha',
        departmentId: 'dept-cse',
        title: 'TensorFlow Developer Certificate',
        type: CertificateType.technical,
        issuer: 'DeepLearning.AI',
        issueDate: now,
        fileName: 'tf.pdf',
        fileType: 'pdf',
        fileSizeBytes: 300000,
        storageFileId: 'stored-789',
        storagePath: 'certificates/student_uid_1/tf.pdf',
        status: CertificateStatus.active,
        uploadedAt: now,
        updatedAt: now,
        uploadedBy: 'student_uid_1',
        isVerified: false,
      );

      await fakeFirestore.setDocument('certificates', 'cert-to-verify', cert.toJson());

      // Verify certificate
      await repository.verifyCertificate(
        certificateId: 'cert-to-verify',
        verifierUid: 'faculty_uid_1',
        verifierName: 'Prof. Alan Turing',
      );

      final updatedDoc = await fakeFirestore.getDocument('certificates', 'cert-to-verify');
      expect(updatedDoc?['isVerified'], true);
      expect(updatedDoc?['verifiedBy'], 'Prof. Alan Turing');
      expect(updatedDoc?['status'], 'verified');
    });

    test('Certificate file validation enforces allowed extensions and 10MB limit', () {
      // Valid file
      final validErr = validateCertificateFile(
        fileName: 'my_certificate.pdf',
        fileSizeBytes: 5 * 1024 * 1024,
      );
      expect(validErr, isNull);

      // Invalid extension (.exe)
      final extErr = validateCertificateFile(
        fileName: 'malicious.exe',
        fileSizeBytes: 1024,
      );
      expect(extErr, contains('Executable files are not allowed'));

      // Size limit exceeded (11MB)
      final sizeErr = validateCertificateFile(
        fileName: 'huge_scan.pdf',
        fileSizeBytes: 11 * 1024 * 1024,
      );
      expect(sizeErr, contains('File too large'));
    });
  });

  group('MockCertificateRepository Streams & In-Memory Operations', () {
    late MockCertificateRepository mockRepo;

    setUp(() {
      mockRepo = MockCertificateRepository();
    });

    test('Mock repo creates and streams student certificates correctly', () async {
      final now = DateTime.now();
      final newCert = Certificate(
        id: 'mock-c1',
        studentId: 'stud-mock',
        studentUid: 'student_mock_uid',
        studentName: 'Carol Danvers',
        collegeId: 'col-1',
        departmentId: 'dept-1',
        title: 'IEEE Best Paper Award',
        type: CertificateType.achievement,
        issuer: 'IEEE Computer Society',
        issueDate: now,
        fileName: 'ieee.pdf',
        fileType: 'pdf',
        fileSizeBytes: 150000,
        storageFileId: 'file-1',
        storagePath: 'mock/ieee.pdf',
        status: CertificateStatus.active,
        uploadedAt: now,
        updatedAt: now,
        uploadedBy: 'student_mock_uid',
        isVerified: false,
      );

      await mockRepo.createCertificate(newCert);
      final list = await mockRepo.watchStudentCertificates('student_mock_uid').first;

      expect(list.any((c) => c.title == 'IEEE Best Paper Award'), isTrue);
    });

    test('Mock repo verify updates in-memory record and stream reflects verification', () async {
      final now = DateTime.now();
      final newCert = Certificate(
        id: 'mock-verify-1',
        studentId: 'stud-mock-2',
        studentUid: 'student_mock_uid_2',
        studentName: 'David Banner',
        collegeId: 'col-1',
        departmentId: 'dept-1',
        title: 'AWS Machine Learning Specialty',
        type: CertificateType.technical,
        issuer: 'AWS',
        issueDate: now,
        fileName: 'aws.pdf',
        fileType: 'pdf',
        fileSizeBytes: 120000,
        storageFileId: 'file-2',
        storagePath: 'mock/aws.pdf',
        status: CertificateStatus.active,
        uploadedAt: now,
        updatedAt: now,
        uploadedBy: 'student_mock_uid_2',
        isVerified: false,
      );

      await mockRepo.createCertificate(newCert);
      await mockRepo.verifyCertificate(
        certificateId: 'mock-verify-1',
        verifierUid: 'faculty-1',
        verifierName: 'Dr. Bruce',
      );

      final fetched = await mockRepo.getCertificate('mock-verify-1');
      expect(fetched?.isVerified, isTrue);
      expect(fetched?.verifiedBy, 'faculty-1');
      expect(fetched?.status, CertificateStatus.verified);
    });
  });

  group('O(1) Student Identity Resolution & Request Model', () {
    test('CertificateRequest serialization and status transitions', () {
      final now = DateTime(2026, 3, 15);
      final req = CertificateRequest(
        id: 'req-101',
        studentId: 'STU-2024-001',
        studentUserId: 'user-auth-uid-1',
        collegeId: 'COL-001',
        departmentId: 'DEP-CSE',
        courseId: 'CRS-BTECH-CSE',
        academicYearId: 'AY-2024-25',
        certificateTypeId: 'cert-bonafide',
        certificateTypeName: 'Bonafide Certificate',
        reason: 'Required for passport application',
        purpose: 'Passport and Visa Renewal',
        status: CertificateRequestStatus.pending,
        requestedAt: now,
        createdAt: now,
        updatedAt: now,
      );

      final json = req.toJson();
      expect(json['certificateTypeName'], 'Bonafide Certificate');
      expect(json['status'], 'pending');
      expect(json['studentId'], 'STU-2024-001');

      final restored = CertificateRequest.fromJson(json);
      expect(restored.certificateTypeName, 'Bonafide Certificate');
      expect(restored.status, CertificateRequestStatus.pending);

      // Transition to approved
      final approved = restored.copyWith(
        status: CertificateRequestStatus.approved,
        reviewedBy: 'Admin Smith',
        reviewedAt: now,
      );
      expect(approved.status, CertificateRequestStatus.approved);
      expect(approved.reviewedBy, 'Admin Smith');
    });

    test('ConfiguredCertificateType model serialization', () {
      const type = ConfiguredCertificateType(
        id: 'type-bonafide',
        name: 'Bonafide Certificate',
        description: 'Institutional proof of active student enrollment',
        requiresPurpose: true,
        requiresReason: true,
        isActive: true,
      );

      final json = type.toJson();
      expect(json['requiresPurpose'], isTrue);
      expect(json['requiresReason'], isTrue);

      final restored = ConfiguredCertificateType.fromJson(json);
      expect(restored.name, 'Bonafide Certificate');
      expect(restored.requiresPurpose, isTrue);
    });
  });
}
