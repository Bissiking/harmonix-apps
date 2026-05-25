import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:harmonix_apps/core/models/album.dart';
import 'package:harmonix_apps/features/catalog/data/catalog_repository.dart';

part 'albums_provider.g.dart';

@riverpod
Future<List<Album>> albums(AlbumsRef ref) =>
    ref.watch(catalogRepositoryProvider).getAlbums();

@riverpod
Future<Album> albumDetail(AlbumDetailRef ref, String albumId) =>
    ref.watch(catalogRepositoryProvider).getAlbum(albumId);
