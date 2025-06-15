import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
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
  File? _file;

  // Backup Vault
  Future<void> _backupVault() async {
    try {
      // Request storage permission
      if (await Permission.storage.request().isGranted) {
        // Get the database path
        String dbPath = await getDatabasesPath();
        String sourcePath = p.join(dbPath, 'wan_protector.db');
        
        // Create backup directory if it doesn't exist
        Directory? backupDir = await getExternalStorageDirectory();
        String backupPath = p.join(backupDir!.path, 'WANProtectorBackups');
        await Directory(backupPath).create(recursive: true);
        
        // Create backup file with timestamp
        String timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
        String destPath = p.join(backupPath, 'wan_protector_backup_$timestamp.db');
        
        // Copy the database file
        await File(sourcePath).copy(destPath);
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup created successfully at: $destPath')),
        );
        
        // Optionally open the file location
        OpenFile.open(destPath);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Storage permission denied')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup failed: ${e.toString()}')),
      );
    }
  }

  // Restore Vault
  Future<void> _restoreVault() async {
    try {
      // Pick the backup file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['db'],
      );

      if (result != null) {
        File backupFile = File(result.files.single.path!);
        
        // Show confirmation dialog
        bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Confirm Restore'),
            content: Text('This will overwrite your current entries. Are you sure?'),
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
          // Get current database path
          String dbPath = await getDatabasesPath();
          String destPath = p.join(dbPath, 'wan_protector.db');
          
          // Close the database before restoring
          await dbHelper.close();
          
          // Copy the backup file to the database location
          await backupFile.copy(destPath);
          
          // Reopen the database
          await dbHelper.database;
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vault restored successfully')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Restore failed: ${e.toString()}')),
      );
      // Reopen database if restore failed
      await dbHelper.database;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Vault Settings'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
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
        separatorBuilder: (BuildContext context, int index) => const Divider(),
      ),
    );
  }
}