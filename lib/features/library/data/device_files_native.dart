// device_files_native.dart
import 'dart:io';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:harmonix_apps/core/models/track.dart';
import 'package:harmonix_apps/features/library/domain/music_source.dart';

const supportsDeviceFiles = true;
const _extensions = ['mp3', 'flac', 'm4a', 'aac', 'ogg', 'opus', 'wav'];
Future<String> mediaDirectory(String scope) async {
  final root = await getApplicationSupportDirectory();
  final dir = Directory(p.join(root.path, 'media', scope));
  await dir.create(recursive: true);
  return dir.path;
}

Future<bool> deviceFileExists(String path) => File(path).exists();

Future<bool> verifyDeviceFile(DeviceTrack file) =>
    compute(_verifyFile, [file.path, file.fingerprint, file.bytes]);
Future<bool> _verifyFile(List<Object> data) async {
  final file = File(data[0] as String);
  if (!await file.exists() || await file.length() != data[2]) return false;
  return (await sha256.bind(file.openRead()).first).toString() == data[1];
}

Future<void> removeDeviceFile(String path, String scope) async {
  final root = await mediaDirectory(scope);
  final target = p.normalize(p.absolute(path));
  if (!p.isWithin(root, target)) throw StateError('Unsafe media path');
  final file = File(target);
  if (await file.exists()) await file.delete();
}

Future<List<DeviceTrack>> pickAudioFiles(String scope,
    {bool folder = false}) async {
  final paths = <String>[];
  if (folder) {
    final dir = await FilePicker.platform.getDirectoryPath();
    if (dir == null) return [];
    await for (final entry
        in Directory(dir).list(recursive: true, followLinks: false)) {
      if (entry is File &&
          _extensions
              .map((e) => '.$e')
              .contains(p.extension(entry.path).toLowerCase())) {
        paths.add(entry.path);
      }
    }
  } else {
    final picked = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: _extensions);
    if (picked == null) return [];
    paths.addAll(picked.files.map((file) => file.path).whereType<String>());
  }
  final result = <DeviceTrack>[];
  final directory = await mediaDirectory(scope);
  for (final path in paths) {
    result.add(await compute(_importFile, [path, directory]));
  }
  return result;
}

Future<DeviceTrack> _importFile(List<String> arguments) async {
  final input = File(arguments[0]);
  final digest = (await sha256.bind(input.openRead()).first).toString();
  final output =
      p.join(arguments[1], '$digest${p.extension(input.path).toLowerCase()}');
  if (!await File(output).exists()) await input.copy(output);
  String? artwork;
  var title = p.basenameWithoutExtension(input.path);
  var artist = 'Artiste inconnu';
  String? album;
  var duration = 0;
  try {
    final metadata = readMetadata(File(output), getImage: true);
    if (metadata.title?.trim().isNotEmpty == true) title = metadata.title!;
    if (metadata.artist?.trim().isNotEmpty == true) artist = metadata.artist!;
    album = metadata.album;
    duration = metadata.duration?.inMilliseconds ?? 0;
    if (metadata.pictures.isNotEmpty) {
      artwork = p.join(arguments[1], '$digest.cover');
      await File(artwork)
          .writeAsBytes(metadata.pictures.first.bytes, flush: true);
    }
  } catch (_) {/* Unsupported tags: keep the real file name. */}
  return DeviceTrack(
      track: Track(
          id: 'local:$digest',
          title: title,
          artist: artist,
          album: album,
          durationMs: duration),
      source: MusicSource.personal,
      path: output,
      fingerprint: digest,
      bytes: await File(output).length(),
      artworkPath: artwork);
}

Future<DeviceTrack> downloadAudio(
    Track track,
    String scope,
    String url,
    Map<String, String>? headers,
    void Function(int, int) progress,
    dynamic cancelToken,
    {bool temporary = false}) async {
  final dir = await mediaDirectory(scope);
  final key =
      '${temporary ? "cache_" : ""}${sha256.convert(track.id.codeUnits)}';
  final partial = File(p.join(dir, '$key.part'));
  final client = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(minutes: 3)));
  try {
    // Restart safely when no verified Range/ETag contract is available.
    final response = await client.download(url, partial.path,
        options: Options(headers: headers),
        cancelToken: cancelToken as CancelToken?,
        onReceiveProgress: progress,
        deleteOnError: true);
    final bytes = await partial.length();
    final type = response.headers.value('content-type') ?? '';
    if (bytes == 0 || type.contains('text/') || type.contains('json')) {
      throw StateError('Le serveur ne fournit pas un fichier audio.');
    }
    final expected =
        int.tryParse(response.headers.value('content-length') ?? '');
    if (expected != null && expected != bytes) {
      throw StateError('Téléchargement incomplet');
    }
    final digest = (await sha256.bind(partial.openRead()).first).toString();
    final extension = switch (type.split(';').first.trim()) {
      'audio/mpeg' || 'audio/mp3' => 'mp3',
      'audio/flac' || 'audio/x-flac' => 'flac',
      'audio/mp4' || 'audio/x-m4a' => 'm4a',
      'audio/ogg' || 'application/ogg' => 'ogg',
      'audio/wav' || 'audio/x-wav' || 'audio/wave' => 'wav',
      'audio/aac' => 'aac',
      _ => 'audio',
    };
    final finalFile = File(p.join(dir, '$key.$extension'));
    await partial.rename(finalFile.path);
    return DeviceTrack(
        track: track,
        source: MusicSource.downloaded,
        path: finalFile.path,
        fingerprint: digest,
        bytes: bytes);
  } finally {
    client.close(force: true);
    if (await partial.exists()) await partial.delete();
  }
}
