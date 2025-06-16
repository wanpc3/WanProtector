import 'package:flutter/material.dart';
import 'models/entry.dart';
import 'vault.dart';

class EntriesState with ChangeNotifier {
  List<Entry> _entries = [];
  bool _isLoading = true;

  List<Entry> get entries => _entries;
  bool get isLoading => _isLoading;

  Future<void> fetchEntries() async {
    _isLoading = true;
    notifyListeners();
    _entries = await Vault().getEntries();
    _isLoading = false;
    notifyListeners();
  }

  //Refresh entries
  Future<void> refreshEntries() async {
    _entries = await Vault().getEntries();
    notifyListeners();
  }
}