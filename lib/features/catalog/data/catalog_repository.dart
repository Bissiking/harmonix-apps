import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/providers/catalog_client_provider.dart';
import '../../../core/models/track.dart';

part 'catalog_repository.g.dart';

class CatalogRepository {
  CatalogRepository(this._ref);

  final dynamic _ref;

  Future<List<Track>> getTracks() =>
      _ref.read(catalogClientProvider).getTracks();

  Future<Track> getTrack(String id) =>
      _ref.read(catalogClientProvider).getTrack(id);

  Future<List<Track>> search(String query) =>
      _ref.read(catalogClientProvider).search(query);
}

@riverpod
CatalogRepository catalogRepository(CatalogRepositoryRef ref) =>
    CatalogRepository(ref);
