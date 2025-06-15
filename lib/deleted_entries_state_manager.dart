import 'package:flutter/material.dart';
import 'vault.dart';

class DeletedEntriesStateManager extends ChangeNotifier {
  final Vault _dbHelper = Vault();
  
  List<Map<String, dynamic>> _deletedEntries = [];
  List<Map<String, dynamic>> _filteredDeletedEntries = [];
  bool _isLoading = true;
  bool _hasMore = true;
  int _currentPage = 0;
  final int _itemsPerPage = 20;
  bool _isSearching = false;

  List<Map<String, dynamic>> get deletedEntries => _deletedEntries;
  List<Map<String, dynamic>> get filteredDeletedEntries => _filteredDeletedEntries;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  bool get isSearching => _isSearching;

  Future<void> loadDeletedEntries() async {
    _isLoading = true;
    notifyListeners();
    
    _currentPage = 0;
    final newEntries = await _dbHelper.getDeletedEntriesPaginated(_itemsPerPage, 0);

    _deletedEntries = List<Map<String, dynamic>>.from(newEntries);
    _filteredDeletedEntries = List<Map<String, dynamic>>.from(newEntries);
    _isLoading = false;
    _hasMore = newEntries.length == _itemsPerPage;
    notifyListeners();
  }

  Future<void> loadMoreDeletedEntries() async {
    if (!_hasMore || _isLoading || _isSearching) return;
    
    _isLoading = true;
    notifyListeners();
    
    _currentPage++;
    try {
      final newEntries = await _dbHelper.getDeletedEntriesPaginated(
        _itemsPerPage,
        _currentPage * _itemsPerPage,
      );

      if (newEntries.isNotEmpty) {
        _deletedEntries.addAll(newEntries);
        if (!_isSearching) {
          _filteredDeletedEntries.addAll(newEntries);
        }
        _hasMore = newEntries.length == _itemsPerPage;
      } else {
        _hasMore = false;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshDeletedEntries() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await loadDeletedEntries();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchDeletedEntries(String query) async {

    if (query.isEmpty) {
      exitSearch();
      return;
    }

    _isSearching = true;
    _isLoading = true;
    notifyListeners();
    
    try {
      final results = await _dbHelper.searchDeletedEntries(query);
      _filteredDeletedEntries = List<Map<String, dynamic>>.from(results);
      
      _currentPage = 0;
      _hasMore = false;
    } catch (e) {
      _filteredDeletedEntries = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void exitSearch() {
    if (!_isSearching) return;
    
    _isSearching = false;
    _filteredDeletedEntries = List.from(_deletedEntries);
    _currentPage = 0;
    _hasMore = _filteredDeletedEntries.length == _itemsPerPage;
    notifyListeners();
  }

  void deleteEntry(int id) {
    _deletedEntries.removeWhere((entry) => entry['deleted_id'] == id);
    _filteredDeletedEntries.removeWhere((entry) => entry['deleted_id'] == id);
    notifyListeners();
  }
}