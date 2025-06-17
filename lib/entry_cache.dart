import 'models/entry.dart';

class EntryCache {
  static final _instance = EntryCache._internal();
  final _cache = <int, Entry>{};
  
  factory EntryCache() => _instance;
  EntryCache._internal();
  
  void addEntry(Entry entry) => _cache[entry.id!] = entry;
  Entry? getEntry(int id) => _cache[id];
  void invalidate(int id) => _cache.remove(id);
}