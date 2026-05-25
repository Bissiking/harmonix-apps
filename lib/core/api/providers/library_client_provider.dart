import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:harmonix_apps/core/api/clients/library_client.dart';
import 'package:harmonix_apps/core/api/dio_provider.dart';

part 'library_client_provider.g.dart';

@Riverpod(keepAlive: true)
LibraryClient libraryClient(LibraryClientRef ref) {
  return LibraryClient(ref.watch(dioProvider));
}
