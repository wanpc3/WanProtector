import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'autolock_state.dart';

class AutoLock extends StatelessWidget {
  const AutoLock({super.key});

  @override
  Widget build(BuildContext context) {
    final autoLockState = Provider.of<AutoLockState>(context);
    final isEnabled = autoLockState.isAutoLockEnabled;
    final selectedDuration = autoLockState.lockDuration;

    final List<Map<String, dynamic>> timeIntervals = [
      {'text': 'Immediately (Locks quickly)', 'value': 0},
      {'text': '15 seconds', 'value': 15},
      {'text': '30 seconds', 'value': 30},
      {'text': '1 minute', 'value': 60},
      {'text': '2 minutes', 'value': 120},
      {'text': '5 minutes', 'value': 300},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Auto-Lock"),
        backgroundColor: const Color(0xFF2ECC71),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Auto-Lock Switch
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
            title: const Text("Enable Auto-Lock"),
            subtitle: const Text("Enable auto-lock when you're not using the app or when your screen is off."),
            value: isEnabled,
            onChanged: (bool value) {
              autoLockState.setAutoLockEnabled(value);
            },
            secondary: const Icon(Icons.lock_clock),
          ),

          // Time interval Dropdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: AbsorbPointer(
              absorbing: !isEnabled,
              child: Opacity(
                opacity: isEnabled ? 1.0 : 0.5,
                child: DropdownButtonFormField<int>(
                  value: selectedDuration,
                  hint: const Text("Select Auto-Lock duration"),
                  isExpanded: true,
                  items: timeIntervals.map((interval) {
                    return DropdownMenuItem<int>(
                      value: interval['value'],
                      child: Text(interval['text']),
                    );
                  }).toList(),
                  onChanged: isEnabled ? (int? newValue) {
                    if (newValue != null) {
                      autoLockState.setLockDuration(newValue);
                    }
                  } : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}