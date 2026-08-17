import '../../../../core/firebase/firebase_services.dart';
import '../../domain/models/settings_models.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../../auth/domain/models/user_model.dart';

class FirebaseSettingsRepository implements SettingsRepository {
  final FirestoreService _firestoreService;
  final UserModel? _currentUser;

  FirebaseSettingsRepository(this._firestoreService, this._currentUser);

  String get _userId {
    if (_currentUser == null) throw Exception('User must be logged in to access settings.');
    return _currentUser.id;
  }

  @override
  Future<AppSettings> getAppSettings() async {
    final doc = await _firestoreService.getDocument('userSettings', _userId);
    if (doc == null || !doc.containsKey('appSettings')) {
      return AppSettings.defaults();
    }
    return AppSettings.fromJson(doc['appSettings'] as Map<String, dynamic>);
  }

  @override
  Future<void> updateAppSettings(AppSettings newSettings) async {
    await _firestoreService.setDocument('userSettings', _userId, {
      'appSettings': newSettings.toJson(),
    });
  }

  @override
  Future<NotificationPreferences> getNotificationPreferences() async {
    final doc = await _firestoreService.getDocument('userSettings', _userId);
    if (doc == null || !doc.containsKey('notificationPreferences')) {
      return NotificationPreferences.defaults();
    }
    return NotificationPreferences.fromJson(doc['notificationPreferences'] as Map<String, dynamic>);
  }

  @override
  Future<void> updateNotificationPreferences(NotificationPreferences newPrefs) async {
    await _firestoreService.setDocument('userSettings', _userId, {
      'notificationPreferences': newPrefs.toJson(),
    });
  }
}
