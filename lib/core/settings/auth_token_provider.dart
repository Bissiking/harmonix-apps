import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'settings_repository.dart';

final authTokenProvider = Provider<String?>((ref) {
  return ref.watch(settingsRepositoryProvider).authToken;
});
