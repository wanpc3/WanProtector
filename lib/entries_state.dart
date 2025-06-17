import 'package:flutter/material.dart';
import 'models/entry.dart';
import 'vault.dart';

class EntriesState with ChangeNotifier {
  List<Entry> _entries = [];
  bool _isLoading = true;
  final String _searchText = "";

  List<Entry> get entries {
    if (_searchText.isEmpty) return _entries;

    final lowerQuery = _searchText.toLowerCase();
    return _entries.where((entry) {
      return entry.title.toLowerCase().contains(lowerQuery) ||
             entry.username.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  bool get isLoading => _isLoading;

  Future<void> fetchEntries() async {
    _isLoading = true;
    notifyListeners();
    _entries = await Vault().getEntries();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> searchEntries(String query) async {
    _isLoading = true;
    notifyListeners();
    _entries = await Vault().searchEntries(query);
    _isLoading = false;
    notifyListeners();
  }

  //Refresh entries
  Future<void> refreshEntries() async {
    _entries = await Vault().getEntries();
    notifyListeners();
  }
}