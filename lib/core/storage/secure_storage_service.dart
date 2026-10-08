import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService(const FlutterSecureStorage());
});

class SecureStorageService {
  final FlutterSecureStorage _storage;

  static const String _tokenKey = 'detailed_to_do_auth_token';
  static const String _userEmailKey = 'detailed_to_do_user_email';

  /// Preferencias visuales (tema). No se borran al cerrar sesión.
  static const String _themeKey = 'detailed_to_do_theme_preference';

  SecureStorageService(this._storage);

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  Future<void> saveUserEmail(String email) async {
    await _storage.write(key: _userEmailKey, value: email);
  }

  Future<String?> getUserEmail() async {
    return await _storage.read(key: _userEmailKey);
  }

  Future<void> saveThemeId(String themeId) async {
    await _storage.write(key: _themeKey, value: themeId);
  }

  Future<String?> getThemeId() async {
    return await _storage.read(key: _themeKey);
  }

  /// Borra los datos de sesión (token y email).
  ///
  /// Las preferencias de la interfaz, como el tema elegido, se conservan.
  Future<void> clearAll() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userEmailKey);
  }
}
