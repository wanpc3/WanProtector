import 'package:flutter/material.dart';
import 'models/entry.dart';
import 'vault.dart';

class EntriesState with ChangeNotifier {
  List<Entry> _entries = [];
  bool _isLoading = true;
  String _searchText = "";
  String? _error;

  List<Entry> get entries => List.unmodifiable(_entries);
  String get searchText => _searchText;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchEntries() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _entries = await Vault().getEntries();
    } catch (e) {
      _error = 'Failed to load entries';
      debugPrint('Fetch error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchEntries(String query) async {
    if (_searchText == query && _entries.isNotEmpty) return;

    _searchText = query;

    if (query.isNotEmpty) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      _entries = query.isEmpty
          ? _entries
          : await Vault().searchEntries(query);
    } catch (e) {
      _error = 'Search failed';
      debugPrint('Search error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshEntries() async {
    if (_isLoading) return;
    await fetchEntries();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void resetSearch() {
    _searchText = '';
    notifyListeners();
  }
}