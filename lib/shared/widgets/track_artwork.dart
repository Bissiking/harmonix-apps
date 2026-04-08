import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/settings/settings_repository.dart';
import '../../core/utils/image_url_builder.dart' as url_builder;

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
    final token = settings.authToken;
    final headers =
        token != null && token.isNotEmpty ? {'Authorization': 'Bearer $token'} : null;
    final coverPath = coverFile ?? coverUrl;
    final url = coverPath == null
        ? null
        : url_builder.coverUrl(baseUrl, coverPath);
    assert(() {
      if (url != null) {
        debugPrint('TrackArtwork url=$url hasAuth=${token != null}');
      }
      return true;
    }());

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: url != null
          ? CachedNetworkImage(
              imageUrl: url,
              httpHeaders: headers ?? const {},
              width: size,
              height: size,
              fit: BoxFit.cover,
              placeholder: (_, __) => _placeholder(size),
              errorWidget: (_, __, ___) => _placeholder(size),
            )
          : _placeholder(size),
    );
  }

  Widget _placeholder(double size) => Container(
        width: size,
        height: size,
        color: Colors.white10,
        child: Icon(Icons.music_note, size: size * 0.5, color: Colors.white24),
      );
}
