import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:campus_management/core/firebase/firebase_config.dart';
import 'package:campus_management/core/firebase/firebase_exceptions.dart';

void main() {
  group('Firebase Config Tests', () {
    test('Development Config parses placeholders correctly', () {
      final config = FirebaseConfig.fromEnvironment(FirebaseEnv.development);
      expect(config.environment, FirebaseEnv.development);
      expect(config.projectId, 'acadex-dev');
      expect(config.isPlaceholder, isTrue);
    });

    test('Production Config parses placeholders correctly', () {
      final config = FirebaseConfig.fromEnvironment(FirebaseEnv.production);
      expect(config.environment, FirebaseEnv.production);
      expect(config.projectId, 'acadex-prod');
    });
  });

  group('Firebase Error Mapping Tests', () {
    test('map maps invalid-credential code to BackendAuthException', () {
      final authException = FirebaseAuthException(
        code: 'invalid-credential',
        message: 'Invalid credential.',
      );
      final mapped = FirebaseErrorMapper.map(authException);
      expect(mapped, isA<BackendAuthException>());
      expect(mapped.message, 'Invalid email or password.');
    });

    test('map maps permission-denied code to BackendPermissionException', () {
      final firebaseException = FirebaseException(
        plugin: 'firestore',
        code: 'permission-denied',
        message: 'Permission denied.',
      );
      final mapped = FirebaseErrorMapper.map(firebaseException);
      expect(mapped, isA<BackendPermissionException>());
      expect(mapped.message, 'You are not authorized to perform this action.');
    });

    test('map maps unknown exception to UnknownBackendException', () {
      final mapped = FirebaseErrorMapper.map(Exception('Test error'));
      expect(mapped, isA<UnknownBackendException>());
      expect(mapped.message, contains('Test error'));
    });
  });
}
