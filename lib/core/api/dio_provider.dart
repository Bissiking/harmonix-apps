import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:harmonix_apps/core/settings/settings_repository.dart';
import 'package:harmonix_apps/core/api/harmonix_interceptor.dart';
import 'package:harmonix_apps/core/api/retry_interceptor.dart';
import 'package:harmonix_apps/core/session/session_controller.dart';

part 'dio_provider.g.dart';

@Riverpod(keepAlive: true)
Dio dio(DioRef ref) {
  final settings = ref.watch(settingsRepositoryProvider);
  final baseUrl = _normalizeBaseUrl(settings.serverUrl);

  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Accept': 'application/json'},
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = settings.authToken;
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        } else {
          options.headers.remove('Authorization');
        }
        handler.next(options);
      },
    ),
  );
  dio.interceptors.add(RetryInterceptor(dio));
  dio.interceptors.add(
    HarmonixInterceptor(
      onConnectionFailure: (_) {
        ref.read(requireLoginProvider.notifier).state = true;
      },
    ),
  );

  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(
        requestBody: false,
        responseBody: false,
        requestHeader: false,
      ),
    );
  }

  return dio;
}

String _normalizeBaseUrl(String rawUrl) {
  final trimmed = rawUrl.trim();
  if (trimmed.isEmpty) return 'https://sonora.mhemery.fr';
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }
  return 'https://$trimmed';
}
