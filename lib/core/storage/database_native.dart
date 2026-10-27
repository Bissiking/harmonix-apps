// database_native.dart
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' as mobile;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:harmonix_apps/core/storage/local_store.dart';

Future<Database> openLocalDatabase() async {
  final directory = await getApplicationSupportDirectory();
  final DatabaseFactory factory;
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    factory = databaseFactoryFfi;
  } else {
    factory = mobile.databaseFactory;
  }
  return factory.openDatabase(p.join(directory.path, 'harmonix-v4.sqlite'),
      options:
          OpenDatabaseOptions(version: 1, onCreate: LocalStore.createSchema));
}
