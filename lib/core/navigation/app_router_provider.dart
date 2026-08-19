import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:go_router/go_router.dart';

import 'package:harmonix_apps/core/navigation/app_router.dart';
import 'package:harmonix_apps/core/session/session_controller.dart';

part 'app_router_provider.g.dart';

@Riverpod(keepAlive: true)
GoRouter appRouter(AppRouterRef ref) {
  final requireLogin = ref.watch(requireLoginProvider);
  return buildAppRouter(requireLogin: requireLogin);
}
