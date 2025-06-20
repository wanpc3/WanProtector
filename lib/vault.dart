import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:path/path.dart';
import 'entry_cache.dart';
import 'deleted_entry_cache.dart';
import 'encryption_helper.dart';
import 'models/master_password.dart';
import 'models/entry.dart';
import 'models/deleted_entry.dart';
import 'deleted_state.dart';
import 'entries_state.dart';

extension IntToBytes on int {
  List<int> get bigEndianBytes => [
    (this >> 24) & 0xFF,
    (this >> 16) & 0xFF,
    (this >> 8) & 0xFF,
    this & 0xFF,
  ];
}

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

  Future<void> clearCacheAndReopen() async {
    await close();
    _database = await _initDB();
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), "wp_vault.db");

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {

        //Master Password
        db.execute('''
          CREATE TABLE master_password(
            id INTEGER PRIMARY KEY CHECK (id = 1),
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

  //Get Vault path
  getVaultPath() async {
    String vaultPath = await getDatabasesPath();
    print("Path to Vault: $vaultPath");
    Directory? externalStoragePath = await getExternalStorageDirectory();
    print("Path to external storage: $externalStoragePath");
  }

  /*
  I/flutter (18649): Path to Vault: /data/user/0/com.ilhanidriss.wan_protector/databases/wp_vault.db
  I/flutter (18649): Path to external storage: Directory: '/storage/emulated/0/Android/data/com.ilhanidriss.wan_protector/files'
  */
  
  Future<String?> backupVault() async {
    try {
      // 1. Request permissions
      if (!await _requestStoragePermissions()) {
        return "Storage permission denied";
      }

      // 2. Get database file and encryption key
      final dbPath = await getDatabasesPath();
      final sourceFile = File(join(dbPath, 'wp_vault.db'));
      final key = await EncryptionHelper.backupKey();
      
      if (key == null) return "No encryption key found";
      if (!await sourceFile.exists()) return "No vault database found to backup";

      // 3. Read original database and encode key
      final originalBytes = await sourceFile.readAsBytes();
      final keyBytes = utf8.encode(key);

      // 4. Create backup bytes in separate steps
      final backupBytes = Uint8List(8 + keyBytes.length + originalBytes.length);
      
      // Set magic number "WPVK"
      backupBytes.setRange(0, 4, [0x57, 0x50, 0x56, 0x4B]);
      
      // Set key length (big-endian)
      backupBytes.setRange(4, 8, keyBytes.length.bigEndianBytes);
      
      // Set key bytes
      backupBytes.setRange(8, 8 + keyBytes.length, keyBytes);
      
      // Set original database content
      backupBytes.setRange(8 + keyBytes.length, backupBytes.length, originalBytes);

      // 5. Save as single file
      final String? savePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Vault Backup',
        fileName: 'wp_vault_backup.db',
        allowedExtensions: ['db'],
        type: FileType.custom,
        bytes: backupBytes,
      );

      return savePath == null ? "Backup cancelled" : null;
    } catch (e) {
      return "Backup failed: ${e.toString()}";
    }
  }
  
  Future<String?> restoreVault(BuildContext context) async {
  try {
    // 1. Request permissions
    if (!await _requestStoragePermissions()) {
      return "Storage permission denied";
    }

    FilePickerResult? result;
    
    // Try different file picking methods with fallbacks
    try {
      // First attempt: Use any file type but suggest .db files
      result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Select Vault Backup File',
        type: FileType.any,
        allowMultiple: false,
      );
    } catch (e) {
      debugPrint("FilePicker error: $e");
      // Fallback to basic file picker if the first attempt fails
      result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Select Vault Backup File',
        allowMultiple: false,
      );
    }

    if (result == null || result.files.isEmpty) {
      return "Restore cancelled";
    }

    final platformFile = result.files.single;
    if (platformFile.path == null) {
      return "Invalid file selected";
    }

    // 2. Read and validate backup file
    final backupFile = File(platformFile.path!);
    final backupBytes = await backupFile.readAsBytes();

    // Verify minimum file size and magic number
    if (backupBytes.length < 8 || 
        backupBytes[0] != 0x57 || // W
        backupBytes[1] != 0x50 || // P
        backupBytes[2] != 0x56 || // V
        backupBytes[3] != 0x4B) { // K
      return "Invalid backup file format";
    }

    // 3. Extract key length (big-endian)
    final keyLength = (backupBytes[4] << 24) | 
                     (backupBytes[5] << 16) | 
                     (backupBytes[6] << 8) | 
                     backupBytes[7];

    // Validate key length
    if (8 + keyLength > backupBytes.length) {
      return "Corrupted backup file (invalid key length)";
    }

    // 4. Extract and restore encryption key
    final key = utf8.decode(backupBytes.sublist(8, 8 + keyLength));
    if (!await EncryptionHelper.restoreKey(key)) {
      return "Failed to restore encryption key";
    }

    // 5. Extract and restore database
    final dbBytes = backupBytes.sublist(8 + keyLength);
    final dbPath = await getDatabasesPath();
    final destFile = File(join(dbPath, 'wp_vault.db'));
    await destFile.writeAsBytes(dbBytes);

    // 6. Refresh application state
    await clearCacheAndReopen();
    final stateDeletedManager = context.read<DeletedState>();
    final stateManager = context.read<EntriesState>();
    await stateDeletedManager.refreshDeletedEntries();
    await stateManager.refreshEntries();

    return null;
  } catch (e, stackTrace) {
    debugPrint("Restore error: $e\n$stackTrace");
    return "Restore failed: ${e.toString()}";
  }
}
  
  Future<bool> _requestStoragePermissions() async {
    try {
      if (Platform.isAndroid) {
        // For Android 10 and below
        var storageStatus = await Permission.storage.status;
        if (storageStatus.isDenied) {
          storageStatus = await Permission.storage.request();
        }

        // For Android 11 and above
        var manageStatus = await Permission.manageExternalStorage.status;
        if (manageStatus.isDenied) {
          manageStatus = await Permission.manageExternalStorage.request();
        }

        // Check if either permission is granted
        return storageStatus.isGranted || manageStatus.isGranted;
      }
      return true; // On iOS, permissions are handled differently
    } catch (e) {
      debugPrint("Permission error: $e");
      return false;
    }
  }

  //Check Master Password availability
  Future<bool> isMasterPasswordSet() async {
    final db = await database;
    final result = await db.query('master_password');
    return result.isNotEmpty;
  }

  //Insert Master Password
  Future<int> insertMasterPassword(
    String password, String createdAt, String lastUpdated) async {
    final db = await database;

    final masterPassword = MasterPassword(
      id: 1,
      password: password,
      createdAt: createdAt,
      lastUpdated: lastUpdated,
    );

    final map = await masterPassword.toMapAsync();

    return await db.insert(
      'master_password',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  //Verify master password
  Future<bool> verifyMasterPassword(String inputPassword) async {
    final db = await database;
    final result = await db.query('master_password', limit: 1);

    if (result.isEmpty) return false;

    final storedMasterPassword = await MasterPassword.fromMapAsync(result.first);

    return storedMasterPassword.password == inputPassword;
  }

  //Get Master Password
  Future<String?> getEncryptedMasterPassword() async {
    final db = await database;
    final result = await db.query('master_password', limit: 1);
    if (result.isNotEmpty) {
      return result.first['password'] as String;
    }
    return null;
  }

  //Update Master Password
  Future<int> updateMasterPassword(String newPassword) async {
    final db = await database;

    final masterPassword = MasterPassword(
      id: 1,
      password: newPassword,
      createdAt: "",
      lastUpdated: DateTime.now().toIso8601String(),
    );

    final map = await masterPassword.toMapAsync();

    map.remove('created_at');

    final rowsUpdated = await db.update(
      'master_password',
      map,
      where: 'id = 1',
    );

    if (rowsUpdated == 0) {
      throw Exception("No master password record to update.");
    }

    return rowsUpdated;
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
    
    //Encrypt before save
    final encryptedPassword = await EncryptionHelper.encryptText(password);
    final encryptedUsername = await EncryptionHelper.encryptText(username);
    final encryptedNotes = await EncryptionHelper.encryptText(notes);
    
    return await db.insert(
      'entry', 
      {
        'title': title,
        'username': encryptedUsername,
        'password': encryptedPassword,
        'url': url,
        'notes': encryptedNotes,
        'created_at': DateTime.now().toIso8601String(),
        'last_updated': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace
    );
  }

  //Read Entry
  Future<List<Entry>> getEntries() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'entry',
      orderBy: 'datetime(created_at) DESC',
    );

    final entries =  await Future.wait(
      maps.map((e) => Entry.fromMapAsync(e))
    );

    for (var entry in entries) {
      EntryCache().addEntry(entry);
    }

    return entries;
  }

  //Search Entry
  Future<List<Entry>> searchEntries(String query) async {
    final db = await this.database;
    final result = await db.query(
      'entry',
      where: 'LOWER(title) LIKE ? OR LOWER(username) LIKE ? OR LOWER(notes) LIKE ?',
      whereArgs: [
        '%${query.toLowerCase()}%',
        '%${query.toLowerCase()}%',
        '%${query.toLowerCase()}%'
      ],
    );

    return Future.wait(
      result.map((map) => Entry.fromMapAsync(map))
    );
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
    
    //Encrypt before save
    final encryptedPassword = await EncryptionHelper.encryptText(newPassword);
    final encryptedUsername = await EncryptionHelper.encryptText(newUsername);
    final encryptedNotes = await EncryptionHelper.encryptText(newNotes);

    final updated = await db.update(
      'entry',
      {
        'title': newTitle,
        'username': encryptedUsername,
        'password': encryptedPassword,
        'url': newUrl,
        'notes': encryptedNotes,
        'last_updated': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    EntryCache().invalidate(id);
    return updated;
  }

  //Get single entry by ID
  Future<Entry?> getEntryById(int id) async {

    //1) Check memory cache
    if (EntryCache().getEntry(id) != null) {
      return EntryCache().getEntry(id);
    }

    //2) Fetch from database
    final db = await database;
    final maps = await db.query(
      'entry',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    
    //3) Decrypt and cache
    final entry = await Entry.fromMapAsync(maps.first);
    EntryCache().addEntry(entry);
    return entry;
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
  Future<List<DeletedEntry>> getDeletedEntries() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'deleted_entry',
      orderBy: 'datetime(created_at) DESC',
    );
    
    final deletedEntries = await Future.wait(
      maps.map((e) => DeletedEntry.fromMapAsync(e))
    );

    for (var deletedEntry in deletedEntries) {
      DeletedEntryCache().addDeletedEntry(deletedEntry);
    }

    return deletedEntries;
  }

  //Search Deleted Entries
  Future<List<DeletedEntry>> searchDeletedEntries(String query) async {
    final db = await this.database;
    final result = await db.query(
      'deleted_entry',
      where: 'LOWER(title) LIKE ? OR LOWER(username) LIKE ? OR LOWER(notes) LIKE ?',
      whereArgs: [
        '%${query.toLowerCase()}%',
        '%${query.toLowerCase()}%',
        '%${query.toLowerCase()}%'
      ],
    );
    
    return Future.wait(
      result.map((map) => DeletedEntry.fromMapAsync(map))
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

  Future<DeletedEntry?> getDeletedEntryById(int deletedId) async {

    if (DeletedEntryCache().getDeletedEntry(deletedId) != null) {
      return DeletedEntryCache().getDeletedEntry(deletedId);
    }

    final db = await database;
    final maps = await db.query(
      'deleted_entry',
      where: 'deleted_id = ?',
      whereArgs: [deletedId],
    );

    if (maps.isEmpty) return null;
    
    final deletedEntry = await DeletedEntry.fromMapAsync(maps.first);
    DeletedEntryCache().addDeletedEntry(deletedEntry);
    return deletedEntry;
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