// music_source.dart
import 'package:harmonix_apps/core/models/track.dart';

enum MusicSource { sonora, downloaded, personal }

enum NightAssignment { automatic, allowed, excluded }

/// Device availability is separate from the logical Sonora identity.
class DeviceTrack {
  const DeviceTrack(
      {required this.track,
      required this.source,
      required this.path,
      required this.fingerprint,
      required this.bytes,
      this.artworkPath});
  final Track track;
  final MusicSource source;
  final String path;
  final String fingerprint;
  final int bytes;
  final String? artworkPath;
  Map<String, dynamic> toJson() => {
        'track': track.toJson(),
        'source': source.name,
        'path': path,
        'fingerprint': fingerprint,
        'bytes': bytes,
        'artworkPath': artworkPath
      };
  factory DeviceTrack.fromJson(Map<String, dynamic> json) => DeviceTrack(
      track: Track.fromJson(json['track'] as Map<String, dynamic>),
      source: MusicSource.values.byName(json['source'] as String),
      path: json['path'] as String,
      fingerprint: json['fingerprint'] as String,
      bytes: json['bytes'] as int,
      artworkPath: json['artworkPath'] as String?);
}

bool isPersonalTrack(String id) => id.startsWith('local:');

class MixedPlaylist {
  const MixedPlaylist(
      {required this.id,
      required this.name,
      this.trackIds = const [],
      this.revision = 0,
      this.keepOffline = false});
  final String id;
  final String name;
  final List<String> trackIds;
  final int revision;
  final bool keepOffline;
  MixedPlaylist edit(
          {String? name, List<String>? trackIds, bool? keepOffline}) =>
      MixedPlaylist(
          id: id,
          name: name ?? this.name,
          trackIds: trackIds ?? this.trackIds,
          revision: revision + 1,
          keepOffline: keepOffline ?? this.keepOffline);
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'trackIds': trackIds,
        'revision': revision,
        'keepOffline': keepOffline
      };
  factory MixedPlaylist.fromJson(Map<String, dynamic> json) => MixedPlaylist(
      id: json['id'] as String,
      name: json['name'] as String,
      trackIds: (json['trackIds'] as List).cast<String>(),
      revision: json['revision'] as int,
      keepOffline: json['keepOffline'] == true);
}

/// Never silently overwrite a stale edit. The caller must retain both versions.
MixedPlaylist applyPlaylistEdit(
    MixedPlaylist current, MixedPlaylist edited, int baseRevision) {
  if (current.revision != baseRevision) throw StateError('playlist_conflict');
  return edited;
}
