import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:harmonix_apps/core/api/dio_provider.dart';

class CastRepository {
  CastRepository(this._dio);

  final Dio _dio;

  static const _riftBase = '/api/harmonix/apps/v2/rift/sessions';
  Future<String?> createSession({
    required String deviceId,
    String? userId,
    required Map<String, dynamic> state,
    int stateVersion = 1,
  }) async {
    final payload = {
      'device_id': deviceId,
      if (userId != null && userId.isNotEmpty) 'user_id': userId,
      'state_version': stateVersion,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      'state': state,
    };
    final response = await _postWithCompat(_riftBase, payload);
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final sessionId = data['session_id'] ?? data['id'];
      if (sessionId is String && sessionId.isNotEmpty) return sessionId;
    }
    return null;
  }

  Future<Map<String, dynamic>?> getSession(String sessionId) async {
    final response = await _getWithCompat('$_riftBase/$sessionId');
    final data = response.data;
    if (data is Map<String, dynamic>) return data;
    return null;
  }

  Future<void> joinSession(
    String sessionId, {
    required String deviceId,
    String? userId,
    String? code,
    String? role,
  }) async {
    final payload = {
      'device_id': deviceId,
      if (userId != null && userId.isNotEmpty) 'user_id': userId,
      if (code != null && code.isNotEmpty) 'code': code,
      if (role != null && role.isNotEmpty) 'role': role,
    };
    await _postWithCompat('$_riftBase/$sessionId/join', payload);
  }

  Future<void> updateSession(
    String sessionId, {
    required Map<String, dynamic> state,
    required int stateVersion,
    String? userId,
    required String deviceId,
  }) async {
    final payload = {
      'device_id': deviceId,
      if (userId != null && userId.isNotEmpty) 'user_id': userId,
      'state_version': stateVersion,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      'state': state,
    };
    await _patchWithCompat('$_riftBase/$sessionId/state', payload);
  }

  Future<void> sendStateAction(
    String sessionId, {
    required String deviceId,
    String? userId,
    required String action,
    Map<String, dynamic>? payload,
  }) async {
    final body = <String, dynamic>{
      'device_id': deviceId,
      if (userId != null && userId.isNotEmpty) 'user_id': userId,
      'action': action,
      if (payload != null) 'payload': payload,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    await _patchWithCompat('$_riftBase/$sessionId/state', body);
  }

  Future<void> endSession(String sessionId) async {
    await _deleteWithCompat('$_riftBase/$sessionId');
  }

  Future<Response<dynamic>> _postWithCompat(String riftUrl, Object? data) async {
    try {
      return await _dio.post(riftUrl, data: data);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 404 || status == 405) {
        return _dio.post(riftUrl.replaceFirst('/rift/', '/sync/'), data: data);
      }
      rethrow;
    }
  }

  Future<Response<dynamic>> _patchWithCompat(String riftUrl, Object? data) async {
    try {
      return await _dio.patch(riftUrl, data: data);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 404 || status == 405) {
        return _dio.patch(riftUrl.replaceFirst('/rift/', '/sync/'), data: data);
      }
      rethrow;
    }
  }

  Future<Response<dynamic>> _getWithCompat(String riftUrl) async {
    try {
      return await _dio.get(riftUrl);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 404 || status == 405) {
        return _dio.get(riftUrl.replaceFirst('/rift/', '/sync/'));
      }
      rethrow;
    }
  }

  Future<Response<dynamic>> _deleteWithCompat(String riftUrl) async {
    try {
      return await _dio.delete(riftUrl);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 404 || status == 405) {
        return _dio.delete(riftUrl.replaceFirst('/rift/', '/sync/'));
      }
      rethrow;
    }
  }
}

final castRepositoryProvider = Provider<CastRepository>((ref) {
  return CastRepository(ref.watch(dioProvider));
});
