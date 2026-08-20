import 'package:dio/dio.dart';

import 'package:harmonix_apps/core/api/api_exception.dart';

class HarmonixInterceptor extends Interceptor {
  HarmonixInterceptor({this.onConnectionFailure});

  /// Appelé quand une requête échoue pour une raison de connexion
  /// (réseau, timeout, 401, erreur serveur) afin de rediriger vers le login.
  final void Function(ApiException mapped)? onConnectionFailure;

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final path = response.requestOptions.path;
    if (!path.startsWith('/api/harmonix/apps')) {
      handler.next(response);
      return;
    }

    final data = response.data;

    if (data is! Map<String, dynamic>) {
      // Binary / stream responses pass through as-is (e.g. covers)
      handler.next(response);
      return;
    }

    if (data['ok'] == true) {
      if (data.containsKey('data')) {
        response.data = data['data'];
      }
      handler.next(response);
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

    final suppressLoginRedirect =
        err.requestOptions.extra['suppress_login_redirect'] == true;
    if (!suppressLoginRedirect &&
        (mapped is NetworkTimeoutException ||
            mapped is NetworkException ||
            mapped is UnauthorizedException)) {
      onConnectionFailure?.call(mapped);
    }

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
