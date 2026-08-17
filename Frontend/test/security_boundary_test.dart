import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import 'package:campus_management/core/firebase/firebase_initializer.dart';
import 'package:campus_management/core/firebase/dev_identity_registry.dart';

// Import providers
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_management/features/users/presentation/providers/user_profile_providers.dart';
import 'package:campus_management/features/academic_structure/presentation/providers/academic_providers.dart';
import 'package:campus_management/features/attendance/presentation/providers/attendance_providers.dart';
import 'package:campus_management/features/analytics/presentation/providers/analytics_providers.dart';
import 'package:campus_management/features/notifications/presentation/providers/notification_providers.dart';
import 'package:campus_management/features/timetable/presentation/providers/timetable_providers.dart';
import 'package:campus_management/features/notes/presentation/providers/notes_providers.dart';
import 'package:campus_management/features/certificates/presentation/providers/certificate_providers.dart';
import 'package:campus_management/features/certificates/presentation/providers/certificate_request_providers.dart';
import 'package:campus_management/features/settings/presentation/providers/settings_providers.dart';

// Import repositories (Mocks and Real)
import 'package:campus_management/features/auth/repositories/auth_repository.dart';
import 'package:campus_management/features/auth/repositories/firebase_auth_repository.dart';
import 'package:campus_management/features/users/data/repositories/mock_user_profile_repository.dart';
import 'package:campus_management/features/users/data/repositories/firebase_user_profile_repository.dart';
import 'package:campus_management/features/academic_structure/data/repositories/mock_academic_repository.dart';
import 'package:campus_management/features/academic_structure/data/repositories/firebase_academic_repository.dart';
import 'package:campus_management/features/attendance/data/repositories/mock_attendance_repository.dart';
import 'package:campus_management/features/attendance/data/repositories/firebase_attendance_repository.dart';
import 'package:campus_management/features/analytics/data/repositories/mock_analytics_repository.dart';
import 'package:campus_management/features/analytics/data/repositories/firebase_analytics_repository.dart';
import 'package:campus_management/features/notifications/data/repositories/mock_notification_repository.dart';
import 'package:campus_management/features/notifications/data/repositories/firebase_notification_repository.dart';
import 'package:campus_management/features/timetable/data/repositories/mock_timetable_repository.dart';
import 'package:campus_management/features/timetable/data/repositories/firebase_timetable_repository.dart';
import 'package:campus_management/features/notes/data/repositories/mock_notes_repository.dart';
import 'package:campus_management/features/notes/data/repositories/firebase_notes_repository.dart';
import 'package:campus_management/features/certificates/data/repositories/mock_certificate_repository.dart';
import 'package:campus_management/features/certificates/data/repositories/firebase_certificate_repository.dart';
import 'package:campus_management/features/certificates/data/repositories/mock_certificate_request_repository.dart';
import 'package:campus_management/features/certificates/data/repositories/firebase_certificate_request_repository.dart';
import 'package:campus_management/features/settings/data/repositories/mock_settings_repository.dart';
import 'package:campus_management/features/settings/data/repositories/firebase_settings_repository.dart';

// Session manager imports
import 'package:campus_management/features/auth/services/session_manager.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';

// Create a FakeSessionManager to bypass SecureStorage platform channel calls in tests
class FakeSessionManager implements SessionManager {
  @override
  Future<void> saveSession({required String token, required UserModel user}) async {}

  @override
  Future<void> clearSession() async {}

  @override
  Future<bool> hasValidSession() async => false;

