import 'package:flutter_test/flutter_test.dart';

import 'package:campus_management/features/auth/data/repositories/mock_activation_repository.dart';

void main() {
  group('Activation Module Tests', () {
    test('Mock repo rejects invalid activation code', () async {
      expect(
        () => mockActivationRepo.validateActivation('CS2025001', 'WRONGCODE'),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Invalid activation details.'))),
      );
    });

    test('Mock repo rejects expired code', () async {
      expect(
        () => mockActivationRepo.validateActivation('CS2025003', 'EXPIRED123'),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('expired'))),
      );
    });

    test('Mock repo rejects already used code', () async {
      expect(
        () => mockActivationRepo.validateActivation('CS2025002', 'USED123'),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('used'))),
      );
    });

    test('Mock repo accepts valid code and completes activation', () async {
      // 1. Validate
      final student = await mockActivationRepo.validateActivation('CS2025001', 'VALID123');
      expect(student['rollNumber'], 'CS2025001');

      // 2. Complete Activation
      final uid = await mockActivationRepo.completeActivation('CS2025001', 'VALID123', 'StrongPass123!');
      expect(uid, isNotEmpty);
      expect(uid, startsWith('mock-uid-'));

      // 3. Try again, should now be USED
      expect(
        () => mockActivationRepo.validateActivation('CS2025001', 'VALID123'),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('used'))),
      );
    });
  });
}
