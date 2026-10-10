import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:harmonix_apps/core/models/track.dart';
import 'package:harmonix_apps/core/settings/settings_repository.dart';
import 'package:harmonix_apps/core/storage/local_store.dart';
import 'package:harmonix_apps/core/utils/trusted_origin.dart';
import 'package:harmonix_apps/features/library/data/device_library.dart';
import 'package:harmonix_apps/features/library/data/mixed_playlist_sync.dart';
import 'package:harmonix_apps/features/library/domain/music_source.dart';
import 'package:harmonix_apps/features/library/domain/source_resolver.dart';
import 'package:harmonix_apps/features/library/data/audio_cache.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:harmonix_apps/core/api/harmonix_interceptor.dart';

class SyncAdapter implements HttpClientAdapter {
  SyncAdapter(this.rows);
  final List<Map<String, dynamic>> rows;
  final sent = <Map<String, dynamic>>[];
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream,
      Future<void>? cancel) async {
    if (options.method == 'PUT') {
      sent.add(options.data as Map<String, dynamic>);
      return ResponseBody.fromString(jsonEncode({'revision': 2}), 409,
          headers: {
            Headers.contentTypeHeader: ['application/json']
          });
    }
    return ResponseBody.fromString(jsonEncode(rows), 200, headers: {
      Headers.contentTypeHeader: ['application/json']
    });
  }

  @override
  void close({bool force = false}) {}
}

