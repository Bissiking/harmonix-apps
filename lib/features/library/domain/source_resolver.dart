// source_resolver.dart
import 'package:harmonix_apps/core/models/track.dart';
import 'package:harmonix_apps/features/library/domain/music_source.dart';

class PlayableSource {
  const PlayableSource(this.url, this.source,
      {this.headers, this.temporary = false});
  final String url;
  final MusicSource source;
  final Map<String, String>? headers;
  final bool temporary;
}

Future<PlayableSource?> resolveMusicSource(
    {required Track track,
    required DeviceTrack? device,
    required Future<bool> Function(String) exists,
    required String remoteUrl,
    required bool offline,
    DeviceTrack? cached,
    Map<String, String>? headers}) async {
  if (device != null && await exists(device.path)) {
    return PlayableSource(Uri.file(device.path).toString(), device.source);
  }
  if (cached != null && await exists(cached.path)) {
    return PlayableSource(Uri.file(cached.path).toString(), MusicSource.sonora,
        temporary: true);
  }
  if (isPersonalTrack(track.id) || offline) return null;
  return PlayableSource(remoteUrl, MusicSource.sonora, headers: headers);
}
