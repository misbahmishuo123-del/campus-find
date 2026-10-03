import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists ONLY the JWT (and the signed-in user id) in the platform's secure
/// storage (Keychain on iOS, encrypted prefs on Android). No secrets or
/// passwords are ever written to disk.
class AuthService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _tokenKey = 'cf_token';

  Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<void> clear() => _storage.delete(key: _tokenKey);
}
