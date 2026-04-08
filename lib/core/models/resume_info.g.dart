// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'resume_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ResumeInfo _$ResumeInfoFromJson(Map<String, dynamic> json) => _ResumeInfo(
      track: Track.fromJson(json['track'] as Map<String, dynamic>),
      positionMs: (json['position_ms'] as num?)?.toInt() ?? 0,
      wasPlaying: json['was_playing'] as bool? ?? false,
    );

Map<String, dynamic> _$ResumeInfoToJson(_ResumeInfo instance) =>
    <String, dynamic>{
      'track': instance.track.toJson(),
      'position_ms': instance.positionMs,
      'was_playing': instance.wasPlaying,
    };
