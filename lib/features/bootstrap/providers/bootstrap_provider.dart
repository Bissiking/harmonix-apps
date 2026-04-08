import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/models/bootstrap_config.dart';
import '../data/bootstrap_repository.dart';

part 'bootstrap_provider.g.dart';

@Riverpod(keepAlive: true)
Future<BootstrapConfig> bootstrap(BootstrapRef ref) {
  return ref.watch(bootstrapRepositoryProvider).fetch();
}
