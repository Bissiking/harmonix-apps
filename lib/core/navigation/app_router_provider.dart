import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:go_router/go_router.dart';

import 'package:harmonix_apps/core/navigation/app_router.dart';
import 'package:harmonix_apps/core/session/session_controller.dart';
import 'package:harmonix_apps/core/settings/auth_token_provider.dart';
import 'package:harmonix_apps/features/library/data/device_library.dart';

part 'app_router_provider.g.dart';

@Riverpod(keepAlive: true)
GoRouter appRouter(AppRouterRef ref) {
  final token = ref.watch(authTokenProvider);
  final requireLogin =
      ref.watch(requireLoginProvider) || token == null || token.isEmpty;
  final router = buildAppRouter(
      requireLogin: requireLogin && !ref.watch(offlineModeProvider));
  ref.onDispose(router.dispose);
  return router;
}
