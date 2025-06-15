import 'package:flutter/material.dart';

class DeletedEntriesController {
  VoidCallback? exitSearch;
  ValueChanged<String>? handleSearch;

  DeletedEntriesController({
    required this.exitSearch,
    required this.handleSearch,
  });

  void dispose() {
    exitSearch = null;
    handleSearch = null;
  }
}