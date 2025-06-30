import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'autolock_state.dart';

class AutoLock extends StatelessWidget {
  const AutoLock({
    Key? key,
  }): super(key: key);

  @override
  Widget build(BuildContext context) {
    final autoLockState = Provider.of<AutoLockState>(context);
    final isEnabled = autoLockState.isAutoLockEnabled;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Auto-Lock"),
        backgroundColor: const Color(0xFF000000),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
            title: const Text("Enable Auto-Lock"),
            subtitle: const Text("Lock the app after 1 minute in the background and when your screen is off."),
            value: isEnabled,
            onChanged: (bool value) {
              autoLockState.setAutoLockEnabled(value);
            },
            secondary: const Icon(
              Icons.lock_clock_outlined,
              color: const Color(0xFF4CAF50),
            ),
          ),
        ],
      ),
    );
  }
}