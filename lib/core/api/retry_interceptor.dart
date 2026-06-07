import 'dart:async';

import 'package:dio/dio.dart';

class RetryInterceptor extends Interceptor {
  RetryInterceptor(
    this._dio, {
    this.maxRetries = 2,
    this.baseDelay = const Duration(milliseconds: 250),
  });

  final Dio _dio;
  final int maxRetries;
  final Duration baseDelay;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final method = options.method.toUpperCase();
    final retries = (options.extra['retry_count'] as int?) ?? 0;

    final isRetryableMethod =
        method == 'GET' || method == 'HEAD' || method == 'OPTIONS';
    final status = err.response?.statusCode ?? 0;
    final isRetryableStatus = status == 502 || status == 503 || status == 504;
    final isRetryableType =
        err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout;

    if (!isRetryableMethod ||
        retries >= maxRetries ||
        (!isRetryableStatus && !isRetryableType)) {
      handler.next(err);
      return;
    }

    options.extra['retry_count'] = retries + 1;
    await Future<void>.delayed(baseDelay * (retries + 1));

    try {
      final response = await _dio.fetch<dynamic>(options);
      handler.resolve(response);
    } catch (_) {
      handler.next(err);
    }
  }
}
