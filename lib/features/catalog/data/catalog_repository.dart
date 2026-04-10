import 'dart:async';

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/providers/catalog_client_provider.dart';
import '../../../core/models/track.dart';

part 'catalog_repository.g.dart';

class CatalogRepository {
  CatalogRepository(this._ref);

  final dynamic _ref;
  List<Track>? _lastTracksCache;

  Future<List<Track>> getTracks() async {
    try {
      final tracks = await _withTransientRetry(
        () => _ref.read(catalogClientProvider).getTracks(),
      );
      _lastTracksCache = tracks;
      return tracks;
    } catch (_) {
      final cached = _lastTracksCache;
      if (cached != null && cached.isNotEmpty) return cached;
      rethrow;
    }
  }

  Future<Track> getTrack(String id) async {
    try {
      return await _withTransientRetry(
        () => _ref.read(catalogClientProvider).getTrack(id),
      );
    } catch (_) {
      final cachedTrack = _lastTracksCache
          ?.where((track) => track.id == id)
          .cast<Track?>()
          .firstWhere((track) => track != null, orElse: () => null);
      if (cachedTrack != null) return cachedTrack;
      rethrow;
    }
  }

  Future<List<Track>> search(String query) =>
      _withTransientRetry(() => _ref.read(catalogClientProvider).search(query));

  Future<T> _withTransientRetry<T>(
    Future<T> Function() action, {
    int maxAttempts = 3,
  }) async {
    Object? lastError;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        return await action();
      } catch (error) {
        lastError = error;
        if (!_isTransientHttpError(error) || attempt == maxAttempts) {
          rethrow;
        }
        await Future<void>.delayed(Duration(milliseconds: 250 * attempt));
      }
    }
    throw lastError ?? StateError('Unexpected retry failure');
  }

  bool _isTransientHttpError(Object error) {
    if (error is! DioException) return false;
    final status = error.response?.statusCode ?? 0;
    return status == 502 || status == 503 || status == 504;
  }
}

@riverpod
CatalogRepository catalogRepository(CatalogRepositoryRef ref) =>
    CatalogRepository(ref);
