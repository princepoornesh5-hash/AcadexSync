import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/firebase/firebase_services.dart';
import '../../domain/models/settings_models.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../../auth/domain/models/user_model.dart';

class FirebaseSettingsRepository implements SettingsRepository {
  final FirestoreService _firestoreService;
  final UserModel? _currentUser;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String _keySettings = 'acadex_local_app_settings';

  FirebaseSettingsRepository(this._firestoreService, this._currentUser);

  String? get _userId => _currentUser?.id;

  @override
  Future<AppSettings> getAppSettings() async {
    // 1. First check local storage for instant theme retrieval
    try {
      final jsonStr = await _storage.read(key: _keySettings);
      if (jsonStr != null) {
        return AppSettings.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
      }
    } catch (_) {}

    // 2. If logged in, fetch from Firestore
    if (_userId != null) {
      try {
        final doc = await _firestoreService.getDocument('userSettings', _userId!);
        if (doc != null && doc.containsKey('appSettings')) {
          final settings = AppSettings.fromJson(doc['appSettings'] as Map<String, dynamic>);
          await _storage.write(key: _keySettings, value: jsonEncode(settings.toJson()));
          return settings;
        }
      } catch (_) {}
    }

    return AppSettings.defaults();
  }

  @override
  Future<void> updateAppSettings(AppSettings newSettings) async {
    // Save locally
    try {
      await _storage.write(key: _keySettings, value: jsonEncode(newSettings.toJson()));
    } catch (_) {}

    // Save to Firestore if authenticated
    if (_userId != null) {
      try {
        await _firestoreService.setDocument('userSettings', _userId!, {
          'appSettings': newSettings.toJson(),
        });
      } catch (_) {}
    }
  }

  @override
  Future<NotificationPreferences> getNotificationPreferences() async {
    if (_userId != null) {
      try {
        final doc = await _firestoreService.getDocument('userSettings', _userId!);
        if (doc != null && doc.containsKey('notificationPreferences')) {
          return NotificationPreferences.fromJson(doc['notificationPreferences'] as Map<String, dynamic>);
        }
      } catch (_) {}
    }
    return NotificationPreferences.defaults();
  }

  @override
  Future<void> updateNotificationPreferences(NotificationPreferences newPrefs) async {
    if (_userId != null) {
      try {
        await _firestoreService.setDocument('userSettings', _userId!, {
          'notificationPreferences': newPrefs.toJson(),
        });
      } catch (_) {}
    }
  }
}
