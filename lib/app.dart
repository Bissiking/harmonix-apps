import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:harmonix_apps/core/navigation/app_router_provider.dart';
import 'package:harmonix_apps/core/platform/auto_bridge.dart';
import 'package:harmonix_apps/core/settings/settings_repository.dart';
import 'package:harmonix_apps/shared/theme/app_theme.dart';
import 'package:harmonix_apps/shared/theme/color_scheme.dart';

class HarmonixApp extends ConsumerStatefulWidget {
  const HarmonixApp({super.key});

  @override
  ConsumerState<HarmonixApp> createState() => _HarmonixAppState();
}

class _HarmonixAppState extends ConsumerState<HarmonixApp> {
  @override
  void initState() {
    super.initState();
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      AutoBridge.register(ref);
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final settings = ref.watch(settingsRepositoryProvider);
    final isDev = settings.serverUrl.contains('dev.mhemery.fr');
    return MaterialApp.router(
      title: 'Harmonix',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      routerConfig: router,
      builder: (context, child) {
        final content = child ?? const SizedBox.shrink();
        if (!isDev) return content;
        return Banner(
          message: 'DEV',
          location: BannerLocation.topStart,
          color: HarmonixColors.accent,
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
}
