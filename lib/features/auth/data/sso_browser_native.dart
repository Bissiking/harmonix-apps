// sso_browser_native.dart
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:window_manager/window_manager.dart';

void prepareSsoBrowser() {}
Future<void> openSsoBrowser(Uri uri) async {
  final mobile = defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
  final mode = mobile && await supportsLaunchMode(LaunchMode.inAppBrowserView)
      ? LaunchMode.inAppBrowserView
      : LaunchMode.externalApplication;
  if (!await launchUrl(uri, mode: mode)) {
    throw StateError('Impossible d’ouvrir le navigateur.');
  }
}

Future<void> finishSsoBrowser() async {
  final mobile = defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
  if (mobile) {
    await closeInAppWebView();
  } else {
    await windowManager.show();
    await windowManager.focus();
  }
}
