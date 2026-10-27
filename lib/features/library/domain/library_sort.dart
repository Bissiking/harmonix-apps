// library_sort.dart
import 'package:harmonix_apps/core/models/track.dart';

/// Order of the Morceaux tab. [recent] is the default: the catalogue itself
/// carries no date, so the app records when each title first appeared on the
/// device (see `DeviceLibrary.stampAdded`).
enum LibrarySort { recent, title, artist, album }

extension LibrarySortLabel on LibrarySort {
  String get label => switch (this) {
        LibrarySort.recent => 'Ajout récent',
        LibrarySort.title => 'Titre A–Z',
        LibrarySort.artist => 'Artiste',
        LibrarySort.album => 'Album',
      };
}

LibrarySort librarySortFromName(String name) => LibrarySort.values.firstWhere(
      (sort) => sort.name == name,
      orElse: () => LibrarySort.recent,
    );

/// Applies [sort] to an already filtered list. Titles never stamped sink to
/// the bottom of "Ajout récent".
List<Track> sortTracks(
  List<Track> tracks,
  LibrarySort sort,
  Map<String, DateTime> addedAt,
) =>
    switch (sort) {
      LibrarySort.recent => _sortByDate(tracks, addedAt),
      LibrarySort.title => _alphabetical(tracks, (track) => track.title),
      LibrarySort.artist => _alphabetical(tracks, (track) => track.artist),
      LibrarySort.album => _alphabetical(tracks, (track) => track.album ?? ''),
    };

List<Track> _sortByDate(List<Track> tracks, Map<String, DateTime> addedAt) {
  final epoch = DateTime.fromMillisecondsSinceEpoch(0);
  final sorted = [...tracks];
  sorted.sort((a, b) {
    final byDate = (b.addedAt ?? addedAt[b.id] ?? epoch)
        .compareTo(a.addedAt ?? addedAt[a.id] ?? epoch);
    return byDate != 0
        ? byDate
        : a.title.toLowerCase().compareTo(b.title.toLowerCase());
  });
  return sorted;
}

List<Track> _alphabetical(List<Track> tracks, String Function(Track) key) {
  final sorted = [...tracks];
  sorted.sort((a, b) {
    final primary = key(a).toLowerCase().compareTo(key(b).toLowerCase());
    return primary != 0
        ? primary
        : a.title.toLowerCase().compareTo(b.title.toLowerCase());
  });
  return sorted;
}
