import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'alerts.dart';

/*
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
            onChanged: (value) => autoLockState.setAutoLockEnabled(value, context),
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
*/

class AutoLockState extends ChangeNotifier {
  bool _isAutoLockEnabled = true;
  final int _lockDuration = 60; //Fixed at 1 minute

  bool get isAutoLockEnabled => _isAutoLockEnabled;
  int get lockDuration => _lockDuration;

  AutoLockState() {
    _loadPreferences();
  }
  
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _isAutoLockEnabled = prefs.getBool('auto_lock_enabled') ?? true;
    notifyListeners();
  }

  Future<void> setAutoLockEnabled(bool value, BuildContext context) async {
    _isAutoLockEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_lock_enabled', value);
    notifyListeners();

    //Snackbar message
    final alertsEnabled = context.read<AlertsProvider>().showAlerts;
    if (alertsEnabled && context.mounted) {
      final message = _isAutoLockEnabled ? 'Auto-Lock Enabled' : 'Auto-Lock Disabled';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }
}