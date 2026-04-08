import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:go_router/go_router.dart';

import 'app_router.dart';

part 'app_router_provider.g.dart';

@Riverpod(keepAlive: true)
GoRouter appRouter(AppRouterRef ref) => buildAppRouter();
