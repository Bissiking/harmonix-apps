import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import 'package:harmonix_apps/core/models/album.dart';
import 'package:harmonix_apps/core/models/lyrics.dart';
import 'package:harmonix_apps/core/models/track.dart';

part 'catalog_client.g.dart';

@RestApi(baseUrl: '')
abstract class CatalogClient {
  factory CatalogClient(Dio dio) = _CatalogClient;

  @GET('/api/harmonix/apps/v2/catalog/tracks')
  Future<List<Track>> getTracks();

  @GET('/api/harmonix/apps/v2/catalog/search')
  Future<List<Track>> search(@Query('q') String query);

  @GET('/api/harmonix/apps/v2/catalog/tracks/{id}')
  Future<Track> getTrack(@Path('id') String id);

  @GET('/api/harmonix/apps/v2/catalog/tracks/{id}/lyrics')
  Future<TrackLyrics> getLyrics(@Path('id') String id);

  @GET('/api/harmonix/apps/v2/catalog/albums')
  Future<List<Album>> getAlbums();

  @GET('/api/harmonix/apps/v2/catalog/albums/{id}')
  Future<Album> getAlbum(@Path('id') String id);
}
