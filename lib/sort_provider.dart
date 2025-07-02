import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SortProvider with ChangeNotifier {
  String _sortMode = 'Recently Added';

  String get sortMode => _sortMode;

  SortProvider() {
    _loadSortMode();
  }

  void _loadSortMode() async {
    final prefs = await SharedPreferences.getInstance();
    _sortMode = prefs.getString('sortMode') ?? 'Recently Added';
    notifyListeners();
  }

  void setSortMode(String mode) async {
    _sortMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sortMode', _sortMode);
    notifyListeners();
  }
}