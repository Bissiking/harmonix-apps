import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:harmonix_apps/core/audio/audio_handler_provider.dart';
import 'package:harmonix_apps/core/settings/auth_token_provider.dart';
import 'package:harmonix_apps/features/player/data/playback_repository.dart';
import 'package:harmonix_apps/features/player/providers/player_provider.dart';

final sessionReconnectProvider = Provider<void>((ref) {
  final token = ref.watch(authTokenProvider);
  if (token == null || token.isEmpty) return;

  Future<void>(() async {
    try {
      final handler = ref.read(audioHandlerProvider);
      if (handler.mediaItem.value != null) return;

      final resume =
          await ref.read(playbackRepositoryProvider).getResumeActive();
      if (resume == null) return;

      final player = ref.read(playerProvider.notifier);
      await player.playTrack(resume.track);
      await player.seek(Duration(milliseconds: resume.positionMs));
      if (!resume.wasPlaying) {
        await player.pause();
      }
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Session restore skipped: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    }
  });
});
