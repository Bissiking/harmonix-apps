// database_web.dart
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:harmonix_apps/core/storage/local_store.dart';

Future<Database> openLocalDatabase() =>
    databaseFactoryFfiWeb.openDatabase('harmonix-v4.sqlite',
        options:
            OpenDatabaseOptions(version: 1, onCreate: LocalStore.createSchema));
