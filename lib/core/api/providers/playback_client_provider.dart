import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:harmonix_apps/core/api/clients/playback_client.dart';
import 'package:harmonix_apps/core/api/dio_provider.dart';

part 'playback_client_provider.g.dart';

@Riverpod(keepAlive: true)
PlaybackClient playbackClient(PlaybackClientRef ref) {
  return PlaybackClient(ref.watch(dioProvider));
}
