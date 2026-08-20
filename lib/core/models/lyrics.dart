class TrackLyrics {
  const TrackLyrics({this.lyrics, this.synced = false});

  factory TrackLyrics.fromJson(Map<String, dynamic> json) => TrackLyrics(
        lyrics: json['lyrics'] as String?,
        synced: json['synced'] == true,
      );

  final String? lyrics;
  final bool synced;

  bool get hasLyrics => lyrics != null && lyrics!.trim().isNotEmpty;

  List<LyricLine> get lines =>
      synced ? parseLrc(lyrics ?? '') : _plainLines(lyrics ?? '');

  List<LyricLine> _plainLines(String raw) => raw
      .split('\n')
      .map((line) => LyricLine(Duration.zero, line.trim()))
      .where((line) => line.text.isNotEmpty)
      .toList();
}

class LyricLine {
  const LyricLine(this.time, this.text);

  final Duration time;
  final String text;
}

/// Parse un fichier LRC (`[mm:ss.xx] paroles`) en lignes horodatées.
List<LyricLine> parseLrc(String lrc) {
  final lines = <LyricLine>[];
  final linePattern = RegExp(r'^\[(\d{1,3}):(\d{2})(?:[.:](\d{1,3}))?\]\s*(.*)$');
  for (final raw in lrc.split('\n')) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) continue;
    final match = linePattern.firstMatch(trimmed);
    if (match == null) continue;
    final minutes = int.parse(match.group(1)!);
    final seconds = int.parse(match.group(2)!);
    final fraction = match.group(3);
    final milliseconds = fraction == null
        ? 0
        : int.parse(fraction.padRight(3, '0').substring(0, 3));
    final text = (match.group(4) ?? '').trim();
    if (text.isEmpty) continue;
    lines.add(
      LyricLine(
        Duration(
          minutes: minutes,
          seconds: seconds,
          milliseconds: milliseconds,
        ),
        text,
      ),
    );
  }
  lines.sort((a, b) => a.time.compareTo(b.time));
  return lines;
}