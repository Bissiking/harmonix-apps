// night_engine.dart
import 'package:harmonix_apps/features/library/domain/music_source.dart';

class NightMetadata {
  const NightMetadata(
      {this.assignment = NightAssignment.automatic,
      this.nightOnly = false,
      this.category = 'Mélange relaxant',
      this.bpm});
  final NightAssignment assignment;
  final bool nightOnly;
  final String category;
  final double? bpm;
  Map<String, dynamic> toJson() => {
        'assignment': assignment.name,
        'nightOnly': nightOnly,
        'category': category,
        'bpm': bpm
      };
  factory NightMetadata.fromJson(Map<String, dynamic> data) => NightMetadata(
      assignment: NightAssignment.values.byName(data['assignment'] as String),
      nightOnly: data['nightOnly'] == true,
      category: data['category'] as String,
      bpm: (data['bpm'] as num?)?.toDouble());
}

class CalmEstimate {
  const CalmEstimate(this.allowed, this.confidence, this.reason);
  final bool allowed;
  final double confidence;
  final String reason;
}

CalmEstimate classifyNight(NightMetadata metadata,
    {bool catalogEligible = false}) {
  if (metadata.assignment == NightAssignment.excluded) {
    return const CalmEstimate(false, 1, 'Exclusion manuelle');
  }
  if (metadata.assignment == NightAssignment.allowed) {
    return const CalmEstimate(true, 1, 'Autorisé manuellement');
  }
  if (catalogEligible) {
    return const CalmEstimate(true, 1, 'Autorisé depuis SonoraStudio');
  }
  // Tags and tempo are hints, never a vocal/sleep classification.
  if (metadata.bpm != null &&
      metadata.bpm! <= 85 &&
      ['Ambient', 'Piano', 'Lo-Fi', 'Nature', 'Instrumental']
          .contains(metadata.category)) {
    return const CalmEstimate(true, .45, 'Estimation par catégorie et tempo');
  }
  return const CalmEstimate(false, 0, 'Validation manuelle nécessaire');
}

class NightTimer {
  NightTimer(
      {required this.startedAt,
      required this.duration,
      this.fadeDuration = const Duration(minutes: 3),
      this.endOfTrack = false}) {
    if (duration <= Duration.zero || fadeDuration < Duration.zero) {
      throw ArgumentError('Invalid session duration');
    }
  }
  final DateTime startedAt;
  final Duration duration;
  final Duration fadeDuration;
  final bool endOfTrack;
  DateTime get deadline => startedAt.add(duration);
  Duration remaining(DateTime now) =>
      now.isBefore(deadline) ? deadline.difference(now) : Duration.zero;
  double gain(DateTime now) {
    if (fadeDuration == Duration.zero) return now.isBefore(deadline) ? 1 : 0;
    final effective = fadeDuration > duration ? duration : fadeDuration;
    return (remaining(now).inMilliseconds / effective.inMilliseconds)
        .clamp(0.0, 1.0);
  }

  bool shouldStop(DateTime now, {bool trackEnded = false}) =>
      !now.isBefore(deadline) && (!endOfTrack || trackEnded);
}

class NightObservation {
  const NightObservation(this.start, this.durationMinutes,
      {this.accepted = true});
  final DateTime start;
  final int durationMinutes;
  final bool accepted;
  Map<String, dynamic> toJson() => {
        'start': start.toIso8601String(),
        'duration': durationMinutes,
        'accepted': accepted
      };
  factory NightObservation.fromJson(Map<String, dynamic> data) =>
      NightObservation(
          DateTime.parse(data['start'] as String), data['duration'] as int,
          accepted: data['accepted'] != false);
}

class NightHabit {
  const NightHabit(this.minuteOfDay, this.observations);
  final int minuteOfDay;
  final int observations;
  String get label =>
      '${(minuteOfDay ~/ 60).toString().padLeft(2, '0')}:${(minuteOfDay % 60).toString().padLeft(2, '0')}';
}

/// Circular weighted median: 23:55 and 00:05 are ten minutes apart.
NightHabit? detectNightHabit(
    List<NightObservation> observations, DateTime now) {
  final weekend = now.weekday >= DateTime.saturday;
  final matching = observations
      .where((o) =>
          !o.start.isAfter(now) &&
          now.difference(o.start).inDays <= 60 &&
          (o.start.weekday >= DateTime.saturday) == weekend)
      .toList();
  if (matching.length < 5) return null;
  final values = <({int minute, double weight})>[];
  for (final observation in matching) {
    final minute =
        (observation.start.hour * 60 + observation.start.minute + 720) % 1440;
    final recency = 1 / (1 + now.difference(observation.start).inDays / 14);
    values.add(
        (minute: minute, weight: recency * (observation.accepted ? 1 : .25)));
  }
  values.sort((a, b) => a.minute.compareTo(b.minute));
  final half = values.fold<double>(0, (sum, value) => sum + value.weight) / 2;
  var sum = 0.0;
  for (final value in values) {
    sum += value.weight;
    if (sum >= half) {
      return NightHabit((value.minute + 720) % 1440, matching.length);
    }
  }
  return null;
}
