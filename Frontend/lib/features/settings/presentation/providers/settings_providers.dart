import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/firebase/firebase_initializer.dart';
import '../../../../core/firebase/firebase_services.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../domain/models/settings_models.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../data/repositories/mock_settings_repository.dart';
import '../../data/repositories/firebase_settings_repository.dart';

final settingsRepoProvider = Provider<SettingsRepository>((ref) {
  if (FirebaseInitializer.shouldUseMock) {
    return mockSettingsRepo;
  }
  final firestoreService = ref.watch(firestoreServiceProvider);
  final authState = ref.watch(authProvider);
  return FirebaseSettingsRepository(
    firestoreService, 
    authState is AuthAuthenticated ? authState.user : null
  );
});

class AppSettingsNotifier extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() async {
    return ref.watch(settingsRepoProvider).getAppSettings();
  }

  Future<void> updateSettings(AppSettings newSettings) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(settingsRepoProvider).updateAppSettings(newSettings);
      return ref.read(settingsRepoProvider).getAppSettings();
    });
  }
}

final appSettingsProvider = AsyncNotifierProvider<AppSettingsNotifier, AppSettings>(() {
  return AppSettingsNotifier();
});

class NotificationPreferencesNotifier extends AsyncNotifier<NotificationPreferences> {
  @override
  Future<NotificationPreferences> build() async {
    return ref.watch(settingsRepoProvider).getNotificationPreferences();
  }

  Future<void> updatePreferences(NotificationPreferences newPrefs) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(settingsRepoProvider).updateNotificationPreferences(newPrefs);
      return ref.read(settingsRepoProvider).getNotificationPreferences();
    });
  }
}

final notificationPreferencesProvider = AsyncNotifierProvider<NotificationPreferencesNotifier, NotificationPreferences>(() {
  return NotificationPreferencesNotifier();
});
