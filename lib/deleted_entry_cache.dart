import 'models/deleted_entry.dart';

class DeletedEntryCache {
  static final _instance = DeletedEntryCache._internal();
  final _cache = <int, DeletedEntry>{};
  
  factory DeletedEntryCache() => _instance;
  DeletedEntryCache._internal();
  
  void addDeletedEntry(DeletedEntry deletedEntry) => _cache[deletedEntry.deletedId!] = deletedEntry;
  DeletedEntry? getDeletedEntry(int deletedId) => _cache[deletedId];
  void invalidate(int deletedId) => _cache.remove(deletedId);
}