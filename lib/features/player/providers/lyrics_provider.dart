import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:harmonix_apps/core/models/lyrics.dart';
import 'package:harmonix_apps/features/catalog/data/catalog_repository.dart';

part 'lyrics_provider.g.dart';

@riverpod
Future<TrackLyrics> trackLyrics(TrackLyricsRef ref, String trackId) =>
    ref.watch(catalogRepositoryProvider).getLyrics(trackId);