import 'package:uuid/uuid.dart';
import '../../../academic_structure/domain/models/academic_models.dart';
import '../../../academic_structure/data/repositories/mock_academic_repository.dart';
import '../../domain/models/activation_model.dart';
import '../../domain/repositories/activation_repository.dart';

class MockActivationRepository implements AccountActivationRepository {
  final List<ActivationRecord> _records = [
    // Pre-seed with mock records for testing
    // VALID CODE: 'VALID123' for student s1 (CS2025001)
    ActivationRecord(
      id: 'mock-act-1',
      studentId: 's1',
      rollNumber: 'CS2025001',
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
    // Generate a secure-looking random code (mock version)
    final String plaintextCode = const Uuid().v4().substring(0, 8).toUpperCase();
    
    final record = ActivationRecord(
      id: const Uuid().v4(),
      studentId: student.id,
      rollNumber: student.rollNumber,
      codeHash: ActivationRecord.hashCodeString(plaintextCode),
      status: ActivationStatus.pending,
      expiresAt: DateTime.now().add(const Duration(hours: 48)),
      createdAt: DateTime.now(),
    );
    
    _records.add(record);
    return plaintextCode;
  }

  @override
  Future<Student> validateActivation(String rollNumber, String code) async {
    await _delay();
    
    final inputHash = ActivationRecord.hashCodeString(code);
    
    try {
      final record = _records.firstWhere((r) => r.rollNumber == rollNumber && r.codeHash == inputHash);
      
      if (record.status == ActivationStatus.used) {
        throw Exception("This activation code has already been used.");
      }
      if (record.status == ActivationStatus.expired || record.isExpired) {
        throw Exception("This activation code has expired.");
      }
      if (record.status == ActivationStatus.disabled) {
        throw Exception("This activation code has been disabled.");
      }
      
      final students = await mockAcademicRepo.getStudents();
      final student = students.firstWhere((s) => s.id == record.studentId);
      return student;
    } catch (e) {
      if (e is StateError) {
        throw Exception("Invalid activation details."); // Generic error to prevent enumeration
      }
      rethrow;
    }
  }

  @override
  Future<String> completeActivation(String rollNumber, String code, String newPassword) async {
    await _delay();
    
    // First, validate again
    await validateActivation(rollNumber, code);
    
    final inputHash = ActivationRecord.hashCodeString(code);
    final index = _records.indexWhere((r) => r.rollNumber == rollNumber && r.codeHash == inputHash);
    
    if (index != -1) {
      _records[index] = _records[index].copyWith(
        status: ActivationStatus.used,
        usedAt: DateTime.now(),
      );
      // In a real mock, we might also create a mock UserProfile here
      // but the mock auth system typically uses pre-defined static accounts.
      // We will just return a fake UID for success.
      return 'mock-uid-${_records[index].studentId}';
    }
    
    throw Exception("Activation failed.");
  }
}

final mockActivationRepo = MockActivationRepository();
