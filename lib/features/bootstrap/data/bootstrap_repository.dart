import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/dio_provider.dart';
import '../../../core/models/bootstrap_config.dart';

part 'bootstrap_repository.g.dart';

class BootstrapRepository {
  BootstrapRepository(this._dio);

  final Dio _dio;

  Future<BootstrapConfig> fetch() async {
    final response = await _dio.get('/api/harmonix/apps/bootstrap');
    return BootstrapConfig.fromJson(response.data as Map<String, dynamic>);
  }
}

@Riverpod(keepAlive: true)
BootstrapRepository bootstrapRepository(BootstrapRepositoryRef ref) {
  return BootstrapRepository(ref.watch(dioProvider));
}
