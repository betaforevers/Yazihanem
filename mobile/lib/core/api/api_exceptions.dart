/// Custom API exceptions for structured error handling.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  const ApiException({
    required this.message,
    this.statusCode,
    this.data,
  });

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException({super.message = 'Oturum süresi doldu'})
      : super(statusCode: 401);
}

class ForbiddenException extends ApiException {
  const ForbiddenException({super.message = 'Bu işlem için yetkiniz yok'})
      : super(statusCode: 403);
}

class NotFoundException extends ApiException {
  const NotFoundException({super.message = 'Kayıt bulunamadı'})
      : super(statusCode: 404);
}

class ConflictException extends ApiException {
  const ConflictException({super.message = 'Çakışma: kayıt zaten mevcut'})
      : super(statusCode: 409);
}

class RateLimitException extends ApiException {
  final Duration? retryAfter;
  const RateLimitException({
    super.message = 'Çok fazla istek gönderildi',
    this.retryAfter,
  }) : super(statusCode: 429);
}

class ServerException extends ApiException {
  const ServerException({super.message = 'Sunucu hatası oluştu'})
      : super(statusCode: 500);
}

class NetworkException extends ApiException {
  const NetworkException({super.message = 'İnternet bağlantısı yok'})
      : super(statusCode: null);
}
