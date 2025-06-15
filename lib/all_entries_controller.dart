import 'package:flutter/material.dart';

class AllEntriesController {
  VoidCallback? exitSearch;
  ValueChanged<String>? handleSearch;
  VoidCallback? navigateToAddEntry;

  AllEntriesController({
    required this.exitSearch,
    required this.handleSearch,
    required this.navigateToAddEntry,
  });

  void dispose() {
    exitSearch = null;
    handleSearch = null;
    navigateToAddEntry = null;
  }
}