import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../../models/track.dart';

part 'catalog_client.g.dart';

@RestApi(baseUrl: '')
abstract class CatalogClient {
  factory CatalogClient(Dio dio) = _CatalogClient;

  @GET('/api/harmonix/apps/catalog/tracks')
  Future<List<Track>> getTracks();

  @GET('/api/harmonix/apps/catalog/search')
  Future<List<Track>> search(@Query('q') String query);

  @GET('/api/harmonix/apps/catalog/tracks/{id}')
  Future<Track> getTrack(@Path('id') String id);
}
