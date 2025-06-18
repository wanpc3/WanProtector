import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'dart:io';
import 'vault.dart';

class VaultSettings extends StatefulWidget {
  @override
  _VaultSettingsState createState() => _VaultSettingsState();
}

class _VaultSettingsState extends State<VaultSettings> {
  final List<String> contents = <String>[
    'Backup Vault',
    'Restore Vault',
  ];

  final Vault dbHelper = Vault();
  bool _isProcessing = false;
  
  Future<void> _backupVault() async {
    setState(() => _isProcessing = true);
    
    try {
      // 1. Get source file
      final dbPath = await getDatabasesPath();
      final sourceFile = File(p.join(dbPath, 'wan_protector.db'));
      if (!await sourceFile.exists()) {
        throw Exception('Database file not found');
      }

      // 2. Let user choose save location using system picker
      final String? savePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Backup As',
        fileName: 'wan_protector_backup_${DateTime.now().toIso8601String().replaceAll(RegExp(r'[:\.]'), '-')}.db',
        type: FileType.any,
        lockParentWindow: true,
      );

      if (savePath == null) return; // User cancelled

      // 3. Copy using FilePicker's result (works with scoped storage)
      final bytes = await sourceFile.readAsBytes();
      final backupFile = File(savePath);
      await backupFile.writeAsBytes(bytes);

      // 4. Verify
      if (!await backupFile.exists()) {
        throw Exception('Backup file was not created');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup saved successfully'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup failed: ${e.toString()}'),
            duration: Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _restoreVault() async {
    setState(() => _isProcessing = true);
    
    try {
      // 1. Let user select backup file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        File backupFile = File(result.files.single.path!);

        // 2. Verify the file exists
        if (!await backupFile.exists()) {
          throw Exception('Selected file not found');
        }

        // 3. Show confirmation dialog
        bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Confirm Restore'),
            content: Text('This will overwrite ALL current data. Continue?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Restore'),
              ),
            ],
          ),
        ) ?? false;

        if (confirm) {
          // 4. Get current database path
          String dbPath = await getDatabasesPath();
          String destPath = p.join(dbPath, 'wan_protector.db');
          
          // 5. Close database before restoring
          await dbHelper.close();
          
          // 6. Copy the backup file
          await backupFile.copy(destPath);
          
          // 7. Verify the restored database
          try {
            final db = await openDatabase(destPath);
            await db.close();
          } catch (e) {
            await File(destPath).delete();
            throw Exception('Invalid database file');
          }
          
          // 8. Reinitialize database
          await dbHelper.database;
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Vault restored successfully')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Restore failed: ${e.toString()}')),
      );
      // Reopen database if restore failed
      await dbHelper.database;
    } finally {
      setState(() => _isProcessing = false);
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
      body: _isProcessing
          ? Center(child: CircularProgressIndicator())
          : ListView.separated(
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