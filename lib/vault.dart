import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class Vault {
  static final Vault _instance = Vault._internal();
  factory Vault() => _instance;
  Vault._internal();
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), "wan_protector.db");
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {

        //Master Password
        db.execute('''
          CREATE TABLE master_password(
            id INTEGER PRIMARY KEY,
            password TEXT NOT NULL,
            created_at TEXT NOT NULL DEFAULT (datetime('now', 'localtime')),
            last_updated TEXT NOT NULL DEFAULT (datetime('now', 'localtime'))
          )
        ''');

        //Entry
        db.execute('''
          CREATE TABLE entry(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            username TEXT NOT NULL,
            password TEXT,
            url TEXT,
            notes TEXT,
            created_at TEXT NOT NULL DEFAULT (datetime('now', 'localtime')),
            last_updated TEXT NOT NULL DEFAULT (datetime('now', 'localtime'))
          )
        ''');

        //Deleted Entry
        db.execute('''
          CREATE TABLE deleted_entry(
            deleted_id INTEGER PRIMARY KEY,
            title TEXT NOT NULL,
            username TEXT NOT NULL,
            password TEXT,
            url TEXT,
            notes TEXT,
            created_at TEXT NOT NULL DEFAULT (datetime('now', 'localtime')),
            last_updated TEXT NOT NULL DEFAULT (datetime('now', 'localtime'))
          )
        ''');
      },
    );
  }

  //Check Master Password availability
  Future<bool> isMasterPasswordSet() async {
    final db = await database;
    final result = await db.query('master_password');
    return result.isNotEmpty;
  }

  //Insert Master Password
  Future<int> insertMasterPassword(
    String password,
    String createdAt,
    String lastUpdated,
  ) async {
    final db = await database;
    return await db.insert(
      'master_password',
      {
        'password': password,
        'created_at': createdAt,
        'last_updated': lastUpdated,
      },
      conflictAlgorithm: ConflictAlgorithm.replace
    );
  }

  //Update Master Password
  Future<int> updateMasterPassword(
    String newPassword,
  ) async {
    final db = await database;
    return await db.update(
      'master_password',
      {
        'password': newPassword,
        'last_updated': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace
    );
  }

  //Insert Entry
  Future<int> insertEntry(
    String title,
    String username,
    String password,
    String url,
    String notes,
  ) async {
    final db = await database;
    return await db.insert(
      'entry', 
      {
        'title': title,
        'username': username,
        'password': password,
        'url': url,
        'notes': notes,
        'created_at': DateTime.now().toIso8601String(),
        'last_updated': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace
    );
  }

  //Read Entry
  Future<List<Map<String, dynamic>>> getEntries() async {
    final db = await database;
    return db.query('entry');
  }

  //Search Entry
  Future<List<Map<String, dynamic>>> searchEntries(String query) async {
    final db = await this.database;
    final result = await db.query(
      'entry',
      where: 'title LIKE ? OR username LIKE ? OR notes LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
    );
    return result;
  }

  Future<List<Map<String, dynamic>>> getEntriesPaginated(int limit, int offset) async {
    final db = await database;
    return db.query(
      'entry',
      limit: limit,
      offset: offset,
      orderBy: 'created_at DESC',
    );
  }

  //Update Entry
  Future<int> updateEntry(
    int id,
    String newTitle,
    String newUsername,
    String newPassword,
    String newUrl,
    String newNotes,
  ) async {
    final db = await database;
    return await db.update(
      'entry',
      {
        'title': newTitle,
        'username': newUsername,
        'password': newPassword,
        'url': newUrl,
        'notes': newNotes,
        'last_updated': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  //Get single entry by ID
  Future<Map<String, dynamic>?> getEntryById(int id) async {
    final db = await database;
    final result = await db.query(
      'entry',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? result.first : null;
  }

  //Soft Delete
  Future<bool> softDeleteEntry(int id) async {
    final db = await database;
    try {
      return await db.transaction((txn) async {
        final entry = await txn.query(
          'entry',
          where: 'id = ?',
          whereArgs: [id],
          limit: 1,
        );

        if (entry.isNotEmpty) {
          await txn.insert('deleted_entry', {
            'deleted_id': id,
            'title': entry.first['title'],
            'username': entry.first['username'],
            'password': entry.first['password'],
            'url': entry.first['url'],
            'notes': entry.first['notes'],
            'created_at': entry.first['created_at'],
            'last_updated': DateTime.now().toIso8601String(),
          });

          await txn.delete('entry', where: 'id = ?', whereArgs: [id]);
          return true;
        }
        return false;
      });
    } catch (e) {
      debugPrint("Soft delete error: $e");
      return false;
    }
  }

  //Read Deleted Entry
  Future<List<Map<String, dynamic>>> getDeletedEntries() async {
    final db = await database;
    return db.query('deleted_entry');
  }

  //Search Deleted Entries
  Future<List<Map<String, dynamic>>> searchDeletedEntries(String query) async {
    final db = await this.database;
    if (query.isEmpty) return [];
    
    final searchQuery = query.toLowerCase();
    return await db.query(
      'deleted_entry',
      where: 'LOWER(title) LIKE ? OR LOWER(username) LIKE ? OR LOWER(notes) LIKE ?',
      whereArgs: ['%$searchQuery%', '%$searchQuery%', '%$searchQuery%'],
    );
  }

  Future<List<Map<String, dynamic>>> getDeletedEntriesPaginated(int limit, int offset) async {
    final db = await database;
    return db.query(
      'deleted_entry',
      limit: limit,
      offset: offset,
      orderBy: 'created_at DESC',
    );
  }

  Future<Map<String, dynamic>?> getDeletedEntryById(int id) async {
    final db = await database;
    final results = await db.query(
      'deleted_entry',
      where: 'deleted_id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return results.isEmpty ? null : results.first;
  }

  //Restore Deleted Entry
  Future<bool> restoreEntry(int deletedId) async {
    final db = await database;
    try {
      return await db.transaction((txn) async {
        // 1. Get the deleted entry
        final deletedEntry = await txn.query(
          'deleted_entry',
          where: 'deleted_id = ?',
          whereArgs: [deletedId],
          limit: 1,
        );

        if (deletedEntry.isNotEmpty) {
          // 2. Insert back into main table
          await txn.insert('entry', {
            'title': deletedEntry.first['title'],
            'username': deletedEntry.first['username'],
            'password': deletedEntry.first['password'],
            'url': deletedEntry.first['url'],
            'notes': deletedEntry.first['notes'],
            'created_at': deletedEntry.first['created_at'],
          });

          // 3. Remove from deleted table
          await txn.delete(
            'deleted_entry',
            where: 'deleted_id = ?',
            whereArgs: [deletedId],
          );
          return true;
        }
        return false;
      });
    } catch (e) {
      debugPrint("Restore error: $e");
      return false;
    }
  }

  //Delete Entry Permanently
  Future<void> deleteEntryPermanently(int oldId) async {
    final db = await database;
    await db.delete(
      'deleted_entry',
      where: 'deleted_id = ?',
      whereArgs: [oldId],
    );
  }
}