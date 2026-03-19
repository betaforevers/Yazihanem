import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage service for JWT tokens and tenant info.
///
/// Uses platform-native secure storage:
/// - iOS: Keychain
/// - Android: EncryptedSharedPreferences (Keystore)
class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
          iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
        );

  // ─────────── Keys ───────────
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _tenantDomainKey = 'tenant_domain';
  static const _tenantIdKey = 'tenant_id';
  static const _userIdKey = 'user_id';

  // ─────────── Token ───────────
  Future<void> saveAccessToken(String token) =>
      _storage.write(key: _accessTokenKey, value: token);

  Future<String?> getAccessToken() =>
      _storage.read(key: _accessTokenKey);

  Future<void> saveRefreshToken(String token) =>
      _storage.write(key: _refreshTokenKey, value: token);

  Future<String?> getRefreshToken() =>
      _storage.read(key: _refreshTokenKey);

  // ─────────── Tenant ───────────
  Future<void> saveTenantDomain(String domain) =>
      _storage.write(key: _tenantDomainKey, value: domain);

  Future<String?> getTenantDomain() =>
      _storage.read(key: _tenantDomainKey);

  Future<void> saveTenantId(String id) =>
      _storage.write(key: _tenantIdKey, value: id);

  Future<String?> getTenantId() =>
      _storage.read(key: _tenantIdKey);

  // ─────────── User ───────────
  Future<void> saveUserId(String id) =>
      _storage.write(key: _userIdKey, value: id);

  Future<String?> getUserId() =>
      _storage.read(key: _userIdKey);

  // ─────────── Clear ───────────
  Future<void> clearAll() => _storage.deleteAll();

  Future<bool> hasToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}

/// Riverpod provider for [SecureStorageService].
final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});
