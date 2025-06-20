import 'package:flutter/material.dart';
import 'models/deleted_entry.dart';
import 'vault.dart';

class DeletedState with ChangeNotifier {
  List<DeletedEntry> _deletedEntries = [];
  bool _isLoading = true;
  final String _searchText = "";

  List<DeletedEntry> get deletedEntries {
    if (_searchText.isEmpty) return _deletedEntries;

    final lowerQuery = _searchText.toLowerCase();
    return _deletedEntries.where((deletedEntry) {
      return deletedEntry.title.toLowerCase().contains(lowerQuery) ||
             deletedEntry.username.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  bool get isLoading => _isLoading;

  Future<void> fetchDeletedEntries() async {
    _isLoading = true;
    notifyListeners();

    final newDeletedEntries = _deletedEntries = await Vault().getDeletedEntries();

    _deletedEntries = newDeletedEntries;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> searchDeletedEntries(String query) async {
    _isLoading = true;
    notifyListeners();
    _deletedEntries = await Vault().searchDeletedEntries(query);
    _isLoading = false;
    notifyListeners();
  }

  //Refresh entries
  Future<void> refreshDeletedEntries() async {
    _deletedEntries = await Vault().getDeletedEntries();
    notifyListeners();
  }
}