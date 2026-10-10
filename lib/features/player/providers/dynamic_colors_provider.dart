// dynamic_colors_provider.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:harmonix_apps/core/settings/settings_repository.dart';
import 'package:harmonix_apps/core/theme/flow_appearance.dart';
import 'package:harmonix_apps/core/utils/image_url_builder.dart';
import 'package:harmonix_apps/core/utils/trusted_origin.dart';
import 'package:harmonix_apps/features/library/data/device_library.dart';
import 'package:harmonix_apps/features/player/providers/now_playing_provider.dart';
import 'package:harmonix_apps/shared/widgets/local_artwork_native.dart'
    if (dart.library.js_interop) 'package:harmonix_apps/shared/widgets/local_artwork_web.dart';

final _paletteCache = <String, Color>{};
final playerAmbientProvider = FutureProvider<Color>((ref) async {
  ref.watch(appearanceRevisionProvider);
  final settings = ref.watch(settingsRepositoryProvider);
  final fallback = ref.watch(appearanceProvider).palette.accent;
  if (!settings.dynamicColors) return fallback;
  final item = ref.watch(nowPlayingProvider).valueOrNull;
  if (item == null) return fallback;
  final local = ref.watch(deviceTracksProvider.select((files) => files
      .valueOrNull
      ?.where((file) => file.track.id == item.id)
      .firstOrNull
      ?.artworkPath));
  final cover = item.extras?['coverFile'] as String? ??
      item.extras?['coverUrl'] as String?;
  if (local == null && cover == null) return fallback;
  final key = '${settings.libraryScope}:${local ?? cover}';
  if (_paletteCache.containsKey(key)) return _paletteCache[key]!;
  try {
    final ImageProvider provider = local != null
        ? localArtworkProvider(local)
        : CachedNetworkImageProvider(coverUrl(settings.serverUrl, cover!),
            headers: serverHeaders(settings.serverUrl,
                coverUrl(settings.serverUrl, cover), settings.authToken));
    final colors = await ColorScheme.fromImageProvider(
        provider: provider, brightness: Brightness.dark);
    final hsl = HSLColor.fromColor(colors.primary);
    final accent = hsl
        .withSaturation(hsl.saturation.clamp(.18, .6))
        .withLightness(.62)
        .toColor();
    if (_paletteCache.length >= 64) {
      _paletteCache.remove(_paletteCache.keys.first);
    }
    _paletteCache[key] = accent;
    return accent;
  } catch (_) {
    return fallback;
  }
});
