import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:harmonix_apps/core/settings/settings_repository.dart';
import 'package:harmonix_apps/core/platform/platform_capabilities.dart';
import 'package:harmonix_apps/features/auth/presentation/login_screen.dart';
import 'package:harmonix_apps/core/session/auth_session_tokens.dart';
import 'package:harmonix_apps/features/auth/data/device_authorization_repository.dart';
import 'package:harmonix_apps/features/auth/providers/device_login_controller.dart';
import 'package:harmonix_apps/features/auth/providers/device_login_provider.dart';
import 'package:harmonix_apps/shared/theme/app_theme.dart';
import 'package:harmonix_apps/core/theme/flow_appearance.dart';

final testConfiguration = DeviceLoginConfiguration(
    'public-client',
    Uri.parse('https://kyros.example/device/authorize'),
    Uri.parse('https://kyros.example/token'),
    'profile');
final grant = DeviceAuthorization(
    deviceCode: 'private-device-code',
    userCode: 'ABCD-EFGH',
    verificationUri: Uri.parse('https://kyros.example/device'),
    verificationUriComplete:
        Uri.parse('https://kyros.example/device?user_code=ABCD-EFGH'),
    expiresIn: const Duration(seconds: 60),
    interval: const Duration(seconds: 5));
const tokens = AuthSessionTokens(
    accessToken: 'access', refreshToken: 'refresh', expiresInSeconds: 900);

class FakeRepository extends DeviceAuthorizationRepository {
  FakeRepository() : super(Dio(), 'https://sonora.example');
  int starts = 0, polls = 0;
  DeviceAuthorization challenge = grant;
  Future<AuthSessionTokens> Function() outcome =
      () async => throw const DeviceLoginFailure('authorization_pending');
  @override
  Future<DeviceLoginConfiguration> configuration() async => configurationValue;
  DeviceLoginConfiguration get configurationValue => testConfiguration;
  @override
  Future<DeviceAuthorization> authorize(
      DeviceLoginConfiguration configuration) async {
    starts++;
    return challenge;
  }