class StatusAdapter implements HttpClientAdapter {
  StatusAdapter(this.status);
  final int status;
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream,
          Future<void>? cancel) async =>
      ResponseBody.fromString('{}', status, headers: {
        Headers.contentTypeHeader: ['application/json']
      });
  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  const track = Track(
      id: 'sonora-1', title: 'Piano', artist: 'Artiste', durationMs: 60000);
  late Database db;
  late DeviceLibrary library;
  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath,
        options:
            OpenDatabaseOptions(version: 1, onCreate: LocalStore.createSchema));
    library = DeviceLibrary(LocalStore(db, 'alice'));
  });
  tearDown(() => db.close());

  test('local records survive a real close and reopen of the database file',
      () async {
    final directory =
        await Directory.systemTemp.createTemp('harmonix-v4-test-');
    final path = p.join(directory.path, 'library.sqlite');
    var disk = await databaseFactoryFfi.openDatabase(path,
        options:
            OpenDatabaseOptions(version: 1, onCreate: LocalStore.createSchema));
    try {
      await LocalStore(disk, 'account')
          .put('history', 'track', {'positionMs': 9000});
      await disk.close();
      disk = await databaseFactoryFfi.openDatabase(path);
      expect(
          (await LocalStore(disk, 'account')
              .get('history', 'track'))?['positionMs'],
          9000);
      expect(await LocalStore(disk, 'other-account').all('history'), isEmpty);
    } finally {
      await disk.close();
      if (!p.isWithin(
          Directory.systemTemp.absolute.path, directory.absolute.path)) {
        throw StateError('Unsafe temporary directory');
      }
      await directory.delete(recursive: true);
    }
  });

  test('temporary HTTP failure never requests login; confirmed 401 does',
      () async {
    var redirects = 0;
    final dio = Dio()
      ..interceptors
          .add(HarmonixInterceptor(onConnectionFailure: (_) => redirects++));
    dio.httpClientAdapter = StatusAdapter(503);
    await expectLater(dio.get<dynamic>('https://sonora.test/api/health'),
        throwsA(isA<DioException>()));
    expect(redirects, 0);
    dio.httpClientAdapter = StatusAdapter(401);
    await expectLater(dio.get<dynamic>('https://sonora.test/api/health'),
        throwsA(isA<DioException>()));
    expect(redirects, 1);
    dio.close();
  });

  test('records, source identity and account boundaries persist in SQLite',
      () async {
    await library.saveFile(const DeviceTrack(
        track: track,
        source: MusicSource.downloaded,
        path: 'private/audio',
        fingerprint: 'hash',
        bytes: 400));
    await library.cacheCatalog([track]);
    final reopened = DeviceLibrary(LocalStore(db, 'alice'));
    expect((await reopened.allTracks()).map((t) => t.id), ['sonora-1']);
    expect((await reopened.file(track.id))?.source, MusicSource.downloaded);
    expect(await DeviceLibrary(LocalStore(db, 'bob')).allTracks(), isEmpty);
  });
  test('fresh Night tags win over downloaded snapshots and persist offline',
      () async {
    await library.saveFile(const DeviceTrack(
      track: track,
      source: MusicSource.downloaded,
      path: 'private/audio',
      fingerprint: 'hash',
      bytes: 400,
    ));
    await library.cacheCatalog([track.copyWith(nightEligible: true)]);
    expect((await library.allTracks()).single.nightEligible, isTrue);
    final reopened = DeviceLibrary(LocalStore(db, 'alice'));
    expect((await reopened.allTracks()).single.nightEligible, isTrue);
    expect((await reopened.file(track.id))!.path, 'private/audio');
    await library.cacheCatalog([track]);
    expect((await reopened.allTracks()).single.nightEligible, isFalse);
    // A retained download stays available when absent from the cached catalogue.
    await library.cacheCatalog([]);
    expect((await reopened.allTracks()).single.id, track.id);
  });
  test('simultaneous stale playlist edits cannot overwrite the winner',
      () async {
    final p = await library.createPlaylist('Mix');
    final results = await Future.wait([
      library
          .savePlaylist(p.edit(name: 'A'), baseRevision: 0)
          .then((_) => true)
          .catchError((_) => false),
      library
          .savePlaylist(p.edit(name: 'B'), baseRevision: 0)
          .then((_) => true)
          .catchError((_) => false),
    ]);
    expect(results.where((r) => r).length, 1);
    expect((await library.playlists()).single.revision, 1);
  });
  test(
      'local playback has no HTTP credentials and missing files fall back only online',
      () async {
    const file = DeviceTrack(
        track: track,
        source: MusicSource.downloaded,
        path: 'C:/private/a.mp3',
        fingerprint: 'hash',
        bytes: 100);
    Future<PlayableSource?> resolve(bool exists, bool offline) =>
        resolveMusicSource(
            track: track,
            device: file,
            exists: (_) async => exists,
            remoteUrl: 'https://sonora.test/audio',
            offline: offline,
            headers: {'Authorization': 'secret'});
    final local = await resolve(true, true);
    expect(local?.url, startsWith('file:'));
    expect(local?.headers, isNull);
    expect((await resolve(false, false))?.source, MusicSource.sonora);
    expect(await resolve(false, true), isNull);
    expect(
        await resolveMusicSource(
            track: const Track(
                id: 'local:missing', title: 'M', artist: 'A', durationMs: 0),
            device: null,
            exists: (_) async => false,
            remoteUrl: 'https://server/test',
            offline: false),
        isNull);
  });
  test('credentials never cross protocol, host or port boundaries', () {
    expect(
        serverHeaders(
            'https://sonora.test', 'https://sonora.test/audio', 'token'),
        isNotNull);
    for (final url in [
      'http://sonora.test/audio',
      'https://other.test/audio',
      'https://sonora.test:8443/audio'
    ]) {
      expect(serverHeaders('https://sonora.test', url, 'token'), isNull);
    }
  });
  test('temporary cache eviction respects LRU and protects queued sources', () {
    final rows = [
      for (final id in ['old', 'queued', 'recent'])
        {
          'file': {
            'bytes': 100,
            'track': {'id': id}
          },
          'lastUsed': {
            'old': '2026-01-01',
            'queued': '2026-01-02',
            'recent': '2026-01-03'
          }[id]
        }
    ];
    expect(cacheEvictions(rows, 200).single['file']['track']['id'], 'old');
    expect(
        cacheEvictions(rows, 0, protectedIds: {'queued'})
            .map((r) => r['file']['track']['id']),
        ['old', 'recent']);
  });
  test('changing server clears credentials while preserving old scoped records',
      () async {
    SharedPreferences.setMockInitialValues({});
    final settings = SettingsRepository(await SharedPreferences.getInstance());
    await settings.setAuthToken('opaque-token');
    final scope = settings.libraryScope;
    await LocalStore(db, scope).put('favorites', 'one', {'id': 'one'});
    await settings.setServerUrl('other.test');
    expect(settings.authToken, isNull);
    expect(settings.libraryScope, isNot(scope));
    expect(await LocalStore(db, scope).get('favorites', 'one'), isNotNull);
    expect(() => settings.setServerUrl('ftp://bad.test'), throwsArgumentError);
  });
  test(
      'verified secure migration preserves session and deletes plaintext only after copying',
      () async {
    SharedPreferences.setMockInitialValues(
        {'auth_token': 'old-access', 'refresh_token': 'old-refresh'});
    FlutterSecureStorage.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final settings = SettingsRepository(prefs);
    await settings.initializeSecureSession(const FlutterSecureStorage());
    expect(settings.authToken, 'old-access');
    expect(settings.refreshToken, 'old-refresh');
    expect(settings.sessionStorageUnavailable, isFalse);
    expect(prefs.getString('auth_token'), isNull);
    expect(await const FlutterSecureStorage().read(key: 'auth_token'),
        'old-access');
  });
  test(
      'mixed payload shares metadata and fingerprint, never paths or audio URLs',
      () {
    final fingerprint = List.filled(64, 'a').join();
    final personal = Track(
        id: 'local:$fingerprint',
        title: 'Privé',
        artist: 'Moi',
        durationMs: 10,
        streamUrl: 'file:///private/music.mp3',
        coverUrl: 'file:///private/cover.png');
    final payload = mixedPlaylistPayload(
        MixedPlaylist(
            id: 'device:abc', name: 'Mix', trackIds: [track.id, personal.id]),
        [track, personal],
        0);
    expect(jsonEncode(payload), isNot(contains('/private')));
    expect((payload['entries'] as List).last['fingerprint'], fingerprint);
    expect((payload['entries'] as List).first['source'], 'sonora');
  });
  test(
      'remote conflict preserves local order and explicit resolution keeps a copy',
      () async {
    final p = (await library.createPlaylist('Local'))
        .edit(trackIds: [track.id, 'remote-2']);
    await library.savePlaylist(p);
    final adapter = SyncAdapter([
      {
        'id': p.id,
        'name': 'Distant',
        'revision': 2,
        'entries': [
          {
            'trackId': 'remote-3',
            'source': 'sonora',
            'title': 'Distant',
            'artist': 'A',
            'durationMs': 100
          }
        ],
        'deleted': false
      }
    ]);
    final sync = MixedPlaylistSync(library, Dio()..httpClientAdapter = adapter);
    expect(await sync.synchronize(), 1);
    expect((await library.playlists()).single.trackIds, p.trackIds);
    await sync.preserveLocalAndAcceptRemote(p.id);
    final playlists = await library.playlists();
    expect(playlists.firstWhere((x) => x.id == p.id).trackIds, ['remote-3']);
    expect(playlists.firstWhere((x) => x.id != p.id).trackIds, p.trackIds);
    expect(await library.store.all('playlist_conflicts'), isEmpty);
  });
  test('retry operations are stable and independent devices get distinct ids',
      () async {
    final p = await library.createPlaylist('Mix');
    final adapter = SyncAdapter([]);
    final sync = MixedPlaylistSync(library, Dio()..httpClientAdapter = adapter);
    await sync.synchronize();
    await sync.synchronize();
    expect(adapter.sent[0]['operationId'], adapter.sent[1]['operationId']);
    final second = DeviceLibrary(LocalStore(db, 'device-two'));
    await second.savePlaylist(p);
    final secondAdapter = SyncAdapter([]);
    await MixedPlaylistSync(second, Dio()..httpClientAdapter = secondAdapter)
        .synchronize();
    expect(secondAdapter.sent.single['operationId'],
        isNot(adapter.sent.first['operationId']));
  });
}
