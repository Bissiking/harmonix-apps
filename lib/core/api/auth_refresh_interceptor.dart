import 'package:dio/dio.dart';

import 'package:harmonix_apps/core/session/auth_refresh_service.dart';
import 'package:harmonix_apps/core/settings/settings_repository.dart';

class AuthRefreshInterceptor extends Interceptor {
  AuthRefreshInterceptor({
    required Dio dio,
    required SettingsRepository settings,
    required AuthRefreshService refreshService,
    required void Function() onSessionExpired,
  })  : _dio = dio,
        _settings = settings,
        _refreshService = refreshService,
        _onSessionExpired = onSessionExpired;

  final Dio _dio;
  final SettingsRepository _settings;
  final AuthRefreshService _refreshService;
  final void Function() _onSessionExpired;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_isAuthRoute(options)) {
      await _refreshService.refresh();
      _setAuthorization(options);
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401 ||
        err.requestOptions.extra['auth_retry'] == true ||
        _isAuthRoute(err.requestOptions)) {
      handler.next(err);
      return;
    }

    final result = await _refreshService.refresh(force: true);
    if (result == AuthRefreshResult.refreshed ||
        result == AuthRefreshResult.stillValid) {
      final options = err.requestOptions;
      options.extra['auth_retry'] = true;
      _setAuthorization(options);
      try {
        handler.resolve(await _dio.fetch<dynamic>(options));
      } on DioException catch (retryError) {
        handler.next(retryError);
      }
      return;
    }

    if (result == AuthRefreshResult.invalid) {
      await _refreshService.expireSession();
      _onSessionExpired();
    } else {
      err.requestOptions.extra['suppress_login_redirect'] = true;
    }
    handler.next(err);
  }

  void _setAuthorization(RequestOptions options) {
    final token = _settings.authToken;
    if (token == null || token.isEmpty) {
      options.headers.remove('Authorization');
    } else {
      options.headers['Authorization'] = 'Bearer $token';
    }
  }

  bool _isAuthRoute(RequestOptions options) {
    final path = options.uri.path;
    return path == '/api/auth/login' ||
        path == '/api/auth/refresh' ||
        path == '/api/auth/session' ||
        path.startsWith('/api/harmonix/apps/v2/sso/');
  }
}
