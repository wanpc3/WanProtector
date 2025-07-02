import 'package:flutter/material.dart';
import 'models/deleted_entry.dart';
import 'vault.dart';

class DeletedState with ChangeNotifier {
  List<DeletedEntry> _deletedEntries = [];
  bool _isLoading = true;
  String _searchText = "";
  String? _error;

  List<DeletedEntry> get deletedEntries => List.unmodifiable(_deletedEntries);
  String get searchText => _searchText;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchDeletedEntries() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _deletedEntries = await Vault().getDeletedEntries();
    } catch (e) {
      _error = 'Failed to load deleted entries';
      debugPrint('Fetch error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchDeletedEntries(String query) async {
    if (_searchText == query && _deletedEntries.isNotEmpty) return;

    _searchText = query;

    if (query.isNotEmpty) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      _deletedEntries = query.isEmpty
          ? _deletedEntries
          : await Vault().searchDeletedEntries(query);
    } catch (e) {
      _error = 'Search failed';
      debugPrint('Search error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshDeletedEntries() async {
    if (_isLoading) return;
    await fetchDeletedEntries();
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
