import '../../domain/models/settings_models.dart';
import '../../domain/repositories/settings_repository.dart';

class MockSettingsRepository implements SettingsRepository {
  // In-memory storage for current session
  AppSettings _appSettings = AppSettings.defaults();
  NotificationPreferences _notificationPreferences = NotificationPreferences.defaults();

  Future<void> _delay() async => await Future.delayed(const Duration(milliseconds: 300));

  @override
  Future<AppSettings> getAppSettings() async {
    await _delay();
    return _appSettings;
  }

  @override
  Future<void> updateAppSettings(AppSettings newSettings) async {
    await _delay();
    _appSettings = newSettings;
  }

  @override
  Future<NotificationPreferences> getNotificationPreferences() async {
    await _delay();
    return _notificationPreferences;
  }

  @override
  Future<void> updateNotificationPreferences(NotificationPreferences newPrefs) async {
    await _delay();
    _notificationPreferences = newPrefs;
  }
}

final mockSettingsRepo = MockSettingsRepository();
