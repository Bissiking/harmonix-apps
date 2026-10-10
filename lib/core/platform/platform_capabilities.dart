// platform_capabilities.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final isTelevisionProvider = FutureProvider<bool>((ref) async {
  if (const bool.fromEnvironment('HARMONIX_TV')) return true;
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
  try {
    return await const MethodChannel('harmonix/platform')
            .invokeMethod<bool>('isTelevision') ??
        false;
  } on PlatformException {
    return false;
  } on MissingPluginException {
    return false;
  }
});
