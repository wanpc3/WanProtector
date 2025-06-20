import 'vault.dart';
import 'package:flutter/material.dart';

class VaultSettings extends StatefulWidget {
  @override
  _VaultSettingsState createState() => _VaultSettingsState();
}

class _VaultSettingsState extends State<VaultSettings> {

  final List<String> contents = <String>[
    'Backup Vault',
    'Restore Vault',
  ];

  final List<IconData> leadingIcons = <IconData>[
    Icons.save,
    Icons.restore,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Vault Settings'),
        backgroundColor: const Color(0xFF0A708A),
        foregroundColor: Colors.white,
      ),
      body: ListView.separated(
              padding: const EdgeInsets.all(8),
              itemCount: contents.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  leading: Icon(leadingIcons[index]),
                  title: Text(contents[index]),
                  onTap: () async {
                    if (contents[index] == 'Backup Vault') {
                      await Vault().backupVault(context);
                    } else if (contents[index] == 'Restore Vault') {
                      await Vault().restoreVault(context);
                    }
                  },
                );
              },
              separatorBuilder: (BuildContext context, int index) => Divider(),
            ),
    );
  }
}