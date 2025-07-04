import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
import 'auto_lock.dart';
import 'alerts.dart';
import 'lifecycle_watcher.dart';

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

  //Vault Initialization
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

  //Verify Database Integrity
  Future<bool> verifyDatabaseIntegrity() async {
    final db = await database;
    try {
      // Check master_password table exists
      final result = await db.rawQuery('''
        SELECT 1 FROM sqlite_master 
        WHERE type='table' AND name='master_password'
      ''');
      
      if (result.isEmpty) return false;
      
      // Verify we can read password
      final pw = await getEncryptedMasterPassword();
      return pw != null;
    } catch (e) {
      debugPrint('Database integrity check failed: $e');
      return false;
    }
  }
  
  //Backup Vault
  Future<String?> backupVault(BuildContext context) async {

    bool isCancelled = false;
    bool isDialogShowing = false;

    //Pause auto-lock immediately
    LifecycleWatcher.of(context)?.pauseAutoLock();

    // Show progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          title: const Text("Creating Backup"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              const Text("Preparing backup..."),
              const SizedBox(height: 20),
              TextButton(
                child: const Text("Cancel"),
                onPressed: () {
                  isCancelled = true;
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      ),
    ).then((_) => isDialogShowing = false);
    isDialogShowing = true;
    
    try {
      //1) Check cancellation
      if (isCancelled) {
        _showCancellationSnackBar(context, "Backup cancelled");
        return "Backup cancelled";
      }

      //2) Request permissions
      if (!await _requestStoragePermissions()) {
        if (isDialogShowing) Navigator.of(context).pop();
        _showErrorSnackBar(context, "Storage permission denied");
        return "Storage permission denied";
      }

      //3) Get database file and encryption key
      if (isCancelled) {
        _showCancellationSnackBar(context, "Backup cancelled");
        return "Backup cancelled";
      }

      final dbPath = await getDatabasesPath();
      final sourceFile = File(join(dbPath, 'wp_vault.db'));
      final key = await EncryptionHelper.backupKey();

      if (isCancelled) {
        _showCancellationSnackBar(context, "Backup cancelled");
        return "Backup cancelled";
      }
      
      if (key == null) {
        if (isDialogShowing) Navigator.of(context).pop();
        _showErrorSnackBar(context, "No encryption key found");
        return "No encryption key found";
      }
      
      if (!await sourceFile.exists()) {
        if (isDialogShowing) Navigator.of(context).pop();
        _showErrorSnackBar(context, "No vault database found to backup");
        return "No vault database found to backup";
      }

      //4) Create backup file
      final originalBytes = await sourceFile.readAsBytes();
      final keyBytes = utf8.encode(key);
      final backupBytes = Uint8List(8 + keyBytes.length + originalBytes.length);
      
      backupBytes.setRange(0, 4, [0x57, 0x50, 0x56, 0x4B]);
      backupBytes.setRange(4, 8, keyBytes.length.bigEndianBytes);
      backupBytes.setRange(8, 8 + keyBytes.length, keyBytes);
      backupBytes.setRange(8 + keyBytes.length, backupBytes.length, originalBytes);

      //5) Save file
      final String? savePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Vault Backup',
        fileName: 'wp_vault_backup.db',
        allowedExtensions: ['db'],
        type: FileType.custom,
        bytes: backupBytes,
      );

      if (savePath == null) {
        if (isDialogShowing) Navigator.of(context).pop();
        _showCancellationSnackBar(context, "Backup cancelled");
        return "Backup cancelled";
      }

      if (isCancelled) {
        _showCancellationSnackBar(context, "Backup cancelled");
        return "Backup cancelled";
      }

      // Close loading dialog
      if (isDialogShowing) Navigator.of(context).pop();

      // Show success dialog (keep as dialog for important feedback)
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Backup Succeeded"),
            content: const Text("Vault backup saved successfully"),
            actions: [
              TextButton(
                child: const Text("OK"), 
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        },
      );

      return null;
    } catch (e) {
      if (isDialogShowing) Navigator.of(context).pop();
      
      // For unexpected errors, show a dialog with more details
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Backup Error"),
          content: Text(e.toString()),
          actions: [
            TextButton(
              child: const Text("OK"),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
      return "Backup failed: ${e.toString()}";
    } finally {
      final duration = Provider.of<AutoLockState>(context, listen: false).lockDuration;
      LifecycleWatcher.of(context)?.resumeAutoLock(duration);
    }
  }
  
  //Restore Vault
  Future<String?> restoreVault(BuildContext context) async {
    bool isCancelled = false;
    bool isDialogShowing = false;
    File? tempRestoreFile;
    File? backupDbFile;
    final secureStorage = FlutterSecureStorage();

    // Pause auto-lock
    LifecycleWatcher.of(context)?.pauseAutoLock();

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Restoring Vault"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            const Text("Preparing restore..."),
            const SizedBox(height: 20),
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                isCancelled = true;
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    ).then((_) => isDialogShowing = false);
    isDialogShowing = true;

    try {
      if (isCancelled) {
        _showErrorSnackBar(context, "Restore cancelled");
        return "Restore cancelled";
      }

      // 1. Request permissions
      if (!await _requestStoragePermissions()) {
        if (isDialogShowing) Navigator.of(context).pop();
        _showErrorSnackBar(context, "Storage permission denied");
        return "Storage permission denied";
      }

      // 2. Pick backup file
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Select Vault Backup File',
        type: FileType.any,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty || result.files.single.path == null) {
        if (isDialogShowing) Navigator.of(context).pop();
        _showErrorSnackBar(context, "Restore cancelled");
        return "Restore cancelled";
      }

      final backupFile = File(result.files.single.path!);
      final backupBytes = await backupFile.readAsBytes();

      // 3. Validate backup file format
      if (backupBytes.length < 8 ||
          backupBytes[0] != 0x57 ||
          backupBytes[1] != 0x50 ||
          backupBytes[2] != 0x56 ||
          backupBytes[3] != 0x4B) {
        _showErrorSnackBar(context, "Invalid backup file format");
        return "Invalid backup file format";
      }

      // 4. Extract encryption key and database
      final keyLength = (backupBytes[4] << 24) |
          (backupBytes[5] << 16) |
          (backupBytes[6] << 8) |
          backupBytes[7];

      if (8 + keyLength > backupBytes.length) {
        _showErrorSnackBar(context, "Corrupted backup file (invalid key length)");
        return "Corrupted backup file (invalid key length)";
      }

      final key = utf8.decode(backupBytes.sublist(8, 8 + keyLength));
      final dbBytes = backupBytes.sublist(8 + keyLength);

      // 5. Create temporary restore file
      final dbPath = await getDatabasesPath();
      tempRestoreFile = File(join(dbPath, 'wp_vault_temp_restore.db'));
      await tempRestoreFile.writeAsBytes(dbBytes);

      // 6. Open temp database and extract backup password
      final tempDb = await openDatabase(tempRestoreFile.path);
      String? backupPassword;
      try {
        final result = await tempDb.query('master_password', limit: 1);
        if (result.isEmpty) {
          _showErrorSnackBar(context, "Backup missing master password");
          return "Backup missing master password";
        }

        // Use the backup encryption key temporarily
        EncryptionHelper.useTemporaryKey(key);

        final backupRecord = await MasterPassword.fromMapAsync(result.first);
        backupPassword = backupRecord.password;

        // Restore previous key immediately after use
        EncryptionHelper.restorePreviousKey();

      } finally {
        await tempDb.close();
      }

      // 7. Compare with current master password
      final currentRecord = await Vault().getMasterPasswordRecord();
      final currentPassword = currentRecord?.password;

      if (currentPassword != null && currentPassword != backupPassword) {
        if (isDialogShowing) Navigator.of(context).pop();

        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Restore Blocked"),
            content: const Text(
              "This backup uses a different master password.\n\n"
              "Please use the password that was set when this backup was created.",
            ),
            actions: [
              TextButton(
                child: const Text("OK"),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );

        return "Master password mismatch";
      }

      // 9. Confirm restore
      final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Confirm Restore"),
              content: const Text(
                "All current entries will be replaced with data from this backup. Continue?",
              ),
              actions: [
                TextButton(
                  child: const Text("Cancel"),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                TextButton(
                  child: const Text("Proceed"),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            ),
          ) ??
          false;

      if (!confirm) {
        if (isDialogShowing) Navigator.of(context).pop();
        _showErrorSnackBar(context, "Restore cancelled");
        return "Restore cancelled";
      }

      // 10. Backup current database
      final mainDbFile = File(join(dbPath, 'wp_vault.db'));
      backupDbFile = File(join(dbPath, 'wp_vault_backup.db'));
      if (await mainDbFile.exists()) {
        await mainDbFile.copy(backupDbFile.path);
      }

      // 11. Restore encryption key
      if (!await EncryptionHelper.restoreKey(key)) {
        _showErrorSnackBar(context, "Failed to restore encryption key");
        return "Failed to restore encryption key";
      }

      // 12. Replace database
      if (await mainDbFile.exists()) await mainDbFile.delete();
      await tempRestoreFile.rename(mainDbFile.path);

      // 13. Reinitialize database connection
      await Vault().close();
      final db = await Vault().database;

      // 14. Update master password record
      if (currentPassword != null) {
        // Preserve current password
        await db.delete('master_password');
        await db.insert(
          'master_password',
          await currentRecord!.toMapAsync(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // Update secure storage with current password
        final encrypted = await EncryptionHelper.encryptText(currentPassword);
        await secureStorage.write(key: 'auth_token', value: encrypted);
      } else if (backupPassword != null) {
        // If no current password, use backup's password
        final encrypted = await EncryptionHelper.encryptText(backupPassword);
        await secureStorage.write(key: 'auth_token', value: encrypted);
      }

      // 15. Refresh application state
      final stateManager = context.read<EntriesState>();
      final deletedManager = context.read<DeletedState>();
      await stateManager.refreshEntries();
      await deletedManager.refreshDeletedEntries();

      if (isDialogShowing) Navigator.of(context).pop();

      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Restore Complete"),
          content: const Text("Your vault has been successfully restored."),
          actions: [
            TextButton(
              child: const Text("OK"),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );

      return null;
    } catch (e, stack) {
      debugPrint("Restore error: $e\n$stack");

      // Attempt to restore from backup if available
      final dbPath = await getDatabasesPath();
      final mainDbFile = File(join(dbPath, 'wp_vault.db'));
      final backupDbFile = File(join(dbPath, 'wp_vault_backup.db'));

      if (await backupDbFile.exists()) {
        try {
          if (await mainDbFile.exists()) await mainDbFile.delete();
          await backupDbFile.rename(mainDbFile.path);
          await Vault().close();
          await Vault().database;
        } catch (err) {
          debugPrint("Rollback failed: $err");
        }
      }

      if (isDialogShowing) Navigator.of(context).pop();

      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Restore Failed"),
          content: Text("Error occurred: ${e.toString()}"),
          actions: [
            TextButton(
              child: const Text("OK"),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );

      return "Restore failed: ${e.toString()}";
    } finally {
      try {
        if (tempRestoreFile != null && await tempRestoreFile.exists()) {
          await tempRestoreFile.delete();
        }
        if (backupDbFile != null && await backupDbFile.exists()) {
          await backupDbFile.delete();
        }
      } catch (e) {
        debugPrint("Cleanup failed: $e");
      }

      final duration = Provider.of<AutoLockState>(context, listen: false).lockDuration;
      LifecycleWatcher.of(context)?.resumeAutoLock(duration);
    }
  }

  //Show Cancel Snackbar
  void _showCancellationSnackBar(BuildContext context, String message) {
    final alertsEnabled = context.read<AlertsProvider>().showAlerts;
    if (alertsEnabled && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  //Show Error Snackbar
  void _showErrorSnackBar(BuildContext context, String message) {
    final alertsEnabled = context.read<AlertsProvider>().showAlerts;
    if (alertsEnabled && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }
  
  //Request Storage Permission: For Backup and Restore Vault
  Future<bool> _requestStoragePermissions() async {
    try {
      if (Platform.isAndroid) {
        //For Android 10 and below
        var storageStatus = await Permission.storage.status;
        if (storageStatus.isDenied) {
          storageStatus = await Permission.storage.request();
        }

        //For Android 11 and above
        var manageStatus = await Permission.manageExternalStorage.status;
        if (manageStatus.isDenied) {
          manageStatus = await Permission.manageExternalStorage.request();
        }

        return storageStatus.isGranted || manageStatus.isGranted;
      }
      return true;
    } catch (e) {
      debugPrint("Permission error: $e");
      return false;
    }
  }

  //Verify Mastear Password Consistency
  Future<bool> verifyMasterPasswordConsistency() async {
    try {
      // Get from database
    final dbRecord = await getMasterPasswordRecord();
    if (dbRecord == null) return false;
    
    // Get from secure storage
    final secureStorage = FlutterSecureStorage();
    final storedToken = await secureStorage.read(key: 'auth_token');
    if (storedToken == null) return false;
    
    // Decrypt and compare
    final decryptedSecure = await EncryptionHelper.decryptText(storedToken);
    return dbRecord.password == decryptedSecure;
    } catch (e) {
      debugPrint("Consistency check error: $e");
      return false;
    }
  }

  //Check Master Password availability
  Future<bool> isMasterPasswordSet() async {
    final db = await database;
    final result = await db.query('master_password');
    return result.isNotEmpty;
  }

  //Get Master Password Record
  Future<MasterPassword?> getMasterPasswordRecord() async {
    final db = await database;
    final result = await db.query('master_password', limit: 1);
    if (result.isEmpty) return null;
    return await MasterPassword.fromMapAsync(result.first);
  }

  //Get Master Password
  Future<String?> getMasterPassword() async {
    final db = await database;
    final result = await db.query('master_password', limit: 1);
    if (result.isNotEmpty) {
      return result.first['password'] as String;
    }
    return null;
  }

  //Get Encrypted Master Password
  Future<String?> getEncryptedMasterPassword() async {
    final db = await database;
    final result = await db.query('master_password', limit: 1);
    if (result.isNotEmpty) {
      return result.first['password'] as String;
    }
    return null;
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

  //Count how many entries are there
  Future<int> getEntryCount() async {
    final db = await database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM entry')
    );
    return count ?? 0;
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
    final lowerQuery = query.toLowerCase();

    final result = await db.query('entry');

    final entries = await Future.wait(
      result.map((map) => Entry.fromMapAsync(map)),
    );

    return entries.where((entry) {
      return _matchesSearchEntries(entry, lowerQuery);
    }).toList();
  }

  bool _matchesSearchEntries(Entry entry, String lowerQuery) {
    return entry.title.toLowerCase().contains(lowerQuery) ||
           entry.username.toLowerCase().contains(lowerQuery) ||
          (entry.password?.toLowerCase().contains(lowerQuery) ?? false ) ||
          (entry.url?.toLowerCase().contains(lowerQuery) ?? false) ||
          (entry.notes?.toLowerCase().contains(lowerQuery) ?? false);
  }

  //Get Entries Paginated
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

  //Count how many deleted entries are there
  Future<int> getDeletedEntryCount() async {
    final db = await database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM deleted_entry')
    );
    return count ?? 0;
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
    final lowerQuery = query.toLowerCase();

    final result = await db.query('deleted_entry');

    final deletedEntries = await Future.wait(
      result.map((map) => DeletedEntry.fromMapAsync(map)),
    );

    return deletedEntries.where((deletedEntry) {
      return _matchesSearchDeletedEntries(deletedEntry, lowerQuery);
    }).toList();
  }

  bool _matchesSearchDeletedEntries(DeletedEntry deletedEntry, String lowerQuery) {
    return deletedEntry.title.toLowerCase().contains(lowerQuery) ||
           deletedEntry.username.toLowerCase().contains(lowerQuery) ||
          (deletedEntry.password?.toLowerCase().contains(lowerQuery) ?? false ) ||
          (deletedEntry.url?.toLowerCase().contains(lowerQuery) ?? false) ||
          (deletedEntry.notes?.toLowerCase().contains(lowerQuery) ?? false);
  }

  //Get Deleted Entries Paginated
  Future<List<Map<String, dynamic>>> getDeletedEntriesPaginated(int limit, int offset) async {
    final db = await database;
    return db.query(
      'deleted_entry',
      limit: limit,
      offset: offset,
      orderBy: 'created_at DESC',
    );
  }

  //Get Deleted Entry By Id
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