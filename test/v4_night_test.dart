import 'package:flutter_test/flutter_test.dart';
import 'package:harmonix_apps/core/models/track.dart';
import 'package:harmonix_apps/features/night/domain/night_engine.dart';
import 'package:harmonix_apps/features/library/domain/music_source.dart';

void main() {
  final start = DateTime(2026, 10, 5, 23, 55);
  test('Sonora Night eligibility survives JSON and respects local choices', () {
    final track = Track.fromJson({
      'id': 'night-tagged',
      'title': 'Ambient',
      'artist': 'Test',
      'night_eligible': true,
    });
    expect(track.nightEligible, isTrue);
    expect(Track.fromJson(track.toJson()).nightEligible, isTrue);
    expect(
        Track.fromJson({'id': 'legacy', 'title': 'Piano', 'artist': 'Test'})
            .nightEligible,
        isFalse);
    expect(
        classifyNight(const NightMetadata(),
                catalogEligible: track.nightEligible)
            .allowed,
        isTrue);
    expect(
        classifyNight(const NightMetadata(assignment: NightAssignment.excluded),
                catalogEligible: true)
            .allowed,
        isFalse);
    expect(
        classifyNight(const NightMetadata(assignment: NightAssignment.allowed),
                catalogEligible: false)
            .allowed,
        isTrue);
    expect(classifyNight(const NightMetadata(), catalogEligible: false).allowed,
        isFalse);
    // Catalogue opt-in never changes a user's separate Night Only preference.
    expect(const NightMetadata().nightOnly, isFalse);
  });
  test('Night deadline survives suspended ticks and fade never amplifies', () {
    final timer =
        NightTimer(startedAt: start, duration: const Duration(minutes: 45));
    expect(timer.gain(start), 1);
    expect(
        timer.gain(timer.deadline.subtract(const Duration(seconds: 90))), .5);
    expect(timer.remaining(timer.deadline.add(const Duration(hours: 1))),
        Duration.zero);
    expect(
        timer.shouldStop(timer.deadline.add(const Duration(hours: 1))), isTrue);
    expect(timer.gain(timer.deadline.add(const Duration(hours: 1))), 0);
    expect(() => NightTimer(startedAt: start, duration: Duration.zero),
        throwsArgumentError);
  });
  test('end of track waits for a boundary after deadline', () {
    final timer = NightTimer(
        startedAt: start,
        duration: const Duration(minutes: 1),
        endOfTrack: true);
    expect(timer.shouldStop(timer.deadline), isFalse);
    expect(timer.shouldStop(timer.deadline, trackEnded: true), isTrue);
    expect(timer.shouldStop(start, trackEnded: true), isFalse);
  });
  test('manual overrides win; unknown audio is never presented as sleep-safe',
      () {
    expect(classifyNight(const NightMetadata()).confidence, 0);
    expect(
        classifyNight(const NightMetadata(
                assignment: NightAssignment.excluded,
                bpm: 60,
                category: 'Piano'))
            .allowed,
        isFalse);
    expect(
        classifyNight(const NightMetadata(assignment: NightAssignment.allowed))
            .allowed,
        isTrue);
    expect(
        classifyNight(const NightMetadata(bpm: 60, category: 'Piano'))
            .confidence,
        lessThan(.5));
  });
  test('habit requires five recent observations and handles midnight', () {
    final now = DateTime(2026, 10, 9, 12);
    final events = [
      for (final day in [1, 2, 5, 6, 7, 8])
        NightObservation(
            DateTime(2026, 10, day, day.isEven ? 0 : 23, day.isEven ? 5 : 55),
            45)
    ];
    expect(detectNightHabit(events.take(4).toList(), now), isNull);
    final habit = detectNightHabit(events, now)!;
    expect(habit.minuteOfDay < 15 || habit.minuteOfDay > 1425, isTrue);
    expect(detectNightHabit(events, DateTime(2027, 1, 5)), isNull);
  });
}
