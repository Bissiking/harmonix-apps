import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

class UpdateInfo {
  UpdateInfo({
    required this.latestVersion,
    required this.minVersion,
    required this.forceUpdate,
    required this.updateAvailable,
    required this.downloadUrl,
    this.artifactFileName,
    this.artifactSize,
    this.artifactSha256,
    this.releaseNotes,
  });

  final String? latestVersion;
  final String? minVersion;
  final bool forceUpdate;
  final bool updateAvailable;
  final String? downloadUrl;
  final String? artifactFileName;
  final int? artifactSize;
  final String? artifactSha256;
  final String? releaseNotes;
}

class UpdateVerificationException implements Exception {
  const UpdateVerificationException(this.message);

  final String message;

  @override
  String toString() => message;
}

const String updateStoreBaseUrl = String.fromEnvironment(
  'HARMONIX_STORE_URL',
  defaultValue: 'https://store.mhemery.fr',
);

Future<UpdateInfo?> checkForUpdate({
  required Dio dio,
  required PackageInfo packageInfo,
}) async {
  if (kIsWeb) return null;
  final currentVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
  final platform = _platformParam();
  final query = {
    'current_version': currentVersion,
    'platform': platform,
    'arch': 'universal',
    'channel': 'stable',
  };
  final payload = await _fetchStorePayload(dio: dio, queryParameters: query);
  if (payload == null) return null;

  final available = _boolValue(payload['available']);
  if (!available) {
    return UpdateInfo(
      latestVersion: payload['currentVersion'] as String?,
      minVersion: null,
      forceUpdate: false,
      updateAvailable: false,
      downloadUrl: null,
    );
  }

  final artifact = payload['artifact'];
  final artifactMap = artifact is Map<String, dynamic> ? artifact : null;

  final downloadUrl = artifactMap?['url'] as String?;

  if (kDebugMode) {
    debugPrint(
      'UpdateCheck current=$currentVersion '
      'latest=${payload['version']} platform=$platform '
      'available=true url=$downloadUrl',
    );
  }

  return UpdateInfo(
    latestVersion: payload['version'] as String?,
    minVersion: null,
    forceUpdate: false,
    updateAvailable: true,
    downloadUrl: downloadUrl,
    artifactFileName: artifactMap?['fileName'] as String?,
    artifactSize: artifactMap?['size'] is num
        ? (artifactMap!['size'] as num).toInt()
        : null,
    artifactSha256: artifactMap?['sha256'] as String?,
    releaseNotes: payload['releaseNotes'] as String?,
  );
}

Future<Map<String, dynamic>?> _fetchStorePayload({
  required Dio dio,
  required Map<String, dynamic> queryParameters,
}) async {
  final uri = Uri.parse('$updateStoreBaseUrl/api/v1/apps/harmonix/updates')
      .replace(queryParameters: queryParameters);
  try {
    final response = await dio.getUri<dynamic>(uri);
    final data = response.data;
    if (kDebugMode) {
      debugPrint('UpdateCheck store response: $data');
    }
    if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
      return data['data'] as Map<String, dynamic>;
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('UpdateCheck store failed: $e');
    }
  }
  return null;
}

/// Télécharge l'artefact vers un fichier temporaire en calculant son
/// empreinte SHA-256 à la volée, puis vérifie qu'elle correspond à celle
/// annoncée par le store avant de le proposer à l'installation.
Future<File> downloadArtifactAndVerify({
  required UpdateInfo update,
  void Function(int received, int total)? onProgress,
}) async {
  final downloadUrl = update.downloadUrl;
  if (downloadUrl == null || downloadUrl.isEmpty) {
    throw const UpdateVerificationException('URL de téléchargement manquante');
  }
  if (kIsWeb) {
    throw UnsupportedError(
      'Web ne permet pas de vérifier un artefact local',
    );
  }

  final storeDio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(minutes: 10),
    ),
  );

  final dir = await Directory.systemTemp.createTemp('harmonix_update');
  final safeName =
      (update.artifactFileName ?? 'harmonix-update').replaceAll(
            RegExp(r'[^\w.\-]'),
            '_',
          );
  final file = File('${dir.path}${Platform.pathSeparator}$safeName');

  final digestSink = _DigestSink();
  final hasher = crypto.sha256.startChunkedConversion(digestSink);

  final response = await storeDio.get<ResponseBody>(
    downloadUrl,
    options: Options(responseType: ResponseType.stream),
  );

  final stream = response.data?.stream;
  if (stream == null) {
    hasher.close();
    throw const UpdateVerificationException('Réponse de téléchargement vide');
  }

  final raf = await file.open(mode: FileMode.write);
  var received = 0;
  final total = update.artifactSize ?? 0;
  try {
    await for (final chunk in stream) {
      await raf.writeFrom(chunk);
      hasher.add(chunk);
      received += chunk.length;
      onProgress?.call(received, total);
    }
  } finally {
    await raf.close();
    hasher.close();
  }

  final expected = update.artifactSha256?.trim().toLowerCase() ?? '';
  final digest = digestSink.digest?.toString().toLowerCase() ?? '';
  if (expected.isNotEmpty && digest != expected) {
    throw UpdateVerificationException(
      'Empreinte SHA-256 invalide (attendue $expected, obtenue $digest)',
    );
  }
  return file;
}

class _DigestSink implements Sink<crypto.Digest> {
  crypto.Digest? digest;

  @override
  void add(crypto.Digest event) => digest = event;

  @override
  void close() {}
}

String _platformParam() {
  return switch (defaultTargetPlatform) {
    TargetPlatform.windows => 'windows',
    TargetPlatform.macOS => 'macos',
    TargetPlatform.linux => 'linux',
    _ => 'android',
  };
}

bool get isDesktopPlatform {
  if (kIsWeb) return false;
  return switch (defaultTargetPlatform) {
    TargetPlatform.windows ||
    TargetPlatform.macOS ||
    TargetPlatform.linux => true,
    _ => false,
  };
}

bool _boolValue(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.toLowerCase();
    return normalized == 'true' ||
        normalized == '1' ||
        normalized == 'yes' ||
        normalized == 'on';
  }
  return false;
}