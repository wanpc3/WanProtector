import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AutoLockState extends ChangeNotifier {
  bool _isAutoLockEnabled = true;
  final int _lockDuration = 60; // Fixed at 1 minute

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

  Future<void> setAutoLockEnabled(bool value) async {
    _isAutoLockEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_lock_enabled', value);
    notifyListeners();
  }
}