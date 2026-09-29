import 'dart:io' show Platform;

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/account.dart';
import '../models/app_data.dart';
import '../models/category.dart';
import '../models/transaction_record.dart';
import 'ledger_store.dart';

/// SQLite backed [LedgerStore].
class SqfliteLedgerStore implements LedgerStore {
  SqfliteLedgerStore({String? databasePathOverride})
      : _databasePathOverride = databasePathOverride;

  static const String _fileName = 'ledger.db';
  static const int _version = 1;

  final String? _databasePathOverride;
  Database? _database;

  /// iOS and Android hand back their databases directory; on macOS the
  /// database lives in the app container's Application Support folder, which
  /// the sandbox allows and which survives app upgrades.
  Future<String> _resolvePath() async {
    final override = _databasePathOverride;
    if (override != null) return override;
    if (Platform.isIOS || Platform.isAndroid) {
      return p.join(await getDatabasesPath(), _fileName);
    }
    final directory = await getApplicationSupportDirectory();
    await directory.create(recursive: true);
    return p.join(directory.path, _fileName);
  }

  Future<Database> get _db async {
    final existing = _database;
    if (existing != null) return existing;
    final path = await _resolvePath();
    final opened = await openDatabase(
      path,
      version: _version,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async {
        final batch = db.batch();
        batch.execute('''
          CREATE TABLE categories(
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            icon TEXT NOT NULL,
            color INTEGER NOT NULL,
            type TEXT NOT NULL,
            sort_order INTEGER NOT NULL DEFAULT 0,
            is_system INTEGER NOT NULL DEFAULT 0
          )
        ''');
        batch.execute('''
          CREATE TABLE accounts(
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            icon TEXT NOT NULL,
            color INTEGER NOT NULL,
            kind TEXT NOT NULL DEFAULT 'other',
            initial_balance INTEGER NOT NULL DEFAULT 0,
            sort_order INTEGER NOT NULL DEFAULT 0,
            is_system INTEGER NOT NULL DEFAULT 0
          )
        ''');
        batch.execute('''
          CREATE TABLE records(
            id TEXT PRIMARY KEY,
            type TEXT NOT NULL,
            amount INTEGER NOT NULL,
            category_id TEXT NOT NULL,
            account_id TEXT NOT NULL,
            note TEXT NOT NULL DEFAULT '',
            date INTEGER NOT NULL,
            created_at INTEGER NOT NULL
          )
        ''');
        batch.execute('''
          CREATE TABLE settings(
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
        batch.execute('CREATE INDEX idx_records_date ON records(date DESC)');
        batch.execute(
          'CREATE INDEX idx_records_category ON records(category_id)',
        );
        batch.execute('CREATE INDEX idx_records_account ON records(account_id)');
        await batch.commit(noResult: true);
      },
    );
    _database = opened;
    return opened;
  }

  @override
  Future<AppData> load() async {
    try {
      final db = await _db;
      final categoryRows = await db.query('categories', orderBy: 'sort_order');
      final accountRows = await db.query('accounts', orderBy: 'sort_order');
      final recordRows = await db.query('records', orderBy: 'date DESC');
      final settingRows = await db.query('settings');

      return AppData(
        categories: categoryRows.map(Category.fromMap).toList(),
        accounts: accountRows.map(Account.fromMap).toList(),
        transactions: recordRows.map(TransactionRecord.fromMap).toList(),
        settings: <String, String>{
          for (final row in settingRows)
            row['key']! as String: row['value']! as String,
        },
      );
    } on DatabaseException catch (error) {
      throw LedgerStoreException('读取本地数据失败：${error.toString()}');
    }
  }

  @override
  Future<void> putCategory(Category category) async {
    final db = await _db;
    await db.insert(
      'categories',
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteCategory(String id) async {
    final db = await _db;
    await db.delete('categories', where: 'id = ?', whereArgs: <Object>[id]);
  }

  @override
  Future<void> putAccount(Account account) async {
    final db = await _db;
    await db.insert(
      'accounts',
      account.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteAccount(String id) async {
    final db = await _db;
    await db.delete('accounts', where: 'id = ?', whereArgs: <Object>[id]);
  }

  @override
  Future<void> putTransaction(TransactionRecord record) async {
    final db = await _db;
    await db.insert(
      'records',
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteTransaction(String id) async {
    final db = await _db;
    await db.delete('records', where: 'id = ?', whereArgs: <Object>[id]);
  }

  @override
  Future<void> putSetting(String key, String value) async {
    final db = await _db;
    await db.insert(
      'settings',
      <String, Object?>{'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> putAll(AppData data) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete('categories');
      await txn.delete('accounts');
      await txn.delete('records');
      final batch = txn.batch();
      for (final category in data.categories) {
        batch.insert(
          'categories',
          category.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      for (final account in data.accounts) {
        batch.insert(
          'accounts',
          account.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      for (final record in data.transactions) {
        batch.insert(
          'records',
          record.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      for (final entry in data.settings.entries) {
        batch.insert(
          'settings',
          <String, Object?>{'key': entry.key, 'value': entry.value},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  @override
  Future<void> wipe() async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete('records');
      await txn.delete('categories');
      await txn.delete('accounts');
      await txn.delete('settings');
    });
  }
}
