import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../config/api_config.dart';
import '../core/errors/app_exception.dart';
import 'storage_service.dart';

class ApiClient {
  static Future<void> Function()? onUnauthorizedGlobal;

  final Dio _dio;
  final StorageService _storageService;
  Future<void> Function()? onUnauthorized;

  ApiClient({
    Dio? dio,
    StorageService? storageService,
    this.onUnauthorized,
  })  : _storageService = storageService ?? StorageService(),
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: ApiConfig.baseUrl,
                connectTimeout: ApiConfig.timeout,
                receiveTimeout: ApiConfig.timeout,
                sendTimeout: ApiConfig.timeout,
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ),
            ) {
    _initInterceptors();
  }

  Dio get dio => _dio;
  StorageService get storageService => _storageService;

  void _initInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Automatic JWT injection if token exists
          final token = await _storageService.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException err, handler) async {
          if (err.response?.statusCode == 401) {
            // Clear token on 401 Unauthorized
            await _storageService.deleteToken();
            await (onUnauthorized ?? onUnauthorizedGlobal)?.call();
          }
          return handler.next(err);
        },
      ),
    );

    // Pretty logger in debug mode
    if (kDebugMode) {
      _dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseBody: true,
          responseHeader: false,
          error: true,
          compact: true,
          maxWidth: 90,
        ),
      );
    }
  }

  /// Perform a GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw ApiException(e.toString());
    }
  }

  /// Perform a POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw ApiException(e.toString());
    }
  }

  /// Perform a PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw ApiException(e.toString());
    }
  }

  /// Perform a DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw ApiException(e.toString());
    }
  }

  /// Maps DioExceptions to strongly-typed AppExceptions
  AppException _handleDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return const NetworkException(
          'Unable to connect to the server. Please check your internet connection.',
        );

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final data = e.response?.data;

        if (statusCode == 401) {
          final message = _parseDetail(data) ?? 'Session expired or invalid. Please log in again.';
          return AuthException(message);
        }

        if (statusCode == 422) {
          final parsedMessage = _parseValidationErrors(data);
          return ApiException(
            parsedMessage ?? 'Validation failed. Please verify your input.',
            statusCode: 422,
            details: data,
          );
        }

        final message = _parseDetail(data) ??
            e.response?.statusMessage ??
            'An unexpected error occurred ($statusCode).';
        return ApiException(message, statusCode: statusCode, details: data);

      case DioExceptionType.cancel:
        return const ApiException('Request was cancelled.');

      case DioExceptionType.badCertificate:
        return const NetworkException('Security certificate verification failed.');

      case DioExceptionType.unknown:
      default:
        final errStr = '${e.message ?? ''} ${e.error ?? ''}'.trim();
        if (errStr.toLowerCase().contains('socket') ||
            errStr.toLowerCase().contains('connection refused') ||
            errStr.toLowerCase().contains('network is unreachable')) {
          return NetworkException(
            'Unable to connect to the server. Please check your network connection.',
            e.error,
          );
        }
        return ApiException(
          errStr.isNotEmpty ? errStr : 'An unexpected error occurred.',
          details: e.error,
        );
    }
  }

  /// Extracts the `detail` message from FastAPI JSON response
  String? _parseDetail(dynamic data) {
    if (data is Map<String, dynamic>) {
      final detail = data['detail'];
      if (detail is String) return detail;
      if (detail is List) return _formatErrorList(detail);
    }
    return null;
  }

  /// Parses 422 Unprocessable Entity detail array
  String? _parseValidationErrors(dynamic data) {
    if (data is Map<String, dynamic>) {
      final detail = data['detail'];
      if (detail is List) {
        return _formatErrorList(detail);
      } else if (detail is String) {
        return detail;
      }
    }
    return null;
  }

  String _formatErrorList(List<dynamic> list) {
    final messages = <String>[];
    for (final item in list) {
      if (item is Map<String, dynamic>) {
        final loc = item['loc'] as List<dynamic>?;
        final msg = item['msg'] as String? ?? 'Invalid value';
        final field = loc != null && loc.isNotEmpty ? loc.last.toString() : null;
        if (field != null && field != 'body') {
          messages.add('$field: $msg');
        } else {
          messages.add(msg);
        }
      } else {
        messages.add(item.toString());
      }
    }
    return messages.join('\n');
  }
}
