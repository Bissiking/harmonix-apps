// local_store.dart
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:harmonix_apps/core/settings/settings_repository.dart';
import 'package:harmonix_apps/core/settings/auth_token_provider.dart';
import 'package:harmonix_apps/core/storage/database_native.dart'
    if (dart.library.js_interop) 'database_web.dart';

/// Account-scoped records, with transactional replacement and schema migrations.
class LocalStore {
  LocalStore(this.database, this.scope);
  final DatabaseExecutor database;
  final String scope;

  static Future<LocalStore> open(String scope) async {
    final db = await openLocalDatabase();
    return LocalStore(db, scope);
  }

  static Future<void> createSchema(Database db, int version) async {
    await db.execute('''CREATE TABLE records (
      scope TEXT NOT NULL, bucket TEXT NOT NULL, id TEXT NOT NULL,
      data TEXT NOT NULL, PRIMARY KEY(scope, bucket, id))''');
  }

  Future<Map<String, dynamic>?> get(String bucket, String id) async {
    final rows = await database.query('records',
        columns: ['data'],
        where: 'scope = ? AND bucket = ? AND id = ?',
        whereArgs: [scope, bucket, id]);
    return rows.isEmpty
        ? null
        : jsonDecode(rows.first['data'] as String) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> all(String bucket) async {
    final rows = await database.query('records',
        columns: ['data'],
        where: 'scope = ? AND bucket = ?',
        whereArgs: [scope, bucket]);
    return rows
        .map((row) => jsonDecode(row['data'] as String) as Map<String, dynamic>)
        .toList();
  }

  Future<void> put(String bucket, String id, Map<String, dynamic> data) async {
    await database.insert('records',
        {'scope': scope, 'bucket': bucket, 'id': id, 'data': jsonEncode(data)},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> remove(String bucket, String id) async {
    await database.delete('records',
        where: 'scope = ? AND bucket = ? AND id = ?',
        whereArgs: [scope, bucket, id]);
  }

  Future<void> replace(
      String bucket, Map<String, Map<String, dynamic>> records) async {
    await (database as Database).transaction((txn) async {
      await txn.delete('records',
          where: 'scope = ? AND bucket = ?', whereArgs: [scope, bucket]);
      final batch = txn.batch();
      for (final entry in records.entries) {
        batch.insert('records', {
          'scope': scope,
          'bucket': bucket,
          'id': entry.key,
          'data': jsonEncode(entry.value)
        });
      }
      await batch.commit(noResult: true);
    });
  }
}

final libraryScopeProvider = Provider<String>((ref) {
  ref.watch(authTokenProvider);
  return ref.watch(settingsRepositoryProvider).libraryScope;
});
final localStoreProvider = FutureProvider<LocalStore>((ref) {
  return LocalStore.open(ref.watch(libraryScopeProvider));
});
