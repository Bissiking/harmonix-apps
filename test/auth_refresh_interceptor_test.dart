import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:harmonix_apps/core/api/auth_refresh_interceptor.dart';
import 'package:harmonix_apps/core/session/auth_refresh_service.dart';
import 'package:harmonix_apps/core/settings/settings_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('refreshes once and replays a request rejected with 401', () async {
    SharedPreferences.setMockInitialValues({
      'auth_token': 'old-access',
      'refresh_token': 'old-refresh',
      'token_expires_at': DateTime.now()
          .add(const Duration(minutes: 10))
          .millisecondsSinceEpoch,
    });
    final preferences = await SharedPreferences.getInstance();
    final settings = SettingsRepository(preferences);
    final refreshClient = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) => handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: {
                'access_token': 'new-access',
                'refresh_token': 'new-refresh',
                'expires_in': 900,
              },
            ),
          ),
        ),
      );
    final refreshService = AuthRefreshService(
      settings: settings,
      client: refreshClient,
      onSessionChanged: () {},
    );
    final adapter = _UnauthorizedThenSuccessAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    dio.interceptors.add(
      AuthRefreshInterceptor(
        dio: dio,
        settings: settings,
        refreshService: refreshService,
        onSessionExpired: () => fail('session should stay active'),
      ),
    );

    final response = await dio.get<dynamic>('https://sonora.test/protected');

    expect(response.statusCode, 200);
    expect(response.data, {'ok': true});
    expect(adapter.authorizationHeaders, [
      'Bearer old-access',
      'Bearer new-access',
    ]);
    expect(settings.refreshToken, 'new-refresh');
  });
}

class _UnauthorizedThenSuccessAdapter implements HttpClientAdapter {
  final List<String?> authorizationHeaders = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    authorizationHeaders.add(options.headers['Authorization'] as String?);
    if (authorizationHeaders.length == 1) {
      return ResponseBody.fromString(
        '{"error":"INVALID_ACCESS_TOKEN"}',
        401,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    return ResponseBody.fromString(
      '{"ok":true}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
