import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:harmonix_apps/core/api/dio_provider.dart';
import 'package:harmonix_apps/core/session/auth_session_tokens.dart';

/// Client côté app pour le SSO OAuth2 via le relais web.
///
/// Le relais web (player Harmonix) est le seul à connaître le
/// `client_secret` Kyros : il exécute le flow authorization_code et met le
/// token à disposition de l'app via un `state` éphémère.
class SsoRepository {
  SsoRepository(this._dio);

  final Dio _dio;

  static const _ssoBase = '/api/harmonix/apps/v2/sso';

  /// Ouvre le flow SSO : renvoie l'URL du relais à ouvrir dans le navigateur.
  Future<String?> start(String state, {String? platform}) async {
    final response = await _dio.get<dynamic>(
      '$_ssoBase/start',
      queryParameters: {
        'state': state,
        if (platform != null && platform.isNotEmpty) 'platform': platform,
      },
    );
    final data = response.data;
    if (data is! Map<String, dynamic>) return null;
    final url = data['authorize_url'] ?? data['url'];
    return url is String && url.isNotEmpty ? url : null;
  }

  /// Interroge le relais pour récupérer le token une fois le flow terminé.
  Future<AuthSessionTokens?> getTokens(String state) async {
    final response = await _dio.get<dynamic>(
      '$_ssoBase/status',
      queryParameters: {'state': state},
    );
    final data = response.data;
    if (data is! Map<String, dynamic>) return null;
    return AuthSessionTokens.fromJson(data);
  }
}

final ssoRepositoryProvider = Provider<SsoRepository>((ref) {
  return SsoRepository(ref.watch(dioProvider));
});
