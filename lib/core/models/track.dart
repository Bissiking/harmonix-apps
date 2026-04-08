import 'package:freezed_annotation/freezed_annotation.dart';

part 'track.freezed.dart';
part 'track.g.dart';

@freezed
abstract class Track with _$Track {
  const factory Track({
    @JsonKey(readValue: readId, fromJson: stringFromJson)
    required String id,
    @JsonKey(readValue: readTitle, fromJson: stringFromJson)
    required String title,
    @JsonKey(readValue: readArtist, fromJson: stringFromJson)
    required String artist,
    String? album,
    @JsonKey(readValue: readCoverFile, fromJson: coverFileFromJson)
    String? coverFile,
    @JsonKey(readValue: readCoverUrl, fromJson: stringFromJson)
    String? coverUrl,
    @JsonKey(readValue: readStreamUrl, fromJson: stringFromJson)
    String? streamUrl,
    @JsonKey(readValue: readDurationMs, fromJson: durationMsFromJson)
    @Default(0)
    int durationMs,
    @JsonKey(readValue: readIsFavorite, fromJson: boolFromJson)
    @Default(false)
    bool isFavorite,
  }) = _Track;

  factory Track.fromJson(Map<String, dynamic> json) => _$TrackFromJson(json);
}

Object? readCoverFile(Map json, String key) =>
    json['coverFile'] ?? json['cover'] ?? json['cover_file'];

Object? readId(Map json, String key) => json['id'] ?? json['track_id'];

Object? readTitle(Map json, String key) =>
    json['title'] ?? json['name'] ?? json['track_title'];

Object? readArtist(Map json, String key) =>
    json['artist'] ?? json['author'] ?? json['track_artist'];

String? coverFileFromJson(Object? value) {
  if (value == null) return null;
  if (value is String) return value;
  if (value is Map) {
    for (final candidate in ['file', 'path', 'filename', 'id']) {
      final v = value[candidate];
      if (v is String) return v;
    }
  }
  return null;
}

Object? readCoverUrl(Map json, String key) =>
    json['coverUrl'] ?? json['cover_url'] ?? json['cover'];

Object? readStreamUrl(Map json, String key) =>
    json['streamUrl'] ?? json['stream_url'] ?? json['stream'];

String? stringFromJson(Object? value) => value is String ? value : null;

Object? readDurationMs(Map json, String key) {
  if (json['duration_ms'] != null) {
    return {'value': json['duration_ms'], 'unit': 'ms'};
  }
  if (json['durationMs'] != null) {
    return {'value': json['durationMs'], 'unit': 'ms'};
  }
  if (json['duration_seconds'] != null) {
    return {'value': json['duration_seconds'], 'unit': 's'};
  }
  if (json['duration'] != null) {
    return {'value': json['duration'], 'unit': 's'};
  }
  return null;
}

int durationMsFromJson(Object? value) {
  if (value == null) return 0;
  if (value is Map) {
    final raw = value['value'];
    if (raw is num) {
      final unit = value['unit'];
      if (unit == 's') return (raw * 1000).round();
      return raw.toInt();
    }
  }
  if (value is num) return value.toInt();
  return 0;
}

Object? readIsFavorite(Map json, String key) =>
    json['isFavorite'] ?? json['is_favorite'] ?? json['favorite'];

bool boolFromJson(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.toLowerCase();
    return normalized == 'true' || normalized == '1' || normalized == 'on';
  }
  return false;
}
