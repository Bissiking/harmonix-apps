import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:harmonix_apps/core/api/clients/playlist_client.dart';
import 'package:harmonix_apps/core/api/dio_provider.dart';

part 'playlist_client_provider.g.dart';

@Riverpod(keepAlive: true)
PlaylistClient playlistClient(PlaylistClientRef ref) {
  return PlaylistClient(ref.watch(dioProvider));
}