// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playback_state_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PlaybackStateModel _$PlaybackStateModelFromJson(Map<String, dynamic> json) =>
    _PlaybackStateModel(
      trackId: json['track_id'] as String?,
      positionMs: (json['position_ms'] as num?)?.toInt() ?? 0,
      volume: (json['volume'] as num?)?.toDouble() ?? 1.0,
      shuffle: json['shuffle'] as bool? ?? false,
      repeat: json['repeat'] as String? ?? 'none',
      isPlaying: json['is_playing'] as bool? ?? false,
    );

Map<String, dynamic> _$PlaybackStateModelToJson(_PlaybackStateModel instance) =>
    <String, dynamic>{
      'track_id': instance.trackId,
      'position_ms': instance.positionMs,
      'volume': instance.volume,
      'shuffle': instance.shuffle,
      'repeat': instance.repeat,
      'is_playing': instance.isPlaying,
    };
