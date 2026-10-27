import 'package:flutter_test/flutter_test.dart';
import 'package:harmonix_apps/core/models/track.dart';
import 'package:harmonix_apps/features/night/domain/night_engine.dart';
import 'package:harmonix_apps/features/night/domain/night_visibility.dart';

void main() {
  const regular = Track(id: 'regular', title: 'Piano', artist: 'A', durationMs: 1);
  const nightOnly = Track(id: 'night', title: 'Nuit', artist: 'A', durationMs: 1);
  const eligible = Track(id: 'eligible', title: 'Lo-Fi', artist: 'A', durationMs: 1);
  const unknown = Track(id: 'unknown', title: 'Autre', artist: 'A', durationMs: 1);
  const metadata = <String, NightMetadata>{
    'night': NightMetadata(nightOnly: true),
    'eligible': NightMetadata(),
  };

  test('only Night-only titles are hidden, night eligibility is not', () {
    expect(isNightOnly(metadata, 'night'), isTrue);
    expect(isNightOnly(metadata, 'eligible'), isFalse);
    expect(isNightOnly(metadata, 'regular'), isFalse);
    expect(isNightOnly(const {}, 'night'), isFalse);
  });

  test('library surfaces share one rule and never drop unknown titles', () {
    expect(visibleInLibrary([regular, nightOnly, eligible], metadata),
        [regular, eligible]);
    expect(visibleInLibrary(const [], metadata), isEmpty);
    // A title without metadata stays visible: a missing entry must not hide
    // an otherwise normal track.
    expect(visibleInLibrary([unknown], metadata), [unknown]);
    expect(visibleInLibrary([nightOnly], metadata), isEmpty);
  });
}
