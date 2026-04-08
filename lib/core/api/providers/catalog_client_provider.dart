import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../clients/catalog_client.dart';
import '../dio_provider.dart';

part 'catalog_client_provider.g.dart';

@Riverpod(keepAlive: true)
CatalogClient catalogClient(CatalogClientRef ref) {
  return CatalogClient(ref.watch(dioProvider));
}
