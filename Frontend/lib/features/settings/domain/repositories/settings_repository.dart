import '../models/settings_models.dart';

abstract class SettingsRepository {
  Future<AppSettings> getAppSettings();
  Future<void> updateAppSettings(AppSettings newSettings);
  
  Future<NotificationPreferences> getNotificationPreferences();
  Future<void> updateNotificationPreferences(NotificationPreferences newPrefs);
}
