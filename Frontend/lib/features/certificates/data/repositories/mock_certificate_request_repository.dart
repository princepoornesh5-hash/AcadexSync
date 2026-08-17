import 'dart:async';
import 'package:uuid/uuid.dart';
import '../../domain/models/certificate_request_model.dart';
import 'certificate_request_repository.dart';

class MockCertificateRequestRepository implements CertificateRequestRepository {
  final List<CertificateRequest> _requests = [];
  bool _initialized = false;
  final _controller = StreamController<List<CertificateRequest>>.broadcast();

  final List<ConfiguredCertificateType> _types = const [
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

  Future<void> _delay() async => await Future.delayed(const Duration(milliseconds: 300));

  void _emit() {
    if (!_controller.isClosed) {
      _controller.add(List.from(_requests));
    }
  }

  void _generateInitialData() {
    final now = DateTime.now();
    _requests.addAll([
      CertificateRequest(
        id: 'req-1',
        studentId: 'STU001',
        studentUserId: 'student-user-id',
        collegeId: 'col-1',
        departmentId: 'dept-cse',
        courseId: 'crs-cse',
        academicYearId: 'ay-2023',
        certificateTypeId: 'type-bonafide',
        certificateTypeName: 'Bonafide Certificate',
        purpose: 'Passport application',
        status: CertificateRequestStatus.pending,
        requestedAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(days: 2)),
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      CertificateRequest(
        id: 'req-2',
        studentId: 'STU001',
        studentUserId: 'student-user-id',
        collegeId: 'col-1',
        departmentId: 'dept-cse',
        courseId: 'crs-cse',
        academicYearId: 'ay-2023',
        certificateTypeId: 'type-study',
        certificateTypeName: 'Study Certificate',
        reason: 'Applying for internship',
        status: CertificateRequestStatus.approved,
        requestedAt: now.subtract(const Duration(days: 5)),
        updatedAt: now.subtract(const Duration(days: 4)),
        reviewedAt: now.subtract(const Duration(days: 4)),
        reviewedBy: 'hod-user-id',
        createdAt: now.subtract(const Duration(days: 5)),
      ),
    ]);
  }

  @override
  Future<List<ConfiguredCertificateType>> getCertificateTypes() async {
    await _delay();
    return _types.where((t) => t.isActive).toList();
  }

  @override
  Stream<List<CertificateRequest>> watchStudentRequests(String studentUserId) {
    if (!_initialized) {
      _generateInitialData();
      _initialized = true;
    }
    Future.microtask(() => _emit());
    return _controller.stream.map((requests) {
      return requests.where((r) => r.studentUserId == studentUserId).toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    });
  }

  @override
  Stream<List<CertificateRequest>> watchAdminRequests({
    String? collegeId,
    String? departmentId,
  }) {
    if (!_initialized) {
      _generateInitialData();
      _initialized = true;
    }
    Future.microtask(() => _emit());
    return _controller.stream.map((requests) {
      return requests.where((r) {
        if (collegeId != null && r.collegeId != collegeId) return false;
        if (departmentId != null && r.departmentId != departmentId) return false;
        return true;
      }).toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    });
  }

  @override
  Future<void> createRequest(CertificateRequest request) async {
    await _delay();
    final newReq = request.copyWith(
      id: const Uuid().v4(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      requestedAt: DateTime.now(),
      status: CertificateRequestStatus.pending,
    );
    _requests.add(newReq);
    _emit();
  }

  @override
  Future<void> updateRequestStatus({
    required String requestId,
    required CertificateRequestStatus status,
    String? rejectionReason,
    String? reviewedBy,
  }) async {
    await _delay();
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index == -1) throw Exception('Request not found');

    final now = DateTime.now();
    _requests[index] = _requests[index].copyWith(
      status: status,
      rejectionReason: rejectionReason,
      reviewedBy: reviewedBy ?? _requests[index].reviewedBy,
      reviewedAt: now,
      updatedAt: now,
    );
    _emit();
  }
}
