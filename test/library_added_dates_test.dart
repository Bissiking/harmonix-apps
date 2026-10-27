import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:harmonix_apps/core/models/track.dart';
import 'package:harmonix_apps/core/settings/settings_repository.dart';
import 'package:harmonix_apps/core/storage/local_store.dart';
import 'package:harmonix_apps/features/catalog/data/catalog_repository.dart';
import 'package:harmonix_apps/features/catalog/providers/tracks_provider.dart';
import 'package:harmonix_apps/features/library/data/device_library.dart';
import 'package:harmonix_apps/features/library/domain/music_source.dart';
import 'package:harmonix_apps/features/night/providers/night_provider.dart';

class _Catalog extends CatalogRepository {
  _Catalog(super.ref, this.library, this.ready);
  final DeviceLibrary library;
  final Future<void> ready;

  @override
  Future<List<Track>> getTracks() async {
    await ready;
    const tracks = [Track(id: 'new', title: 'New title', artist: 'Artist')];
    await library.cacheCatalog(tracks);
    return tracks;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  late Database db;
  late DeviceLibrary library;
  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath,
        options:
            OpenDatabaseOptions(version: 1, onCreate: LocalStore.createSchema));
    library = DeviceLibrary(LocalStore(db, 'account'));
  });
  tearDown(() => db.close());

  test('downloads should use current Studio flags without changing their files',
      () async {
    const track = Track(id: 'night-later', title: 'Moonlit', artist: 'Artist');
    await library.saveFile(const DeviceTrack(
        track: track,
        source: MusicSource.downloaded,
        path: 'kept.mp3',
        fingerprint: 'kept',
        bytes: 42));
    await library.cacheCatalog([track.copyWith(nightEligible: true)]);
    final file = (await library.files()).single;
    expect(file.track.nightEligible, isTrue);
    expect(file.path, 'kept.mp3');
    expect(file.bytes, 42);
  });

  test('refresh and download preserve the first date, scoped to the account',
      () async {
    const track = Track(id: 'known', title: 'Known title', artist: 'Artist');
    final original = DateTime.utc(2025, 1, 1);
    await library.store.put('track_added', track.id,
        {'id': track.id, 'at': original.toIso8601String()});
    await library.cacheCatalog([track]);
    await library.saveFile(const DeviceTrack(
        track: track,
        path: 'audio.mp3',
        fingerprint: 'test',
        bytes: 1,
        source: MusicSource.downloaded));
    expect((await library.addedDates())[track.id], original);
    expect(await DeviceLibrary(LocalStore(db, 'other')).addedDates(), isEmpty);
  });

  test('catalogue completion refreshes dates read before the first scan',
      () async {
    SharedPreferences.setMockInitialValues({});
    final settings = SettingsRepository(await SharedPreferences.getInstance());
    final ready = Completer<void>();
    final container = ProviderContainer(overrides: [
      settingsRepositoryProvider.overrideWithValue(settings),
      deviceLibraryProvider.overrideWith((ref) async => library),
      nightMetadataProvider.overrideWith((ref) async => {}),
      catalogRepositoryProvider
          .overrideWith((ref) => _Catalog(ref, library, ready.future)),
    ]);
    addTearDown(container.dispose);
    final dates = container.listen(trackAddedDatesProvider, (_, __) {});
    addTearDown(dates.close);
    expect(await container.read(trackAddedDatesProvider.future), isEmpty);
    final loading = container.read(tracksProvider.future);
    ready.complete();
    await loading;
    expect(
        await container.read(trackAddedDatesProvider.future), contains('new'));
  });
}
