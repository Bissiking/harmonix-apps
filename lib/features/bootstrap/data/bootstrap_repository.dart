import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/dio_provider.dart';
import '../../../core/models/bootstrap_config.dart';

part 'bootstrap_repository.g.dart';

class BootstrapRepository {
  BootstrapRepository(this._dio);

  final Dio _dio;
  BootstrapConfig? _lastConfig;

  Future<BootstrapConfig> fetch() async {
    try {
      final response = await _withTransientRetry(
        () => _dio.get('/api/harmonix/apps/bootstrap'),
      );
      final config = BootstrapConfig.fromJson(response.data as Map<String, dynamic>);
      _lastConfig = config;
      return config;
    } on DioException catch (e) {
      final status = e.response?.statusCode ?? 0;
      if (status == 502 || status == 503 || status == 504) {
        return _lastConfig ?? const BootstrapConfig();
      }
      rethrow;
    }
  }

  Future<Response<dynamic>> _withTransientRetry(
    Future<Response<dynamic>> Function() action, {
    int maxAttempts = 3,
  }) async {
    Object? lastError;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        return await action();
      } catch (error) {
        lastError = error;
        if (error is! DioException) rethrow;
        final status = error.response?.statusCode ?? 0;
        final isTransient = status == 502 || status == 503 || status == 504;
        if (!isTransient || attempt == maxAttempts) rethrow;
        await Future<void>.delayed(Duration(milliseconds: 250 * attempt));
      }
    }
    throw lastError ?? StateError('Unexpected retry failure');
  }
}

@Riverpod(keepAlive: true)
BootstrapRepository bootstrapRepository(BootstrapRepositoryRef ref) {
  return BootstrapRepository(ref.watch(dioProvider));
}
