import 'package:yazihanem_mobile/core/api/api_exceptions.dart';
import 'package:yazihanem_mobile/core/storage/secure_storage.dart';
import 'package:yazihanem_mobile/features/auth/data/auth_remote_source.dart';
import 'package:yazihanem_mobile/features/auth/domain/models/user_model.dart';

/// Coordinates auth remote source with secure storage.
///
/// When [useMockAuth] is true (dev mode), login bypasses the API
/// and returns a fake user — useful for UI testing without backend.
class AuthRepository {
  final AuthRemoteSource _remoteSource;
  final SecureStorageService _secureStorage;
  final bool useMockAuth;

  AuthRepository({
    required AuthRemoteSource remoteSource,
    required SecureStorageService secureStorage,
    this.useMockAuth = false,
  })  : _remoteSource = remoteSource,
        _secureStorage = secureStorage;

  /// Mock user for dev testing.
  static const _mockUser = UserModel(
    id: 'dev-mock-user-001',
    email: 'admin@yazihanem.dev',
    firstName: 'Dev',
    lastName: 'Admin',
    role: UserRole.admin,
    tenant: 'yazihanem-dev',
  );

  /// Login and persist tokens.
  Future<UserModel> login(String email, String password) async {
    if (useMockAuth) {
      // Dev mock: simulate 500ms network delay
      await Future.delayed(const Duration(milliseconds: 500));

      // Basic validation even in mock mode
      if (email.isEmpty || password.length < 8) {
        throw const UnauthorizedException(message: 'Geçersiz kimlik bilgileri');
      }

      await _secureStorage.saveAccessToken('mock-jwt-token-dev');
      await _secureStorage.saveUserId(_mockUser.id);
      return _mockUser.copyWith(email: email);
    }

    final response = await _remoteSource.login(email, password);
    await _secureStorage.saveAccessToken(response.accessToken);
    await _secureStorage.saveUserId(response.user.id);
    return response.user;
  }

  /// Logout and clear all stored credentials.
  Future<void> logout() async {
    if (!useMockAuth) {
      try {
        await _remoteSource.logout();
      } catch (_) {
        // Ignore API errors on logout — always clear local state
      }
    }
    await _secureStorage.clearAll();
  }

  /// Check if user has a stored token and verify it's still valid.
  Future<UserModel?> tryAutoLogin() async {
    final hasToken = await _secureStorage.hasToken();
    if (!hasToken) return null;

    if (useMockAuth) {
      return _mockUser;
    }

    try {
      final user = await _remoteSource.getMe();
      return user;
    } on UnauthorizedException {
      try {
        final refreshResponse = await _remoteSource.refreshToken();
        await _secureStorage.saveAccessToken(refreshResponse.accessToken);
        return await _remoteSource.getMe();
      } catch (_) {
        await _secureStorage.clearAll();
        return null;
      }
    } catch (_) {
      return null;
    }
  }

  /// Change password and force re-login.
  Future<void> changePassword(String oldPassword, String newPassword) async {
    if (!useMockAuth) {
      await _remoteSource.changePassword(oldPassword, newPassword);
    } else {
      await Future.delayed(const Duration(milliseconds: 300));
    }
    await _secureStorage.clearAll();
  }

  /// Save tenant domain to secure storage.
  Future<void> saveTenantDomain(String domain) async {
    await _secureStorage.saveTenantDomain(domain);
  }

  /// Get stored tenant domain.
  Future<String?> getTenantDomain() async {
    return _secureStorage.getTenantDomain();
  }

  /// Check if tenant domain is configured.
  Future<bool> hasTenantDomain() async {
    final domain = await _secureStorage.getTenantDomain();
    return domain != null && domain.isNotEmpty;
  }
}

