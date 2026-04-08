import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../../models/track.dart';

part 'library_client.g.dart';

@RestApi(baseUrl: '')
abstract class LibraryClient {
  factory LibraryClient(Dio dio) = _LibraryClient;

  @GET('/api/harmonix/apps/library/favorites')
  Future<List<Track>> getFavorites();

  @POST('/api/harmonix/apps/library/favorites/toggle')
  Future<void> toggleFavorite(@Body() Map<String, dynamic> body);
}
