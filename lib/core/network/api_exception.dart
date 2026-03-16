enum ApiErrorType {
  unauthorized,
  network,
  server,
  unknown,
}

class ApiException implements Exception {
  const ApiException({
    required this.type,
    required this.message,
    this.statusCode,
  });

  final ApiErrorType type;
  final String message;
  final int? statusCode;

  factory ApiException.fromStatusCode(int statusCode, {String? message}) {
    if (statusCode == 401) {
      return ApiException(
        type: ApiErrorType.unauthorized,
        message: message ?? 'Unauthorized request.',
        statusCode: statusCode,
      );
    }

    if (statusCode >= 500) {
      return ApiException(
        type: ApiErrorType.server,
        message: message ?? 'Server error.',
        statusCode: statusCode,
      );
    }

    return ApiException(
      type: ApiErrorType.unknown,
      message: message ?? 'Unknown request error.',
      statusCode: statusCode,
    );
  }

  @override
  String toString() => 'ApiException(statusCode: $statusCode, message: $message)';
}