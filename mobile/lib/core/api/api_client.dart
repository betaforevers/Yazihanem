import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yazihanem_mobile/core/config/app_config.dart';
import 'package:yazihanem_mobile/core/api/api_exceptions.dart';
import 'package:yazihanem_mobile/core/storage/secure_storage.dart';

/// Central Dio HTTP client with auth, tenant, and error interceptors.
///
/// All API calls flow through this client, which automatically:
/// - Adds JWT token to every request
/// - Adds tenant domain header
/// - Handles 401 with token refresh
/// - Maps HTTP errors to typed exceptions
class ApiClient {
  late final Dio dio;
  final AppConfig config;
  final SecureStorageService secureStorage;

  ApiClient({
    required this.config,
    required this.secureStorage,
  }) {
    dio = Dio(
      BaseOptions(
        baseUrl: config.apiBaseUrl,
        connectTimeout: config.connectTimeout,
        receiveTimeout: config.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.addAll([
      _AuthInterceptor(secureStorage),
      _ErrorInterceptor(),
      if (config.isDev) LogInterceptor(requestBody: true, responseBody: true),
    ]);
  }
}

/// Injects JWT Authorization header and tenant domain into every request.
class _AuthInterceptor extends Interceptor {
  final SecureStorageService _storage;

  _AuthInterceptor(this._storage);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Add JWT token
    final token = await _storage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    // Add tenant domain
    final tenantDomain = await _storage.getTenantDomain();
    if (tenantDomain != null) {
      options.headers['X-Tenant-Domain'] = tenantDomain;
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Auto-refresh on 401
    if (err.response?.statusCode == 401) {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken != null) {
        try {
          // Attempt token refresh
          final refreshDio = Dio(BaseOptions(
            baseUrl: err.requestOptions.baseUrl,
          ));
          final response = await refreshDio.post(
            '/api/v1/auth/refresh',
            data: {'refresh_token': refreshToken},
          );

          if (response.statusCode == 200) {
            final responseData = response.data as Map<String, dynamic>;
            final newToken = responseData['token'] as String;
            await _storage.saveAccessToken(newToken);

            // Retry original request with new token
            err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
            final retryResponse = await refreshDio.fetch(err.requestOptions);
            return handler.resolve(retryResponse);
          }
        } catch (_) {
          // Refresh failed — force logout
          await _storage.clearAll();
        }
      }
    }

    handler.next(err);
  }
}

/// Maps Dio errors to typed [ApiException] subclasses.
class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final statusCode = err.response?.statusCode;

    switch (err.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        throw const NetworkException();
      default:
        break;
    }

    switch (statusCode) {
      case 401:
        throw const UnauthorizedException();
      case 403:
        throw const ForbiddenException();
      case 404:
        throw const NotFoundException();
      case 409:
        throw const ConflictException();
      case 429:
        throw const RateLimitException();
      case 500:
      case 502:
      case 503:
        throw const ServerException();
      default:
        final responseData = err.response?.data is Map
            ? err.response!.data as Map<String, dynamic>
            : null;
        final msg = responseData?['error'] as String? ??
            err.message ??
            'Bilinmeyen hata';
        throw ApiException(message: msg, statusCode: statusCode);
    }
  }
}

/// Riverpod provider for [ApiClient].
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    config: ref.watch(appConfigProvider),
    secureStorage: ref.watch(secureStorageProvider),
  );
});

/// Riverpod provider for [AppConfig]. Override in main.dart per environment.
final appConfigProvider = Provider<AppConfig>((ref) {
  return AppConfig.dev; // Default to dev, override in ProviderScope
});
