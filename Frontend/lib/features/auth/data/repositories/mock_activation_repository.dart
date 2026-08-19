import 'package:uuid/uuid.dart';
import '../../../academic_structure/domain/models/academic_models.dart';
import '../../../academic_structure/data/repositories/mock_academic_repository.dart';
import '../../domain/models/activation_model.dart';
import '../../domain/repositories/activation_repository.dart';
import '../../domain/models/role_enum.dart';

class MockActivationRepository implements AccountActivationRepository {
  final List<ActivationRecord> _records = [
    // Pre-seed with mock records for testing
    // VALID CODE: 'VALID123' for student s1 (CS2025001)
    ActivationRecord(
      id: 'mock-act-1',
      studentId: 's1',
      rollNumber: 'CS2025001',
      role: AppRole.student,
      codeHash: ActivationRecord.hashCodeString('VALID123'),
      status: ActivationStatus.pending,
      expiresAt: DateTime.now().add(const Duration(days: 1)),
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    // USED CODE: 'USED123' for student s2 (CS2025002)
    ActivationRecord(
      id: 'mock-act-2',
      studentId: 's2',
      rollNumber: 'CS2025002',
      role: AppRole.student,
      codeHash: ActivationRecord.hashCodeString('USED123'),
      status: ActivationStatus.used,
      expiresAt: DateTime.now().add(const Duration(days: 1)),
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      usedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    // EXPIRED CODE: 'EXPIRED123' for student s3 (CS2025003)
    ActivationRecord(
      id: 'mock-act-3',
      studentId: 's3',
      rollNumber: 'CS2025003',
      role: AppRole.student,
      codeHash: ActivationRecord.hashCodeString('EXPIRED123'),
      status: ActivationStatus.expired,
      expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  Future<void> _delay() async => await Future.delayed(const Duration(milliseconds: 500));

  @override
  Future<String> generateActivationCode(Student student) async {
    await _delay();
    final String plaintextCode = const Uuid().v4().substring(0, 8).toUpperCase();
    final record = ActivationRecord(
      id: const Uuid().v4(),
      studentId: student.id,
      rollNumber: student.rollNumber,
      role: AppRole.student,
      codeHash: ActivationRecord.hashCodeString(plaintextCode),
      status: ActivationStatus.pending,
      expiresAt: DateTime.now().add(const Duration(hours: 48)),
      createdAt: DateTime.now(),
    );
    _records.add(record);
    return plaintextCode;
  }

  @override
  Future<String> generateFacultyActivationCode(Faculty faculty) async {
    await _delay();
    final String plaintextCode = const Uuid().v4().substring(0, 8).toUpperCase();
    final record = ActivationRecord(
      id: const Uuid().v4(),
      facultyId: faculty.id,
      employeeId: faculty.employeeId,
      role: AppRole.faculty,
      codeHash: ActivationRecord.hashCodeString(plaintextCode),
      status: ActivationStatus.pending,
      expiresAt: DateTime.now().add(const Duration(hours: 48)),
      createdAt: DateTime.now(),
    );
    _records.add(record);
    return plaintextCode;
  }

  @override
  Future<dynamic> validateActivation(String identifier, String code) async {
    await _delay();
    final inputHash = ActivationRecord.hashCodeString(code);
    
    try {
      final record = _records.firstWhere((r) => 
        (r.rollNumber == identifier || r.employeeId == identifier) && r.codeHash == inputHash);
      
      if (record.status == ActivationStatus.used) {
        throw Exception("This activation code has already been used.");
      }
      if (record.status == ActivationStatus.expired || record.isExpired) {
        throw Exception("This activation code has expired.");
      }
      if (record.status == ActivationStatus.disabled) {
        throw Exception("This activation code has been disabled.");
      }
      
      if (record.role == AppRole.student) {
        final students = await mockAcademicRepo.getStudents();
        return students.firstWhere((s) => s.id == record.studentId).toJson();
      } else {
        final faculty = await mockAcademicRepo.getFaculty();
        return faculty.firstWhere((f) => f.id == record.facultyId).toJson();
      }
    } catch (e) {
      if (e is StateError) {
        throw Exception("Invalid activation details."); // Generic error to prevent enumeration
      }
      rethrow;
    }
  }

  @override
  Future<String> completeActivation(String identifier, String code, String newPassword) async {
    await _delay();
    await validateActivation(identifier, code);
    
    final inputHash = ActivationRecord.hashCodeString(code);
    final index = _records.indexWhere((r) => 
      (r.rollNumber == identifier || r.employeeId == identifier) && r.codeHash == inputHash);
    
    if (index != -1) {
      _records[index] = _records[index].copyWith(
        status: ActivationStatus.used,
        usedAt: DateTime.now(),
      );
      final id = _records[index].role == AppRole.student ? _records[index].studentId : _records[index].facultyId;
      return 'mock-uid-$id';
    }
    
    throw Exception("Activation failed.");
  }
}

final mockActivationRepo = MockActivationRepository();