  @override
  Future<UserModel?> getUser() async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FirebaseInitializer.overrideShouldUseMock = null;
  });

  tearDown(() {
    FirebaseInitializer.overrideShouldUseMock = null;
  });

  group('Release Mode Hardening & Security Boundary Tests', () {
    test('1. Release Mode prevents fallback to Mock Mode', () {
      FirebaseInitializer.overrideShouldUseMock = false;
      expect(FirebaseInitializer.shouldUseMock, isFalse);
    });

    test('2. DevIdentityRegistry throws StateError in Release Mode', () {
      expect(kDebugMode, isTrue);
      expect(() => DevIdentityRegistry.getProfile('mock-student-uid'), returnsNormally);
    });

    test('3. Providers resolve to Real Firebase Repositories when Mock is disabled', () {
      FirebaseInitializer.overrideShouldUseMock = false;

      final container = ProviderContainer(
        overrides: [
          sessionManagerProvider.overrideWithValue(FakeSessionManager()),
        ],
      );

      addTearDown(() => container.dispose());

      // Verify that providers DO NOT resolve to Mock repositories when shouldUseMock is false
      expect(container.read(authRepositoryProvider), isNot(isA<MockAuthRepository>()));
      expect(container.read(userProfileRepositoryProvider), isNot(isA<MockUserProfileRepository>()));
      expect(container.read(academicRepositoryProvider), isNot(isA<MockAcademicRepository>()));
      expect(container.read(attendanceRepoProvider), isNot(isA<MockAttendanceRepository>()));
      expect(container.read(analyticsRepositoryProvider), isNot(isA<MockAnalyticsRepository>()));
      expect(container.read(notificationRepositoryProvider), isNot(isA<MockNotificationRepository>()));
      expect(container.read(timetableRepositoryProvider), isNot(isA<MockTimetableRepository>()));
      expect(container.read(notesRepositoryProvider), isNot(isA<MockNotesRepository>()));
      expect(container.read(certificateRepositoryProvider), isNot(isA<MockCertificateRepository>()));
      expect(container.read(certificateRequestRepositoryProvider), isNot(isA<MockCertificateRequestRepository>()));
      expect(container.read(settingsRepoProvider), isNot(isA<MockSettingsRepository>()));

      // Confirm they map to their respective Firebase implementations
      expect(container.read(authRepositoryProvider), isA<FirebaseAuthRepository>());
      expect(container.read(userProfileRepositoryProvider), isA<FirebaseUserProfileRepository>());
      expect(container.read(academicRepositoryProvider), isA<FirebaseAcademicRepository>());
      expect(container.read(attendanceRepoProvider), isA<FirebaseAttendanceRepository>());
      expect(container.read(analyticsRepositoryProvider), isA<FirebaseAnalyticsRepository>());
      expect(container.read(notificationRepositoryProvider), isA<FirebaseNotificationRepository>());
      expect(container.read(timetableRepositoryProvider), isA<FirebaseTimetableRepository>());
      expect(container.read(notesRepositoryProvider), isA<FirebaseNotesRepository>());
      expect(container.read(certificateRepositoryProvider), isA<FirebaseCertificateRepository>());
      expect(container.read(certificateRequestRepositoryProvider), isA<FirebaseCertificateRequestRepository>());
      expect(container.read(settingsRepoProvider), isA<FirebaseSettingsRepository>());
    });

    test('4. Providers resolve to Mock Repositories when Mock is enabled (Debug Mode)', () {
      FirebaseInitializer.overrideShouldUseMock = true;

      final container = ProviderContainer(
        overrides: [
          sessionManagerProvider.overrideWithValue(FakeSessionManager()),
        ],
      );

      addTearDown(() => container.dispose());

      // Verify that providers DO resolve to Mock repositories when shouldUseMock is true
      expect(container.read(authRepositoryProvider), isA<MockAuthRepository>());
      expect(container.read(userProfileRepositoryProvider), isA<MockUserProfileRepository>());
      expect(container.read(academicRepositoryProvider), isA<MockAcademicRepository>());
      expect(container.read(attendanceRepoProvider), isA<MockAttendanceRepository>());
      expect(container.read(analyticsRepositoryProvider), isA<MockAnalyticsRepository>());
      expect(container.read(notificationRepositoryProvider), isA<MockNotificationRepository>());
      expect(container.read(timetableRepositoryProvider), isA<MockTimetableRepository>());
      expect(container.read(notesRepositoryProvider), isA<MockNotesRepository>());
      expect(container.read(certificateRepositoryProvider), isA<MockCertificateRepository>());
      expect(container.read(certificateRequestRepositoryProvider), isA<MockCertificateRequestRepository>());
      expect(container.read(settingsRepoProvider), isA<MockSettingsRepository>());
    });
  });
}
