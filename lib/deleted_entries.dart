import 'package:flutter/material.dart';
import 'view_deleted_entry.dart';
import 'vault.dart';

class DeletedEntries extends StatefulWidget {
  final VoidCallback? onEntryUpdated;

  const DeletedEntries({
    Key? key,
    this.onEntryUpdated
  }) : super(key: key);

  @override
  DeletedEntriesState createState() => DeletedEntriesState();
}

class DeletedEntriesState extends State<DeletedEntries> {
  final Vault _dbHelper = Vault();
  List<Map<String, dynamic>> _deletedEntries = [];
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
    _loadDeletedEntries();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadDeletedEntries();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void reload() {
    _loadDeletedEntries();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
      _scrollController.position.maxScrollExtent) {
        if (_hasMore && !_isLoading) {
          _loadMoreDeletedEntries();
        }
      }
  }

  Future <void> _loadDeletedEntries() async {
    setState(() => _isLoading = true);
    _currentPage = 0;
    final deletedEntries = await _dbHelper.getDeletedEntriesPaginated(
      _itemsPerPage,
      0
    );

    if (!mounted) return;
    
    setState(() {
      _deletedEntries = [];
      _deletedEntries.addAll(deletedEntries);

      if (deletedEntries.isNotEmpty) {
        _listKey.currentState?.removeAllItems(
          (context, animation) => SizeTransition(sizeFactor: animation),
        );

        for (int i = 0; i < deletedEntries.length; i++) {
          _listKey.currentState?.insertItem(i);
        }
      }

      _isLoading = false;
      _hasMore = deletedEntries.length == _itemsPerPage;
    });
  }

  void _loadMoreDeletedEntries() async {
    if (!_hasMore || _isLoading || !mounted) return;

    setState(() => _isLoading = true);
    _currentPage++;

    try {
      final deletedEntries = await _dbHelper.getDeletedEntriesPaginated(
        _itemsPerPage,
        _currentPage * _itemsPerPage, 
      );

      if (!mounted) return;

      setState(() {
        if (deletedEntries.isNotEmpty) {
          final startIndex = _deletedEntries.length;
          _deletedEntries.addAll(deletedEntries);

          for (int i = 0; i < deletedEntries.length; i++) {
            _listKey.currentState?.insertItem(startIndex + i);
          }

          _hasMore = deletedEntries.length == _itemsPerPage;
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

  //During deletion process
  void deleteEntryWithAnimation(int id) {
    if (!mounted || _deletedEntries.isEmpty || _isLoading) return;

    final index = _deletedEntries.indexWhere((deletedEntry) => deletedEntry['deleted_id'] == id);
    if (index == -1 || index >= _deletedEntries.length) return;

    final deleteEntry = _deletedEntries.removeAt(index);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _listKey.currentState?.mounted == true) {
        _listKey.currentState?.removeItem(
          index,
          (context, animation) => _buildAnimatedItem(deleteEntry, animation),
          duration: const Duration(milliseconds: 300),
        );
      }
    });
  }

  //To view deleted entry
  void _navigateToViewDeletedEntry(Map<String, dynamic> oldEntry) async {
    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => ViewDeletedEntry(
          oldId: oldEntry['deleted_id'],
          onRestored: () {
            restoreEntryWithAnimation(oldEntry['deleted_id']);
            widget.onEntryUpdated?.call();
          },
          onEntryUpdated: widget.onEntryUpdated,
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
      _loadDeletedEntries();
    }
  }

  Future<void> insertNewDeletedEntry(int id) async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    
    try {
      final entry = await _dbHelper.getDeletedEntryById(id);
      if (entry == null || !mounted) return;

      await Future.delayed(const Duration(milliseconds: 100)); // Allow animation to complete
      
      if (!mounted) return;
      
      setState(() {
        _deletedEntries.insert(0, entry);
        _listKey.currentState?.insertItem(0, duration: const Duration(milliseconds: 300));
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      debugPrint('Error inserting deleted entry: $e');
      // Fallback to refresh if single insert fails
      if (mounted) _loadDeletedEntries();
    }
  }

  //During restoration
  void restoreEntryWithAnimation(int id) {
    if (!mounted || _deletedEntries.isEmpty || _isLoading) return;

    final index = _deletedEntries.indexWhere((entry) => entry['deleted_id'] == id);
    if (index == -1) return;

    final restoredEntry = _deletedEntries.removeAt(index);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _listKey.currentState?.mounted == true) {
        _listKey.currentState?.removeItem(
          index,
          (context, animation) => SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(-1, 0),
              end: Offset.zero,
            ).animate(animation),
            child: _buildAnimatedItem(restoredEntry, animation),
          ),
          duration: const Duration(milliseconds: 300),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: _isLoading && _deletedEntries.isEmpty
          ? Center(child: CircularProgressIndicator())
          : _deletedEntries.isEmpty
              ? Center(
                child: Text(
                  'No deleted entries.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ): NotificationListener<ScrollNotification>(
                onNotification: (scrollNotification) {
                  if (scrollNotification is ScrollEndNotification &&
                      _scrollController.position.extentAfter == 0) {
                        if (_hasMore && !_isLoading) {
                          _loadMoreDeletedEntries();
                        }
                      }
                    return false;
                  },
                  child: AnimatedList(
                    key: _listKey,
                    controller: _scrollController,
                    initialItemCount: _deletedEntries.length,
                    itemBuilder: (context, index, animation) {
                      if (index >= _deletedEntries.length) {
                        return SizedBox.shrink();
                      }
                      final deletedEntry = _deletedEntries[index];
                      return _buildAnimatedItem(deletedEntry, animation);
                    },
                  ),
              ),
    );
  }

  //Animated Item
  Widget _buildAnimatedItem(Map<String, dynamic> deletedEntry, Animation<double> animation) {
    return SizeTransition(
      sizeFactor: animation,
      child: Column(
        children: [
          Divider(height: 1, thickness: 0.5),
          ListTile(
            key: ValueKey(deletedEntry['deleted_id']),
            leading: Icon(Icons.close, color: Colors.red),
            title: Text(deletedEntry['title']),
            subtitle: Text(deletedEntry['username']),
            trailing: Text(
              _formatDate(deletedEntry['created_at']),
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            onTap: () => _navigateToViewDeletedEntry(deletedEntry),
          ),
          Divider(height: 1, thickness: 0.5),
        ],
      ),
    );
  }
}

String _formatDate(String isoString) {
  final dateTime = DateTime.parse(isoString);
  return "${dateTime.day}/${dateTime.month}/${dateTime.year}";
}