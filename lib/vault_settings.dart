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
                  onTap: () async {
                    if (contents[index] == 'Backup Vault') {
                      //_backupVault();
                      await Vault().backupVault();
                    } else if (contents[index] == 'Restore Vault') {
                      //_restoreVault();
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