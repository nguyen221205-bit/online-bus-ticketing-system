import 'api_response.dart';

/// Base exception for API errors returned by backend
class ApiException implements Exception {
  final ApiError error;

  const ApiException(this.error);

  int get statusCode => error.statusCode;
  String get errorCode => error.errorCode;
  String get message => error.message;
  List<ApiValidationErrorDetail> get details => error.details;

  @override
  String toString() => 'ApiException($statusCode, $errorCode): $message';
}

/// Thrown when device cannot connect to server (offline, connection refused, DNS error, timeout)
class NetworkException implements Exception {
  final String message;
  final dynamic originalError;

  const NetworkException({
    this.message = 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng.',
    this.originalError,
  });

  @override
  String toString() => 'NetworkException: $message ($originalError)';
}

/// Thrown when token is invalid or expired (401)
class UnauthorizedException extends ApiException {
  UnauthorizedException({
    String message = 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
    String errorCode = 'UNAUTHORIZED',
  }) : super(ApiError(
          statusCode: 401,
          errorCode: errorCode,
          message: message,
        ));
}
