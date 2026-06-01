import 'package:dio/dio.dart';

class FormErrorMapper {
  /// Analyzes an error (usually a DioException) and extracts a user-friendly message.
  static String mapError(Object error) {
    if (error is DioException) {
      if (error.response?.data != null) {
        final data = error.response!.data;
        if (data is Map<String, dynamic>) {
          if (data['message'] != null) {
            return data['message'].toString();
          }
          if (data['error'] != null) {
            return data['error'].toString();
          }
        }
      }
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Connection timed out. Please check your network and try again.';
        case DioExceptionType.badResponse:
          if (error.response?.statusCode == 409) {
            return 'A conflict occurred. Someone else may have updated this data. Please refresh and try again.';
          }
          return 'Server returned an error (${error.response?.statusCode}). Please try again.';
        case DioExceptionType.connectionError:
          return 'No internet connection. Please check your network.';
        default:
          return 'An unexpected network error occurred.';
      }
    }
    return error.toString();
  }
}
