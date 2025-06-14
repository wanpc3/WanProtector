import 'package:flutter/material.dart';
import 'vault.dart';
import 'add_entry.dart';
import 'view_entry.dart';

class AllEntries extends StatefulWidget {
  final Function(int)? onEntryDeleted;

  const AllEntries({
    Key? key,
    this.onEntryDeleted
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

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _loadEntries();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadEntries();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void reload() {
    _loadEntries();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
          if (_hasMore && !_isLoading) {
            _loadMoreEntries();
          }
        }
  }

  void _loadEntries() async {
    setState(() => _isLoading = true);
    _currentPage = 0;
    final newEntries = await _dbHelper.getEntriesPaginated(_itemsPerPage, 0);

    if (!mounted) return;

    setState(() {
      _entries = []; // Clear immediately
      _entries.addAll(newEntries); // Add all new items
      
      // Only reset AnimatedList if we have items
      if (newEntries.isNotEmpty) {
        _listKey.currentState?.removeAllItems(
          (context, animation) => SizeTransition(sizeFactor: animation),
        );
        
        for (int i = 0; i < newEntries.length; i++) {
          _listKey.currentState?.insertItem(i);
        }
      }
      
      _isLoading = false;
      _hasMore = newEntries.length == _itemsPerPage;
    });
  }

  void _loadMoreEntries() async {
    if (!_hasMore || _isLoading || !mounted) return;

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
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  //During removal process
  void removeEntryWithAnimation(int id) {
    if (!mounted || _entries.isEmpty || _isLoading) return;

    final index = _entries.indexWhere((entry) => entry['id'] == id);
    if (index == -1 || index >= _entries.length) return;

    final removedEntry = _entries.removeAt(index);

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

  //To add entry form
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

    if (result == true) {
      _loadEntries();
    }
  }

  //To view entry
  void _navigateToViewEntry(Map<String, dynamic> entry) async {
    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => ViewEntry(
          entryId: entry['id'],
          onEntryUpdated: _loadEntries,
          onEntryDeleted: (id) => removeEntryWithAnimation(id),
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

    if (result == true) {
      _loadEntries();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading && _entries.isEmpty
          ? Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? Center(
                  child: Text(
                    'No entries found.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : NotificationListener<ScrollNotification>(
                  onNotification: (scrollNotification) {
                    if (scrollNotification is ScrollEndNotification &&
                        _scrollController.position.extentAfter == 0) {
                      if (_hasMore && !_isLoading) {
                        _loadMoreEntries();
                      }
                    }
                    return false;
                  },
                  child: AnimatedList(
                    key: _listKey,
                    controller: _scrollController,
                    initialItemCount: _entries.length,
                    itemBuilder: (context, index, animation) {
                      if (index >= _entries.length) {
                        return SizedBox.shrink();
                      }
                      final entry = _entries[index];
                      return _buildAnimatedItem(entry, animation);
                    },
                  ),
                ),

      //FAB: FLoating Action Button  
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddEntry,
        backgroundColor: const Color(0xFF085465),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  //Animated Item
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
  final dateTime = DateTime.parse(isoString);
  return "${dateTime.day}/${dateTime.month}/${dateTime.year}";
}
