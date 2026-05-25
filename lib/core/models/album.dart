import 'package:harmonix_apps/core/models/track.dart';

class Album {
  const Album({
    required this.id,
    required this.title,
    required this.artist,
    required this.tracks,
    this.coverFile,
    this.coverUrl,
    required this.totalDurationMs,
  });

  final String id;
  final String title;
  final String artist;
  final String? coverFile;
  final String? coverUrl;
  final List<Track> tracks;
  final int totalDurationMs;
}
