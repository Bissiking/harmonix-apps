import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:harmonix_apps/core/models/track.dart';

part 'resume_info.freezed.dart';
part 'resume_info.g.dart';

@freezed
class ResumeInfo with _$ResumeInfo {
  const factory ResumeInfo({
    required Track track,
    @Default(0) int positionMs,
    @Default(false) bool wasPlaying,
  }) = _ResumeInfo;

  factory ResumeInfo.fromJson(Map<String, dynamic> json) =>
      _$ResumeInfoFromJson(json);
}
