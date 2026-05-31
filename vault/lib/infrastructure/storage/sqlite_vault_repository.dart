import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/errors.dart';
import '../../domain/models/vault_entry.dart';
import '../../domain/repositories/vault_repository.dart';

class SqliteVaultRepository implements VaultRepository {
  static const _dbName = 'vault.db';
  static const _tableName = 'entries';
  static const _version = 1;

  Database? _db;

  Future<Database> get _database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _version,
      onCreate: (db, version) => db.execute('''
        CREATE TABLE $_tableName (
          id TEXT PRIMARY KEY,
          app_name TEXT NOT NULL,
          username TEXT NOT NULL,
          encrypted_password TEXT NOT NULL,
          iv TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      '''),
    );
  }

  @override
  Future<List<VaultEntry>> getAll() async {
    try {
      final db = await _database;
      final rows = await db.query(
        _tableName,
        orderBy: 'app_name ASC',
      );
      return rows.map(VaultEntry.fromJson).toList();
    } catch (e) {
      throw StorageException('Failed to load entries: $e');
    }
  }

  @override
  Future<VaultEntry?> getById(String id) async {
    try {
      final db = await _database;
      final rows = await db.query(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      return VaultEntry.fromJson(rows.first);
    } catch (e) {
      throw StorageException('Failed to get entry: $e');
    }
  }

  @override
  Future<void> insert(VaultEntry entry) async {
    try {
      final db = await _database;
      await db.insert(
        _tableName,
        entry.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw StorageException('Failed to insert entry: $e');
    }
  }

  @override
  Future<void> update(VaultEntry entry) async {
    try {
      final db = await _database;
      await db.update(
        _tableName,
        entry.toJson(),
        where: 'id = ?',
        whereArgs: [entry.id],
      );
    } catch (e) {
      throw StorageException('Failed to update entry: $e');
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      final db = await _database;
      await db.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw StorageException('Failed to delete entry: $e');
    }
  }
}
