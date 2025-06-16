import 'package:flutter/material.dart';
import 'models/deleted_entry.dart';
import 'vault.dart';

class DeletedState with ChangeNotifier {
  List<DeletedEntry> _deletedEntries = [];
  bool _isLoading = true;

  List<DeletedEntry> get deletedEntries => _deletedEntries;
  bool get isLoading => _isLoading;

  Future<void> fetchDeletedEntries() async {
    _isLoading = true;
    notifyListeners();
    _deletedEntries = await Vault().getDeletedEntries();
    _isLoading = false;
    notifyListeners();
  }

  //Refresh entries
  Future<void> refreshDeletedEntries() async {
    _deletedEntries = await Vault().getDeletedEntries();
    notifyListeners();
  }
}