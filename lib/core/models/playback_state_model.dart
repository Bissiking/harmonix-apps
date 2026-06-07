import 'package:freezed_annotation/freezed_annotation.dart';

part 'playback_state_model.freezed.dart';
part 'playback_state_model.g.dart';

@freezed
abstract class PlaybackStateModel with _$PlaybackStateModel {
  const factory PlaybackStateModel({
    String? trackId,
    @Default(0) int positionMs,
    @Default(1.0) double volume,
    @Default(false) bool shuffle,
    @Default('none') String repeat, // none | one | all
    @Default(false) bool isPlaying,
  }) = _PlaybackStateModel;

  factory PlaybackStateModel.fromJson(Map<String, dynamic> json) =>
      _$PlaybackStateModelFromJson(json);
}
