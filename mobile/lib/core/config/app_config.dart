/// Application environment configuration.
///
/// Manages API base URL and other environment-specific settings
/// for dev, staging, and production environments.
enum AppEnvironment { dev, staging, production }

class AppConfig {
  final AppEnvironment environment;
  final String apiBaseUrl;
  final String appName;
  final Duration connectTimeout;
  final Duration receiveTimeout;

  const AppConfig._({
    required this.environment,
    required this.apiBaseUrl,
    required this.appName,
    this.connectTimeout = const Duration(seconds: 10),
    this.receiveTimeout = const Duration(seconds: 30),
  });

  /// Development configuration (localhost backend)
  static const dev = AppConfig._(
    environment: AppEnvironment.dev,
    apiBaseUrl: 'http://10.0.2.2:8080', // Android emulator -> host machine
    appName: 'Yazıhanem DEV',
    connectTimeout: Duration(seconds: 10),
    receiveTimeout: Duration(seconds: 30),
  );

  /// Staging configuration
  static const staging = AppConfig._(
    environment: AppEnvironment.staging,
    apiBaseUrl: 'https://api-staging.yazihanem.com',
    appName: 'Yazıhanem STAGING',
    connectTimeout: Duration(seconds: 10),
    receiveTimeout: Duration(seconds: 30),
  );

  /// Production configuration
  static const production = AppConfig._(
    environment: AppEnvironment.production,
    apiBaseUrl: 'https://api.yazihanem.com',
    appName: 'Yazıhanem',
    connectTimeout: Duration(seconds: 10),
    receiveTimeout: Duration(seconds: 30),
  );

  bool get isDev => environment == AppEnvironment.dev;
  bool get isProduction => environment == AppEnvironment.production;
}
