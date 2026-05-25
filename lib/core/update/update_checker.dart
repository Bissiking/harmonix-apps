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
  final response = await dio.get(
    '/api/harmonix/apps/v2/version',
    queryParameters: {'app_version': currentVersion},
  );
  final data = response.data;
  if (kDebugMode) {
    debugPrint('UpdateCheck response: $data');
  }
  if (data is! Map<String, dynamic>) {
    return null;
  }
  Map<String, dynamic>? payload;
  if (data['ok'] == true && data['data'] is Map<String, dynamic>) {
    payload = data['data'] as Map<String, dynamic>;
  } else if (data.containsKey('latest_version') ||
      data.containsKey('min_version') ||
      data.containsKey('download_url')) {
    payload = data;
  } else {
    return null;
  }

  final latest = payload['latest_version'] as String?;
  final min = payload['min_version'] as String?;
  final downloadUrl = _resolveAndroidDownloadUrl(dio.options.baseUrl);

  final forceUpdate = _boolValue(payload['force_update']);
  final updateAvailable =
      _boolValue(payload['update_available']) ||
      _isNewerVersion(latest, currentVersion);

  if (kDebugMode) {
    debugPrint(
      'UpdateCheck current=$currentVersion latest=$latest '
      'force=$forceUpdate available=$updateAvailable url=$downloadUrl',
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

String _resolveAndroidDownloadUrl(String baseUrl) {
  final serverUri = Uri.tryParse(baseUrl);
  if (serverUri != null) {
    return serverUri.resolve('/harmonix/download/android').toString();
  }
  return '/harmonix/download/android';
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
  final nums =
      parts.first.split('.').map((e) => int.tryParse(e) ?? 0).toList();
  while (nums.length < 3) {
    nums.add(0);
  }
  final build = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
  return [nums[0], nums[1], nums[2], build];
}
