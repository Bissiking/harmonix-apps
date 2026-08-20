import 'package:harmonix_apps/core/models/track.dart' show Track;

class Album {
  const Album({
    required this.id,
    required this.title,
    required this.artist,
    this.coverFile,
    this.coverUrl,
    this.trackCount = 0,
    this.durationMs = 0,
    this.tracks = const [],
  });

  factory Album.fromJson(Map<String, dynamic> json) {
    final rawTracks = json['tracks'];
    return Album(
      id: readId(json, 'id')?.toString() ?? '',
      title: readTitle(json, 'title')?.toString() ?? '',
      artist: readArtist(json, 'artist')?.toString() ?? '',
      coverFile: readCoverFile(json, 'coverFile') as String?,
      coverUrl: readCoverUrl(json, 'coverUrl') as String?,
      trackCount: (json['track_count'] as num?)?.toInt() ?? 0,
      durationMs: (json['duration_ms'] as num?)?.toInt() ?? 0,
      tracks: rawTracks is List
          ? rawTracks
              .whereType<Map>()
              .map((e) => Track.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
    );
  }

  final String id;
  final String title;
  final String artist;
  final String? coverFile;
  final String? coverUrl;
  final int trackCount;
  final int durationMs;
  final List<Track> tracks;

  int get totalDurationMs =>
      durationMs > 0 ? durationMs : tracks.fold(0, (sum, t) => sum + t.durationMs);
}

Object? readCoverFile(Map json, String key) =>
    json['coverFile'] ?? json['cover'] ?? json['cover_file'];

Object? readId(Map json, String key) => json['id'] ?? json['album_id'];

Object? readTitle(Map json, String key) =>
    json['title'] ?? json['name'] ?? json['album_title'];

Object? readArtist(Map json, String key) =>
    json['artist'] ?? json['author'] ?? json['album_artist'];

Object? readCoverUrl(Map json, String key) =>
    json['coverUrl'] ?? json['cover_url'];