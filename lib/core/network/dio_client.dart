import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import 'package:talker_flutter/talker_flutter.dart';
import 'package:talker_dio_logger/talker_dio_logger.dart';
import 'package:uuid/uuid.dart';
import '../config/app_config.dart';
import 'api_exception.dart';
import '../providers/repository_providers.dart';
import 'dio_retry_interceptor.dart';

class DioClient {
  final Dio _dio;
  final Talker _talker;
  final String deviceFingerprint;
  final void Function(String message)? onUnauthorized;
  final _uuid = const Uuid();
  bool _isRefreshing = false;
  final _retryQueue = <Map<String, dynamic>>[];

  DioClient({
    required Talker talker,
    required this.deviceFingerprint,
    this.onUnauthorized,
  })  : _talker = talker,
        _dio = Dio(
          BaseOptions(
            baseUrl: AppConfig.instance.apiBaseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
            sendTimeout: const Duration(seconds: 15),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        ) {
    
    // Auth & Trace Interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // 1. Inject Trace ID
          options.headers['x-request-id'] = _uuid.v4();
          
          // 2. Inject Device Fingerprint
          options.headers['X-Device-Fingerprint'] = deviceFingerprint;
          
          // 3. Inject Idempotency-Key for unsafe mutations
          if (['POST', 'PUT', 'PATCH', 'DELETE'].contains(options.method.toUpperCase())) {
            // Only inject if not already provided
            options.headers['Idempotency-Key'] ??= _uuid.v4();
          }

          // 4. Inject Auth Token
          try {
            if (kUseMockRepositories) {
              options.headers['Authorization'] = 'Bearer mock-jwt-token';
            } else {
              final session = Supabase.instance.client.auth.currentSession;
              if (session != null) {
                options.headers['Authorization'] = 'Bearer ${session.accessToken}';
              }
            }
          } catch (_) {
            options.headers['Authorization'] = 'Bearer mock-jwt-token';
          }
          
          return handler.next(options);
        },
        onError: (DioException err, handler) async {
          if (err.response?.statusCode == 401) {
             if (kUseMockRepositories) {
                return handler.next(err);
             }
             return _handleTokenRefresh(err, handler);
          }
          return handler.next(err);
        },
      ),
    );

    // Add exponential retry interceptor (Ensure we don't retry unsafe mutations without idempotency keys)
    _dio.interceptors.add(DioRetryInterceptor(dio: _dio, talker: _talker));

    // Add Talker structured logging interceptor if enabled
    if (AppConfig.instance.enableLogging) {
      _dio.interceptors.add(
        TalkerDioLogger(
          talker: _talker,
          settings: const TalkerDioLoggerSettings(
            printRequestHeaders: true,
            printResponseHeaders: false,
            printResponseMessage: true,
          ),
        ),
      );
    }
  }

  Dio get dio => _dio;

  Future<void> _handleTokenRefresh(DioException err, ErrorInterceptorHandler handler) async {
    if (_isRefreshing) {
      // Queue the request
      _retryQueue.add({'err': err, 'handler': handler});
      return;
    }

    _isRefreshing = true;
    try {
      final response = await Supabase.instance.client.auth.refreshSession();
      final newSession = response.session;
      
      if (newSession != null) {
        final newToken = newSession.accessToken;
        
        // Retry the original request
        final opts = err.requestOptions;
        opts.headers['Authorization'] = 'Bearer $newToken';
        final retryResponse = await _dio.fetch(opts);
        handler.resolve(retryResponse);

        // Retry queued requests
        for (var queued in _retryQueue) {
          final queuedOpts = (queued['err'] as DioException).requestOptions;
          queuedOpts.headers['Authorization'] = 'Bearer $newToken';
          final queuedRes = await _dio.fetch(queuedOpts);
          (queued['handler'] as ErrorInterceptorHandler).resolve(queuedRes);
        }
      } else {
        throw Exception('Refresh failed');
      }
    } catch (e) {
      _retryQueue.clear();
      onUnauthorized?.call('Session expired. Please log in again.');
      handler.next(err);
    } finally {
      _isRefreshing = false;
      _retryQueue.clear();
    }
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters, Options? options, CancelToken? cancelToken}) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters, options: options, cancelToken: cancelToken);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options, CancelToken? cancelToken}) async {
    try {
      return await _dio.post(path, data: data, queryParameters: queryParameters, options: options, cancelToken: cancelToken);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response> put(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options, CancelToken? cancelToken}) async {
    try {
      return await _dio.put(path, data: data, queryParameters: queryParameters, options: options, cancelToken: cancelToken);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response> patch(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options, CancelToken? cancelToken}) async {
    try {
      return await _dio.patch(path, data: data, queryParameters: queryParameters, options: options, cancelToken: cancelToken);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response> delete(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options, CancelToken? cancelToken}) async {
    try {
      return await _dio.delete(path, data: data, queryParameters: queryParameters, options: options, cancelToken: cancelToken);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  ApiException _handleDioError(DioException error) {
    final response = error.response;
    final payload = response?.data;
    
    // Try to parse structured backend error
    String message = error.message ?? 'Unknown network error';
    String codeStr = 'UNKNOWN';
    Map<String, dynamic>? details;

    if (payload is Map<String, dynamic>) {
      if (payload['error'] != null && payload['error'] is Map) {
        message = payload['error']['message'] ?? message;
        codeStr = payload['error']['code'] ?? codeStr;
        details = payload['error']['details'];
      } else {
        message = payload['message'] ?? message;
      }
    }

    final statusCode = response?.statusCode;

    ApiErrorCode code = ApiErrorCode.unknown;
    if (statusCode == 400) code = ApiErrorCode.badRequest;
    if (statusCode == 401) code = ApiErrorCode.unauthorized;
    if (statusCode == 403) code = ApiErrorCode.forbidden;
    if (statusCode == 404) code = ApiErrorCode.notFound;
    if (statusCode == 409) code = ApiErrorCode.conflict;
    if (statusCode == 422) code = ApiErrorCode.validationError;
    if (statusCode != null && statusCode >= 500) code = ApiErrorCode.serverError;

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.connectionError) {
      code = ApiErrorCode.networkError;
      message = 'Network connection error: $message';
    }

    return ApiException(
      code: code,
      message: message,
      details: details,
    );
  }
}
