import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import 'package:harmonix_apps/core/models/playback_state_model.dart';
import 'package:harmonix_apps/core/models/resume_info.dart';

part 'playback_client.g.dart';

@RestApi(baseUrl: '')
abstract class PlaybackClient {
  factory PlaybackClient(Dio dio) = _PlaybackClient;

  @GET('/api/harmonix/apps/v2/playback/state')
  Future<PlaybackStateModel> getState();

  @PUT('/api/harmonix/apps/v2/playback/state')
  Future<void> saveState(@Body() Map<String, dynamic> body);

  @GET('/api/harmonix/apps/v2/playback/resume-active')
  Future<ResumeInfo?> getResumeActive();

  @GET('/api/harmonix/apps/v2/playback/resume/{trackId}')
  Future<ResumeInfo> getResumeForTrack(@Path('trackId') String trackId);
}
