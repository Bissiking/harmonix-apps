import 'package:cached_network_image/cached_network_image.dart';
import 'package:cached_network_image_platform_interface/cached_network_image_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:harmonix_apps/core/settings/settings_repository.dart';
import 'package:harmonix_apps/core/settings/auth_token_provider.dart';
import 'package:harmonix_apps/core/utils/image_url_builder.dart' as url_builder;

class TrackArtwork extends ConsumerWidget {
  const TrackArtwork({
    super.key,
    required this.coverFile,
    this.coverUrl,
    this.size = 56,
    this.borderRadius = 8,
  });

  final String? coverFile;
  final String? coverUrl;
  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsRepositoryProvider);
    final baseUrl = settings.serverUrl;
    final token = ref.watch(authTokenProvider);
    final headers = token != null && token.isNotEmpty
        ? {'Authorization': 'Bearer $token'}
        : null;
    final coverPath = coverFile ?? coverUrl;
    final url =
        coverPath == null ? null : url_builder.coverUrl(baseUrl, coverPath);
    assert(() {
      if (url != null) {
        debugPrint('TrackArtwork url=$url hasAuth=${token != null}');
      }
      return true;
    }());

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: url != null
            ? CachedNetworkImage(
                imageUrl: url,
                httpHeaders: headers ?? const {},
                imageRenderMethodForWeb: ImageRenderMethodForWeb.HttpGet,
                width: size,
                height: size,
                fit: BoxFit.cover,
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
