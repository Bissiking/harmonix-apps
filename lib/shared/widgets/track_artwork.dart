import 'package:cached_network_image/cached_network_image.dart';
import 'package:cached_network_image_platform_interface/cached_network_image_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:harmonix_apps/core/settings/settings_repository.dart';
import 'package:harmonix_apps/core/settings/auth_token_provider.dart';
import 'package:harmonix_apps/core/utils/image_url_builder.dart' as url_builder;
import 'package:harmonix_apps/features/library/data/device_library.dart';
import 'package:harmonix_apps/core/utils/trusted_origin.dart';
import 'package:harmonix_apps/shared/widgets/local_artwork_native.dart'
    if (dart.library.js_interop) 'package:harmonix_apps/shared/widgets/local_artwork_web.dart';

class TrackArtwork extends ConsumerWidget {
  const TrackArtwork({
    super.key,
    required this.coverFile,
    this.coverUrl,
    this.size = 56,
    this.borderRadius = 8,
    this.trackId,
  });

  final String? coverFile;
  final String? coverUrl;
  final double size;
  final double borderRadius;
  final String? trackId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsRepositoryProvider);
    final baseUrl = settings.serverUrl;
    final token = ref.watch(authTokenProvider);
    final coverPath = coverFile ?? coverUrl;
    final artwork = trackId == null
        ? null
        : ref.watch(deviceTracksProvider.select((files) => files.valueOrNull
            ?.where((file) => file.track.id == trackId)
            .firstOrNull
            ?.artworkPath));
    final url =
        coverPath == null ? null : url_builder.coverUrl(baseUrl, coverPath);
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: artwork != null
            ? Image(
                image: localArtworkProvider(artwork),
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(size))
            : url != null
                ? CachedNetworkImage(
                    imageUrl: url,
                    httpHeaders: serverHeaders(baseUrl, url, token) ?? const {},
                    imageRenderMethodForWeb: ImageRenderMethodForWeb.HttpGet,
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                    memCacheWidth:
                        (size * MediaQuery.devicePixelRatioOf(context))
                            .ceil()
                            .clamp(48, 1024),
                    placeholder: (_, __) => _placeholder(size),
                    errorWidget: (_, __, ___) => _placeholder(size),
                  )
                : _placeholder(size),
      ),
    );
  }

  Widget _placeholder(double size) => Container(
        width: size,
        height: size,
        color: const Color(0x00000000),
        child: Builder(
          builder: (context) => ColoredBox(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Icon(
              Icons.music_note_rounded,
              size: size * 0.5,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.28),
            ),
          ),
        ),
      );
}
