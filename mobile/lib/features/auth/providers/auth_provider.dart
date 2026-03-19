import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yazihanem_mobile/core/api/api_client.dart';
import 'package:yazihanem_mobile/core/config/app_config.dart';
import 'package:yazihanem_mobile/core/storage/secure_storage.dart';
import 'package:yazihanem_mobile/features/auth/data/auth_remote_source.dart';
import 'package:yazihanem_mobile/features/auth/data/auth_repository.dart';
import 'package:yazihanem_mobile/features/auth/domain/auth_state.dart';

/// Provider for [AuthRemoteSource].
final authRemoteSourceProvider = Provider<AuthRemoteSource>((ref) {
  return AuthRemoteSource(ref.watch(apiClientProvider));
});

/// Provider for [AuthRepository].
/// In dev mode, enables mock auth for UI testing without backend.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  return AuthRepository(
    remoteSource: ref.watch(authRemoteSourceProvider),
    secureStorage: ref.watch(secureStorageProvider),
    useMockAuth: config.environment == AppEnvironment.dev,
  );
});

/// Global auth state provider.
///
/// Manages the authentication lifecycle:
/// - `checkAuth()` on app start → auto-login if token exists
/// - `login()` → authenticate user
/// - `logout()` → clear session
/// - `changePassword()` → change + force re-login
final authStateProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});

/// Auth state notifier — drives the entire auth flow.
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AuthInitial());

  /// Check stored credentials on app startup.
  Future<void> checkAuth() async {
    state = const AuthLoading();

    final user = await _repository.tryAutoLogin();
    if (user != null) {
      state = AuthAuthenticated(user);
    } else {
      state = const AuthUnauthenticated();
    }
  }

  /// Login with email and password.
  Future<void> login(String email, String password) async {
    state = const AuthLoading();

    try {
      final user = await _repository.login(email, password);
      state = AuthAuthenticated(user);
    } catch (e) {
      state = AuthError(_errorMessage(e));
    }
  }

  /// Logout and clear session.
  Future<void> logout() async {
    await _repository.logout();
    state = const AuthUnauthenticated();
  }

  /// Change password and force re-login.
  Future<void> changePassword(
    String oldPassword,
    String newPassword,
  ) async {
    state = const AuthLoading();

    try {
      await _repository.changePassword(oldPassword, newPassword);
      state = const AuthUnauthenticated(reason: 'Şifre değiştirildi. Lütfen tekrar giriş yapın.');
    } catch (e) {
      state = AuthError(_errorMessage(e));
    }
  }

  /// Save tenant domain for API requests.
  Future<void> setTenantDomain(String domain) async {
    await _repository.saveTenantDomain(domain);
  }

  /// Check if tenant domain is configured.
  Future<bool> hasTenantDomain() async {
    return _repository.hasTenantDomain();
  }

  String _errorMessage(dynamic error) {
    if (error is Exception) {
      return error.toString().replaceFirst('Exception: ', '');
    }
    return 'Bilinmeyen bir hata oluştu';
  }
}
