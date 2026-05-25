import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:harmonix_apps/core/api/clients/catalog_client.dart';
import 'package:harmonix_apps/core/api/dio_provider.dart';

part 'catalog_client_provider.g.dart';

@Riverpod(keepAlive: true)
CatalogClient catalogClient(CatalogClientRef ref) {
  return CatalogClient(ref.watch(dioProvider));
}
