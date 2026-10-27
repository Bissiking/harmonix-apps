import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:harmonix_apps/core/api/dio_provider.dart';
import 'package:harmonix_apps/core/settings/settings_repository.dart';
import 'package:harmonix_apps/core/settings/auth_token_provider.dart';
import 'package:harmonix_apps/core/session/session_controller.dart';
import 'package:harmonix_apps/core/storage/local_store.dart';
import 'package:harmonix_apps/features/bootstrap/providers/bootstrap_provider.dart';
import 'package:harmonix_apps/features/library/data/device_library.dart';
import 'package:harmonix_apps/features/auth/data/device_authorization_repository.dart';
import 'package:harmonix_apps/features/auth/providers/device_login_controller.dart';

final deviceLoginProvider =
    StateNotifierProvider.autoDispose<DeviceLoginController, DeviceLoginState>(
        (ref) {
  final settings = ref.watch(settingsRepositoryProvider);
  final server = settings.serverUrl;
  final account = settings.libraryScope;
  // No access token interceptor, redirects, automatic retry or request logging.
  final client = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Accept': 'application/json'}));
  ref.onDispose(() => client.close(force: true));
  return DeviceLoginController(DeviceAuthorizationRepository(client, server),
      (tokens) async {
    if (settings.serverUrl != server || settings.libraryScope != account) {
      throw StateError('The local account changed during login');
    }
    await settings.setAuthSession(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        expiresInSeconds: tokens.expiresInSeconds,
        newLogin: true);
    ref.invalidate(dioProvider);
    ref.invalidate(authTokenProvider);
    ref.invalidate(bootstrapProvider);
    ref.invalidate(localStoreProvider);
    ref.invalidate(deviceLibraryProvider);
    await ref.read(offlineModeProvider.notifier).setEnabled(false);
    ref.read(requireLoginProvider.notifier).state = false;
  });
});
