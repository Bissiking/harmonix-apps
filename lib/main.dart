import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import 'package:harmonix_apps/app.dart';
import 'package:harmonix_apps/core/audio/audio_handler.dart';
import 'package:harmonix_apps/core/audio/audio_handler_provider.dart';
import 'package:harmonix_apps/core/settings/settings_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (defaultTargetPlatform == TargetPlatform.android) {
    try {
      await Permission.notification.request();
    } on PlatformException catch (e) {
      // Android Auto/background starts can run without a foreground Activity.
      // In that case permission_handler throws; keep app startup alive.
      if (e.code != 'PermissionHandler.PermissionManager') rethrow;
    }
  }

  // Desktop window setup
  if (defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux) {
    await windowManager.ensureInitialized();
    const options = WindowOptions(
      size: Size(1100, 720),
      minimumSize: Size(800, 600),
      title: 'Harmonix',
      center: true,
    );
    await windowManager.waitUntilReadyToShow(options);
    await windowManager.show();
  }

  // Initialize audio service (mobile only; desktop uses handler directly)
  HarmonixAudioHandler? audioHandler;
  if (defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS) {
    audioHandler = await AudioService.init(
      builder: HarmonixAudioHandler.new,
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.harmonix.apps.audio',
        androidNotificationChannelName: 'Harmonix Playback',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
      ),
    );
  } else {
    audioHandler = HarmonixAudioHandler();
  }

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        audioHandlerProvider.overrideWithValue(audioHandler),
        settingsRepositoryProvider.overrideWithValue(SettingsRepository(prefs)),
      ],
      child: const HarmonixApp(),
    ),
  );
}
