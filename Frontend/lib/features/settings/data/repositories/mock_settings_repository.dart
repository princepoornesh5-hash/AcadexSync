import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/models/settings_models.dart';
import '../../domain/repositories/settings_repository.dart';

class MockSettingsRepository implements SettingsRepository {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String _keySettings = 'acadex_local_app_settings';

  AppSettings _appSettings = AppSettings.defaults();
  NotificationPreferences _notificationPreferences = NotificationPreferences.defaults();
  bool _loaded = false;

  Future<void> _loadFromStorage() async {
    if (_loaded) return;
    try {
      final jsonStr = await _storage.read(key: _keySettings);
      if (jsonStr != null) {
        _appSettings = AppSettings.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
      }
    } catch (_) {}
    _loaded = true;
  }

  @override
  Future<AppSettings> getAppSettings() async {
    await _loadFromStorage();
    return _appSettings;
  }

  @override
  Future<void> updateAppSettings(AppSettings newSettings) async {
    _appSettings = newSettings;
    try {
      await _storage.write(key: _keySettings, value: jsonEncode(newSettings.toJson()));
    } catch (_) {}
  }

  @override
  Future<NotificationPreferences> getNotificationPreferences() async {
    return _notificationPreferences;
  }

  @override
  Future<void> updateNotificationPreferences(NotificationPreferences newPrefs) async {
    _notificationPreferences = newPrefs;
  }
}

final mockSettingsRepo = MockSettingsRepository();
