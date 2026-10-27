// Optional contract test. Started by Kyros scripts/qa/harmonix-live.mjs only.
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:harmonix_apps/core/settings/settings_repository.dart';
import 'package:harmonix_apps/core/session/auth_refresh_service.dart';
import 'package:harmonix_apps/features/auth/data/sso_repository.dart';
import 'package:harmonix_apps/core/api/harmonix_interceptor.dart';
import 'package:harmonix_apps/features/auth/providers/device_login_controller.dart';
import 'package:harmonix_apps/features/auth/providers/device_login_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final control = Platform.environment['KYROS_QA_HARMONIX_CONTROL'];
  test(
      'real Kyros device approval/refusal/expiry and Sonora refresh preserve the local session',
      () async {
    HttpOverrides.global =
        null; // Real loopback network, no Flutter mock HTTP client.
    final qa = Dio(BaseOptions(
        baseUrl: control!,
        headers: {'x-qa-key': Platform.environment['KYROS_QA_HARMONIX_KEY']}));
    addTearDown(() => qa.close(force: true));
    final setup = (await qa.get<Map<String, dynamic>>('/setup')).data!;
    SharedPreferences.setMockInitialValues({
      'server_url': setup['sonora'],
      'flow_offline': true,
      'local_account_id': 'local-fixture'
    });
    FlutterSecureStorage.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final settings = SettingsRepository(preferences);
    await settings.initializeSecureSession(const FlutterSecureStorage());
    final container = ProviderContainer(
        overrides: [settingsRepositoryProvider.overrideWithValue(settings)]);
    final subscription = container.listen(deviceLoginProvider, (_, __) {});
    addTearDown(() {
      subscription.close();
      container.dispose();
    });
    Future<void> waitFor(DeviceLoginPhase phase) async {
      final deadline = DateTime.now().add(const Duration(seconds: 30));
      while (container.read(deviceLoginProvider).phase != phase) {
        if (DateTime.now().isAfter(deadline)) {
          fail('Timed out waiting for $phase');
        }
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    }

    final controller = container.read(deviceLoginProvider.notifier);
    await controller.start();
    expect(container.read(deviceLoginProvider).phase, DeviceLoginPhase.waiting);
    final first = container.read(deviceLoginProvider);
    expect(first.qrUri!.queryParameters, {'user_code': first.userCode});
    // Allow a real pending response at the advertised interval before approval.
    await Future<void>.delayed(const Duration(milliseconds: 5400));
    expect(container.read(deviceLoginProvider).phase, DeviceLoginPhase.waiting);
    await qa.post('/decision', data: {
      'code': first.userCode,
      'decision': 'approve',
      'crossAccount': true
    });
    await waitFor(DeviceLoginPhase.done);
    expect(settings.authToken, isNotEmpty);
    expect(settings.refreshToken, isNotEmpty);
    expect(settings.offlineMode, isFalse);
    expect(preferences.getString('auth_token'), isNull);
    expect(preferences.getString('refresh_token'), isNull);
    expect(await const FlutterSecureStorage().read(key: 'auth_token'),
        settings.authToken);
    await qa.post('/assert-saved', data: {
      'accessToken': settings.authToken,
      'name': 'Flutter TV grant saves tokens accepted by real Sonora catalogue'
    });
    final restarted = SettingsRepository(preferences);
    await restarted.initializeSecureSession(const FlutterSecureStorage());
    expect(restarted.authToken, settings.authToken);
    expect(restarted.libraryScope, settings.libraryScope);
    final refresh =
        AuthRefreshService(settings: settings, onSessionChanged: () {});
    final initialRefresh = settings.refreshToken;
    final renewed = await Future.wait(
        [refresh.refresh(force: true), refresh.refresh(force: true)]);
    expect(renewed, everyElement(AuthRefreshResult.refreshed));
    expect(settings.refreshToken, isNot(initialRefresh));
    await qa.post('/assert-saved', data: {
      'accessToken': settings.authToken,
      'name': 'TV refresh rotates through the actual confidential Sonora relay'
    });
    final validAccess = settings.authToken,
        validRefresh = settings.refreshToken,
        scope = settings.libraryScope;
    await qa.post('/online', data: {'online': false});
    expect(await refresh.refresh(force: true), AuthRefreshResult.unavailable);
    expect(settings.authToken, validAccess);
    expect(settings.refreshToken, validRefresh);
    expect(settings.libraryScope, scope);
    await qa.post('/online', data: {'online': true});
    await qa.post('/assert-saved', data: {
      'accessToken': settings.authToken,
      'name':
          'real Kyros outage returns unavailable and preserves the existing TV session'
    });
    controller.reset();
    await controller.start();
    await qa.post('/decision', data: {
      'code': container.read(deviceLoginProvider).userCode,
      'decision': 'deny'
    });
    await waitFor(DeviceLoginPhase.denied);
    expect(settings.authToken, validAccess);
    expect(settings.refreshToken, validRefresh);
    controller.reset();
    await controller.start();
    await qa.post('/expire',
        data: {'code': container.read(deviceLoginProvider).userCode});
    await waitFor(DeviceLoginPhase.expired);
    expect(settings.authToken, validAccess);
    expect(settings.libraryScope, scope);
    await qa.post('/assert-saved', data: {
      'accessToken': settings.authToken,
      'name':
          'real refusal and forced server expiry preserve the previous account and tokens'
    });
    // Existing browser relay remains usable as the TV fallback (real PAR URL).
    final state = 'flutter-fallback-${DateTime.now().microsecondsSinceEpoch}';
    final browserClient = Dio(BaseOptions(baseUrl: setup['sonora'] as String))
      ..interceptors.add(HarmonixInterceptor());
    addTearDown(() => browserClient.close(force: true));
    final browserRepository = SsoRepository(browserClient);
    final authorize = await browserRepository.start(state, platform: 'android');
    expect(Uri.parse(authorize!).queryParameters['request_uri'],
        startsWith('urn:ietf:params:oauth:request_uri:'));
    await qa.post('/browser-complete', data: {'url': authorize});
    final fallbackTokens = await browserRepository.getTokens(state);
    expect(fallbackTokens, isNotNull);
    await qa.post('/assert-saved', data: {
      'accessToken': fallbackTokens!.accessToken,
      'name':
          'real Flutter browser relay consumes fallback tokens once, accepted by Sonora'
    });
    await expectLater(
        browserRepository.getTokens(state), throwsA(isA<DioException>()));
    expect(settings.authToken, validAccess);
    expect(settings.libraryScope, scope);
    await qa.post('/revoke', data: {'refreshToken': settings.refreshToken});
    expect(await refresh.refresh(force: true), AuthRefreshResult.invalid);
    await refresh.expireSession();
    expect(settings.authToken, isNull);
    expect(settings.refreshToken, isNull);
    expect(settings.libraryScope, scope);
  }, skip: control == null, timeout: const Timeout(Duration(minutes: 2)));
}
