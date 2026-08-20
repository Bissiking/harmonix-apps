import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import 'package:harmonix_apps/core/models/playlist.dart';

part 'playlist_client.g.dart';

@RestApi(baseUrl: '')
abstract class PlaylistClient {
  factory PlaylistClient(Dio dio) = _PlaylistClient;

  @GET('/api/harmonix/apps/v2/playlists')
  Future<List<Playlist>> getPlaylists();

  @POST('/api/harmonix/apps/v2/playlists')
  Future<Playlist> createPlaylist(@Body() Map<String, dynamic> body);

  @GET('/api/harmonix/apps/v2/playlists/{id}')
  Future<Playlist> getPlaylist(@Path('id') String id);

  @PATCH('/api/harmonix/apps/v2/playlists/{id}')
  Future<Playlist> renamePlaylist(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @DELETE('/api/harmonix/apps/v2/playlists/{id}')
  Future<void> deletePlaylist(@Path('id') String id);

  @POST('/api/harmonix/apps/v2/playlists/{id}/tracks')
  Future<void> addTracks(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @DELETE('/api/harmonix/apps/v2/playlists/{id}/tracks/{trackId}')
  Future<void> removeTrack(
    @Path('id') String id,
    @Path('trackId') String trackId,
  );
}