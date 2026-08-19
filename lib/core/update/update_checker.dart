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

class UpdateCheckException implements Exception {
  const UpdateCheckException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}

const String updateStoreBaseUrl = String.fromEnvironment(
  'HARMONIX_STORE_URL',
  defaultValue: 'https://store.mhemery.fr',
);

Future<UpdateInfo?> checkForUpdate({
  required PackageInfo packageInfo,
  Dio? client,
}) async {
  if (kIsWeb) return null;
  final currentVersion = packageInfo.version;
  final platform = _platformParam();
  if (platform == null) return null;
  final query = {
    'current_version': currentVersion,
    'platform': platform,
    'arch': 'universal',
    'channel': 'stable',
  };
  final payload = await _fetchStorePayload(
    client: client ?? _createStoreClient(),
    queryParameters: query,
  );

  final available = _boolValue(payload['available']);
  if (!available) {
    return UpdateInfo(
      latestVersion: null,
      minVersion: null,
      forceUpdate: false,
      updateAvailable: false,
      downloadUrl: null,
    );
  }

  final artifact = payload['artifact'];
  final artifactMap =
      artifact is Map ? Map<String, dynamic>.from(artifact) : null;

  final latestVersion = _stringValue(payload['version']);
  final rawDownloadUrl = _stringValue(artifactMap?['url']);
  final artifactSha256 = _stringValue(artifactMap?['sha256']);
  if (latestVersion == null ||
      rawDownloadUrl == null ||
      artifactSha256 == null) {
    throw const UpdateCheckException(
      'Réponse de mise à jour incomplète reçue du Store.',
      code: 'invalid_response',
    );
  }
  final downloadUrl =
      Uri.parse(updateStoreBaseUrl).resolve(rawDownloadUrl).toString();

  if (kDebugMode) {
    debugPrint(
      'UpdateCheck current=$currentVersion '
      'latest=$latestVersion platform=$platform '
      'available=true url=$downloadUrl',
    );
  }

  return UpdateInfo(
    latestVersion: latestVersion,
    minVersion: null,
    forceUpdate: false,
    updateAvailable: true,
    downloadUrl: downloadUrl,
    artifactFileName: _stringValue(artifactMap?['fileName']),
    artifactSize: artifactMap?['size'] is num
        ? (artifactMap!['size'] as num).toInt()
        : null,
    artifactSha256: artifactSha256,
    releaseNotes: _stringValue(payload['releaseNotes']),
  );
}

Future<Map<String, dynamic>> _fetchStorePayload({
  required Dio client,
  required Map<String, dynamic> queryParameters,
}) async {
  final uri = Uri.parse(updateStoreBaseUrl).replace(
    path: '/api/v1/apps/harmonix/updates',
    queryParameters: queryParameters,
  );
  try {
    final response = await client.getUri<dynamic>(uri);
    final data = response.data;
    if (kDebugMode) {
      debugPrint('UpdateCheck store response: $data');
    }
    if (data is Map && data['data'] is Map) {
      return Map<String, dynamic>.from(data['data'] as Map);
    }
    throw const UpdateCheckException(
      'Réponse invalide reçue du Store.',
      code: 'invalid_response',
    );
  } on UpdateCheckException {
    rethrow;
  } on DioException catch (error) {
    if (kDebugMode) {
      debugPrint('UpdateCheck store failed: $error');
    }
    final errorData = error.response?.data;
    final errorMap = errorData is Map && errorData['error'] is Map
        ? Map<String, dynamic>.from(errorData['error'] as Map)
        : null;
    final code = _stringValue(errorMap?['code']);
    final apiMessage = _stringValue(errorMap?['message']);
    throw UpdateCheckException(
      _updateErrorMessage(code, apiMessage),
      code: code,
    );
  }
}

Dio _createStoreClient() {
  return Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: const {'Accept': 'application/json'},
    ),
  );
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

  final expected = update.artifactSha256?.trim().toLowerCase() ?? '';
  if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(expected)) {
    throw const UpdateVerificationException(
      'Empreinte SHA-256 absente ou invalide.',
    );
  }

  final storeDio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(minutes: 10),
    ),
  );

  final dir = await Directory.systemTemp.createTemp('harmonix_update');
  final safeName = (update.artifactFileName ?? 'harmonix-update').replaceAll(
    RegExp(r'[^\w.\-]'),
    '_',
  );
  final file = File('${dir.path}${Platform.pathSeparator}$safeName');
  try {
    final response = await storeDio.get<ResponseBody>(
      downloadUrl,
      options: Options(responseType: ResponseType.stream),
    );

    final stream = response.data?.stream;
    if (stream == null) {
      throw const UpdateVerificationException(
        'Réponse de téléchargement vide',
      );
    }

    final digestSink = _DigestSink();
    final hasher = crypto.sha256.startChunkedConversion(digestSink);
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

    if (total > 0 && received != total) {
      throw UpdateVerificationException(
        'Taille du fichier invalide (attendue $total, reçue $received).',
      );
    }

    final digest = digestSink.digest?.toString().toLowerCase() ?? '';
    if (digest != expected) {
      throw UpdateVerificationException(
        'Empreinte SHA-256 invalide (attendue $expected, obtenue $digest)',
      );
    }
    return file;
  } catch (_) {
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
    rethrow;
  }
}

class _DigestSink implements Sink<crypto.Digest> {
  crypto.Digest? digest;

  @override
  void add(crypto.Digest event) => digest = event;

  @override
  void close() {}
}

String? _platformParam() {
  return switch (defaultTargetPlatform) {
    TargetPlatform.android => 'android',
    TargetPlatform.windows => 'windows',
    TargetPlatform.macOS => 'macos',
    TargetPlatform.linux => 'linux',
    TargetPlatform.iOS || TargetPlatform.fuchsia => null,
  };
}

bool get isDesktopPlatform {
  if (kIsWeb) return false;
  return switch (defaultTargetPlatform) {
    TargetPlatform.windows ||
    TargetPlatform.macOS ||
    TargetPlatform.linux =>
      true,
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

String? _stringValue(Object? value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

String _updateErrorMessage(String? code, String? apiMessage) {
  return switch (code) {
    'invalid_parameters' =>
      'La requête de mise à jour envoyée au Store est invalide.',
    'not_found' => 'Harmonix est introuvable dans le Store.',
    'rate_limited' =>
      'Trop de vérifications ont été effectuées. Réessayez plus tard.',
    _ => apiMessage ?? 'Impossible de joindre le service de mise à jour.',
  };
}
