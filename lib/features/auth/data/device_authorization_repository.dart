import 'package:dio/dio.dart';
import 'package:harmonix_apps/core/session/auth_session_tokens.dart';

/// Public metadata only. Sonora keeps its confidential client credentials.
class DeviceLoginConfiguration {
  const DeviceLoginConfiguration(
      this.clientId, this.authorize, this.token, this.scope);
  final String clientId;
  final Uri authorize;
  final Uri token;
  final String scope;

  factory DeviceLoginConfiguration.fromJson(Map<String, dynamic> data) {
    final authorize = deviceLoginUri(data['device_authorization_endpoint']);
    final token = deviceLoginUri(data['token_endpoint']);
    final client = data['client_id'];
    if (client is! String ||
        client.isEmpty ||
        authorize.origin != token.origin) {
      throw const FormatException('Invalid device configuration');
    }
    return DeviceLoginConfiguration(
        client, authorize, token, data['scope'] as String? ?? 'profile');
  }
}

Uri deviceLoginUri(Object? value) {
  final uri = value is String ? Uri.tryParse(value) : null;
  if (uri == null ||
      !uri.hasAuthority ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty ||
      uri.hasFragment ||
      (uri.scheme != 'https' &&
          !(uri.scheme == 'http' &&
              ['localhost', '127.0.0.1', '::1'].contains(uri.host)))) {
    throw const FormatException('Invalid device URL');
  }
  return uri;
}

class DeviceAuthorization {
  const DeviceAuthorization(
      {required this.deviceCode,
      required this.userCode,
      required this.verificationUri,
      required this.verificationUriComplete,
      required this.expiresIn,
      required this.interval});
  // Never render, persist or log this bearer capability.
  final String deviceCode;
  final String userCode;
  final Uri verificationUri;
  final Uri verificationUriComplete;
  final Duration expiresIn;
  final Duration interval;

  factory DeviceAuthorization.fromJson(Map<String, dynamic> data, Uri issuer) {
    final manual = deviceLoginUri(data['verification_uri']);
    final complete = deviceLoginUri(data['verification_uri_complete']);
    final code = data['device_code'];
    final user = data['user_code'];
    final expiry = data['expires_in'];
    final interval = data['interval'] ?? 5;
    if (manual.origin != issuer.origin ||
        complete.origin != issuer.origin ||
        manual.hasQuery ||
        complete.path != manual.path ||
        complete.queryParametersAll.length != 1 ||
        complete.queryParametersAll['user_code']?.length != 1 ||
        complete.queryParameters['user_code'] != user ||
        code is! String ||
        code.isEmpty ||
        user is! String ||
        !RegExp(r'^[A-Z]{4}-[A-Z]{4}$').hasMatch(user) ||
        expiry is! int ||
        expiry <= 0 ||
        expiry > 600 ||
        interval is! int ||
        interval < 1 ||
        interval > 600) {
      throw const FormatException('Invalid device authorization');
    }
    return DeviceAuthorization(
        deviceCode: code,
        userCode: user,
        verificationUri: manual,
        verificationUriComplete: complete,
        expiresIn: Duration(seconds: expiry),
        interval: Duration(seconds: interval));
  }
}

class DeviceLoginFailure implements Exception {
  const DeviceLoginFailure(this.code, {this.retryAfter});
  final String code;
  final Duration? retryAfter;
}

class DeviceAuthorizationRepository {
  DeviceAuthorizationRepository(this.client, this.sonoraBase);
  final Dio client;
  final String sonoraBase;

  Future<Map<String, dynamic>> _request(String url,
      {Map<String, dynamic>? body}) async {
    final response = await client.request<dynamic>(url,
        data: body,
        options: Options(
            method: body == null ? 'GET' : 'POST',
            contentType: Headers.jsonContentType,
            followRedirects: false,
            validateStatus: (status) => status != null && status < 600));
    final payload = response.data;
    if (response.statusCode != 200) {
      final rawRetry =
          int.tryParse(response.headers.value('retry-after') ?? '');
      final code = response.statusCode == 429
          ? 'temporarily_unavailable'
          : (response.statusCode! >= 500
              ? 'temporarily_unavailable'
              : (payload is Map ? payload['error'] : null));
      throw DeviceLoginFailure(code is String ? code : 'unavailable',
          retryAfter: rawRetry != null && rawRetry > 0
              ? Duration(seconds: rawRetry.clamp(1, 600))
              : null);
    }
    if (payload is! Map<String, dynamic>) {
      throw const FormatException('Invalid response');
    }
    return payload['data'] is Map<String, dynamic>
        ? payload['data'] as Map<String, dynamic>
        : payload;
  }

  Future<DeviceLoginConfiguration> configuration() async {
    final base = sonoraBase.replaceFirst(RegExp(r'/+$'), '');
    deviceLoginUri(base);
    return DeviceLoginConfiguration.fromJson(
        await _request('$base/api/harmonix/apps/v2/sso/device-config'));
  }

  Future<DeviceAuthorization> authorize(
          DeviceLoginConfiguration configuration) async =>
      DeviceAuthorization.fromJson(
          await _request(configuration.authorize.toString(), body: {
            'client_id': configuration.clientId,
            'scope': configuration.scope,
            'device_name': 'Harmonix TV',
          }),
          configuration.authorize);

  Future<AuthSessionTokens> poll(
      DeviceLoginConfiguration configuration, String code) async {
    final data = await _request(configuration.token.toString(), body: {
      'client_id': configuration.clientId,
      'device_code': code,
      'grant_type': 'urn:ietf:params:oauth:grant-type:device_code',
    });
    final tokens = AuthSessionTokens.fromJson(data);
    if (tokens == null) throw const FormatException('Invalid tokens');
    return tokens;
  }
}
