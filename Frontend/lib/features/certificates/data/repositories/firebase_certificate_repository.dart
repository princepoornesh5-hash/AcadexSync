import 'package:uuid/uuid.dart';
import '../../../../core/firebase/firebase_services.dart';
import '../../../storage/domain/repositories/file_storage_repository.dart';
import '../../domain/models/certificate.dart';
import '../../domain/models/certificate_status.dart';
import '../../domain/models/certificate_type.dart';
import '../../domain/repositories/certificate_repository.dart';

class FirebaseCertificateRepository implements CertificateRepository {
  final FirestoreService _firestoreService;
  final FileStorageRepository? _fileStorageRepository;

  FirebaseCertificateRepository(
    this._firestoreService, {
    FileStorageRepository? fileStorageRepository,
  })  : _fileStorageRepository = fileStorageRepository;

  @override
  Stream<List<Certificate>> watchStudentCertificates(String studentUid) {
    return _firestoreService.watchQuery('certificates', {
      'studentUid': studentUid,
    }).map((docs) => docs.map((d) => Certificate.fromJson(d)).toList()
      ..sort((a, b) => b.issueDate.compareTo(a.issueDate)));
  }

  @override
  Future<List<Certificate>> getStudentCertificates(String studentUid) async {
    final docs = await _firestoreService.queryCollection('certificates', {
      'studentUid': studentUid,
    });
    return docs.map((d) => Certificate.fromJson(d)).toList()
      ..sort((a, b) => b.issueDate.compareTo(a.issueDate));
  }

  @override
  Future<Certificate?> getCertificate(String certificateId) async {
    final doc = await _firestoreService.getDocument('certificates', certificateId);
    if (doc == null) return null;
    return Certificate.fromJson(doc);
  }

  @override
  Future<Certificate> createCertificate(Certificate certificate) async {
    final docId = certificate.id.isNotEmpty ? certificate.id : const Uuid().v4();
    final newCert = certificate.copyWith(id: docId);
    await _firestoreService.setDocument('certificates', docId, newCert.toJson());
    return newCert;
  }

  @override
  Future<Certificate> updateCertificate(Certificate certificate) async {
    await _firestoreService.setDocument('certificates', certificate.id, certificate.toJson());
    return certificate;
  }

  @override
  Future<void> deleteCertificate(String certificateId, String requestingUid) async {
    try {
      final cert = await getCertificate(certificateId);
      if (cert != null && cert.storagePath.isNotEmpty && _fileStorageRepository != null) {
        try {
          await _fileStorageRepository.deleteFile(cert.storagePath);
        } catch (_) {
          // File may already be deleted; continue with Firestore document cleanup
        }
      }
    } catch (_) {
      // Best-effort storage cleanup; proceed to document deletion
    }
    await _firestoreService.deleteDocument('certificates', certificateId);
  }

  @override
  Future<List<Certificate>> searchCertificates(String query, {String? scopeStudentUid, String? scopeCollegeId, String? scopeDepartmentId}) async {
    final filters = <String, dynamic>{};
    if (scopeStudentUid != null) filters['studentUid'] = scopeStudentUid;
    if (scopeCollegeId != null) filters['collegeId'] = scopeCollegeId;
    if (scopeDepartmentId != null) filters['departmentId'] = scopeDepartmentId;
    
    final docs = await _firestoreService.queryCollection('certificates', filters);
    final results = docs.map((d) => Certificate.fromJson(d)).toList();
    
    final q = query.toLowerCase();
    return results.where((c) => 
      c.title.toLowerCase().contains(q) || 
      c.issuer.toLowerCase().contains(q) || 
      c.studentName.toLowerCase().contains(q)
    ).toList();
  }

  @override
  Future<List<Certificate>> filterCertificates({
    String? studentUid,
    String? collegeId,
    String? departmentId,
    String? courseId,
    CertificateType? type,
    CertificateStatus? status,
    DateTime? issuedAfter,
    DateTime? issuedBefore,
  }) async {
    final filters = <String, dynamic>{};
    if (studentUid != null) filters['studentUid'] = studentUid;
    if (collegeId != null) filters['collegeId'] = collegeId;
    if (departmentId != null) filters['departmentId'] = departmentId;
    if (courseId != null) filters['courseId'] = courseId;
    if (type != null) filters['type'] = type.name;
    if (status != null) filters['status'] = status.name;

    final docs = await _firestoreService.queryCollection('certificates', filters);
    var results = docs.map((d) => Certificate.fromJson(d)).toList();

    if (issuedAfter != null) {
      results = results.where((c) => c.issueDate.isAfter(issuedAfter)).toList();
    }
    if (issuedBefore != null) {
      results = results.where((c) => c.issueDate.isBefore(issuedBefore)).toList();
    }

    return results;
  }

  @override
  Stream<List<Certificate>> watchFacultyStudentCertificates({
    required String facultyUid,
    required String collegeId,
    required String departmentId,
    String? sectionId,
  }) {
    final filters = <String, dynamic>{
      'collegeId': collegeId,
      'departmentId': departmentId,
    };
    if (sectionId != null) filters['sectionId'] = sectionId;

    return _firestoreService.watchQuery('certificates', filters)
      .map((docs) => docs.map((d) => Certificate.fromJson(d)).toList()
        ..sort((a, b) => b.issueDate.compareTo(a.issueDate)));
  }

  @override
  Future<List<Certificate>> getFacultyStudentCertificates({
    required String facultyUid,
    required String collegeId,
    required String departmentId,
    String? sectionId,
  }) async {
    final filters = <String, dynamic>{
      'collegeId': collegeId,
      'departmentId': departmentId,
    };
    if (sectionId != null) filters['sectionId'] = sectionId;

    final docs = await _firestoreService.queryCollection('certificates', filters);
    return docs.map((d) => Certificate.fromJson(d)).toList()
      ..sort((a, b) => b.issueDate.compareTo(a.issueDate));
  }

  @override
  Future<Certificate> verifyCertificate({
    required String certificateId,
    required String verifierUid,
    required String verifierName,
  }) async {
    final existing = await getCertificate(certificateId);
    if (existing == null) {
      throw Exception('Certificate not found: $certificateId');
    }
    final now = DateTime.now();
    final verified = existing.copyWith(
      isVerified: true,
      verifiedBy: verifierName,
      verifiedAt: now,
      status: CertificateStatus.verified,
      updatedAt: now,
      updatedBy: verifierUid,
    );
    await _firestoreService.setDocument('certificates', certificateId, verified.toJson());
    return verified;
  }
}
