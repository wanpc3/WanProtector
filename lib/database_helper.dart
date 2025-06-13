import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class Databasehelper {
  static final Databasehelper _instance = Databasehelper._internal();
  factory Databasehelper() => _instance;
  Databasehelper._internal();
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
  Future<void> insertMasterPassword(
    String password,
    String createdAt,
    String lastUpdated,
  ) async {
    final db = await database;
    await db.insert(
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
  Future<void> updateMasterPassword(
    String newPassword,
  ) async {
    final db = await database;
    await db.update(
      'master_password',
      {
        'password': newPassword,
        'last_updated': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace
    );
  }

  //Insert Entry
  Future<void> insertEntry(
    String title,
    String username,
    String password,
    String url,
    String notes,
  ) async {
    final db = await database;
    await db.insert(
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
  Future<void> updateEntry(
    int id,
    String newTitle,
    String newUsername,
    String newPassword,
    String newUrl,
    String newNotes,
  ) async {
    final db = await database;
    await db.update(
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
      limit: 1,
    );
    if (result.isNotEmpty) {
      return result.first;
    } else {
      return null;
    }
  }

  //Soft Delete
  Future<void> softDeleteEntry(int id) async {
    final db = await database;

    //1) Get the entry to perform soft-delete
    final entry = await db.query(
      'entry',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    //2) Insert into deleted_entry table
    if (entry.isNotEmpty) {
      await db.insert(
        'deleted_entry',
        {
          'deleted_id': entry[0]['id'],
          'title': entry[0]['title'],
          'username': entry[0]['username'],
          'password': entry[0]['password'],
          'url': entry[0]['url'],
          'notes': entry[0]['notes'],
          'last_updated': DateTime.now().toIso8601String(),
        }
      );
    }

    //3) Delete from main entry table
    await db.delete(
      'entry',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  //Read Deleted Entry
  Future<List<Map<String, dynamic>>> getDeletedEntries() async {
    final db = await database;
    return db.query('deleted_entry');
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

  //Restore Deleted Entry
  Future<void> restoreEntry(int oldId) async {
    final db = await database;
    
    //1) Get the deleted entry
    final deletedEntry = await db.query(
      'deleted_entry',
      where: 'deleted_id = ?',
      whereArgs: [oldId],
      limit: 1,
    );
    
    if (deletedEntry.isNotEmpty) {
      //2) Insert back into entry table
      await db.insert(
        'entry',
        {
          'id': deletedEntry[0]['deleted_id'],
          'title': deletedEntry[0]['title'],
          'username': deletedEntry[0]['username'],
          'password': deletedEntry[0]['password'],
          'url': deletedEntry[0]['url'],
          'notes': deletedEntry[0]['notes'],
          'last_updated': DateTime.now().toIso8601String(),
        },
      );
      
      //3) Remove from deleted_entry table
      await db.delete(
        'deleted_entry',
        where: 'deleted_id = ?',
        whereArgs: [oldId],
      );
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