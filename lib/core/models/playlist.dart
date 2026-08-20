import 'package:harmonix_apps/core/models/track.dart' show Track;

class Playlist {
  const Playlist({
    required this.id,
    required this.name,
    this.description,
    this.coverFile,
    this.trackCount = 0,
    this.tracks = const [],
    this.ownerId,
    this.updatedAt,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    final rawTracks = json['tracks'];
    return Playlist(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description'] as String?,
      coverFile: json['cover_file'] as String? ?? json['cover'] as String?,
      trackCount: (json['track_count'] as num?)?.toInt() ?? 0,
      ownerId: json['owner_id']?.toString(),
      updatedAt: json['updated_at'] as String?,
      tracks: rawTracks is List
          ? rawTracks
              .whereType<Map>()
              .map((e) => Track.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
    );
  }

  final String id;
  final String name;
  final String? description;
  final String? coverFile;
  final int trackCount;
  final List<Track> tracks;
  final String? ownerId;
  final String? updatedAt;
}