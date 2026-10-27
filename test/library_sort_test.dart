import 'package:flutter_test/flutter_test.dart';
import 'package:harmonix_apps/core/models/track.dart';
import 'package:harmonix_apps/features/library/domain/library_sort.dart';

void main() {
  const newer = Track(id: 'newer', title: 'Bravo', artist: 'Zed', durationMs: 1);
  const older = Track(id: 'older', title: 'alpha', artist: 'Amy', durationMs: 1);
  const unstamped =
      Track(id: 'unstamped', title: 'Charlie', artist: 'Amy', durationMs: 1);
  final addedAt = {
    'older': DateTime(2026, 1, 1),
    'newer': DateTime(2026, 3, 1),
    // 'unstamped' never appeared in the bucket.
  };

  test('Ajout récent is the default and never loses an unstamped title', () {
    expect(librarySortFromName('recent'), LibrarySort.recent);
    expect(librarySortFromName('title'), LibrarySort.title);
    expect(librarySortFromName('not-a-sort'), LibrarySort.recent);
    expect(
      sortTracks([older, unstamped, newer], LibrarySort.recent, addedAt)
          .map((track) => track.id),
      ['newer', 'older', 'unstamped'],
    );
  });

  test('alphabetical orders ignore case and break ties by title', () {
    // alpha < bravo < charlie, whatever the capitalisation.
    expect(
      sortTracks([newer, older, unstamped], LibrarySort.title, addedAt)
          .map((track) => track.id),
      ['older', 'newer', 'unstamped'],
    );
    // Amy ties for the first two: the title breaks it, then Zed.
    expect(
      sortTracks([newer, older, unstamped], LibrarySort.artist, addedAt)
          .map((track) => track.id),
      ['older', 'unstamped', 'newer'],
    );
    expect(
      sortTracks([newer, older, unstamped], LibrarySort.album, addedAt)
          .map((track) => track.id),
      ['older', 'newer', 'unstamped'],
    );
  });

  test('sorting never mutates the list it is given', () {
    final tracks = [newer, older, unstamped];
    sortTracks(tracks, LibrarySort.recent, addedAt);
    expect(tracks.map((track) => track.id), ['newer', 'older', 'unstamped']);
  });
}
