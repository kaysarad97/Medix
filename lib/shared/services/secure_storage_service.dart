import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Защищённое хранилище токенов.
///
/// Медицинские данные и токены доступа не должны попадать в
/// SharedPreferences — на Android используется EncryptedSharedPreferences,
/// на iOS Keychain.
abstract interface class AuthSessionStorage {
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  });

  Future<void> saveUserRole(String role);
}

class SecureStorageService implements AuthSessionStorage {
  const SecureStorageService(this._storage);

  final FlutterSecureStorage _storage;

  static const _accessTokenKey = 'medix.access_token';
  static const _refreshTokenKey = 'medix.refresh_token';
  static const _userRoleKey = 'medix.user_role';

  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);

  Future<String?> readRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<String?> readUserRole() => _storage.read(key: _userRoleKey);

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  @override
  Future<void> saveUserRole(String role) =>
      _storage.write(key: _userRoleKey, value: role);

  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userRoleKey);
  }
}

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return const SecureStorageService(
    FlutterSecureStorage(
      // На Android с v10 шифрование включено по умолчанию (собственные
      // шифры вместо устаревшей Jetpack Security) — отдельный флаг не нужен.
      iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    ),
  );
});
