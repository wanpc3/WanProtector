import 'dart:io';
import 'dart:typed_data';
import 'vault.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'entries_state.dart';
import 'deleted_state.dart';

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
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Select Vault Backup',
      type: FileType.any,
    );

    if (result == null || result.files.isEmpty) {
      // User canceled
      return;
    }

    // Handle both web and mobile platforms
    String? pickedFilePath = result.files.single.path;
    Uint8List? fileBytes = result.files.single.bytes;

    if (pickedFilePath == null && fileBytes == null) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Error"),
          content: const Text("Could not access the selected file."),
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

    // 2. Close current DB connection
    await Vault().close();

    // 3. Replace the current DB file with the selected backup
    final vaultPath = path.join(await getDatabasesPath(), "wp_vault.db");
    final File vaultFile = File(vaultPath);

    if (fileBytes != null) {
      // For web or when bytes are available
      await vaultFile.writeAsBytes(fileBytes);
    } else if (pickedFilePath != null) {
      // For mobile when path is available
      await File(pickedFilePath).copy(vaultFile.path);
    }

    // 4. Reopen DB connection
    await Vault().database;

    // 5. Refresh UI state from Providers
    if (mounted) {
      final entriesState = context.read<EntriesState>();
      final deletedState = context.read<DeletedState>();

      await entriesState.refreshEntries();
      await deletedState.refreshDeletedEntries();
    }

    // 6. Inform user
    if (mounted) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Restore Complete"),
          content: const Text("Vault restored successfully."),
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
    // Reopen database even if restore failed
    await Vault().database;

    if (mounted) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Restore Failed"),
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