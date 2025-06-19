import 'dart:io';
import 'dart:typed_data';
import 'package:WanProtector/vault.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

class VaultSettings extends StatefulWidget {
  @override
  _VaultSettingsState createState() => _VaultSettingsState();
}

class _VaultSettingsState extends State<VaultSettings> {
  final List<String> contents = <String>[
    'Backup Vault',
    'Restore Vault',
  ];

  //Upload Vault to Files
  Future<void> _backupVault() async {
    try {
      //1) Permission check
      var status = await Permission.storage.status;
      if (status.isPermanentlyDenied) {
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Permission denied"),
            content: const Text("Enable storage permission in settings"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text("OK"),
              ),
            ],
          ),
        );
        return;
      }

      //2) Close database
      await Vault().close();

      //3) Get file and check existence
      final vaultPath = path.join(await getDatabasesPath(), "wp_vault.db");
      final vaultFile = File(vaultPath);

      if (!await vaultFile.exists()) {
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Error"),
            content: const Text("Database file not found."),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text("OK"),
              ),
            ],
          ),
        );
        return;
      }

      //4) Read bytes
      final bytes = await vaultFile.readAsBytes();

      //5) Save with FilePicker
      final String? savePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Backup Vault',
        fileName: 'wp_vault_backup.db',
        allowedExtensions: ['db'],
        type: FileType.custom,
        bytes: bytes,
      );

      //6) Reopen database
      await Vault().database;

      //7) Enhanced success feedback
      if (savePath != null && mounted) {
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Backup Complete"),
            content: const Text("Vault backed up successfully."),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Backup Failed"),
          content: Text("Error: ${e.toString()}"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }
  }

  //Restore Vault
  Future<void> _restoreVault() async {
    try {
      // 1. Pick backup file
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.any,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      // 2. Get bytes from file (with fallback)
      Uint8List? bytes = result.files.first.bytes;
      if (bytes == null || bytes.isEmpty) {
        final filePath = result.files.first.path;
        if (filePath != null) {
          bytes = await File(filePath).readAsBytes();
        } else {
          throw Exception("Could not read file contents");
        }
      }

      // 3. Create temp file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/restore_temp.db');
      await tempFile.writeAsBytes(bytes);

      // 4. Open backup database
      final backupDb = await openDatabase(tempFile.path);

      // 5. Verify backup structure
      final tables = await backupDb.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'");
      final requiredTables = ['entry', 'deleted_entry'];
      if (!requiredTables.every((t) => tables.any((row) => row['name'] == t))) {
        throw Exception("Invalid backup file structure");
      }

      // 6. Get current database
      final currentDb = await Vault().database;
      
      // 7. Get current master password to preserve it
      final currentMasterPassword = await currentDb.query('master_password');

      // 8. Perform restore transaction
      await currentDb.transaction((txn) async {
        // Clear existing data (except master_password)
        await txn.delete('entry');
        await txn.delete('deleted_entry');

        // Restore entries
        final entries = await backupDb.rawQuery('SELECT * FROM entry');
        for (final entry in entries) {
          await txn.insert('entry', entry);
        }

        // Restore deleted entries
        final deletedEntries = await backupDb.rawQuery('SELECT * FROM deleted_entry');
        for (final entry in deletedEntries) {
          await txn.insert('deleted_entry', entry);
        }

        // Restore original master password if it was cleared
        if (currentMasterPassword.isNotEmpty) {
          await txn.insert('master_password', currentMasterPassword.first,
            conflictAlgorithm: ConflictAlgorithm.replace);
        }
      });

      // 9. Clean up
      await backupDb.close();
      await tempFile.delete();

      // 10. Show success
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Restore Complete"),
            content: const Text("Vault data restored successfully\nMaster password preserved"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("OK"))
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Restore Failed"),
            content: Text("Error: ${e.toString()}"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("OK"))
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Vault Settings'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: ListView.separated(
              padding: const EdgeInsets.all(8),
              itemCount: contents.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  title: Text(contents[index]),
                  onTap: () {
                    if (contents[index] == 'Backup Vault') {
                      _backupVault();
                    } else if (contents[index] == 'Restore Vault') {
                      _restoreVault();
                    }
                  },
                );
              },
              separatorBuilder: (BuildContext context, int index) => Divider(),
            ),
    );
  }
}