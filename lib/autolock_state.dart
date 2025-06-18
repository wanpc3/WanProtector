import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AutoLockState extends ChangeNotifier {
  bool _isAutoLockEnabled = false;
  bool _isLoaded = false;

  bool get isAutoLockEnabled => _isAutoLockEnabled;
  bool get isLoaded => _isLoaded;

  AutoLockState() {
    _loadAutoLockPreference();
  }
  
  Future<void> _loadAutoLockPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstRun = prefs.getBool('is_first_run') ?? true;

    if (isFirstRun) {
      _isAutoLockEnabled = true;
      await prefs.setBool('auto_lock_enabled', true);
      await prefs.setBool('is_first_run', false);
    } else {
      _isAutoLockEnabled = prefs.getBool('auto_lock_enabled') ?? false;
    }

    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setAutoLockEnabled(bool value) async {
    _isAutoLockEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_lock_enabled', value);
    notifyListeners();
  }
}
