import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/firebase/firebase_services.dart';
import '../../domain/models/certificate_request_model.dart';
import 'certificate_request_repository.dart';

class FirebaseCertificateRequestRepository implements CertificateRequestRepository {
  final FirestoreService _firestoreService;

  FirebaseCertificateRequestRepository(this._firestoreService);

  CollectionReference get _collection => FirebaseFirestore.instance.collection('certificateRequests');
  CollectionReference get _typesCollection => FirebaseFirestore.instance.collection('certificateTypes');

  @override
  Future<List<ConfiguredCertificateType>> getCertificateTypes() async {
    final snapshot = await _typesCollection.where('isActive', isEqualTo: true).get();
    
    // If the database has no types configured yet, we can return a fallback list or just the results
    if (snapshot.docs.isEmpty) {
      // In a real scenario, an admin would set these up. For safety during migration, we can return defaults
      return const [
        ConfiguredCertificateType(
          id: 'type-bonafide',
          name: 'Bonafide Certificate',
          description: 'Official confirmation of student status.',
          requiresPurpose: true,
        ),
        ConfiguredCertificateType(
          id: 'type-study',
          name: 'Study Certificate',
          description: 'Certificate detailing course and academic year.',
          requiresReason: true,
        ),
        ConfiguredCertificateType(
          id: 'type-transfer',
          name: 'Transfer Certificate',
          description: 'Issued upon leaving the institution.',
          requiresReason: true,
          requiresPurpose: true,
        ),
      ];
    }
    
    return snapshot.docs
        .map((doc) => ConfiguredCertificateType.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  @override
  Stream<List<CertificateRequest>> watchStudentRequests(String studentUserId) {
    return _collection
        .where('studentUserId', isEqualTo: studentUserId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CertificateRequest.fromJson(doc.data() as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    });
  }

  @override
  Stream<List<CertificateRequest>> watchAdminRequests({
    String? collegeId,
    String? departmentId,
  }) {
    Query query = _collection;

    if (collegeId != null) {
      query = query.where('collegeId', isEqualTo: collegeId);
    }
    if (departmentId != null) {
      query = query.where('departmentId', isEqualTo: departmentId);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => CertificateRequest.fromJson(doc.data() as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    });
  }

  @override
  Future<void> createRequest(CertificateRequest request) async {
    final docRef = _collection.doc();
    final newReq = request.copyWith(
      id: docRef.id,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      requestedAt: DateTime.now(),
    );
    await docRef.set(newReq.toJson());
  }

  @override
  Future<void> updateRequestStatus({
    required String requestId,
    required CertificateRequestStatus status,
    String? rejectionReason,
    String? reviewedBy,
  }) async {
    final docRef = _collection.doc(requestId);
    
    final updates = <String, dynamic>{
      'status': status.value,
      'updatedAt': DateTime.now().toIso8601String(),
    };

    if (rejectionReason != null) {
      updates['rejectionReason'] = rejectionReason;
    }
    
    if (reviewedBy != null) {
      updates['reviewedBy'] = reviewedBy;
      updates['reviewedAt'] = DateTime.now().toIso8601String();
    }

    await docRef.update(updates);
  }
}
