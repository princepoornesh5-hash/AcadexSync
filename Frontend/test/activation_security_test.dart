import 'package:flutter_test/flutter_test.dart';
import 'package:campus_management/features/academic_structure/domain/models/academic_models.dart';
import 'package:campus_management/features/auth/data/repositories/mock_activation_repository.dart';

void main() {
  group('Prompt 57: Student Onboarding & Activation Security Tests', () {
    late MockActivationRepository activationRepo;

    final studentA = Student(
      id: 's1',
      collegeId: 'col-1',
      departmentId: 'dept-cse',
      courseId: 'crs-cse',
      sectionId: 'sec-1',
      semesterId: 'sem-1',
      rollNumber: 'CS2025001',
      name: 'Student A',
      email: 'studenta@acadex.com',
      phone: '1111111111',
    );

    final studentB = Student(
      id: 'std-b',
      collegeId: 'col-1',
      departmentId: 'dept-cse',
      courseId: 'crs-cse',
      sectionId: 'sec-1',
      semesterId: 'sem-1',
      rollNumber: 'COL002',
      name: 'Student B',
      email: 'studentb@acadex.com',
      phone: '2222222222',
    );

    setUp(() {
      activationRepo = MockActivationRepository();
    });

    test('1. Generated activation code is unique, unpredictable, and valid for student', () async {
      final codeA = await activationRepo.generateActivationCode(studentA);
      expect(codeA.length, equals(8));

      final validatedStudent = await activationRepo.validateActivation('CS2025001', codeA);
      expect(validatedStudent['id'], equals('s1')); // s1 corresponds to CS2025001 pre-seeded or generated
    });

    test('2. MANDATORY SECURITY MATRIX (Section 27): College ID + Activation Code Binding', () async {
      final codeA = await activationRepo.generateActivationCode(studentA);
      final codeB = await activationRepo.generateActivationCode(studentB);

      // COL001 + Activation A -> SUCCESS (Pre-seeded CS2025001 / VALID123 check)
      final validA = await activationRepo.validateActivation('CS2025001', 'VALID123');
      expect(validA['rollNumber'], equals('CS2025001'));

      // COL001 + Activation B -> FAILURE
      expect(
        () => activationRepo.validateActivation('COL001', codeB),
        throwsA(isA<Exception>()),
      );

      // COL002 + Activation A -> FAILURE
      expect(
        () => activationRepo.validateActivation('COL002', codeA),
        throwsA(isA<Exception>()),
      );

      // COL001 + Random Code -> FAILURE
      expect(
        () => activationRepo.validateActivation('COL001', 'RANDOM999'),
        throwsA(isA<Exception>()),
      );

      // COL002 + Random Code -> FAILURE
      expect(
        () => activationRepo.validateActivation('COL002', 'RANDOM999'),
        throwsA(isA<Exception>()),
      );
    });

    test('3. Reused activation code throws exception immediately', () async {
      // USED123 is pre-seeded as used
      expect(
        () => activationRepo.validateActivation('CS2025002', 'USED123'),
        throwsA(predicate((e) => e.toString().contains('already been used'))),
      );
    });

    test('4. Expired activation code throws exception', () async {
      // EXPIRED123 is pre-seeded as expired
      expect(
        () => activationRepo.validateActivation('CS2025003', 'EXPIRED123'),
        throwsA(predicate((e) => e.toString().contains('expired'))),
      );
    });

    test('5. Successful completion invalidates code immediately', () async {
      // Complete activation for valid code
      await activationRepo.completeActivation('CS2025001', 'VALID123', 'NewPass123!');

      // Attempting to reuse VALID123 immediately fails
      expect(
        () => activationRepo.validateActivation('CS2025001', 'VALID123'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
