import 'package:flutter/material.dart';
import 'all_entries_controller.dart';
import 'vault.dart';
import 'add_entry.dart';
import 'view_entry.dart';

class AllEntries extends StatefulWidget {
  final Function(int)? onEntryDeleted;
  final AllEntriesController? controller;

  const AllEntries({
    Key? key,
    this.onEntryDeleted,
    this.controller,
  }) : super(key: key);

  @override
  AllEntriesState createState() => AllEntriesState();
}

class AllEntriesState extends State<AllEntries> {
  final Vault _dbHelper = Vault();
  List<Map<String, dynamic>> _entries = [];
  bool _isLoading = true;
  bool _hasMore = true;
  int _currentPage = 0;
  final int _itemsPerPage = 20;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  // Search-related state
  bool _isSearching = false;
  List<Map<String, dynamic>> _filteredEntries = [];

  @override
  void initState() {
    super.initState();
    widget.controller?.exitSearch = _exitSearch;
    widget.controller?.handleSearch = _handleSearch;
    widget.controller?.navigateToAddEntry = _navigateToAddEntry;
    _scrollController.addListener(_scrollListener);
    _loadEntries();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_entries.isEmpty) {
      _loadEntries();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    widget.controller?.dispose();
    super.dispose();
  }

  void reload() {
    _loadEntries();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      if (_hasMore && !_isLoading && !_isSearching) {
        _loadMoreEntries();
      }
    }
  }

  //Search functionality
  void _handleSearch(String query) async {
    if (query.isEmpty) {
      _exitSearch();
      return;
    }

    final currentQuery = query;

    await Future.delayed(const Duration(milliseconds: 300));
  
    if (currentQuery != query || !mounted) return;
    
    setState(() => _isLoading = true);
    
    try {
      final results = await _dbHelper.searchEntries(query);
      
      if (!mounted) return;
      
      setState(() {
        _filteredEntries = results;
        _isLoading = false;
        _updateAnimatedList();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _exitSearch() {
    setState(() {
      _isSearching = false;
      _filteredEntries = List.from(_entries);
      _updateAnimatedList();
    });
  }

  void _updateAnimatedList() {
    _listKey.currentState?.removeAllItems(
      (context, animation) => SizeTransition(sizeFactor: animation),
    );
    
    for (int i = 0; i < _filteredEntries.length; i++) {
      _listKey.currentState?.insertItem(i);
    }
  }

  Future<void> _loadEntries() async {
    setState(() => _isLoading = true);
    _currentPage = 0;
    final newEntries = await _dbHelper.getEntriesPaginated(_itemsPerPage, 0);

    if (!mounted) return;

    setState(() {
      _entries = newEntries;
      _filteredEntries = List.from(newEntries);
      _isLoading = false;
      _hasMore = newEntries.length == _itemsPerPage;
      _updateAnimatedList();
    });
  }

  void _loadMoreEntries() async {
    if (!_hasMore || _isLoading || !mounted || _isSearching) return;

    setState(() => _isLoading = true);
    _currentPage++;
    
    try {
      final newEntries = await _dbHelper.getEntriesPaginated(
        _itemsPerPage,
        _currentPage * _itemsPerPage,
      );

      if (!mounted) return;

      setState(() {
        if (newEntries.isNotEmpty) {
          final startIndex = _entries.length;
          _entries.addAll(newEntries);
          _filteredEntries.addAll(newEntries);
          
          for (int i = 0; i < newEntries.length; i++) {
            _listKey.currentState?.insertItem(startIndex + i);
          }
          
          _hasMore = newEntries.length == _itemsPerPage;
        } else {
          _hasMore = false;
        }
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void removeEntryWithAnimation(int id) {
    if (!mounted || _entries.isEmpty || _isLoading) return;

    final index = _entries.indexWhere((entry) => entry['id'] == id);
    if (index == -1 || index >= _entries.length) return;

    final removedEntry = _entries.removeAt(index);
    _filteredEntries.removeWhere((entry) => entry['id'] == id);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _listKey.currentState?.mounted == true) {
        _listKey.currentState?.removeItem(
          index,
          (context, animation) => _buildAnimatedItem(removedEntry, animation),
          duration: const Duration(milliseconds: 300),
        );
      }
    });
  }

  void _navigateToAddEntry() async {
    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => AddEntry(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        }
      ),
    );

    if (result == true && mounted) {
      _loadEntries();
    }
  }

  void _navigateToViewEntry(Map<String, dynamic> entry) async {
    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => ViewEntry(
          entryId: entry['id'],
          onEntryUpdated: _loadEntries,
          onEntryDeleted: (id) {
            removeEntryWithAnimation(id);
            widget.onEntryDeleted?.call(id);
          },
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        }
      ),
    );

    if (result == true && mounted) {
      _loadEntries();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading && _filteredEntries.isEmpty
          ? Center(child: CircularProgressIndicator())
          : _filteredEntries.isEmpty
              ? Center(
                  child: Text(
                    _isSearching ? 'No results found' : 'No entries found.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : NotificationListener<ScrollNotification>(
                  onNotification: (scrollNotification) {
                    if (scrollNotification is ScrollEndNotification &&
                        _scrollController.position.extentAfter == 0) {
                      if (_hasMore && !_isLoading && !_isSearching) {
                        _loadMoreEntries();
                      }
                    }
                    return false;
                  },
                  child: AnimatedList(
                    key: _listKey,
                    controller: _scrollController,
                    initialItemCount: _filteredEntries.length,
                    itemBuilder: (context, index, animation) {
                      if (index >= _filteredEntries.length) {
                        return SizedBox.shrink();
                      }
                      final entry = _filteredEntries[index];
                      return _buildAnimatedItem(entry, animation);
                    },
                  ),
                ),
    );
  }

  Widget _buildAnimatedItem(Map<String, dynamic> entry, Animation<double> animation) {
    return SizeTransition(
      sizeFactor: animation,
      child: ListTile(
        key: ValueKey(entry['id']),
        leading: Icon(Icons.key, color: Colors.amber),
        title: Text(entry['title']),
        subtitle: Text(entry['username']),
        trailing: Text(
          _formatDate(entry['created_at']),
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        onTap: () => _navigateToViewEntry(entry),
      ),
    );
  }
}

String _formatDate(String isoString) {
  try {
    final dateTime = DateTime.parse(isoString);
    return "${dateTime.day}/${dateTime.month}/${dateTime.year}";
  } catch (e) {
    return isoString;
  }
}