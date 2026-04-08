// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'track.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Track _$TrackFromJson(Map<String, dynamic> json) => _Track(
      id: stringFromJson(readId(json, 'id')) ?? '',
      title: stringFromJson(readTitle(json, 'title')) ?? '',
      artist: stringFromJson(readArtist(json, 'artist')) ?? '',
      album: json['album'] as String?,
      coverFile: coverFileFromJson(readCoverFile(json, 'cover_file')),
      coverUrl: stringFromJson(readCoverUrl(json, 'cover_url')),
      streamUrl: stringFromJson(readStreamUrl(json, 'stream_url')),
      durationMs: durationMsFromJson(readDurationMs(json, 'duration_ms')),
      isFavorite: readIsFavorite(json, 'is_favorite') == null
          ? false
          : boolFromJson(readIsFavorite(json, 'is_favorite')),
    );

Map<String, dynamic> _$TrackToJson(_Track instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'artist': instance.artist,
      'album': instance.album,
      'cover_file': instance.coverFile,
      'cover_url': instance.coverUrl,
      'stream_url': instance.streamUrl,
      'duration_ms': instance.durationMs,
      'is_favorite': instance.isFavorite,
    };
