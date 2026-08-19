import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:harmonix_apps/core/session/auth_refresh_service.dart';
import 'package:harmonix_apps/core/settings/settings_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('refreshes and rotates an expiring authentication session', () async {
    SharedPreferences.setMockInitialValues({
      'auth_token': 'old-access',
      'refresh_token': 'old-refresh',
      'token_expires_at': DateTime.now()
          .subtract(const Duration(minutes: 1))
          .millisecondsSinceEpoch,
    });
    final preferences = await SharedPreferences.getInstance();
    final settings = SettingsRepository(preferences);
    var requests = 0;
    var notifications = 0;
    final client = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requests++;
            expect(options.uri.path, '/api/auth/refresh');
            expect(options.data, {'refresh_token': 'old-refresh'});
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'ok': true,
                  'access_token': 'new-access',
                  'refresh_token': 'new-refresh',
                  'expires_in': 900,
                },
              ),
            );
          },
        ),
      );
    final service = AuthRefreshService(
      settings: settings,
      client: client,
      onSessionChanged: () => notifications++,
    );

    final results = await Future.wait([
      service.refresh(force: true),
      service.refresh(force: true),
    ]);

    expect(results, everyElement(AuthRefreshResult.refreshed));
    expect(requests, 1);
    expect(notifications, 1);
    expect(settings.authToken, 'new-access');
    expect(settings.refreshToken, 'new-refresh');
    expect(settings.tokenExpiresAt, isNotNull);
    expect(settings.tokenExpiresAt!.isAfter(DateTime.now()), isTrue);
  });

  test('does not erase the session during a temporary refresh outage',
      () async {
    SharedPreferences.setMockInitialValues({
      'auth_token': 'access',
      'refresh_token': 'refresh',
      'token_expires_at': DateTime.now().millisecondsSinceEpoch,
    });
    final preferences = await SharedPreferences.getInstance();
    final settings = SettingsRepository(preferences);
    final client = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) => handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.connectionError,
            ),
          ),
        ),
      );
    final service = AuthRefreshService(
      settings: settings,
      client: client,
      onSessionChanged: () {},
    );

    expect(
      await service.refresh(force: true),
      AuthRefreshResult.unavailable,
    );
    expect(settings.authToken, 'access');
    expect(settings.refreshToken, 'refresh');
  });
}
