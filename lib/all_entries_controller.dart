import 'package:flutter/material.dart';

class AllEntriesController {
  VoidCallback? exitSearch;
  ValueChanged<String>? handleSearch;
  VoidCallback? navigateToAddEntry;

  void dispose() {
    exitSearch = null;
    handleSearch = null;
    navigateToAddEntry = null;
  }
}