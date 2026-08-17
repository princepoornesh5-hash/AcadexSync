import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../domain/models/user_model.dart';

class SessionManager {
  final FlutterSecureStorage _storage;
  
  static const String _keyToken = 'auth_token';
  static const String _keyUser = 'auth_user';

  SessionManager(this._storage);

  Future<void> saveSession({required String token, required UserModel user}) async {
    await _storage.write(key: _keyToken, value: token);
    await _storage.write(key: _keyUser, value: jsonEncode(user.toJson()));
  }

  Future<void> clearSession() async {
    await _storage.delete(key: _keyToken);
    await _storage.delete(key: _keyUser);
  }

  Future<bool> hasValidSession() async {
    final token = await _storage.read(key: _keyToken);
    return token != null && token.isNotEmpty;
  }

  Future<UserModel?> getUser() async {
    final userJson = await _storage.read(key: _keyUser);
    if (userJson != null) {
      try {
        return UserModel.fromJson(jsonDecode(userJson));
      } catch (e) {
        return null;
      }
    }
    return null;
  }
}
