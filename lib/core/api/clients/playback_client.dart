import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../../models/playback_state_model.dart';
import '../../models/resume_info.dart';

part 'playback_client.g.dart';

@RestApi(baseUrl: '')
abstract class PlaybackClient {
  factory PlaybackClient(Dio dio) = _PlaybackClient;

  @GET('/api/harmonix/apps/playback/state')
  Future<PlaybackStateModel> getState();

  @PUT('/api/harmonix/apps/playback/state')
  Future<void> saveState(@Body() Map<String, dynamic> body);

  @GET('/api/harmonix/apps/playback/resume-active')
  Future<ResumeInfo?> getResumeActive();

  @GET('/api/harmonix/apps/playback/resume/{trackId}')
  Future<ResumeInfo> getResumeForTrack(@Path('trackId') String trackId);
}
