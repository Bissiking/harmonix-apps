import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:harmonix_apps/core/api/dio_provider.dart';

class CastRepository {
  CastRepository(this._dio);

  final Dio _dio;

  Future<String?> createSession({
    required String trackId,
    required int positionMs,
    required bool isPlaying,
    double? volume,
  }) async {
    final response = await _dio.post(
      '/api/harmonix/apps/v2/cast/sessions',
      data: {
        'track_id': trackId,
        'position_ms': positionMs,
        'is_playing': isPlaying,
        if (volume != null) 'volume': volume,
      },
    );
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final sessionId = data['session_id'] ?? data['id'];
      if (sessionId is String && sessionId.isNotEmpty) return sessionId;
    }
    return null;
  }

  Future<void> updateSession(
    String sessionId, {
    String? trackId,
    int? positionMs,
    bool? isPlaying,
    double? volume,
  }) async {
    await _dio.patch(
      '/api/harmonix/apps/v2/cast/sessions/$sessionId',
      data: {
        if (trackId != null) 'track_id': trackId,
        if (positionMs != null) 'position_ms': positionMs,
        if (isPlaying != null) 'is_playing': isPlaying,
        if (volume != null) 'volume': volume,
      },
    );
  }

  Future<void> endSession(String sessionId) async {
    await _dio.delete('/api/harmonix/apps/v2/cast/sessions/$sessionId');
  }
}

final castRepositoryProvider = Provider<CastRepository>((ref) {
  return CastRepository(ref.watch(dioProvider));
});
