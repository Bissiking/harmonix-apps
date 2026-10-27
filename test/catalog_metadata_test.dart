import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:harmonix_apps/core/models/track.dart';
import 'package:harmonix_apps/features/library/domain/library_sort.dart';
import 'package:harmonix_apps/features/night/domain/night_visibility.dart';
import 'package:harmonix_apps/features/night/providers/night_provider.dart';
import 'package:harmonix_apps/features/player/providers/player_provider.dart';

void main() {
  group('Track catalogue metadata', () {
    test(
        'should reject a Night title outside Night instead of playing another title',
        () async {
      final container = ProviderContainer(overrides: [
        nightMetadataProvider.overrideWith((ref) async => {}),
      ]);
      final subscription = container.listen(playerProvider, (_, __) {});
      addTearDown(() {
        subscription.close();
        container.dispose();
      });
      await expectLater(
          container.read(playerProvider.notifier).playFromQueue([
            const Track(
                id: 'night', title: 'Night', artist: 'A', nightEligible: true),
            const Track(id: 'day', title: 'Day', artist: 'A'),
          ], 0),
          throwsStateError);
    });
    test('should hide Studio Night flags and exact tags from ordinary lists',
        () {
      final tracks = [
        Track.fromJson({
          'id': 'soft',
          'title': 'Soft Fading Lullaby',
          'night_eligible': true
        }),
        Track.fromJson({
          'id': 'moon',
          'title': 'Moonlit Reverie',
          'genres': 'Ambient; HARMONIX:NIGHT ; Piano'
        }),
        Track.fromJson({
          'id': 'regular',
          'title': 'Regular',
          'tags': ['harmonix:night-only']
        }),
      ];
      expect(visibleInLibrary(tracks, {}).map((t) => t.id), ['regular']);
      expect(Track.fromJson(tracks.first.toJson()).nightEligible, isTrue,
          reason: 'Cached catalogues must keep editorial classification');
    });

    test('should read SQLite timestamps as UTC and retain dates in cache', () {
      final track =
          Track.fromJson({'id': 'new', 'uploaded_at': '2026-10-27 14:05:06'});
      expect(track.addedAt, DateTime.utc(2026, 10, 27, 14, 5, 6));
      expect(Track.fromJson(track.toJson()).addedAt, track.addedAt);
      expect(
          Track.fromJson({'id': 'bad', 'added_at': 'unknown'}).addedAt, isNull);
    });

    test('should sort by server import dates rather than a simultaneous scan',
        () {
      final older = Track.fromJson(
          {'id': 'a', 'title': 'Alpha', 'added_at': '2025-01-01 12:00:00'});
      final newer = Track.fromJson(
          {'id': 'z', 'title': 'Zulu', 'added_at': '2026-10-01T12:00:00Z'});
      final firstScan = DateTime.utc(2026, 10, 27);
      expect(
          sortTracks([older, newer], LibrarySort.recent,
              {'a': firstScan, 'z': firstScan}).map((track) => track.id),
          ['z', 'a']);
    });
  });
}
