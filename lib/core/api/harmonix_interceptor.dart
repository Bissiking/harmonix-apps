import 'package:dio/dio.dart';

import 'api_exception.dart';

class HarmonixInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final data = response.data;

    if (data is! Map<String, dynamic>) {
      // Binary / stream responses pass through as-is (e.g. covers)
      handler.next(response);
      return;
    }

    if (data['ok'] == true) {
      handler.next(response.copyWith(data: data['data']));
      return;
    }

    // ok == false
    final code = data['error'] as String? ?? 'unknown_error';
    final feature = data['feature'] as String?;
    handler.reject(
      DioException(
        requestOptions: response.requestOptions,
        response: response,
        error: ServerException(code, feature: feature),
        type: DioExceptionType.badResponse,
      ),
      true,
    );
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // If already wrapped by onResponse, forward as-is
    if (err.error is ApiException) {
      handler.next(err);
      return;
    }

    final ApiException mapped = switch (err.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        const NetworkTimeoutException(),
      DioExceptionType.badResponse => switch (err.response?.statusCode) {
          401 => const UnauthorizedException(),
          404 => const NotFoundException(),
          _ => UnknownException('HTTP ${err.response?.statusCode}'),
        },
      DioExceptionType.connectionError =>
        NetworkException(err.message ?? 'connection error'),
      _ => UnknownException(err.message ?? 'unknown'),
    };

    handler.next(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        error: mapped,
        type: err.type,
      ),
    );
  }
}
