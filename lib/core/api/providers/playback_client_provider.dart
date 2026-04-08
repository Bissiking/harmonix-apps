import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../clients/playback_client.dart';
import '../dio_provider.dart';

part 'playback_client_provider.g.dart';

@Riverpod(keepAlive: true)
PlaybackClient playbackClient(PlaybackClientRef ref) {
  return PlaybackClient(ref.watch(dioProvider));
}
