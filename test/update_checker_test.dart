import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:harmonix_apps/core/update/update_checker.dart';

void main() {
  late TargetPlatform? previousPlatform;

  setUp(() {
    previousPlatform = debugDefaultTargetPlatformOverride;
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = previousPlatform;
  });

  test('uses the LUMA Store v1 contract and parses an available update',
      () async {
    RequestOptions? request;
    final sha256 = List.filled(64, 'a').join();
    final client = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            request = options;
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'data': {
                    'available': true,
                    'currentVersion': '3.0.0',
                    'version': '3.1.0',
                    'releaseNotes': 'Corrections.',
                    'artifact': {
                      'fileName': 'harmonix-3.1.0.dmg',
                      'size': 1234,
                      'sha256': sha256,
                      'url': '/api/v1/downloads/release-id',
                    },
                  },
                  'meta': {'apiVersion': 'v1'},
                },
              ),
            );
          },
        ),
      );

    final result = await checkForUpdate(
      client: client,
      packageInfo: _packageInfo,
    );

    expect(request?.uri.path, '/api/v1/apps/harmonix/updates');
    expect(request?.uri.queryParameters, {
      'current_version': '3.0.0',
      'platform': 'macos',
      'arch': 'universal',
      'channel': 'stable',
    });
    expect(result?.updateAvailable, isTrue);
    expect(result?.latestVersion, '3.1.0');
    expect(
      result?.downloadUrl,
      'https://store.mhemery.fr/api/v1/downloads/release-id',
    );
    expect(result?.artifactSize, 1234);
    expect(result?.artifactSha256, sha256);
  });

  test('parses a normal no-update response', () async {
    final client = _clientReturning({
      'data': {'available': false, 'currentVersion': '3.0.0'},
      'meta': {'apiVersion': 'v1'},
    });

    final result = await checkForUpdate(
      client: client,
      packageInfo: _packageInfo,
    );

    expect(result?.updateAvailable, isFalse);
    expect(result?.downloadUrl, isNull);
  });

  test('exposes the Store error code and a useful message', () async {
    final client = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.badResponse,
                response: Response<dynamic>(
                  requestOptions: options,
                  statusCode: 404,
                  data: {
                    'error': {
                      'code': 'not_found',
                      'message': 'Application introuvable.',
                    },
                  },
                ),
              ),
            );
          },
        ),
      );

    expect(
      () => checkForUpdate(client: client, packageInfo: _packageInfo),
      throwsA(
        isA<UpdateCheckException>()
            .having((error) => error.code, 'code', 'not_found')
            .having(
              (error) => error.message,
              'message',
              'Harmonix est introuvable dans le Store.',
            ),
      ),
    );
  });

  test('does not request an Android artifact on iOS', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    var requested = false;
    final client = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requested = true;
            handler.next(options);
          },
        ),
      );

    final result = await checkForUpdate(
      client: client,
      packageInfo: _packageInfo,
    );

    expect(result, isNull);
    expect(requested, isFalse);
  });
}

final _packageInfo = PackageInfo(
  appName: 'Harmonix',
  packageName: 'com.harmonix.harmonix_apps',
  version: '3.0.0',
  buildNumber: '3000',
);

Dio _clientReturning(Map<String, dynamic> data) {
  return Dio()
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: data,
            ),
          );
        },
      ),
    );
}
