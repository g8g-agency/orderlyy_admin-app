class ApiException implements Exception {
  final ApiErrorCode code;
  final String message;
  final Map<String, dynamic>? details;

  ApiException({required this.code, required this.message, this.details});

  @override
  String toString() =>
      'ApiException(code: $code, message: $message, details: $details)';
}

enum ApiErrorCode {
  badRequest,
  unauthorized,
  forbidden,
  notFound,
  conflict, // Used for OCC
  validationError,
  serverError,
  networkError,
  timeout,
  unknown,
}

class ApiFailure {
  final String message;
  final ApiErrorCode code;

  ApiFailure(this.message, [this.code = ApiErrorCode.unknown]);

  factory ApiFailure.fromException(Object e) {
    if (e is ApiException) {
      return ApiFailure(e.message, e.code);
    }
    return ApiFailure(e.toString());
  }

  @override
  String toString() => message;
}

// Result Wrapper
sealed class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  final T value;
  const Success(this.value);
}

class Failure<T> extends Result<T> {
  final ApiFailure error;
  const Failure(this.error);
}
