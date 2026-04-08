import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/settings/settings_repository.dart';
import '../../core/utils/image_url_builder.dart';

class TrackArtwork extends ConsumerWidget {
  const TrackArtwork({
    super.key,
    required this.coverFile,
    this.size = 56,
    this.borderRadius = 8,
  });

  final String? coverFile;
  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final baseUrl = ref.watch(settingsRepositoryProvider).serverUrl;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: coverFile != null
          ? CachedNetworkImage(
              imageUrl: coverUrl(baseUrl, coverFile!),
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