  @override
  Future<AuthSessionTokens> poll(
      DeviceLoginConfiguration configuration, String code) {
    polls++;
    expectSync(code, grant.deviceCode);
    return outcome();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('waits the interval, serializes polls and saves exactly once',
      (tester) async {
    final repo = FakeRepository();
    var saved = 0;
    final controller = DeviceLoginController(repo, (_) async {
      saved++;
    }, now: tester.binding.clock.now);
    addTearDown(controller.dispose);
    await Future.wait([controller.start(), controller.start()]);
    expect(repo.starts, 1);
    await tester.pump(const Duration(seconds: 4));
    expect(repo.polls, 0);
    await tester.pump(const Duration(seconds: 1));
    expect(repo.polls, 1);
    final pending = Completer<AuthSessionTokens>();
    repo.outcome = () => pending.future;
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 10));
    expect(repo.polls, 2);
    pending.complete(tokens);
    await tester.pump();
    expect(saved, 1);
    expect(controller.state.phase, DeviceLoginPhase.done);
    await tester.pump(const Duration(minutes: 2));
    expect(repo.polls, 2);
  });
  testWidgets('slow_down adds five seconds and respects Retry-After',
      (tester) async {
    final repo = FakeRepository()
      ..outcome = (() async => throw const DeviceLoginFailure('slow_down',
          retryAfter: Duration(seconds: 12)));
    final controller = DeviceLoginController(repo, (_) async {},
        now: tester.binding.clock.now);
    addTearDown(controller.dispose);
    await controller.start();
    await tester.pump(const Duration(seconds: 5));
    expect(repo.polls, 1);
    repo.outcome = () async => tokens;
    await tester.pump(const Duration(seconds: 11));
    expect(repo.polls, 1);
    await tester.pump(const Duration(seconds: 1));
    expect(repo.polls, 2);
    expect(controller.state.phase, DeviceLoginPhase.done);
  });
  testWidgets(
      'quota and network failure back off without overlapping or erasing the session',
      (tester) async {
    final repo = FakeRepository()
      ..outcome = (() async => throw const DeviceLoginFailure(
          'temporarily_unavailable',
          retryAfter: Duration(seconds: 15)));
    var saved = 0;
    final controller = DeviceLoginController(repo, (_) async {
      saved++;
    }, now: tester.binding.clock.now);
    addTearDown(controller.dispose);
    await controller.start();
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 14));
    expect(repo.polls, 1);
    repo.outcome = () async => throw TimeoutException('offline');
    await tester.pump(const Duration(seconds: 1));
    expect(repo.polls, 2);
    await tester.pump(const Duration(seconds: 29));
    expect(repo.polls, 2);
    repo.outcome = () async => tokens;
    await tester.pump(const Duration(seconds: 1));
    expect(saved, 1);
  });
  for (final spec in [
    ('access_denied', DeviceLoginPhase.denied),
    ('expired_token', DeviceLoginPhase.expired),
    ('invalid_grant', DeviceLoginPhase.unavailable),
    ('unauthorized_client', DeviceLoginPhase.unavailable)
  ]) {
    testWidgets('${spec.$1} stops polling and requires another user action',
        (tester) async {
      final repo = FakeRepository()
        ..outcome = (() async => throw DeviceLoginFailure(spec.$1));
      var saved = 0;
      final controller = DeviceLoginController(repo, (_) async {
        saved++;
      }, now: tester.binding.clock.now);
      addTearDown(controller.dispose);
      await controller.start();
      await tester.pump(const Duration(seconds: 5));
      expect(controller.state.phase, spec.$2);
      expect(controller.state.userCode, isNull);
      await tester.pump(const Duration(minutes: 2));
      expect(repo.polls, 1);
      expect(saved, 0);
      await controller.start();
      expect(repo.starts, 2);
      controller.reset();
    });
  }
  testWidgets('local deadline expires while the provider remains pending',
      (tester) async {
    final repo = FakeRepository();
    final controller = DeviceLoginController(repo, (_) async {},
        now: tester.binding.clock.now);
    addTearDown(controller.dispose);
    await controller.start();
    await tester.pump(const Duration(seconds: 60));
    expect(repo.polls, 11);
    expect(controller.state.phase, DeviceLoginPhase.expired);
  });
  testWidgets(
      'cancelled in-flight response cannot log in, including after retry',
      (tester) async {
    final repo = FakeRepository();
    final pending = Completer<AuthSessionTokens>();
    repo.outcome = () => pending.future;
    var saved = 0;
    final controller = DeviceLoginController(repo, (_) async {
      saved++;
    }, now: tester.binding.clock.now);
    addTearDown(controller.dispose);
    await controller.start();
    await tester.pump(const Duration(seconds: 5));
    controller.reset();
    await controller.start();
    pending.complete(tokens);
    await tester.pump();
    expect(saved, 0);
    controller.reset();
    expect(controller.state.qrUri, isNull);
  });
  testWidgets('failure to persist a consumed grant stops and exposes no tokens',
      (tester) async {
    final repo = FakeRepository()..outcome = (() async => tokens);
    final controller = DeviceLoginController(repo, (_) async {
      throw StateError('keychain locked');
    }, now: tester.binding.clock.now);
    addTearDown(controller.dispose);
    await controller.start();
    await tester.pump(const Duration(seconds: 5));
    expect(controller.state.phase, DeviceLoginPhase.unavailable);
    expect(controller.state.qrUri, isNull);
    await tester.pump(const Duration(minutes: 1));
    expect(repo.polls, 1);
  });
  test(
      'rejects unsafe metadata, cross-origin URLs and secret-bearing QR payloads',
      () {
    final data = {
      'device_code': grant.deviceCode,
      'user_code': grant.userCode,
      'verification_uri': grant.verificationUri.toString(),
      'verification_uri_complete': grant.verificationUriComplete.toString(),
      'expires_in': 600,
      'interval': 5
    };
    expect(
        DeviceAuthorization.fromJson(data, testConfiguration.authorize)
            .verificationUriComplete
            .queryParameters,
        {'user_code': grant.userCode});
    for (final uri in [
      'http://kyros.example/device',
      'https://user:password@kyros.example/device',
      'https://foreign.example/device?user_code=ABCD-EFGH',
      'https://kyros.example/device?device_code=private-device-code',
      'https://kyros.example/device?user_code=ABCD-EFGH&device_code=secret'
    ]) {
      expect(
          () => DeviceAuthorization.fromJson(
              {...data, 'verification_uri_complete': uri},
              testConfiguration.authorize),
          throwsFormatException);
    }
    expect(
        () => DeviceLoginConfiguration.fromJson({
              'client_id': 'a',
              'device_authorization_endpoint':
                  testConfiguration.authorize.toString(),
              'token_endpoint': 'https://foreign.example/token'
            }),
        throwsFormatException);
  });
  test(
      'real repository sends public client ID without credentials and parses rate limits',
      () async {
    final requests = <RequestOptions>[];
    final dio = Dio()
      ..interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
        requests.add(options);
        handler.resolve(Response(
            requestOptions: options,
            statusCode: 429,
            headers: Headers.fromMap({
              'retry-after': ['17']
            }),
            data: {'error': 'temporarily_unavailable'}));
      }));
    final repo = DeviceAuthorizationRepository(dio, 'https://sonora.example');
    await expectLater(
        repo.poll(testConfiguration, grant.deviceCode),
        throwsA(isA<DeviceLoginFailure>().having(
            (e) => e.retryAfter, 'Retry-After', const Duration(seconds: 17))));
    expect(requests.single.headers.containsKey('Authorization'), isFalse);
    expect(requests.single.data['client_secret'], isNull);
    expect(requests.single.followRedirects, isFalse);
  });

  for (final size in [
    const Size(1280, 720),
    const Size(1920, 1080),
    const Size(390, 844)
  ]) {
    testWidgets('TV code and QR layout ${size.width}, remote cancel and focus',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = FakeRepository();
      final key = GlobalKey();
      SharedPreferences.setMockInitialValues({});
      final settings =
          SettingsRepository(await SharedPreferences.getInstance());
      final container = ProviderContainer(overrides: [
        settingsRepositoryProvider.overrideWithValue(settings),
        isTelevisionProvider.overrideWith((ref) async => true),
        deviceLoginProvider.overrideWith((ref) => DeviceLoginController(
            repo, (_) async {},
            now: tester.binding.clock.now))
      ]);
      addTearDown(container.dispose);
      if (const bool.fromEnvironment('FLOW_CAPTURE')) {
        await tester.runAsync(() async {
          for (final spec in [
            ('Roboto', 'roboto-regular.ttf'),
            ('MaterialIcons', 'materialicons-regular.otf')
          ]) {
            final file = File(
                'C:/apps/flutter/bin/cache/artifacts/material_fonts/${spec.$2}');
            if (await file.exists()) {
              final loader = FontLoader(spec.$1)
                ..addFont(Future.value(
                    ByteData.sublistView(await file.readAsBytes())));
              await loader.load();
            }
          }
        });
      }
      await tester.pumpWidget(UncontrolledProviderScope(
          container: container,
          child: RepaintBoundary(
              key: key,
              child: MaterialApp(
                  debugShowCheckedModeBanner: false,
                  theme: AppTheme.dark(FlowAppearance.midnight.palette),
                  home: const LoginScreen()))));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text(grant.userCode), findsOneWidget);
      expect(container.read(deviceLoginProvider).qrUri.toString(),
          grant.verificationUriComplete.toString());
      expect(find.textContaining(grant.deviceCode), findsNothing);
      expect(tester.takeException(), isNull);
      if (const bool.fromEnvironment('FLOW_CAPTURE')) {
        await tester.runAsync(() async {
          final boundary =
              key.currentContext!.findRenderObject() as RenderRepaintBoundary;
          final rendered = await boundary.toImage();
          final data =
              await rendered.toByteData(format: ui.ImageByteFormat.png);
          final directory = Directory('DOCS/validation');
          await directory.create(recursive: true);
          await File('${directory.path}/tv-login-${size.width.toInt()}.png')
              .writeAsBytes(data!.buffer.asUint8List());
          rendered.dispose();
        });
      }
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
      expect(find.byType(QrImageView), findsNothing);
      expect(repo.polls, 0);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
