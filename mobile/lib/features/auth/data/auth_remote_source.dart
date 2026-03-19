import 'package:yazihanem_mobile/core/api/api_client.dart';
import 'package:yazihanem_mobile/core/api/api_endpoints.dart';
import 'package:yazihanem_mobile/features/auth/domain/models/user_model.dart';

/// Remote data source for authentication API calls.
///
/// Maps to backend endpoints:
/// - POST /api/v1/auth/login
/// - POST /api/v1/auth/logout
/// - POST /api/v1/auth/refresh
/// - GET  /api/v1/auth/me
/// - POST /api/v1/auth/change-password
class AuthRemoteSource {
  final ApiClient _apiClient;

  AuthRemoteSource(this._apiClient);

  /// Login with email and password.
  /// Returns `{access_token, expires_in, token_type, user: {...}}`.
  Future<LoginResponseData> login(String email, String password) async {
    final response = await _apiClient.dio.post(
      ApiEndpoints.authLogin,
      data: {'email': email, 'password': password},
    );

    return LoginResponseData.fromJson(response.data as Map<String, dynamic>);
  }

  /// Logout — invalidates server session.
  Future<void> logout() async {
    await _apiClient.dio.post(ApiEndpoints.authLogout);
  }

  /// Refresh access token using current token in header.
  /// Backend returns `{access_token, expires_in, token_type}`.
  Future<RefreshResponseData> refreshToken() async {
    final response = await _apiClient.dio.post(ApiEndpoints.authRefresh);
    return RefreshResponseData.fromJson(response.data as Map<String, dynamic>);
  }

  /// Get current user info.
  /// Returns `{user: {id, email, role, tenant}}`.
  Future<UserModel> getMe() async {
    final response = await _apiClient.dio.get(ApiEndpoints.authMe);
    final data = response.data as Map<String, dynamic>;
    return UserModel.fromJson(data['user'] as Map<String, dynamic>);
  }

  /// Change password.
  Future<void> changePassword(String oldPassword, String newPassword) async {
    await _apiClient.dio.post(
      ApiEndpoints.authChangePassword,
      data: {
        'old_password': oldPassword,
        'new_password': newPassword,
      },
    );
  }
}

/// Parsed login response from backend.
class LoginResponseData {
  final String accessToken;
  final int expiresIn;
  final String tokenType;
  final UserModel user;

  const LoginResponseData({
    required this.accessToken,
    required this.expiresIn,
    required this.tokenType,
    required this.user,
  });

  factory LoginResponseData.fromJson(Map<String, dynamic> json) {
    return LoginResponseData(
      accessToken: json['access_token'] as String,
      expiresIn: json['expires_in'] as int,
      tokenType: json['token_type'] as String? ?? 'Bearer',
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

/// Parsed refresh response from backend.
class RefreshResponseData {
  final String accessToken;
  final int expiresIn;
  final String tokenType;

  const RefreshResponseData({
    required this.accessToken,
    required this.expiresIn,
    required this.tokenType,
  });

  factory RefreshResponseData.fromJson(Map<String, dynamic> json) {
    return RefreshResponseData(
      accessToken: json['access_token'] as String,
      expiresIn: json['expires_in'] as int,
      tokenType: json['token_type'] as String? ?? 'Bearer',
    );
  }
}
