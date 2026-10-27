import 'package:harmonix_apps/core/models/track.dart' show Track;

Map<String, dynamic> playlistJson(Playlist playlist) => {
      'id': playlist.id,
      'name': playlist.name,
      'description': playlist.description,
      'cover_file': playlist.coverFile,
      'track_count': playlist.trackCount,
      'owner_id': playlist.ownerId,
      'updated_at': playlist.updatedAt,
      'tracks': playlist.tracks.map((t) => t.toJson()).toList()
    };

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
