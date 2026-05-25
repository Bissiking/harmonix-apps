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
  });

  final String? latestVersion;
  final String? minVersion;
  final bool forceUpdate;
  final bool updateAvailable;
  final String? downloadUrl;
}

Future<UpdateInfo?> checkForUpdate({
  required Dio dio,
  required PackageInfo packageInfo,
}) async {
  final currentVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
  final platform = _platformParam();
  final query = {
    'platform': platform,
    'app_version': currentVersion,
  };
  final payload = await _fetchFirstPayload(
    dio: dio,
    paths: const [
      '/api/harmonix/apps/v2/releases',
      '/api/harmonix/apps/v2/version',
      '/api/harmonix/apps/releases',
      '/api/harmonix/apps/version',
    ],
    queryParameters: query,
  );
  if (payload == null) return null;

  final latest = payload['latest_version'] as String?;
  final min = payload['min_version'] as String?;
  final downloadUrl = (payload['download_url'] as String?) ??
      _resolveFallbackDownloadUrl(dio.options.baseUrl, platform);

  final forceUpdate = _boolValue(payload['force_update']);
  final updateAvailable = _boolValue(payload['update_available']) ||
      _isNewerVersion(latest, currentVersion);

  if (kDebugMode) {
    debugPrint(
      'UpdateCheck current=$currentVersion latest=$latest '
      'platform=$platform force=$forceUpdate available=$updateAvailable url=$downloadUrl',
    );
  }

  return UpdateInfo(
    latestVersion: latest,
    minVersion: min,
    forceUpdate: forceUpdate,
    updateAvailable: updateAvailable,
    downloadUrl: downloadUrl,
  );
}

Future<Map<String, dynamic>?> _fetchFirstPayload({
  required Dio dio,
  required List<String> paths,
  required Map<String, dynamic> queryParameters,
}) async {
  for (final path in paths) {
    try {
      final response = await dio.get(path, queryParameters: queryParameters);
      final data = response.data;
      if (kDebugMode) {
        debugPrint('UpdateCheck $path response: $data');
      }
      final payload = _extractPayload(data);
      if (payload != null) return payload;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('UpdateCheck $path failed: $e');
      }
      continue;
    }
  }
  return null;
}

Map<String, dynamic>? _extractPayload(dynamic data) {
  if (data is! Map<String, dynamic>) return null;
  if (data['ok'] == true && data['data'] is Map<String, dynamic>) {
    return data['data'] as Map<String, dynamic>;
  }
  if (data.containsKey('latest_version') ||
      data.containsKey('min_version') ||
      data.containsKey('download_url') ||
      data.containsKey('update_available') ||
      data.containsKey('force_update')) {
    return data;
  }
  return null;
}

String _platformParam() {
  return switch (defaultTargetPlatform) {
    TargetPlatform.android => 'android',
    TargetPlatform.windows => 'windows',
    TargetPlatform.macOS => 'macos',
    _ => 'android',
  };
}

String _resolveFallbackDownloadUrl(String baseUrl, String platform) {
  final serverUri = Uri.tryParse(baseUrl);
  if (serverUri != null) {
    return serverUri.resolve('/harmonix/download/$platform').toString();
  }
  return '/harmonix/download/$platform';
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

bool _isNewerVersion(String? latest, String current) {
  if (latest == null || latest.isEmpty) return false;
  final latestParts = _parseVersion(latest);
  final currentParts = _parseVersion(current);
  for (var i = 0; i < 3; i++) {
    final l = latestParts[i];
    final c = currentParts[i];
    if (l != c) return l > c;
  }
  return latestParts[3] > currentParts[3];
}

List<int> _parseVersion(String version) {
  final parts = version.split('+');
  final nums = parts.first.split('.').map((e) => int.tryParse(e) ?? 0).toList();
  while (nums.length < 3) {
    nums.add(0);
  }
  final build = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
  return [nums[0], nums[1], nums[2], build];
}
