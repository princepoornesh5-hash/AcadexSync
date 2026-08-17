import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/firebase/firebase_services.dart';
import '../../domain/models/certificate.dart';
import '../../domain/models/certificate_status.dart';
import '../../domain/models/certificate_type.dart';
import '../../domain/repositories/certificate_repository.dart';

class FirebaseCertificateRepository implements CertificateRepository {
  final FirestoreService _firestoreService;

  FirebaseCertificateRepository(this._firestoreService);

  CollectionReference get _collection => FirebaseFirestore.instance.collection('certificates');

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
    final docId = _collection.doc().id;
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
    await _firestoreService.deleteDocument('certificates', certificateId);
  }

  @override
  Future<List<Certificate>> searchCertificates(String query, {String? scopeStudentUid, String? scopeCollegeId, String? scopeDepartmentId}) async {
    // Note: In Firestore, pure text search across multiple fields requires external indexing. 
    // We will fetch the scoped records and filter client-side.
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
    final now = DateTime.now();
    await _firestoreService.setDocument('certificates', certificateId, {
      'isVerified': true,
      'verifiedBy': verifierUid,
      'verifiedAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
      'updatedBy': verifierUid,
    });
    
    final updatedDoc = await getCertificate(certificateId);
    if (updatedDoc == null) throw Exception('Certificate not found after verification');
    return updatedDoc;
  }
}
