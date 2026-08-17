import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:campus_management/core/firebase/firebase_services.dart';
import 'package:campus_management/features/auth/presentation/screens/login_screen.dart';
import 'package:campus_management/features/auth/repositories/auth_repository.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_management/features/settings/presentation/providers/settings_providers.dart';
import 'package:campus_management/features/settings/domain/models/settings_models.dart';
import 'package:campus_management/features/settings/data/repositories/mock_settings_repository.dart';

class FakeSettingsRepo extends MockSettingsRepository {
  @override
  Future<AppSettings> getAppSettings() async => AppSettings.defaults();
  
  @override
  Future<NotificationPreferences> getNotificationPreferences() async => NotificationPreferences.defaults();
}

class FakeFirebaseAuthService implements FirebaseAuthService {
  final _authStateController = StreamController<firebase.User?>();

  @override
  Stream<firebase.User?> get authStateChanges => _authStateController.stream;

  @override
  firebase.User? get currentUser => null;

  @override
  Future<firebase.UserCredential> signIn(String email, String password) async {
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> updatePassword(String newPassword) async {}
}

void main() {
  testWidgets('App loads initial login screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsRepoProvider.overrideWithValue(FakeSettingsRepo()),
          firebaseAuthServiceProvider.overrideWithValue(FakeFirebaseAuthService()),
          authRepositoryProvider.overrideWithValue(MockAuthRepository()),
        ],
        child: const MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Acadex'), findsOneWidget);
  });
}
