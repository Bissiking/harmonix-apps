// device_files_web.dart
import 'package:harmonix_apps/core/models/track.dart';
import 'package:harmonix_apps/features/library/domain/music_source.dart';

const supportsDeviceFiles = false;
Future<List<DeviceTrack>> pickAudioFiles(String scope,
        {bool folder = false}) async =>
    throw UnsupportedError(
        'Les imports persistants sont disponibles dans les applications natives.');
Future<bool> deviceFileExists(String path) async => false;
Future<bool> verifyDeviceFile(DeviceTrack file) async => false;
Future<String> mediaDirectory(String scope) async =>
    throw UnsupportedError('Stockage natif requis');
Future<void> removeDeviceFile(String path, String scope) async =>
    throw UnsupportedError('Stockage natif requis');
Future<DeviceTrack> downloadAudio(
        Track track,
        String scope,
        String url,
        Map<String, String>? headers,
        void Function(int, int) progress,
        dynamic cancelToken,
        {bool temporary = false}) async =>
    throw UnsupportedError('Téléchargement natif requis');
