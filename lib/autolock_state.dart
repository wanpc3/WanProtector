import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AutoLockState extends ChangeNotifier {
  static const _autoLockEnabledKey = 'auto_lock_enabled';
  bool _isAutoLockEnabled = false;

  AutoLockState() {
    _loadSetting();
  }

  bool get isAutoLockEnabled => _isAutoLockEnabled;

  Future<void> _loadSetting() async {
    final prefs = await SharedPreferences.getInstance();
    _isAutoLockEnabled = prefs.getBool(_autoLockEnabledKey) ?? false;
    notifyListeners();
  }

  Future<void> setAutoLockEnabled(bool value) async {
    _isAutoLockEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoLockEnabledKey, value);
    notifyListeners();
  }
}
