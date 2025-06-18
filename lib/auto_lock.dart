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
              "Enable auto-lock after 1 minute when you're not using the app or when your screen is off.",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
            title: const Text("Enable Auto-Lock"),
            value: isEnabled,
            onChanged: (bool value) {
              autoLockState.setAutoLockEnabled(value);
            },
            secondary: const Icon(Icons.lock_clock),
          ),
        ],
      ),
    );
  }
}
