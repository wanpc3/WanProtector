import 'package:flutter/material.dart';
import 'vault.dart';

class EntriesState extends ChangeNotifier {
  final Vault _dbHelper = Vault();
  
  // Private state
  List<Map<String, dynamic>> _entries = [];
  List<Map<String, dynamic>> _filteredEntries = [];
  bool _isLoading = true;
  bool _hasMore = true;
  int _currentPage = 0;
  final int _itemsPerPage = 20;
  bool _isSearching = false;
  
  // Public getters
  List<Map<String, dynamic>> get entries => _entries;
  List<Map<String, dynamic>> get filteredEntries => _filteredEntries;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  bool get isSearching => _isSearching;

  Future<void> loadEntries() async {
    _isLoading = true;
    notifyListeners();
    
    _currentPage = 0;
    final newEntries = await _dbHelper.getEntriesPaginated(_itemsPerPage, 0);

    _entries = newEntries;
    _filteredEntries = List.from(newEntries);
    _isLoading = false;
    _hasMore = newEntries.length == _itemsPerPage;
    notifyListeners();
  }

  Future<void> loadMoreEntries() async {
    if (!_hasMore || _isLoading) return;
    
    _isLoading = true;
    notifyListeners();
    
    _currentPage++;
    final newEntries = await _dbHelper.getEntriesPaginated(
      _itemsPerPage,
      _currentPage * _itemsPerPage,
    );

    if (newEntries.isNotEmpty) {
      _entries.addAll(newEntries);
      _filteredEntries.addAll(newEntries);
      _hasMore = newEntries.length == _itemsPerPage;
    } else {
      _hasMore = false;
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> searchEntries(String query) async {
    if (query.isEmpty) {
      exitSearch();
      return;
    }

    _isSearching = true;
    _isLoading = true;
    notifyListeners();
    
    try {
      final results = await _dbHelper.searchEntries(query);
      _filteredEntries = results;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void exitSearch() {
    _isSearching = false;
    _filteredEntries = List.from(_entries);
    notifyListeners();
  }

  void removeEntry(int id) {
    _entries.removeWhere((entry) => entry['id'] == id);
    _filteredEntries.removeWhere((entry) => entry['id'] == id);
    notifyListeners();
  }
}