import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:harmonix_apps/core/models/album.dart';
import 'package:harmonix_apps/features/catalog/data/catalog_repository.dart';
import 'package:harmonix_apps/features/night/providers/night_provider.dart';
import 'package:harmonix_apps/features/night/domain/night_visibility.dart';

part 'albums_provider.g.dart';

@riverpod
Future<List<Album>> albums(AlbumsRef ref) =>
    ref.watch(catalogRepositoryProvider).getAlbums();

@riverpod
Future<Album> albumDetail(AlbumDetailRef ref, String albumId) async {
  final metadata = await ref.watch(nightMetadataProvider.future);
  final album = await ref.watch(catalogRepositoryProvider).getAlbum(albumId);
  final tracks = visibleInLibrary(album.tracks, metadata);
  return Album(
      id: album.id,
      title: album.title,
      artist: album.artist,
      coverFile: album.coverFile,
      coverUrl: album.coverUrl,
      trackCount: tracks.length,
      tracks: tracks,
      durationMs: tracks.fold(0, (sum, track) => sum + track.durationMs));
}
