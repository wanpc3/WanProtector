import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'autolock_state.dart';

class AutoLock extends StatelessWidget {
  const AutoLock({super.key});

  @override
  Widget build(BuildContext context) {
    final autoLockState = Provider.of<AutoLockState>(context);
    final isEnabled = autoLockState.isAutoLockEnabled;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Auto-Lock"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Enable auto-lock after 1 minute of inactivity in the background and after 1 minute of inactivity when screen turns off',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SwitchListTile(
            title: const Text("Enable Auto-Lock"),
            value: isEnabled,
            onChanged: (bool value) {
              autoLockState.setAutoLockEnabled(value);
            },
          ),
        ],
      ),
    );
  }
}
