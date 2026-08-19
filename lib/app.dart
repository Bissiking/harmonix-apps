import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:harmonix_apps/core/navigation/app_router_provider.dart';
import 'package:harmonix_apps/core/audio/session_reconnect_provider.dart';
import 'package:harmonix_apps/core/platform/auto_bridge.dart';
import 'package:harmonix_apps/core/settings/settings_repository.dart';
import 'package:harmonix_apps/core/theme/theme_provider.dart';
import 'package:harmonix_apps/features/cast/providers/cast_provider.dart';
import 'package:harmonix_apps/shared/theme/app_theme.dart';

class HarmonixApp extends ConsumerStatefulWidget {
  const HarmonixApp({super.key});

  @override
  ConsumerState<HarmonixApp> createState() => _HarmonixAppState();
}

class _HarmonixAppState extends ConsumerState<HarmonixApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(themeControllerProvider.notifier).initFromCache();
      _requestNotificationPermissionIfForeground();
    });
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      AutoBridge.register(ref);
    }
  }

  Future<void> _requestNotificationPermissionIfForeground() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    if (lifecycle != AppLifecycleState.resumed) return;
    try {
      await Permission.notification.request();
    } on PlatformException catch (_) {
      // Ignore when no foreground activity is bound to this engine.
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(riftPlaybackSyncProvider);
    ref.watch(sessionReconnectProvider);
    final router = ref.watch(appRouterProvider);
    final settings = ref.watch(settingsRepositoryProvider);
    final themePalette = ref.watch(themeControllerProvider);
    final isDev = _isDevServer(settings.serverUrl);
    return MaterialApp.router(
      title: 'Harmonix',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark(themePalette),
      themeMode: settings.themeMode,
      routerConfig: router,
      builder: (context, child) {
        final content = child ?? const SizedBox.shrink();
        if (!isDev) return content;
        return Banner(
          message: 'DEV',
          location: BannerLocation.topStart,
          color: themePalette.accent,
          textStyle: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
          child: content,
        );
      },
    );
  }

  bool _isDevServer(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return false;
    final normalized = trimmed.contains('://') ? trimmed : 'https://$trimmed';
    final uri = Uri.tryParse(normalized);
    final host = uri?.host.toLowerCase() ?? '';
    return host == 'dev.mhemery.fr' ||
        host == 'localhost' ||
        host == '127.0.0.1';
  }
}
