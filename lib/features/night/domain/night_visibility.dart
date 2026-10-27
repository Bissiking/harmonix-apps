// night_visibility.dart
import 'package:harmonix_apps/core/models/track.dart';
import 'package:harmonix_apps/features/night/domain/night_engine.dart';

/// The one rule every library surface obeys: a title flagged `nightOnly`
/// belongs to the Night section and stays hidden everywhere else.
bool isNightOnly(Map<String, NightMetadata> metadata, String trackId,
        {Track? track}) =>
    track?.nightEligible == true || metadata[trackId]?.nightOnly == true;

/// Drops the Night-only titles from [tracks]. Every list shown outside the
/// Night section goes through this helper, so the rule cannot drift apart
/// between screens.
List<Track> visibleInLibrary(
  Iterable<Track> tracks,
  Map<String, NightMetadata> metadata,
) =>
    tracks
        .where((track) => !isNightOnly(metadata, track.id, track: track))
        .toList();
