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

  final List<Color> iconColors = <Color>[
    const Color(0xFF4CAF50),
    const Color(0xFF0288D1),
  ];

  int _entryCount = 0;
  int _deletedEntryCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    final entryCount = await Vault().getEntryCount();
    final deletedCount = await Vault().getDeletedEntryCount();
    
    setState(() {
      _entryCount = entryCount;
      _deletedEntryCount = deletedCount;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Vault Settings'),
          backgroundColor: const Color(0xFF424242),
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Vault Settings'),
        backgroundColor: const Color(0xFF424242),
        foregroundColor: Colors.white,
      ),
      body: ListView.separated(
              padding: const EdgeInsets.all(8),
              itemCount: contents.length,
              itemBuilder: (BuildContext context, int index) {
                final isBackup = contents[index] == 'Backup Vault';
                final canBackup = (_entryCount > 0 || _deletedEntryCount > 0);

                final subtitleText = isBackup
                    ? 'Securely save an encrypted copy of your vault'
                    : 'Recover your vault from an encrypted backup';

                return ListTile(
                  leading: Icon(
                      leadingIcons[index],
                      color: isBackup && !canBackup ? Colors.grey : iconColors[index]),
                  title: Text(
                    contents[index],
                    style: TextStyle(
                      color: isBackup && !canBackup ? Colors.grey : null,
                    ),
                  ),
                  subtitle: Text(subtitleText),
                  onTap: (isBackup && !canBackup)
                      ? null
                      : () async {
                          if (isBackup) {
                            await Vault().backupVault(context);
                          } else {
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